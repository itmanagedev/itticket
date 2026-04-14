import { createClient } from "@supabase/supabase-js";

const supabaseUrl =
  import.meta.env.VITE_SUPABASE_URL ||
  "https://khefvxwpjcuurvsmlhck.supabase.co";

const supabaseKey =
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ||
  "sb_publishable_E8w7SqpZRAmW5Ljw61fJ_A_uNrANSDL";

export const supabase = createClient(supabaseUrl, supabaseKey);
