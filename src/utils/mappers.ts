import { Ticket, UserProfile, Company } from "../types";

// ─── Ticket ──────────────────────────────────────────────

export function mapTicket(row: any): Ticket {
  if (!row) return row;
  return {
    id: row.id,
    companyId: row.company_id,
    title: row.title,
    description: row.description,
    client: row.client,
    status: row.status,
    category: row.category,
    priority: row.priority,
    responsible: row.responsible,
    sla: row.sla,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    updates: row.updates || [],
    attachments: row.attachments || [],
    history: row.history || [],
    archived: row.archived ?? 0,
    slaNotified: row.sla_notified,
    slaNotifiedAt: row.sla_notified_at,
    inProgressSince: row.in_progress_since,
    isImportant: row.is_important,
    totalHours: row.total_hours,
    billedHours: row.billed_hours,
  };
}

export function ticketToRow(ticket: Partial<Ticket>): Record<string, unknown> {
  const row: Record<string, unknown> = {};
  if ("id" in ticket)               row.id = ticket.id;
  if ("companyId" in ticket)        row.company_id = ticket.companyId;
  if ("title" in ticket)            row.title = ticket.title;
  if ("description" in ticket)      row.description = ticket.description;
  if ("client" in ticket)           row.client = ticket.client;
  if ("status" in ticket)           row.status = ticket.status;
  if ("category" in ticket)         row.category = ticket.category;
  if ("priority" in ticket)         row.priority = ticket.priority;
  if ("responsible" in ticket)      row.responsible = ticket.responsible;
  if ("sla" in ticket)              row.sla = ticket.sla;
  if ("createdAt" in ticket)        row.created_at = ticket.createdAt;
  if ("updatedAt" in ticket)        row.updated_at = ticket.updatedAt;
  if ("updates" in ticket)          row.updates = ticket.updates;
  if ("attachments" in ticket)      row.attachments = ticket.attachments;
  if ("history" in ticket)          row.history = ticket.history;
  if ("archived" in ticket)         row.archived = ticket.archived;
  if ("slaNotified" in ticket)      row.sla_notified = ticket.slaNotified;
  if ("slaNotifiedAt" in ticket)    row.sla_notified_at = ticket.slaNotifiedAt;
  if ("inProgressSince" in ticket)  row.in_progress_since = ticket.inProgressSince;
  if ("isImportant" in ticket)      row.is_important = ticket.isImportant;
  if ("totalHours" in ticket)       row.total_hours = ticket.totalHours;
  if ("billedHours" in ticket)      row.billed_hours = ticket.billedHours;
  return row;
}

// ─── UserProfile ─────────────────────────────────────────

export function mapProfile(row: any): UserProfile {
  if (!row) return row;
  return {
    uid: row.id,
    companyId: row.company_id,
    email: row.email,
    displayName: row.display_name,
    role: row.role,
    associatedClient: row.associated_client,
  };
}

export function profileToRow(profile: Partial<UserProfile>): Record<string, unknown> {
  const row: Record<string, unknown> = {};
  if ("uid" in profile)             row.id = profile.uid;
  if ("companyId" in profile)       row.company_id = profile.companyId;
  if ("email" in profile)           row.email = profile.email;
  if ("displayName" in profile)     row.display_name = profile.displayName;
  if ("role" in profile)            row.role = profile.role;
  if ("associatedClient" in profile) row.associated_client = profile.associatedClient;
  return row;
}

// ─── Company ─────────────────────────────────────────────

export function mapCompany(row: any): Company {
  if (!row) return row;
  return {
    id: row.id,
    name: row.name,
    logo: row.logo,
    createdAt: row.created_at,
    active: row.active,
    settings: row.settings || {},
  };
}

// ─── Schedule ────────────────────────────────────────────

export function mapSchedule(row: any): any {
  if (!row) return row;
  return {
    id: row.id,
    companyId: row.company_id,
    analyst: row.analyst,
    date: row.date,
    endDate: row.end_date,
    shift: row.shift,
  };
}
