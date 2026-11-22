import { NextRequest, NextResponse } from "next/server";
import { supabaseAdmin } from "@/lib/supabase-admin";
import { requireAdmin } from "@/lib/admin-auth";

const MAX_MD_SIZE_BYTES = 10 * 1024 * 1024; // 10 Mo max

function normaliserDifficulte(raw: string): string {
  const val = raw.toLowerCase();
  if (val.includes("maitre") || val.includes("maître")) return "maitre";
  if (val.includes("expert")) return "expert";
  if (val.includes("difficile")) return "difficile";
  if (val.includes("facile")) return "facile";
  return "moyen";
}

export async function POST(req: NextRequest) {
  const { errorResponse } = await requireAdmin(req);
  if (errorResponse) return errorResponse;

  try {
    const formData = await req.formData();
    const file = formData.get("file") as File | null;

    if (!file) {
      return NextResponse.json({ error: "Aucun fichier fourni." }, { status: 400 });
    }

    if (!file.name.toLowerCase().endsWith(".md")) {
      return NextResponse.json({ error: "Format non autorise. Fichier .md attendu." }, { status: 400 });
    }

    if (file.size > MAX_MD_SIZE_BYTES) {
      return NextResponse.json({ error: "Fichier trop volumineux (max 10 Mo)." }, { status: 400 });
    }

    const text = await file.text();
    const lines = text.split("\n");
    const questionsToInsert = [];

    // Detection dynamique du format tableau (13 colonnes sans Type ou 14 colonnes avec Type)
    let hasTypeColumn: boolean | null = null;

    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed.startsWith("|")) continue;

      // Detection sur la ligne d'en-tete
      if (trimmed.includes("| Anime |") || trimmed.includes("| ID |")) {
        const lowerHeader = trimmed.toLowerCase();
        hasTypeColumn = lowerHeader.includes("| type |");
        continue;
      }

      // Ignorer la ligne de separation markdown (|---|---|)
      if (/^\|\s*:?-{2,}/.test(trimmed)) continue;

      // Retirer les pipes de bord et nettoyer chaque cellule
      const rawCells = trimmed.split("|");
      const cells = rawCells.slice(1, rawCells.length - 1).map((col) => col.trim());

      // Format 13 colonnes : ID | Anime | Arc | Chapitre | Difficulte | Question | A | B | C | D | Bonne reponse | Explication | Tags
      // Format 14 colonnes : ID | Anime | Arc | Chapitre | Type | Difficulte | Question | A | B | C | D | Bonne reponse | Explication | ...
      if (cells.length < 12) continue;

      const withType = hasTypeColumn !== null ? hasTypeColumn : cells.length >= 14;
      const offset = withType ? 1 : 0;

      const id = cells[0];
      const anime = cells[1];
      const arc = cells[2];
      const type = withType && cells[4] ? cells[4].toLowerCase() : "general";
      const difficulte = normaliserDifficulte(cells[4 + offset] || "moyen");
      const question = cells[5 + offset];
      const choix_a = cells[6 + offset];
      const choix_b = cells[7 + offset];
      const choix_c = cells[8 + offset] || "";
      const choix_d = cells[9 + offset] || "";

      let bonne_reponse = (cells[10 + offset] || "").replace(/\*/g, "").trim().toUpperCase();
      if (!["A", "B", "C", "D"].includes(bonne_reponse)) {
        continue;
      }

      const explication = cells[11 + offset] || null;

      if (!id || !anime || !question || !choix_a || !choix_b) continue;

      questionsToInsert.push({
        id,
        anime: anime.toLowerCase(),
        arc: arc || null,
        difficulte,
        question,
        choix_a,
        choix_b,
        choix_c,
        choix_d,
        bonne_reponse,
        explication,
        statut: "actif",
        type,
      });
    }

    if (questionsToInsert.length === 0) {
      return NextResponse.json(
        { error: "Aucune question valide trouvee dans le fichier." },
        { status: 400 }
      );
    }

    const { error } = await supabaseAdmin
      .from("questions")
      .upsert(questionsToInsert, { onConflict: "id" });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json({ ok: true, count: questionsToInsert.length });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || "Erreur serveur" }, { status: 500 });
  }
}
