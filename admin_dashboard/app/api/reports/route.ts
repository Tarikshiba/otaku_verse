import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { supabaseAdmin } from "@/lib/supabase-admin";

const ALLOWED_STATUSES = ["open", "resolved", "dismissed"];

// GET /api/reports — Liste des signalements d'erreurs questions (admin authentifie)
export async function GET(req: NextRequest) {
  const { errorResponse } = await requireAdmin(req);
  if (errorResponse) return errorResponse;

  const statusFilter = req.nextUrl.searchParams.get("status");
  let query = supabaseAdmin
    .from("question_reports")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(200);

  if (statusFilter && ALLOWED_STATUSES.includes(statusFilter)) {
    query = query.eq("status", statusFilter);
  }

  const { data, error } = await query;
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
  return NextResponse.json({ reports: data ?? [] });
}

// PATCH /api/reports — Mettre a jour le statut d'un signalement (resolved / dismissed / open)
export async function PATCH(req: NextRequest) {
  const { errorResponse } = await requireAdmin(req);
  if (errorResponse) return errorResponse;

  const body = await req.json();
  const id = typeof body?.id === "string" ? body.id.trim() : "";
  const status = typeof body?.status === "string" ? body.status.trim() : "";

  if (!id || !ALLOWED_STATUSES.includes(status)) {
    return NextResponse.json({ error: "Parametres id ou status invalides." }, { status: 400 });
  }

  const { error } = await supabaseAdmin
    .from("question_reports")
    .update({ status })
    .eq("id", id);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
  return NextResponse.json({ ok: true });
}
