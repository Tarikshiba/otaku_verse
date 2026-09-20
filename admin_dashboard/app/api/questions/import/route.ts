import { NextRequest, NextResponse } from "next/server";
import { supabaseAdmin } from "@/lib/supabase-admin";

export async function POST(req: NextRequest) {
  try {
    const formData = await req.formData();
    const file = formData.get("file") as File | null;

    if (!file) {
      return NextResponse.json({ error: "Aucun fichier fourni." }, { status: 400 });
    }

    const text = await file.text();
    const lines = text.split("\n");
    const questionsToInsert = [];

    for (const line of lines) {
      // Ignorer les lignes qui ne commencent pas par un pipe (tableaux markdown)
      if (!line.trim().startsWith("|")) continue;
      
      // Ignorer la ligne d'en-tête et la ligne de séparation markdown (|---|---|)
      if (line.includes("| Anime |") || line.includes("|---") || line.includes("|:---")) continue;

      const cols = line.split("|").map(col => col.trim());
      // Si la ligne ne contient pas assez de colonnes, on ignore
      if (cols.length < 14) continue;

      // cols[0] est vide à cause du premier pipe "|", donc les index sont décalés de 1.
      const id = cols[1];
      const anime = cols[2];
      const arc = cols[3];
      // cols[4] Chapitre, cols[5] Type
      
      // Extraction de la difficulté (ex: "🟡 Moyen" -> "moyen")
      let rawDifficulte = cols[6].toLowerCase();
      let difficulte = "moyen";
      if (rawDifficulte.includes("facile")) difficulte = "facile";
      else if (rawDifficulte.includes("difficile")) difficulte = "difficile";
      else if (rawDifficulte.includes("expert")) difficulte = "expert";
      else if (rawDifficulte.includes("moyen")) difficulte = "moyen";

      const question = cols[7];
      const choix_a = cols[8];
      const choix_b = cols[9];
      const choix_c = cols[10] || "";
      const choix_d = cols[11] || "";
      
      // Extraction de la réponse (ex: "**A**" -> "A")
      let bonne_reponse = cols[12].replace(/\*/g, "").toUpperCase();
      if (!["A", "B", "C", "D"].includes(bonne_reponse)) {
        bonne_reponse = "A"; // fallback
      }

      const explication = cols[13];

      questionsToInsert.push({
        id,
        anime: anime.toLowerCase(), // on normalise en minuscules pour l'app
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
        type: "general"
      });
    }

    if (questionsToInsert.length === 0) {
      return NextResponse.json({ error: "Aucune question valide trouvée dans le fichier." }, { status: 400 });
    }

    // On utilise l'upsert pour écraser si l'ID existe déjà
    const { error } = await supabaseAdmin
      .from("questions")
      .upsert(questionsToInsert, { onConflict: "id" });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json({ ok: true, count: questionsToInsert.length });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
