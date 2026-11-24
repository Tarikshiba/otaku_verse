import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

// ============================================================================
// Edge Function : valider-reponse (Alignee V9.2 Finale §1.3 & §7.4)
// - Valide la reponse cote serveur sans jamais exposer bonne_reponse avant clic
// - Matrice 350 PV exacte : Normal -15/-20, HAYA!! -18/-23, COMBO x3 -30/-35,
//   COMBO x3 + HAYA!! -36/-41, Clash riposte -8 (-15 si adversaire en Combo x3),
//   Auto-faute -5 PV, Bot Facile -12/-17 PV
// - Cloture Verse avec courbe XP officielle V9.2, protection debutant Niv. 1-5
//   et titres de rangs officiels avec accents
// ============================================================================

function getLevelFromXp(xp: number): number {
  if (xp <= 0) return 1;
  let lvl = 1;
  let acc = 0;
  while (true) {
    let step = 25000;
    if (lvl <= 5) step = 100 * lvl;
    else if (lvl <= 15) step = 120 * lvl;
    else if (lvl <= 30) step = 130 * lvl;
    else if (lvl <= 50) step = 140 * lvl;
    else if (lvl <= 75) step = 7000;
    if (acc + step > xp) break;
    acc += step;
    lvl++;
  }
  return lvl;
}

function getRankTitle(level: number): string {
  if (level <= 5) return "Novice du Verse";
  if (level <= 15) return "Apprenti Otaku";
  if (level <= 30) return "Érudit des Arcs";
  if (level <= 50) return "Maître de l'Encre";
  if (level <= 75) return "Seigneur du Verse";
  return `Légende Éternelle ★${level - 75}`;
}

export default {
  fetch: withSupabase({ auth: ["publishable", "secret"] }, async (req, ctx) => {
    if (req.method !== "POST") {
      return new Response("Methode non autorisee", { status: 405 });
    }

    const body = await req.json();

    // Action V2/V9.2 : cloturer un match Verse (PvP temps reel) cote serveur
    if (body.action === "cloturer_match_verse") {
      const authHeader = req.headers.get("Authorization") || "";
      const tokenMatch = authHeader.match(/^Bearer\s+(.+)$/i);
      if (!tokenMatch || !tokenMatch[1]) {
        return Response.json(
          { error: "Authentification requise" },
          { status: 401 },
        );
      }

      const { data: authData, error: authError } =
        await ctx.supabaseAdmin.auth.getUser(tokenMatch[1].trim());

      if (authError || !authData?.user) {
        return Response.json(
          { error: "Session invalide ou expiree" },
          { status: 401 },
        );
      }

      const user_id = authData.user.id;
      const { resultat, mode, ko, bonnes_reponses } = body;
      const RESULTATS_VALIDES = ["victoire", "defaite", "egalite", "abandon"];
      if (!resultat || !RESULTATS_VALIDES.includes(resultat)) {
        return Response.json(
          { error: "resultat invalide" },
          { status: 400 },
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

      const xpActuelle = Number(profil.xp_totale || 0);
      const niveauActuel = getLevelFromXp(xpActuelle);
      const nbBonnes = Math.max(0, Math.min(40, Number(bonnes_reponses) || 0));

      // Calcul XP conforme V9.2 (§1.2-1.3) : 0 perte en defaite du Niv. 1 au Niv. 5
      let xp_gagne = 0;
      if (resultat === "abandon") {
        xp_gagne = -50;
      } else if (resultat === "victoire") {
        xp_gagne = 15 + nbBonnes * 3 + 20 + (ko === true ? 15 : 0);
      } else if (resultat === "egalite") {
        xp_gagne = 15 + nbBonnes * 3;
      } else {
        // Defaite : protection debutant Niv. 1-5, perte nette seche des Niv. 6
        if (niveauActuel <= 5) {
          xp_gagne = 15 + nbBonnes * 3;
        } else {
          xp_gagne = ko === true ? -25 : -15;
        }
      }

      // Calcul points de division conformes §6.1
      let delta_points = 0;
      if (mode === "division") {
        if (resultat === "victoire") delta_points = ko === true ? 30 : 25;
        else if (resultat === "defaite") delta_points = ko === true ? -16 : -12;
        else if (resultat === "egalite") delta_points = 4;
        else if (resultat === "abandon") delta_points = -30;
      }

      const nouvelle_xp = Math.max(0, xpActuelle + xp_gagne);
      const niveau = getLevelFromXp(nouvelle_xp);
      const rang = getRankTitle(niveau);
      const nouveaux_pts = Math.max(0, Number(profil.pts_division || 0) + delta_points);

      const combats_joues = (profil.combats_joues || 0) + 1;
      const combats_gagnes =
        (profil.combats_gagnes || 0) + (resultat === "victoire" ? 1 : 0);

      await ctx.supabaseAdmin
        .from("profiles")
        .update({
          xp_totale: nouvelle_xp,
          niveau,
          rang,
          level_at_last_match: niveau,
          last_match_at: new Date().toISOString(),
          combats_joues,
          combats_gagnes,
          ...(mode === "division" ? { pts_division: nouveaux_pts } : {}),
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

    // Verification JWT obligatoire meme sur la route de validation de question
    const authHeader = req.headers.get("Authorization") || "";
    const tokenMatch = authHeader.match(/^Bearer\s+(.+)$/i);
    if (!tokenMatch || !tokenMatch[1]) {
      return Response.json({ error: "Authentification requise" }, { status: 401 });
    }
    const { data: authData, error: authError } =
      await ctx.supabaseAdmin.auth.getUser(tokenMatch[1].trim());
    if (authError || !authData?.user) {
      return Response.json({ error: "Session invalide ou expiree" }, { status: 401 });
    }

    const { question_id, reponse, combo_joueur, combo_bot, difficulte, response_time_ms } = body;

    if (!question_id || typeof reponse !== "string") {
      return Response.json(
        { error: "question_id et reponse sont requis" },
        { status: 400 },
      );
    }

    const { data: question, error } = await ctx.supabaseAdmin
      .from("questions")
      .select("bonne_reponse")
      .eq("id", question_id)
      .single();

    if (error || !question) {
      return Response.json(
        { error: "Question introuvable" },
        { status: 404 },
      );
    }

    const reponseNorm = reponse.trim().toUpperCase();
    const bonneNorm = String(question.bonne_reponse || "").trim().toUpperCase();
    const joueur_correct = reponseNorm.length > 0 && reponseNorm === bonneNorm;

    const diff = String(difficulte || "moyen").toLowerCase();
    const aiProfiles: Record<string, { acc: number; minMs: number; maxMs: number; normalDmg: number }> = {
      facile:    { acc: 0.55, minMs: 4500, maxMs: 6500, normalDmg: 12 },
      moyen:     { acc: 0.65, minMs: 3500, maxMs: 5000, normalDmg: 15 },
      difficile: { acc: 0.75, minMs: 2600, maxMs: 4000, normalDmg: 15 },
      expert:    { acc: 0.82, minMs: 2000, maxMs: 3200, normalDmg: 15 },
      maitre:    { acc: 0.90, minMs: 1500, maxMs: 2500, normalDmg: 15 },
      adaptatif: { acc: 0.65, minMs: 3000, maxMs: 5000, normalDmg: 15 },
    };
    const ai = aiProfiles[diff] ?? aiProfiles.moyen;
    const bot_correct = Math.random() < ai.acc;
    const playerTimeMs = Math.max(100, Math.min(20000, Number(response_time_ms) || 5000));
    const botTimeMs = Math.round(ai.minMs + Math.random() * (ai.maxMs - ai.minMs));

    const p1Haya = joueur_correct && playerTimeMs < 2000;
    const botHaya = bot_correct && botTimeMs < 2000;

    // Combo strictement multiples de 3 (3e, 6e, 9e...)
    const nouveau_combo_joueur = joueur_correct ? (Number(combo_joueur) || 0) + 1 : 0;
    const nouveau_combo_bot = bot_correct ? (Number(combo_bot) || 0) + 1 : 0;
    const combo_joueur_declenche = joueur_correct && nouveau_combo_joueur > 0 && nouveau_combo_joueur % 3 === 0;
    const combo_bot_declenche = bot_correct && diff !== "facile" && nouveau_combo_bot > 0 && nouveau_combo_bot % 3 === 0;

    // Matrice de degats officielle V9.2 (§7.4) sur 350 PV
    let degats_infliges = 0;
    let degats_subis = 0;

    if (joueur_correct && !bot_correct) {
      const base = combo_joueur_declenche ? (p1Haya ? 36 : 30) : (p1Haya ? 18 : 15);
      degats_infliges = base + 5; // +5 PV Auto-faute adverse
      degats_subis = 0;
    } else if (!joueur_correct && bot_correct) {
      const base = combo_bot_declenche
        ? (botHaya ? 36 : 30)
        : (botHaya ? Math.round(ai.normalDmg * 1.2) : ai.normalDmg);
      degats_subis = base + 5; // +5 PV Auto-faute joueur
      degats_infliges = 0;
    } else if (joueur_correct && bot_correct) {
      // Clash : departage par vitesse, riposte fixe -8 PV (-15 PV si le 2nd est en Combo x3)
      if (playerTimeMs <= botTimeMs) {
        degats_infliges = combo_joueur_declenche ? (p1Haya ? 36 : 30) : (p1Haya ? 18 : 15);
        degats_subis = combo_bot_declenche ? 15 : 8;
      } else {
        degats_subis = combo_bot_declenche
          ? (botHaya ? 36 : 30)
          : (botHaya ? Math.round(ai.normalDmg * 1.2) : ai.normalDmg);
        degats_infliges = combo_joueur_declenche ? 15 : 8;
      }
    } else {
      // Double faute : -5 PV chacun
      degats_infliges = 5;
      degats_subis = 5;
    }

    return Response.json({
      joueur_correct,
      bot_correct,
      bonne_reponse: bonneNorm,
      haya_triggered: p1Haya,
      degats_infliges,
      degats_subis,
      combo_joueur_declenche,
      combo_bot_declenche,
      nouveau_combo_joueur,
      nouveau_combo_bot,
    });
  }),
};
