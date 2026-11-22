import { NextRequest, NextResponse } from "next/server";
import { supabaseAdmin } from "@/lib/supabase-admin";
import { requireAdmin } from "@/lib/admin-auth";

const DIFFICULTES_VALIDES = ["facile", "moyen", "difficile", "expert", "maitre"];
const REPONSES_VALIDES = ["A", "B", "C", "D"];
const STATUTS_VALIDES = ["actif", "inactif"];

// POST : ajouter ou modifier une question (admin verifie cote serveur)
export async function POST(req: NextRequest) {
  const { errorResponse } = await requireAdmin(req);
  if (errorResponse) return errorResponse;

  const body = await req.json();
  const id = typeof body.id === "string" ? body.id.trim() : "";
  const isEdit = Boolean(body.isEdit);

  if (!id) {
    return NextResponse.json({ error: "Identifiant question manquant." }, { status: 400 });
  }

  const anime = typeof body.anime === "string" ? body.anime.trim().toLowerCase() : "";
  const question = typeof body.question === "string" ? body.question.trim() : "";
  const choix_a = typeof body.choix_a === "string" ? body.choix_a.trim() : "";
  const choix_b = typeof body.choix_b === "string" ? body.choix_b.trim() : "";
  const choix_c = typeof body.choix_c === "string" ? body.choix_c.trim() : "";
  const choix_d = typeof body.choix_d === "string" ? body.choix_d.trim() : "";
  const difficulte = typeof body.difficulte === "string" ? body.difficulte.trim().toLowerCase() : "moyen";
  const bonne_reponse = typeof body.bonne_reponse === "string" ? body.bonne_reponse.trim().toUpperCase() : "";

  if (!anime || !question || !choix_a || !choix_b) {
    return NextResponse.json(
      { error: "Champs obligatoires manquants (anime, question, choix A et B)." },
      { status: 400 }
    );
  }

  if (!DIFFICULTES_VALIDES.includes(difficulte)) {
    return NextResponse.json({ error: "Niveau de difficulte invalide." }, { status: 400 });
  }

  if (!REPONSES_VALIDES.includes(bonne_reponse)) {
    return NextResponse.json({ error: "Bonne reponse invalide (A, B, C ou D)." }, { status: 400 });
  }

  // Filtrage strict des champs autorises (aucun spread brut du body)
  const payload = {
    anime,
    arc: typeof body.arc === "string" && body.arc.trim() ? body.arc.trim() : null,
    difficulte,
    question,
    choix_a,
    choix_b,
    choix_c,
    choix_d,
    bonne_reponse,
    explication: typeof body.explication === "string" && body.explication.trim() ? body.explication.trim() : null,
    image_url: typeof body.image_url === "string" && body.image_url.trim() ? body.image_url.trim() : null,
    type: typeof body.type === "string" && body.type.trim() ? body.type.trim() : "general",
    statut: STATUTS_VALIDES.includes(body.statut) ? body.statut : "actif",
  };

  if (isEdit) {
    const { error } = await supabaseAdmin
      .from("questions")
      .update(payload)
      .eq("id", id);

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }
    return NextResponse.json({ ok: true });
  }

  const { error } = await supabaseAdmin
    .from("questions")
    .insert({ id, ...payload });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }
  return NextResponse.json({ ok: true });
}

// PATCH : activer ou desactiver une question (admin verifie cote serveur)
export async function PATCH(req: NextRequest) {
  const { errorResponse } = await requireAdmin(req);
  if (errorResponse) return errorResponse;

  const body = await req.json();
  const id = typeof body.id === "string" ? body.id.trim() : "";
  const statut = typeof body.statut === "string" ? body.statut.trim() : "";

  if (!id || !STATUTS_VALIDES.includes(statut)) {
    return NextResponse.json({ error: "id ou statut invalide." }, { status: 400 });
  }

  const { error } = await supabaseAdmin
    .from("questions")
    .update({ statut })
    .eq("id", id);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }
  return NextResponse.json({ ok: true });
}
