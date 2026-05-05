-- ============================================================
-- IT TICKET — Schema Supabase
-- Execute este SQL no Supabase Dashboard → SQL Editor
-- ============================================================

-- -----------------------------------------------
-- TABELAS
-- -----------------------------------------------

create table if not exists public.companies (
  id          text primary key,
  name        text not null,
  logo        text,
  created_at  timestamptz default now(),
  active      boolean default true,
  settings    jsonb default '{}'::jsonb
);
-- Garantir colunas mesmo se a tabela já existia
alter table public.companies add column if not exists logo        text;
alter table public.companies add column if not exists created_at  timestamptz default now();
alter table public.companies add column if not exists active      boolean default true;
alter table public.companies add column if not exists settings    jsonb default '{}'::jsonb;

create table if not exists public.profiles (
  id                uuid primary key references auth.users(id) on delete cascade,
  company_id        text references public.companies(id),
  email             text not null,
  display_name      text not null,
  role              text not null default 'pending',
  associated_client text,
  created_at        timestamptz default now()
);

create table if not exists public.tickets (
  id               text primary key,
  company_id       text references public.companies(id),
  title            text not null,
  description      text,
  client           text,
  status           text not null,
  category         text,
  priority         text,
  responsible      text,
  sla              text,
  created_at       timestamptz default now(),
  updated_at       timestamptz default now(),
  updates          jsonb default '[]'::jsonb,
  attachments      jsonb default '[]'::jsonb,
  history          jsonb default '[]'::jsonb,
  archived         integer default 0,
  sla_notified     boolean default false,
  sla_notified_at  timestamptz,
  in_progress_since timestamptz,
  is_important     boolean default false,
  total_hours      float default 0,
  billed_hours     float default 0
);
-- Garantir colunas mesmo se a tabela já existia
alter table public.tickets add column if not exists company_id         text references public.companies(id);
alter table public.tickets add column if not exists priority           text;
alter table public.tickets add column if not exists updates            jsonb default '[]'::jsonb;
alter table public.tickets add column if not exists attachments        jsonb default '[]'::jsonb;
alter table public.tickets add column if not exists history            jsonb default '[]'::jsonb;
alter table public.tickets add column if not exists archived           integer default 0;
alter table public.tickets add column if not exists sla_notified       boolean default false;
alter table public.tickets add column if not exists sla_notified_at    timestamptz;
alter table public.tickets add column if not exists in_progress_since  timestamptz;
alter table public.tickets add column if not exists is_important       boolean default false;
alter table public.tickets add column if not exists total_hours        float default 0;
alter table public.tickets add column if not exists billed_hours       float default 0;

create table if not exists public.schedules (
  id          text primary key,
  company_id  text references public.companies(id),
  analyst     text not null,
  date        text not null,
  end_date    text,
  shift       text not null
);

create table if not exists public.backups (
  id          text primary key,
  company_id  text,
  timestamp   timestamptz,
  date        text,
  tickets     jsonb default '[]'::jsonb,
  users       jsonb default '[]'::jsonb,
  schedules   jsonb default '[]'::jsonb,
  company     jsonb
);

-- -----------------------------------------------
-- FUNÇÕES AUXILIARES DE RLS
-- -----------------------------------------------

create or replace function public.my_company_id()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select company_id from profiles where id = auth.uid()
$$;

create or replace function public.my_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from profiles where id = auth.uid()
$$;

-- -----------------------------------------------
-- FUNÇÃO: gerar ID sequencial de ticket por empresa
-- -----------------------------------------------

create or replace function public.get_next_ticket_id(p_company_id text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_next_id  integer;
  v_settings jsonb;
begin
  select settings into v_settings
  from companies
  where id = p_company_id
  for update;

  v_next_id := coalesce((v_settings->>'nextTicketId')::integer, 2000);

  update companies
  set settings = jsonb_set(
    coalesce(settings, '{}'::jsonb),
    '{nextTicketId}',
    (v_next_id + 1)::text::jsonb
  )
  where id = p_company_id;

  return v_next_id::text;
end;
$$;

-- -----------------------------------------------
-- HABILITAR RLS
-- -----------------------------------------------

alter table public.companies  enable row level security;
alter table public.profiles   enable row level security;
alter table public.tickets    enable row level security;
alter table public.schedules  enable row level security;
alter table public.backups    enable row level security;

-- -----------------------------------------------
-- POLÍTICAS: companies
-- -----------------------------------------------

create policy "Usuários veem sua empresa"
  on public.companies for select
  using (
    id = my_company_id()
    or my_role() = 'superadmin'
  );

create policy "Superadmin gerencia empresas"
  on public.companies for all
  using (my_role() = 'superadmin')
  with check (my_role() = 'superadmin');

-- -----------------------------------------------
-- POLÍTICAS: profiles
-- -----------------------------------------------

create policy "Usuários veem perfil próprio"
  on public.profiles for select
  using (
    id = auth.uid()
    or (company_id = my_company_id() and my_role() in ('admin', 'superadmin'))
  );

create policy "Usuários atualizam perfil próprio"
  on public.profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "Admin gerencia perfis da empresa"
  on public.profiles for all
  using (
    company_id = my_company_id()
    and my_role() in ('admin', 'superadmin')
  )
  with check (
    company_id = my_company_id()
    and my_role() in ('admin', 'superadmin')
  );

-- INSERT via service role (criação de usuário pelo admin usa server.ts)
create policy "Service role insere perfis"
  on public.profiles for insert
  with check (true);

-- -----------------------------------------------
-- POLÍTICAS: tickets
-- -----------------------------------------------

create policy "Usuários veem tickets da empresa"
  on public.tickets for select
  using (
    company_id = my_company_id()
    or my_role() = 'superadmin'
  );

create policy "Usuários criam tickets na empresa"
  on public.tickets for insert
  with check (
    company_id = my_company_id()
    or my_role() = 'superadmin'
  );

create policy "Usuários atualizam tickets da empresa"
  on public.tickets for update
  using (
    company_id = my_company_id()
    or my_role() = 'superadmin'
  );

create policy "Admin exclui tickets"
  on public.tickets for delete
  using (
    (company_id = my_company_id() and my_role() in ('admin', 'superadmin'))
    or my_role() = 'superadmin'
  );

-- -----------------------------------------------
-- POLÍTICAS: schedules
-- -----------------------------------------------

create policy "Usuários veem escalas da empresa"
  on public.schedules for select
  using (
    company_id = my_company_id()
    or my_role() = 'superadmin'
  );

create policy "Admin gerencia escalas"
  on public.schedules for all
  using (
    (company_id = my_company_id() and my_role() in ('admin', 'superadmin'))
    or my_role() = 'superadmin'
  )
  with check (
    (company_id = my_company_id() and my_role() in ('admin', 'superadmin'))
    or my_role() = 'superadmin'
  );

-- -----------------------------------------------
-- POLÍTICAS: backups
-- -----------------------------------------------

create policy "Admin vê backups da empresa"
  on public.backups for select
  using (
    (company_id = my_company_id() and my_role() in ('admin', 'superadmin'))
    or my_role() = 'superadmin'
  );

create policy "Admin cria backups"
  on public.backups for insert
  with check (
    (company_id = my_company_id() and my_role() in ('admin', 'superadmin'))
    or my_role() = 'superadmin'
  );

create policy "Admin exclui backups"
  on public.backups for delete
  using (my_role() = 'superadmin');

-- -----------------------------------------------
-- REALTIME — habilitar tabelas
-- -----------------------------------------------
-- Execute no Dashboard: Database → Replication → Source → Add tables:
-- tickets, profiles, companies, schedules, backups

-- OU via SQL:
-- alter publication supabase_realtime add table public.tickets;
-- alter publication supabase_realtime add table public.profiles;
-- alter publication supabase_realtime add table public.companies;
-- alter publication supabase_realtime add table public.schedules;
-- alter publication supabase_realtime add table public.backups;

-- -----------------------------------------------
-- EMPRESA PADRÃO (opcional — seed inicial)
-- -----------------------------------------------
insert into public.companies (id, name, active, settings)
values (
  'itmanage',
  'IT Manage',
  true,
  '{"nextTicketId": 2000, "webhookUrl": "", "customClients": ["Avan\u00e7ar","Bixnet","Brasilink","Iplay","Jrnet","Meconnect","Nexo","Prosseguir"], "customCategories": []}'::jsonb
)
on conflict (id) do nothing;
