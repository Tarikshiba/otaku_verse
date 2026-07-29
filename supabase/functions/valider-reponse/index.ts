import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

// Edge Function : valider-reponse
// Recoit l'ID d'une question + la reponse du joueur (A/B/C/D)
// Verifie en base si c'est correct, calcule les degats
// Ne renvoie JAMAIS la bonne reponse au client

export default {
  fetch: withSupabase({ auth: ["publishable", "secret"] }, async (req, ctx) => {
    if (req.method !== "POST") {
      return new Response("Methode non autorisee", { status: 405 });
    }

    const { question_id, reponse, combo_joueur, combo_bot, difficulte } =
      await req.json();

    // Verification des parametres
    if (!question_id || !reponse) {
      return Response.json(
        { error: "question_id et reponse sont requis" },
        { status: 400 }
      );
    }

    // Recuperer la bonne reponse depuis la base (via admin = bypass RLS)
    const { data: question, error } = await ctx.supabaseAdmin
      .from("questions")
      .select("bonne_reponse")
      .eq("id", question_id)
      .single();

    if (error || !question) {
      return Response.json(
        { error: "Question introuvable" },
        { status: 404 }
      );
    }

    // Verifier si le joueur a bien repondu
    const joueur_correct = reponse === question.bonne_reponse;

    // Simuler la reponse du bot selon la difficulte
    const probas: Record<string, number> = {
      facile: 0.3,
      moyen: 0.5,
      difficile: 0.7,
      expert: 0.85,
      adaptatif: 0.5,
    };
    const proba = probas[difficulte] ?? 0.5;
    const bot_correct = Math.random() < proba;

    // Constantes de combat
    const DEGATS_NORMAUX = 15;
    const DEGATS_SPECIAUX = 30;
    const SEUIL_COMBO = 3;

    // Calcul combo et degats joueur
    let nouveau_combo_joueur = combo_joueur || 0;
    let degats_infliges = 0;
    let combo_joueur_declenche = false;

    if (joueur_correct) {
      nouveau_combo_joueur++;
      if (nouveau_combo_joueur >= SEUIL_COMBO) {
        combo_joueur_declenche = true;
        degats_infliges = DEGATS_SPECIAUX;
        nouveau_combo_joueur = 0;
      } else {
        degats_infliges = DEGATS_NORMAUX;
      }
    } else {
      nouveau_combo_joueur = 0;
    }

    // Calcul combo et degats bot
    let nouveau_combo_bot = combo_bot || 0;
    let degats_subis = 0;
    let combo_bot_declenche = false;

    if (bot_correct) {
      nouveau_combo_bot++;
      if (nouveau_combo_bot >= SEUIL_COMBO) {
        combo_bot_declenche = true;
        degats_subis = DEGATS_SPECIAUX;
        nouveau_combo_bot = 0;
      } else {
        degats_subis = DEGATS_NORMAUX;
      }
    } else {
      nouveau_combo_bot = 0;
    }

    return Response.json({
      joueur_correct,
      bot_correct,
      degats_infliges,
      degats_subis,
      combo_joueur_declenche,
      combo_bot_declenche,
      nouveau_combo_joueur,
      nouveau_combo_bot,
    });
  }),
};
