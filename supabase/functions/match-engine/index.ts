import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

// ============================================================================
// Edge Function : match-engine (Specification V9.2 Finale)
// Actions gerees cote serveur (JWT obligatoire) :
// 1. start_match       : verifie feature_flags, debite frais OC / assurance / puits, cree le match (350 PV)
// 2. submit_answer     : valide la reponse, calcule Haya!! / Combo x3 / Auto-faute -5 PV / Clash / 0 PV simultane
// 3. end_match         : applique les 7 scenarios §6.1, Perte Nette Seche XP, frais OC, ledger, division
// 4. double_oc_ad      : Bouton Roi "Doubler mes OC x2" (max 10/jour, hors remboursement/puits)
// 5. rescue_oc_ad      : Coup de Pouce (+40 OC si solde < frais d'arene, max 3/jour)
// 6. second_chance     : Solo uniquement -> +100 PV sur 350 PV (1 fois/match, pub ou 30 OC)
// ============================================================================

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
// Optionnel : URL du Cloudflare Worker R2 (1,28M questions) + secret partage serveur-a-serveur
const QUIZ_WORKER_URL = Deno.env.get("QUIZ_WORKER_URL") || "";
const WORKER_API_SECRET = Deno.env.get("WORKER_API_SECRET") || "";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const INITIAL_HP = 350;
const MAX_QUESTIONS = 40;
const GLOBAL_TIMER_MS = 120000; // 2 minutes cumulees

// Bareme §1.2bis : gains XP/OC par palier de difficulte
const TIER_REWARDS: Record<string, { xp: number; oc: number; errOc: number; vicXp: number; vicOc: number; koXp: number; koOc: number; lossPtsXp: number; lossKoXp: number; aiAcc: number; aiMinMs: number; aiMaxMs: number; aiDmg: number }> = {
  facile:    { xp: 2, oc: 0.5, errOc: 0.0, vicXp: 15, vicOc: 10, koXp: 5,  koOc: 5,  lossPtsXp: 5,  lossKoXp: 8,  aiAcc: 0.55, aiMinMs: 4500, aiMaxMs: 6500, aiDmg: 12 },
  moyen:     { xp: 3, oc: 1.0, errOc: 0.0, vicXp: 20, vicOc: 12, koXp: 10, koOc: 6,  lossPtsXp: 8,  lossKoXp: 12, aiAcc: 0.65, aiMinMs: 3500, aiMaxMs: 5000, aiDmg: 15 },
  difficile: { xp: 5, oc: 1.5, errOc: 0.5, vicXp: 25, vicOc: 15, koXp: 15, koOc: 8,  lossPtsXp: 12, lossKoXp: 18, aiAcc: 0.75, aiMinMs: 2600, aiMaxMs: 4000, aiDmg: 15 },
  expert:    { xp: 7, oc: 2.0, errOc: 1.0, vicXp: 35, vicOc: 20, koXp: 20, koOc: 10, lossPtsXp: 15, lossKoXp: 25, aiAcc: 0.82, aiMinMs: 2000, aiMaxMs: 3200, aiDmg: 15 },
  maitre:    { xp: 9, oc: 2.5, errOc: 1.5, vicXp: 45, vicOc: 25, koXp: 25, koOc: 15, lossPtsXp: 20, lossKoXp: 30, aiAcc: 0.90, aiMinMs: 1500, aiMaxMs: 2500, aiDmg: 15 },
  adaptatif: { xp: 3, oc: 1.0, errOc: 0.0, vicXp: 20, vicOc: 18, koXp: 10, koOc: 6,  lossPtsXp: 10, lossKoXp: 15, aiAcc: 0.65, aiMinMs: 3000, aiMaxMs: 5000, aiDmg: 15 },
};

const AI_PSEUDOS_DIVISION = [
  "Shanks_DKR", "Itachi_221", "Zoro_Santoryu", "Gojo_SatoruX",
  "Killua_Z", "Mikasa_SN", "Luffy_Nika", "Aizen_Sosuke",
  "Soryn_Echo", "Nyxara_Fang", "Sukuna_K", "Kira_Note",
];

function jsonResp(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

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
  if (level <= 30) return "Erudit des Arcs";
  if (level <= 50) return "Maitre de l'Encre";
  if (level <= 75) return "Seigneur du Verse";
  return `Legende Eternelle ★${level - 75}`;
}

function getDivisionFromPoints(pts: number): number {
  if (pts >= 1900) return 1;
  if (pts >= 1570) return 2;
  if (pts >= 1270) return 3;
  if (pts >= 1000) return 4;
  if (pts >= 760) return 5;
  if (pts >= 550) return 6;
  if (pts >= 370) return 7;
  if (pts >= 220) return 8;
  if (pts >= 100) return 9;
  return 10;
}

function divisionToAiTier(divisionId: number): string {
  if (divisionId >= 9) return "moyen";
  if (divisionId >= 6) return "difficile";
  if (divisionId >= 3) return "expert";
  return "maitre";
}

function divisionBonusOc(divisionId: number): { vicOc: number; koOc: number } {
  if (divisionId >= 9) return { vicOc: 12, koOc: 6 };
  if (divisionId >= 6) return { vicOc: 15, koOc: 8 };
  if (divisionId >= 3) return { vicOc: 20, koOc: 10 };
  return { vicOc: 25, koOc: 15 };
}

function tierIndexToKey(idx: number): string {
  const keys = ["facile", "moyen", "difficile", "expert", "maitre"];
  return keys[Math.max(0, Math.min(4, idx - 1))];
}

function modeToFlagKey(mode: string): string {
  const map: Record<string, string> = {
    solo: "mode_solo",
    division: "mode_division",
    duel_ami: "mode_duel_ami",
    coop_2via: "mode_coop",
    coop_2v2: "mode_coop",
    battle_royale: "mode_battle_royale",
    donjon: "mode_donjons",
    salon_live: "mode_salon_live",
  };
  return map[mode] || "mode_solo";
}

async function authenticateUser(req: Request, supabase: SupabaseClient) {
  const authHeader = req.headers.get("Authorization") || "";
  const match = authHeader.match(/^Bearer\s+(.+)$/i);
  if (!match?.[1]) return null;
  const { data, error } = await supabase.auth.getUser(match[1].trim());
  if (error || !data?.user) return null;
  return data.user;
}

async function resolveExpiredMatches(supabase: SupabaseClient, userId: string) {
  // Securite Anti-Force-Close (§8.2) : inactif > 45s ou > 5 min max => Abandon (-30 pts, -50 XP)
  const cutoffActivity = new Date(Date.now() - 45000).toISOString();
  const cutoffMax = new Date(Date.now() - 300000).toISOString();

  const { data: stale } = await supabase
    .from("matches")
    .select("*")
    .eq("player1_id", userId)
    .eq("status", "in_progress")
    .or(`last_activity_at.lt.${cutoffActivity},started_at.lt.${cutoffMax}`);

  if (!stale || stale.length === 0) return;

  for (const m of stale) {
    await closeMatchInternal(supabase, m, userId, 7, false);
  }
}

async function closeMatchInternal(
  supabase: SupabaseClient,
  match: any,
  userId: string,
  scenarioCode: number,
  player1Won: boolean
) {
  const { data: prof } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .single();

  if (!prof) return null;

  await supabase.rpc("ensure_wallet_exists", { p_user_id: userId });
  const { data: wallet } = await supabase
    .from("economy_wallets")
    .select("*")
    .eq("user_id", userId)
    .single();

  const level = prof.niveau || 1;
  const currentXp = prof.xp_totale || 0;
  const currentDivPts = prof.pts_division || 0;
  const currentDivId = prof.division_id || 10;
  const currentOc = wallet?.oc_balance || 0;

  const isDivision = match.mode === "division";
  const tierInfo = TIER_REWARDS[match.difficulty] || TIER_REWARDS.moyen;
  const hayaBonusPts = Math.min(5, Math.floor((match.player1_haya_count || 0) / 2));

  // Calcul des deltas selon les 7 scenarios officiels (§6.1)
  let deltaXp = 0;
  let deltaDivPts = 0;
  let ocRefund = 0;
  let ocPerfNet = 0;
  let potReturn = 0;
  let newAbandonStreak = prof.abandon_streak || 0;
  let cooldownUntil: string | null = prof.cooldown_until || null;

  const questionsPlayed = Math.max(1, match.questions_played || 0);
  const accuracyPct = (match.player1_correct / questionsPlayed) * 100;
  const sansFaute = match.player1_errors === 0 && match.player1_correct > 0;

  // Base OC de performance (formule SQL §1.2bis)
  const rawOcQuestions = Math.max(
    0,
    Math.floor(Number(match.oc_questions_sum || 0) - Number(match.oc_errors_penalty || 0))
  );

  if (scenarioCode === 7 && !player1Won) {
    // Scenario 7 : Abandon / Force-close (TOUS les niveaux, assurance exclue)
    deltaXp = -50;
    if (isDivision) deltaDivPts = -30;
    ocRefund = 0;
    ocPerfNet = 0;
    potReturn = 0;
    newAbandonStreak += 1;
    const mins = newAbandonStreak >= 3 ? 30 : 5;
    cooldownUntil = new Date(Date.now() + mins * 60000).toISOString();
  } else if (scenarioCode === 6) {
    // Scenario 6 : Double-Faute Totale / Passivite AFK
    deltaXp = level >= 6 ? -25 : 0;
    if (isDivision) deltaDivPts = -12;
    ocRefund = 0;
    ocPerfNet = 0;
    potReturn = 0;
    newAbandonStreak = 0;
  } else if (scenarioCode === 5) {
    // Scenario 5 : Match Nul par Double K.O. (Ai-uchi)
    let rawLoss = level >= 6 ? 10 : 0;
    if (match.xp_insurance_active && rawLoss > 0) rawLoss = Math.floor(rawLoss / 2);
    deltaXp = -rawLoss;
    deltaDivPts = 0;
    ocRefund = Math.floor((match.entry_fee_oc || 0) / 2);
    ocPerfNet = 0;
    potReturn = 0;
    newAbandonStreak = 0;
  } else if (scenarioCode === 4) {
    // Scenario 4 : Match Nul Actif aux Points
    deltaXp = 15 + (match.xp_questions_sum || 0);
    if (isDivision) deltaDivPts = 4;
    ocRefund = match.entry_fee_oc || 0;
    ocPerfNet = rawOcQuestions;
    potReturn = accuracyPct >= 80 ? (match.confidence_pot_oc || 0) : 0;
    newAbandonStreak = 0;
  } else if (player1Won) {
    // Victoire : Scenario 1 (K.O. franc), 2 (K.O. Clash/Mort subite), 3 (Points) ou 7 (Forfait adverse)
    const isKo = scenarioCode === 1 || scenarioCode === 2 || scenarioCode === 7;
    const vicXp = isDivision ? 20 : tierInfo.vicXp;
    const koXp = isKo ? (isDivision ? 15 : tierInfo.koXp) : 0;
    const bonusSansFaute = sansFaute ? 50 : 0;

    // Mode Adaptatif : bonus palier final
    const adaptiveBonusXp = match.difficulty === "adaptatif" ? Math.max(0, (match.adaptive_tier - 1) * 5) : 0;
    const adaptiveBonusOc = match.difficulty === "adaptatif" ? Math.max(0, (match.adaptive_tier - 1) * 3) : 0;

    deltaXp = 15 + (match.xp_questions_sum || 0) + vicXp + koXp + bonusSansFaute + adaptiveBonusXp;

    if (isDivision) {
      deltaDivPts = (isKo ? 30 : 25) + hayaBonusPts;
    }

    const divOc = divisionBonusOc(currentDivId);
    const vicOc = isDivision ? divOc.vicOc : tierInfo.vicOc;
    const koOc = isKo ? (isDivision ? divOc.koOc : tierInfo.koOc) : 0;
    let totalPerfOc = rawOcQuestions + vicOc + koOc + adaptiveBonusOc;

    // Bonus Mode Malicieux : +25% OC en cas de victoire (§7.5)
    if (match.malus_mode === "malicieux") {
      totalPerfOc = Math.floor(totalPerfOc * 1.25);
    }

    ocRefund = match.entry_fee_oc || 0;
    ocPerfNet = totalPerfOc;

    // Puits d'avant-match (§1.4)
    const pot = match.confidence_pot_oc || 0;
    if (pot > 0) {
      if (scenarioCode === 7 && match.questions_played < 10) {
        potReturn = pot; // Rembourse si abandon adverse avant Q10
      } else if ((isKo && match.player1_errors <= 4) || (!isKo && accuracyPct >= 80)) {
        potReturn = pot * 2;
      }
    }
    newAbandonStreak = 0;
  } else {
    // Defaite : Perte Nette Seche d'XP des le Niveau 6 (0 XP de completion ni de bonnes reponses !)
    if (level >= 6) {
      let rawLoss = 0;
      if (isDivision || match.mode === "duel_ami") {
        if (scenarioCode === 1) rawLoss = 25;
        else rawLoss = 15; // Scenario 2 (Clash/Mort subite) ou 3 (Points)
      } else {
        rawLoss = scenarioCode === 1 || scenarioCode === 2 ? tierInfo.lossKoXp : tierInfo.lossPtsXp;
      }

      if (match.xp_insurance_active) {
        rawLoss = Math.floor(rawLoss / 2);
      }

      // Contrat Mode Malicieux echoue (< 50% de bonnes reponses, hors victoire K.O.)
      if (match.malus_mode === "malicieux" && accuracyPct < 50) {
        rawLoss += 20;
      }

      deltaXp = -rawLoss;
    } else {
      // Protection debutant Niv 1-5 : 0 perte d'XP sur defaite, encaisse completion + bonnes reponses
      deltaXp = 15 + (match.xp_questions_sum || 0);
    }

    if (isDivision) {
      if (scenarioCode === 1) deltaDivPts = -16;
      else if (scenarioCode === 2) deltaDivPts = -14;
      else deltaDivPts = -12;
    }

    ocRefund = 0;
    ocPerfNet = 0;
    potReturn = 0;
    newAbandonStreak = 0;
  }

  const newXp = Math.max(0, currentXp + deltaXp);
  const newLevel = getLevelFromXp(newXp);
  const newRank = getRankTitle(newLevel);
  const newDivPts = Math.max(0, currentDivPts + deltaDivPts);
  const newDivId = getDivisionFromPoints(newDivPts);
  const totalOcAdded = ocRefund + ocPerfNet + potReturn;
  const newOcBalance = Math.max(0, currentOc + totalOcAdded);
  const endedByKo = scenarioCode === 1 || scenarioCode === 2;
  const durationSec = Math.max(1, Math.round((Date.now() - new Date(match.started_at).getTime()) / 1000));

  // Mise a jour atomique du match
  await supabase
    .from("matches")
    .update({
      status: scenarioCode === 7 && !player1Won ? "abandoned" : "finished",
      scenario_code: scenarioCode,
      winner_id: player1Won ? userId : match.player2_id,
      duration_seconds: durationSec,
      ended_by_ko: endedByKo,
      oc_performance_net: ocPerfNet,
      ended_at: new Date().toISOString(),
    })
    .eq("id", match.id);

  // Mise a jour du profil
  await supabase
    .from("profiles")
    .update({
      xp_totale: newXp,
      niveau: newLevel,
      rang: newRank,
      level_at_last_match: newLevel,
      last_match_at: new Date().toISOString(),
      combats_joues: (prof.combats_joues || 0) + 1,
      combats_gagnes: (prof.combats_gagnes || 0) + (player1Won ? 1 : 0),
      pts_division: newDivPts,
      division_id: newDivId,
      ko_wins_season: (prof.ko_wins_season || 0) + (player1Won && endedByKo ? 1 : 0),
      season_matches_played: (prof.season_matches_played || 0) + 1,
      season_correct_answers: (prof.season_correct_answers || 0) + (match.player1_correct || 0),
      season_total_answers: (prof.season_total_answers || 0) + questionsPlayed,
      last_score_reached_at: deltaDivPts > 0 ? new Date().toISOString() : prof.last_score_reached_at,
      abandon_streak: newAbandonStreak,
      cooldown_until: cooldownUntil,
    })
    .eq("id", userId);

  // Mise a jour du portefeuille OC
  if (totalOcAdded > 0) {
    await supabase
      .from("economy_wallets")
      .update({ oc_balance: newOcBalance, updated_at: new Date().toISOString() })
      .eq("user_id", userId);
  }

  // Ecriture Ledger d'audit
  const ledgerRows: any[] = [];
  if (deltaXp !== 0) {
    ledgerRows.push({
      user_id: userId,
      currency: "XP",
      delta: deltaXp,
      balance_after: newXp,
      reason: player1Won ? "match_win_xp" : scenarioCode === 7 ? "match_abandon_xp" : "match_loss_xp",
      match_id: match.id,
      metadata: { scenario: scenarioCode, mode: match.mode },
    });
  }
  if (totalOcAdded > 0) {
    ledgerRows.push({
      user_id: userId,
      currency: "OC",
      delta: totalOcAdded,
      balance_after: newOcBalance,
      reason: "match_oc_payout",
      match_id: match.id,
      metadata: { refund: ocRefund, performance: ocPerfNet, pot: potReturn },
    });
  }
  if (isDivision && deltaDivPts !== 0) {
    ledgerRows.push({
      user_id: userId,
      currency: "PTS_DIVISION",
      delta: deltaDivPts,
      balance_after: newDivPts,
      reason: "match_division_pts",
      match_id: match.id,
      metadata: { scenario: scenarioCode, haya_bonus: hayaBonusPts },
    });
  }
  if (ledgerRows.length > 0) {
    await supabase.from("economy_ledger").insert(ledgerRows);
  }

  // RANK-02 (§6.7) : Notification Push "Un ami t'a depasse" avec throttle strict serveur
  if (isDivision && deltaDivPts > 0) {
    await notifyOvertakenFriends(
      supabase,
      userId,
      prof.pseudo || "Un ami",
      "pts_division",
      prof.pts_division || 0,
      newDivPts,
    );
  } else if (deltaXp > 0) {
    await notifyOvertakenFriends(
      supabase,
      userId,
      prof.pseudo || "Un ami",
      "xp_totale",
      prof.xp_totale || 0,
      newXp,
    );
  }

  return {
    scenario_code: scenarioCode,
    won: player1Won,
    ended_by_ko: endedByKo,
    delta_xp: deltaXp,
    new_xp: newXp,
    new_level: newLevel,
    new_rank: newRank,
    delta_division_pts: deltaDivPts,
    new_division_pts: newDivPts,
    new_division_id: newDivId,
    oc_refund: ocRefund,
    oc_performance_net: ocPerfNet,
    oc_pot_return: potReturn,
    new_oc_balance: newOcBalance,
    can_double_oc: ocPerfNet > 0,
  };
}

async function notifyOvertakenFriends(
  supabase: any,
  actorId: string,
  actorPseudo: string,
  scoreField: "pts_division" | "xp_totale",
  oldScore: number,
  newScore: number,
) {
  try {
    // Verifier le Feature Flag serveur (Palier 2+)
    const { data: flag } = await supabase
      .from("app_feature_flags")
      .select("is_enabled")
      .eq("flag_key", "notif_friend_overtake")
      .maybeSingle();
    if (!flag?.is_enabled) return;

    // Recuperer les amis acceptes
    const { data: friendships } = await supabase
      .from("friends")
      .select("sender_id, receiver_id")
      .eq("status", "accepted")
      .or(`sender_id.eq.${actorId},receiver_id.eq.${actorId}`);

    if (!friendships || friendships.length === 0) return;

    const friendIds = friendships.map((f: any) =>
      f.sender_id === actorId ? f.receiver_id : f.sender_id
    );

    // Amis depasses sur ce match : oldScore <= friendScore < newScore
    const { data: overtaken } = await supabase
      .from("profiles")
      .select("id, fcm_token, notif_overtake_enabled, timezone_offset_minutes, pts_division, xp_totale")
      .in("id", friendIds)
      .eq("notif_overtake_enabled", true)
      .gte(scoreField, oldScore)
      .lt(scoreField, newScore)
      .limit(5);

    if (!overtaken || overtaken.length === 0) return;

    const nowMs = Date.now();
    const cutoff24h = new Date(nowMs - 24 * 3600 * 1000).toISOString();

    for (const friend of overtaken) {
      if (!friend.fcm_token) continue;

      // 1. Plage horaire silencieuse 22h00 - 08h00 heure locale
      const tzMin = Number(friend.timezone_offset_minutes || 0);
      const localHour = new Date(nowMs + tzMin * 60 * 1000).getUTCHours();
      if (localHour >= 22 || localHour < 8) continue;

      // 2. Throttle strict : max 1x / 24h par ami
      const { data: pairThrottle } = await supabase
        .from("notification_throttles")
        .select("last_sent_at")
        .eq("recipient_id", friend.id)
        .eq("actor_friend_id", actorId)
        .eq("notif_type", "friend_overtake")
        .maybeSingle();

      if (pairThrottle && pairThrottle.last_sent_at > cutoff24h) continue;

      // 3. Plafond global : max 2 notifications de depassement / 24h par destinataire
      const { count: globalCount } = await supabase
        .from("notification_throttles")
        .select("id", { count: "exact", head: true })
        .eq("recipient_id", friend.id)
        .eq("notif_type", "friend_overtake")
        .gt("last_sent_at", cutoff24h);

      if ((globalCount ?? 0) >= 2) continue;

      // Enregistrer le throttle AVANT l'envoi
      await supabase.from("notification_throttles").upsert(
        {
          recipient_id: friend.id,
          actor_friend_id: actorId,
          notif_type: "friend_overtake",
          last_sent_at: new Date(nowMs).toISOString(),
        },
        { onConflict: "recipient_id,actor_friend_id,notif_type" },
      );

      const modeLabel = scoreField === "pts_division" ? "en Division" : "au Classement XP";
      await fetch(`${SUPABASE_URL}/functions/v1/envoyer-notification`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        },
        body: JSON.stringify({
          receiver_id: friend.id,
          sender_id: actorId,
          notif_type: "friend_overtake",
          title: "Classement Otaku Verse",
          body: `@${actorPseudo} vient de te depasser ${modeLabel} (${newScore} pts) ! Viens reprendre ta place.`,
        }),
      });
    }
  } catch (_) {
    // Une erreur push ne bloque jamais la cloture d'un match
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return jsonResp({ error: "Methode non autorisee" }, 405);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const user = await authenticateUser(req, supabase);
  if (!user) {
    return jsonResp({ error: "Authentification requise" }, 401);
  }

  const body = await req.json();
  const action = body.action as string;

  // =========================================================================
  // 1. START_MATCH : Feature flags + Anti-force-close + Debit frais OC
  // =========================================================================
  if (action === "start_match") {
    const mode = String(body.mode || "solo");
    const difficulty = String(body.difficulty || "moyen");
    const malusMode = ["zen", "normal", "malicieux"].includes(body.malus_mode) ? body.malus_mode : "normal";
    const xpInsurance = Boolean(body.xp_insurance);
    const confidencePot = [0, 15, 30].includes(Number(body.confidence_pot_oc)) ? Number(body.confidence_pot_oc) : 0;

    // Cloturer d'abord tout match precedent abandonne par force-close
    await resolveExpiredMatches(supabase, user.id);

    // Appliquer l'erosion hebdomadaire douce si necessaire (Niv 16+)
    await supabase.rpc("apply_weekly_xp_erosion", { p_user_id: user.id });

    // Verifier le Feature Flag serveur (§8.1)
    const flagKey = modeToFlagKey(mode);
    const { data: flag } = await supabase
      .from("app_feature_flags")
      .select("is_enabled, mode_config, launch_label")
      .eq("flag_key", flagKey)
      .maybeSingle();

    if (flag && !flag.is_enabled) {
      return jsonResp({ error: `Mode verrouille : ${flag.launch_label}`, locked: true }, 403);
    }

    // Verifier le cooldown anti-abandon
    const { data: prof } = await supabase.from("profiles").select("*").eq("id", user.id).single();
    if (!prof) return jsonResp({ error: "Profil introuvable" }, 404);

    if (prof.cooldown_until && new Date(prof.cooldown_until).getTime() > Date.now()) {
      const secs = Math.ceil((new Date(prof.cooldown_until).getTime() - Date.now()) / 1000);
      return jsonResp({ error: "Cooldown anti-abandon actif", cooldown_seconds: secs }, 429);
    }

    // Calcul des frais d'arene OC selon la regle officielle §1.4
    const { data: entryFeeData } = await supabase.rpc("get_arena_entry_fee", {
      p_user_id: user.id,
      p_game_mode: mode,
    });
    const entryFeeOc = Number(entryFeeData || 0);
    const insuranceCost = xpInsurance ? 25 : 0;
    const totalCostOc = entryFeeOc + insuranceCost + confidencePot;

    await supabase.rpc("ensure_wallet_exists", { p_user_id: user.id });
    const { data: wallet } = await supabase
      .from("economy_wallets")
      .select("oc_balance")
      .eq("user_id", user.id)
      .single();

    const currentOc = wallet?.oc_balance || 0;
    if (currentOc < totalCostOc) {
      return jsonResp(
        {
          error: "Solde Otaku Coins insuffisant",
          oc_balance: currentOc,
          required_oc: totalCostOc,
          can_rescue_ad: currentOc < entryFeeOc,
        },
        402
      );
    }

    // Debiter les OC a l'entree du match
    const newOcBalance = currentOc - totalCostOc;
    if (totalCostOc > 0) {
      await supabase
        .from("economy_wallets")
        .update({ oc_balance: newOcBalance, updated_at: new Date().toISOString() })
        .eq("user_id", user.id);
    }

    // Calibrage adversaire IA (Mode Division AI_ONLY ou Solo)
    const divMode = flag?.mode_config?.division_matchmaking_mode || "AI_ONLY";
    const isAi = mode === "solo" || (mode === "division" && divMode === "AI_ONLY");
    const aiTier = mode === "division" ? divisionToAiTier(prof.division_id || 10) : difficulty;
    const aiPseudo = AI_PSEUDOS_DIVISION[Math.floor(Math.random() * AI_PSEUDOS_DIVISION.length)];

    const { data: created, error: createErr } = await supabase
      .from("matches")
      .insert({
        mode,
        difficulty,
        malus_mode: malusMode,
        player1_id: user.id,
        is_ai_opponent: isAi,
        ai_tier: aiTier,
        ai_pseudo: aiPseudo,
        initial_hp: INITIAL_HP,
        player1_hp: INITIAL_HP,
        player2_hp: INITIAL_HP,
        max_questions: MAX_QUESTIONS,
        entry_fee_oc: entryFeeOc,
        xp_insurance_active: xpInsurance,
        confidence_pot_oc: confidencePot,
      })
      .select()
      .single();

    if (createErr || !created) {
      return jsonResp({ error: createErr?.message || "Impossible de creer le match" }, 500);
    }

    if (totalCostOc > 0) {
      await supabase.from("economy_ledger").insert({
        user_id: user.id,
        currency: "OC",
        delta: -totalCostOc,
        balance_after: newOcBalance,
        reason: "arena_entry_fee",
        match_id: created.id,
        metadata: { entry_fee: entryFeeOc, insurance: insuranceCost, pot: confidencePot },
      });
    }

    return jsonResp({
      match_id: created.id,
      initial_hp: INITIAL_HP,
      max_questions: MAX_QUESTIONS,
      global_timer_sec: 120,
      entry_fee_oc: entryFeeOc,
      new_oc_balance: newOcBalance,
      opponent: {
        is_ai: isAi,
        pseudo: aiPseudo,
        tier: aiTier,
        division_id: prof.division_id || 10,
      },
    });
  }

  // =========================================================================
  // 2. SUBMIT_ANSWER : Matrice 350 PV + Auto-Faute -5 + Haya!! + Combo x3 + 0 PV
  // =========================================================================
  if (action === "submit_answer") {
    const matchId = String(body.match_id || "");
    const questionId = String(body.question_id || "");
    const answer = typeof body.answer === "string" ? body.answer.trim().toUpperCase() : "";
    const responseTimeMs = Math.max(100, Math.min(20000, Number(body.response_time_ms) || 20000));
    const isTimeout = Boolean(body.is_timeout) || answer === "";

    const { data: match } = await supabase
      .from("matches")
      .select("*")
      .eq("id", matchId)
      .eq("player1_id", user.id)
      .single();

    if (!match || match.status !== "in_progress") {
      return jsonResp({ error: "Match introuvable ou deja termine" }, 404);
    }

    // Recuperer et valider la bonne reponse cote serveur uniquement (Cloudflare R2 ou Supabase)
    let p1Correct = false;
    let bonneReponseServeur = "";
    let explicationServeur: string | null = null;
    let qTier = "moyen";

    const workSlug = typeof body.work_slug === "string" ? body.work_slug.trim().toLowerCase() : "";
    const difficultyLevel = Number(body.difficulty_level) || 0;

    if (QUIZ_WORKER_URL && WORKER_API_SECRET && workSlug && difficultyLevel >= 1 && difficultyLevel <= 5) {
      const workerRes = await fetch(`${QUIZ_WORKER_URL.replace(/\/$/, "")}/validate`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Worker-Secret": WORKER_API_SECRET,
        },
        body: JSON.stringify({
          question_id: questionId,
          work_slug: workSlug,
          difficulty_level: difficultyLevel,
          answer: isTimeout ? "" : answer,
        }),
      });
      if (!workerRes.ok) {
        return jsonResp({ error: "Question introuvable sur le serveur R2" }, 404);
      }
      const wData = await workerRes.json();
      p1Correct = !isTimeout && Boolean(wData.correct);
      bonneReponseServeur = String(wData.correct_answer || "");
      explicationServeur = wData.explanation || null;
      qTier = tierIndexToKey(Number(wData.difficulty_level) || difficultyLevel);
    } else {
      const { data: question } = await supabase
        .from("questions")
        .select("bonne_reponse, difficulte, explication")
        .eq("id", questionId)
        .single();

      if (!question) {
        return jsonResp({ error: "Question introuvable" }, 404);
      }
      qTier = question.difficulte || "moyen";
      bonneReponseServeur = String(question.bonne_reponse || "").toUpperCase();
      explicationServeur = question.explication || null;
      p1Correct = !isTimeout && answer === bonneReponseServeur;
    }

    const qReward = TIER_REWARDS[qTier] || TIER_REWARDS.moyen;
    const aiProfile = TIER_REWARDS[match.ai_tier || "moyen"] || TIER_REWARDS.moyen;
    const p1Haya = p1Correct && responseTimeMs < 2000;

    // Simulation calibrée du Bot IA (precision + temps de reaction §1.2bis)
    const aiCorrect = Math.random() < aiProfile.aiAcc;
    const aiTimeMs = Math.round(
      aiProfile.aiMinMs + Math.random() * (aiProfile.aiMaxMs - aiProfile.aiMinMs)
    );
    const aiHaya = aiCorrect && aiTimeMs < 2000;

    let p1Combo = p1Correct ? (match.player1_combo || 0) + 1 : 0;
    let p2Combo = aiCorrect ? (match.player2_combo || 0) + 1 : 0;

    const p1Combo3 = p1Correct && p1Combo > 0 && p1Combo % 3 === 0;
    const p2Combo3 = aiCorrect && p2Combo > 0 && p2Combo % 3 === 0;

    // Calcul des degats selon la Matrice Officielle §7.4
    let dmgToP2 = 0;
    let dmgToP1 = 0;
    let clashWinner: "p1" | "p2" | "tie" | null = null;

    if (p1Correct && !aiCorrect) {
      // Cas 1 : A juste, B faux -> B subit coup A + Auto-Faute (-5 PV)
      const base = p1Combo3 ? (p1Haya ? 36 : 30) : (p1Haya ? 18 : 15);
      dmgToP2 = base + 5;
      dmgToP1 = 0;
    } else if (!p1Correct && aiCorrect) {
      // Cas 1 inverse : B juste, A faux -> A subit coup B + Auto-Faute (-5 PV)
      const baseNormal = match.mode === "solo" && match.difficulty === "facile" ? 12 : 15;
      const base = p2Combo3 && match.difficulty !== "facile"
        ? (aiHaya ? 36 : 30)
        : (aiHaya ? Math.round(baseNormal * 1.2) : baseNormal);
      dmgToP1 = base + 5;
      dmgToP2 = 0;
    } else if (p1Correct && aiCorrect) {
      // Cas 2 : Clash ! Departage par vitesse
      if (responseTimeMs < aiTimeMs) {
        clashWinner = "p1";
        dmgToP2 = p1Combo3 ? (p1Haya ? 36 : 30) : (p1Haya ? 18 : 15);
        dmgToP1 = p2Combo3 && match.difficulty !== "facile" ? 15 : 8;
      } else if (aiTimeMs < responseTimeMs) {
        clashWinner = "p2";
        const baseNormal = match.mode === "solo" && match.difficulty === "facile" ? 12 : 15;
        dmgToP1 = p2Combo3 && match.difficulty !== "facile"
          ? (aiHaya ? 36 : 30)
          : (aiHaya ? Math.round(baseNormal * 1.2) : baseNormal);
        dmgToP2 = p1Combo3 ? 15 : 8;
      } else {
        clashWinner = "tie";
        dmgToP1 = 15;
        dmgToP2 = 15;
      }
    } else {
      // Cas 3 : Double erreur / Double timeout -> Auto-Faute -5 PV chacun
      dmgToP1 = 5;
      dmgToP2 = 5;
    }

    let newP1Hp = Math.max(0, (match.player1_hp || INITIAL_HP) - dmgToP1);
    let newP2Hp = Math.max(0, (match.player2_hp || INITIAL_HP) - dmgToP2);
    let suddenDeathTriggered = false;
    let finishedScenario: number | null = null;
    let player1Won = false;

    const newQuestionsPlayed = (match.questions_played || 0) + (match.is_sudden_death ? 0 : 1);
    const newElapsedMs = (match.elapsed_play_ms || 0) + responseTimeMs;
    const newConsecutiveTimeouts = isTimeout ? (match.player1_consecutive_timeouts || 0) + 1 : 0;

    // Resolution Mort Subite deja active (§7.2 Cas B)
    if (match.is_sudden_death) {
      if (p1Correct && (!aiCorrect || responseTimeMs < aiTimeMs)) {
        newP1Hp = 1; newP2Hp = 0; finishedScenario = 2; player1Won = true;
      } else if (aiCorrect && (!p1Correct || aiTimeMs < responseTimeMs)) {
        newP1Hp = 0; newP2Hp = 1; finishedScenario = 2; player1Won = false;
      } else {
        newP1Hp = 0; newP2Hp = 0; finishedScenario = 5; player1Won = false; // Double K.O. Ai-uchi
      }
    } else if (newConsecutiveTimeouts >= 3) {
      // Coupe-circuit 3 timeouts consecutifs AFK (§7.2)
      finishedScenario = match.player1_correct === 0 ? 6 : 7;
      player1Won = false;
    } else if (newP1Hp === 0 && newP2Hp === 0) {
      // 0 PV Simultané (§7.2 Correction n°2)
      if (p1Correct && aiCorrect && clashWinner === "p1") {
        newP1Hp = 1; finishedScenario = 2; player1Won = true;
      } else if (p1Correct && aiCorrect && clashWinner === "p2") {
        newP2Hp = 1; finishedScenario = 2; player1Won = false;
      } else {
        // Double faute ou egalite exacte -> Question Unique de Mort Subite (1 PV chacun, 5s)
        newP1Hp = 1;
        newP2Hp = 1;
        suddenDeathTriggered = true;
      }
    } else if (newP2Hp === 0) {
      finishedScenario = 1; player1Won = true;
    } else if (newP1Hp === 0) {
      // En mode Solo, si la Seconde Chance n'a pas encore ete utilisee, on met en pause 5s avant cloture
      if (match.mode === "solo" && !match.second_chance_used) {
        finishedScenario = null;
      } else {
        finishedScenario = 1; player1Won = false;
      }
    } else if (newElapsedMs >= GLOBAL_TIMER_MS || newQuestionsPlayed >= (match.max_questions || MAX_QUESTIONS)) {
      // Expiration Chrono Global 2 min ou 40e question -> Decision aux Points
      if (newP1Hp > newP2Hp) {
        finishedScenario = 3; player1Won = true;
      } else if (newP2Hp > newP1Hp) {
        finishedScenario = 3; player1Won = false;
      } else if (match.player1_correct + (p1Correct ? 1 : 0) === 0) {
        finishedScenario = 6; player1Won = false;
      } else {
        finishedScenario = 4; player1Won = false; // Match Nul Actif
      }
    }

    // Accumulation XP et OC par question (hors Mort Subite)
    const addXp = !match.is_sudden_death && p1Correct ? qReward.xp : 0;
    const addOc = !match.is_sudden_death && p1Correct ? qReward.oc : 0;
    const addErrOc = !match.is_sudden_death && !p1Correct ? qReward.errOc : 0;

    // Mode Adaptatif : monte tous les 3 combos ou 2 Haya!!, descend de 1 sur erreur
    let nextAdaptiveTier = match.adaptive_tier || 1;
    if (match.difficulty === "adaptatif") {
      if (!p1Correct) nextAdaptiveTier = Math.max(1, nextAdaptiveTier - 1);
      else if (p1Combo3) nextAdaptiveTier = Math.min(5, nextAdaptiveTier + 1);
    }

    const updatedMatchFields = {
      player1_hp: newP1Hp,
      player2_hp: newP2Hp,
      player1_combo: p1Combo,
      player2_combo: p2Combo,
      player1_correct: (match.player1_correct || 0) + (p1Correct ? 1 : 0),
      player1_errors: (match.player1_errors || 0) + (p1Correct ? 0 : 1),
      player1_haya_count: (match.player1_haya_count || 0) + (p1Haya ? 1 : 0),
      player1_consecutive_timeouts: newConsecutiveTimeouts,
      questions_played: newQuestionsPlayed,
      elapsed_play_ms: newElapsedMs,
      is_sudden_death: suddenDeathTriggered,
      adaptive_tier: nextAdaptiveTier,
      oc_questions_sum: Number(match.oc_questions_sum || 0) + addOc,
      oc_errors_penalty: Number(match.oc_errors_penalty || 0) + addErrOc,
      xp_questions_sum: (match.xp_questions_sum || 0) + addXp,
      last_activity_at: new Date().toISOString(),
    };

    await supabase.from("matches").update(updatedMatchFields).eq("id", match.id);

    let summary = null;
    if (finishedScenario !== null) {
      summary = await closeMatchInternal(
        supabase,
        { ...match, ...updatedMatchFields },
        user.id,
        finishedScenario,
        player1Won
      );
    }

    return jsonResp({
      joueur_correct: p1Correct,
      bot_correct: aiCorrect,
      bonne_reponse: bonneReponseServeur,
      explication: explicationServeur,
      haya_triggered: p1Haya,
      combo_joueur_declenche: p1Combo3,
      combo_bot_declenche: p2Combo3 && match.difficulty !== "facile",
      clash_winner: clashWinner,
      degats_infliges: dmgToP2,
      degats_subis: dmgToP1,
      player1_hp: newP1Hp,
      player2_hp: newP2Hp,
      player1_combo: p1Combo,
      player2_combo: p2Combo,
      elapsed_play_ms: newElapsedMs,
      remaining_global_ms: Math.max(0, GLOBAL_TIMER_MS - newElapsedMs),
      sudden_death_triggered: suddenDeathTriggered,
      can_second_chance: match.mode === "solo" && !match.second_chance_used && newP1Hp === 0 && newP2Hp > 0,
      next_adaptive_tier: tierIndexToKey(nextAdaptiveTier),
      match_finished: finishedScenario !== null,
      summary,
    });
  }

  // =========================================================================
  // 3. END_MATCH (Abandon volontaire, refus Seconde Chance ou cloture explicite)
  // =========================================================================
  if (action === "end_match") {
    const matchId = String(body.match_id || "");
    const isAbandon = Boolean(body.abandon);

    const { data: match } = await supabase
      .from("matches")
      .select("*")
      .eq("id", matchId)
      .eq("player1_id", user.id)
      .single();

    if (!match) return jsonResp({ error: "Match introuvable" }, 404);
    if (match.status !== "in_progress") {
      return jsonResp({ already_finished: true, status: match.status });
    }

    let scenario = 3;
    let won = false;
    if (isAbandon) {
      scenario = 7;
      won = false;
    } else if (match.player1_hp <= 0) {
      scenario = 1;
      won = false;
    } else if (match.player2_hp <= 0) {
      scenario = 1;
      won = true;
    } else if (match.player1_hp > match.player2_hp) {
      scenario = 3;
      won = true;
    } else if (match.player1_hp === match.player2_hp) {
      scenario = match.player1_correct > 0 ? 4 : 6;
      won = false;
    }

    const summary = await closeMatchInternal(supabase, match, user.id, scenario, won);

    return jsonResp({ ok: true, summary });
  }

  // =========================================================================
  // 4. DOUBLE_OC_AD : Bouton Roi "Doubler mes OC x2" (max 10/jour, 0 VC)
  // =========================================================================
  if (action === "double_oc_ad") {
    const matchId = String(body.match_id || "");
    const { data: match } = await supabase
      .from("matches")
      .select("id, player1_id, status, oc_performance_net, double_oc_claimed")
      .eq("id", matchId)
      .eq("player1_id", user.id)
      .single();

    if (!match || match.status !== "finished" || match.double_oc_claimed || match.oc_performance_net <= 0) {
      return jsonResp({ error: "Doublement OC non eligible pour ce match" }, 400);
    }

    await supabase.rpc("ensure_wallet_exists", { p_user_id: user.id });
    const { data: wallet } = await supabase
      .from("economy_wallets")
      .select("*")
      .eq("user_id", user.id)
      .single();

    const today = new Date().toISOString().slice(0, 10);
    const countToday = wallet?.daily_double_oc_date === today ? (wallet.daily_double_oc_count || 0) : 0;
    if (countToday >= 10) {
      return jsonResp({ error: "Limite quotidienne atteinte (10 doublages OC/jour)" }, 429);
    }

    const bonusOc = match.oc_performance_net;
    const newOc = (wallet?.oc_balance || 0) + bonusOc;

    await supabase.from("matches").update({ double_oc_claimed: true }).eq("id", match.id);
    await supabase
      .from("economy_wallets")
      .update({
        oc_balance: newOc,
        daily_double_oc_count: countToday + 1,
        daily_double_oc_date: today,
        updated_at: new Date().toISOString(),
      })
      .eq("user_id", user.id);

    await supabase.from("economy_ledger").insert({
      user_id: user.id,
      currency: "OC",
      delta: bonusOc,
      balance_after: newOc,
      reason: "double_oc_ad",
      match_id: match.id,
    });

    return jsonResp({ ok: true, bonus_oc: bonusOc, new_oc_balance: newOc });
  }

  // =========================================================================
  // 5. RESCUE_OC_AD : Coup de Pouce (+40 OC si solde < frais, max 3/jour)
  // =========================================================================
  if (action === "rescue_oc_ad") {
    const mode = String(body.mode || "division");
    const { data: fee } = await supabase.rpc("get_arena_entry_fee", {
      p_user_id: user.id,
      p_game_mode: mode,
    });
    const entryFee = Number(fee || 0);

    await supabase.rpc("ensure_wallet_exists", { p_user_id: user.id });
    const { data: wallet } = await supabase
      .from("economy_wallets")
      .select("*")
      .eq("user_id", user.id)
      .single();

    if ((wallet?.oc_balance || 0) >= entryFee) {
      return jsonResp({ error: "Tu as deja assez d'OC pour entrer dans ce mode" }, 400);
    }

    const today = new Date().toISOString().slice(0, 10);
    const countToday = wallet?.daily_rescue_oc_date === today ? (wallet.daily_rescue_oc_count || 0) : 0;
    if (countToday >= 3) {
      return jsonResp({ error: "Limite de 3 Coups de Pouce par jour atteinte" }, 429);
    }

    const newOc = (wallet?.oc_balance || 0) + 40;
    await supabase
      .from("economy_wallets")
      .update({
        oc_balance: newOc,
        daily_rescue_oc_count: countToday + 1,
        daily_rescue_oc_date: today,
        updated_at: new Date().toISOString(),
      })
      .eq("user_id", user.id);

    await supabase.from("economy_ledger").insert({
      user_id: user.id,
      currency: "OC",
      delta: 40,
      balance_after: newOc,
      reason: "rescue_oc_ad",
    });

    return jsonResp({ ok: true, added_oc: 40, new_oc_balance: newOc });
  }

  // =========================================================================
  // 6. SECOND_CHANCE : Solo uniquement -> Ressusciter a 100 PV (1x/match)
  // =========================================================================
  if (action === "second_chance") {
    const matchId = String(body.match_id || "");
    const payWithOc = Boolean(body.pay_with_oc);

    const { data: match } = await supabase
      .from("matches")
      .select("*")
      .eq("id", matchId)
      .eq("player1_id", user.id)
      .single();

    if (!match || match.mode !== "solo" || match.second_chance_used) {
      return jsonResp({ error: "Seconde Chance reservee au mode Solo (1 fois/match)" }, 400);
    }

    if (payWithOc) {
      const { data: wallet } = await supabase
        .from("economy_wallets")
        .select("oc_balance")
        .eq("user_id", user.id)
        .single();
      if ((wallet?.oc_balance || 0) < 30) {
        return jsonResp({ error: "Solde insuffisant (30 OC requis)" }, 402);
      }
      const newOc = (wallet?.oc_balance || 0) - 30;
      await supabase
        .from("economy_wallets")
        .update({ oc_balance: newOc, updated_at: new Date().toISOString() })
        .eq("user_id", user.id);
      await supabase.from("economy_ledger").insert({
        user_id: user.id,
        currency: "OC",
        delta: -30,
        balance_after: newOc,
        reason: "second_chance_oc",
        match_id: match.id,
      });
    }

    await supabase
      .from("matches")
      .update({
        status: "in_progress",
        player1_hp: 100,
        second_chance_used: true,
        last_activity_at: new Date().toISOString(),
      })
      .eq("id", match.id);

    return jsonResp({ ok: true, player1_hp: 100 });
  }

  return jsonResp({ error: "Action inconnue" }, 400);
});
