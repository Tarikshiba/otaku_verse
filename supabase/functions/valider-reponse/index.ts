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

    const body = await req.json();

    // Action V2 : cloturer un match Verse et calculer l'XP / les points de division cote serveur
    if (body.action === "cloturer_match_verse") {
      const { user_id, resultat, mode, ko, bonnes_reponses } = body;
      if (!user_id || !resultat) {
        return Response.json(
          { error: "user_id et resultat sont requis" },
          { status: 400 }
        );
      }

      const { data: profil, error: errProfil } = await ctx.supabaseAdmin
        .from("profiles")
        .select("*")
        .eq("id", user_id)
        .single();

      if (errProfil || !profil) {
        return Response.json({ error: "Profil introuvable" }, { status: 404 });
      }

      // Calcul XP : +20 fin de match, +10 par bonne reponse, +30 si K.O.
      const nbBonnes = Math.max(0, Math.min(10, Number(bonnes_reponses) || 0));
      let xp_gagne = 20 + nbBonnes * 10;
      if (resultat === "victoire" && ko === true) {
        xp_gagne += 30;
      }

      // Calcul points de division (uniquement en mode division)
      let delta_points = 0;
      if (mode === "division") {
        if (resultat === "victoire") delta_points = 25;
        else if (resultat === "defaite") delta_points = -15;
        else if (resultat === "egalite") delta_points = 5;
        else if (resultat === "abandon") delta_points = -30;
      }

      const nouvelle_xp = (profil.xp_totale || 0) + xp_gagne;
      let niveau = 1;
      let xp_accumulee = 0;
      while (true) {
        const palier = Math.round(100 * niveau * 1.2);
        if (xp_accumulee + palier > nouvelle_xp) break;
        xp_accumulee += palier;
        niveau++;
      }

      let rang = "Legende";
      if (niveau <= 5) rang = "Debutant";
      else if (niveau <= 15) rang = "Apprenti Otaku";
      else if (niveau <= 30) rang = "Passionne";
      else if (niveau <= 50) rang = "Expert";
      else if (niveau <= 75) rang = "Maitre du Verse";

      const combats_joues = (profil.combats_joues || 0) + 1;
      const combats_gagnes =
        (profil.combats_gagnes || 0) + (resultat === "victoire" ? 1 : 0);

      await ctx.supabaseAdmin
        .from("profiles")
        .update({
          xp_totale: nouvelle_xp,
          niveau,
          rang,
          combats_joues,
          combats_gagnes,
        })
        .eq("id", user_id);

      return Response.json({
        xp_gagne,
        delta_points,
        nouvelle_xp,
        niveau,
        rang,
      });
    }

    const { question_id, reponse, combo_joueur, combo_bot, difficulte } = body;

    // Verification des parametres (reponse peut etre une chaine vide en cas de timeout)
    if (!question_id || typeof reponse !== "string") {
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
