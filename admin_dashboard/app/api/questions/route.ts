import { NextRequest, NextResponse } from "next/server";
import { supabaseAdmin } from "@/lib/supabase-admin";

// POST — ajouter ou modifier une question
export async function POST(req: NextRequest) {
  const body = await req.json();

  const { id, isEdit, ...fields } = body;

  if (isEdit) {
    // Modification d'une question existante
    const { error } = await supabaseAdmin
      .from("questions")
      .update(fields)
      .eq("id", id);

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }
    return NextResponse.json({ ok: true });
  }

  // Ajout d'une nouvelle question
  const { error } = await supabaseAdmin
    .from("questions")
    .insert({ id, ...fields });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }
  return NextResponse.json({ ok: true });
}

// PATCH — activer/desactiver une question
export async function PATCH(req: NextRequest) {
  const { id, statut } = await req.json();

  const { error } = await supabaseAdmin
    .from("questions")
    .update({ statut })
    .eq("id", id);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }
  return NextResponse.json({ ok: true });
}
