import { createClient } from "@supabase/supabase-js";

// Client avec service_role key — uniquement cote serveur (Route Handlers)
// Bypass RLS pour les operations admin (ajout, modif, suppression)
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || "";
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY || "";

export const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);
