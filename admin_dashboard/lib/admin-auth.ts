import { NextRequest, NextResponse } from "next/server";
import { supabaseAdmin } from "@/lib/supabase-admin";

// Liste officielle des administrateurs autorises (cote serveur uniquement)
export const ADMIN_EMAILS = ["drx@otaku.admin", "heat@otaku.admin"];

export interface AdminAuthResult {
  user: { id: string; email: string } | null;
  errorResponse: NextResponse | null;
}

/**
 * Verifie le JWT Supabase envoye dans le header Authorization
 * et confirme que le compte fait partie des administrateurs autorises.
 */
export async function requireAdmin(req: NextRequest): Promise<AdminAuthResult> {
  const authHeader = req.headers.get("authorization") || "";
  const match = authHeader.match(/^Bearer\s+(.+)$/i);

  if (!match || !match[1]) {
    return {
      user: null,
      errorResponse: NextResponse.json(
        { error: "Authentification requise." },
        { status: 401 }
      ),
    };
  }

  const token = match[1].trim();
  const { data, error } = await supabaseAdmin.auth.getUser(token);

  if (error || !data?.user?.email) {
    return {
      user: null,
      errorResponse: NextResponse.json(
        { error: "Session invalide ou expiree." },
        { status: 401 }
      ),
    };
  }

  const email = data.user.email.toLowerCase();
  if (!ADMIN_EMAILS.includes(email)) {
    return {
      user: null,
      errorResponse: NextResponse.json(
        { error: "Acces refuse. Droits administrateur requis." },
        { status: 403 }
      ),
    };
  }

  return {
    user: { id: data.user.id, email },
    errorResponse: null,
  };
}
