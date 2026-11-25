import { createClient } from "@supabase/supabase-js";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// ============================================================================
// CATALOGUE OFFICIEL SERVEUR V9.2 (ZERO PRIX FAIT CONFIANCE AU CLIENT)
// ============================================================================

interface CatalogItem {
  id: string;
  name: string;
  category: "skin" | "frame" | "ko_effect" | "emote" | "title";
  currency: "oc" | "vc";
  price: number;
  image_key?: string;
}

const GOODIES_CATALOG: Record<string, CatalogItem> = {
  // 1 seul Goodies en OC : depart tutoriel (300 OC, §2.4 & §4.1)
  skin_mazu: {
    id: "skin_mazu",
    name: "Mazú",
    category: "skin",
    currency: "oc",
    price: 300,
    image_key: "skin_mazu",
  },
  // Goodies Classiques (350-500 VC)
  skin_tavik: {
    id: "skin_tavik",
    name: "Tavik",
    category: "skin",
    currency: "vc",
    price: 350,
    image_key: "skin_tavik",
  },
  skin_ruve: {
    id: "skin_ruve",
    name: "Ruvé",
    category: "skin",
    currency: "vc",
    price: 400,
    image_key: "skin_ruve",
  },
  skin_hesk: {
    id: "skin_hesk",
    name: "Hesk",
    category: "skin",
    currency: "vc",
    price: 450,
    image_key: "skin_hesk",
  },
  skin_ilka: {
    id: "skin_ilka",
    name: "Ilka",
    category: "skin",
    currency: "vc",
    price: 500,
    image_key: "skin_ilka",
  },
  // Goodies Epiques (700-900 VC)
  skin_vael: {
    id: "skin_vael",
    name: "Vael",
    category: "skin",
    currency: "vc",
    price: 700,
    image_key: "skin_vael",
  },
  skin_dakore: {
    id: "skin_dakore",
    name: "Dakoré",
    category: "skin",
    currency: "vc",
    price: 800,
    image_key: "skin_dakore",
  },
  skin_ysae: {
    id: "skin_ysae",
    name: "Ysaé",
    category: "skin",
    currency: "vc",
    price: 850,
    image_key: "skin_ysae",
  },
  skin_cassio_vey: {
    id: "skin_cassio_vey",
    name: "Cassio Vey",
    category: "skin",
    currency: "vc",
    price: 900,
    image_key: "skin_cassio_vey",
  },
  // Fondateurs Legendaires (1200-1500 VC, §2.4)
  avatar_soryn_ether_watcher: {
    id: "avatar_soryn_ether_watcher",
    name: "Soryn",
    category: "skin",
    currency: "vc",
    price: 1200,
    image_key: "bot_akina",
  },
  avatar_nyxara_twin_fangs: {
    id: "avatar_nyxara_twin_fangs",
    name: "Nyxara",
    category: "skin",
    currency: "vc",
    price: 1500,
    image_key: "avatar_nyxara_twin_fangs",
  },
  // Cosmetiques secondaires (100% VC, §2.4)
  cadre_neon_shonen: {
    id: "cadre_neon_shonen",
    name: "Cadre Neon Shonen",
    category: "frame",
    currency: "vc",
    price: 150,
  },
  cadre_flamme_astral: {
    id: "cadre_flamme_astral",
    name: "Cadre Flamme Astrale",
    category: "frame",
    currency: "vc",
    price: 250,
  },
  cadre_eclipse_or: {
    id: "cadre_eclipse_or",
    name: "Cadre Eclipse d'Or",
    category: "frame",
    currency: "vc",
    price: 350,
  },
  ko_eclairs_haki: {
    id: "ko_eclairs_haki",
    name: "Finisher Eclairs du Haki",
    category: "ko_effect",
    currency: "vc",
    price: 400,
  },
  ko_tranche_dimension: {
    id: "ko_tranche_dimension",
    name: "Finisher Tranche Dimensionnelle",
    category: "ko_effect",
    currency: "vc",
    price: 550,
  },
  ko_supernova_verse: {
    id: "ko_supernova_verse",
    name: "Finisher Supernova du Verse",
    category: "ko_effect",
    currency: "vc",
    price: 700,
  },
  emote_salut_shinobi: {
    id: "emote_salut_shinobi",
    name: "Emote Salut Shinobi",
    category: "emote",
    currency: "vc",
    price: 250,
  },
  emote_aura_gear: {
    id: "emote_aura_gear",
    name: "Emote Aura Gear",
    category: "emote",
    currency: "vc",
    price: 350,
  },
  emote_trone_empereur: {
    id: "emote_trone_empereur",
    name: "Emote Trone de l'Empereur",
    category: "emote",
    currency: "vc",
    price: 500,
  },
  titre_chasseur_arcs: {
    id: "titre_chasseur_arcs",
    name: "Titre : Chasseur d'Arcs",
    category: "title",
    currency: "vc",
    price: 150,
  },
  titre_foudre_haya: {
    id: "titre_foudre_haya",
    name: "Titre : Foudre Haya!!",
    category: "title",
    currency: "vc",
    price: 200,
  },
  titre_champion_encre: {
    id: "titre_champion_encre",
    name: "Titre : Champion de l'Encre",
    category: "title",
    currency: "vc",
    price: 250,
  },
};

// 5 Packs VC officiels (§2.1 — convention unique 6,00 FCFA / VC)
const VC_PACKS: Record<string, { vc: number; fcfa: number; label: string }> = {
  pack_eclat: { vc: 150, fcfa: 900, label: "Pack Eclat (150 VC)" },
  pack_decouverte: { vc: 350, fcfa: 1900, label: "Pack Decouverte (350 VC)" },
  pack_populaire: { vc: 800, fcfa: 3900, label: "Pack Populaire (800 VC)" },
  pack_seigneur: { vc: 1800, fcfa: 7900, label: "Pack Seigneur du Verse (1 800 VC)" },
  pack_arche: { vc: 4500, fcfa: 17900, label: "Pack Arche du Verse (4 500 VC)" },
};

// Recompenses du calendrier 21 jours (Cycle 1 = 100 VC total sur J7+J14+J21 ; Cycle 2+ = 250 OC a la place)
function getCalendarDayReward(day: number, cycleNumber: number): { oc: number; vc: number } {
  if (day === 7) return cycleNumber === 1 ? { oc: 0, vc: 25 } : { oc: 250, vc: 0 };
  if (day === 14) return cycleNumber === 1 ? { oc: 0, vc: 35 } : { oc: 250, vc: 0 };
  if (day === 21) return cycleNumber === 1 ? { oc: 0, vc: 40 } : { oc: 250, vc: 0 };
  if (day % 5 === 0) return { oc: 60, vc: 0 };
  return { oc: 30, vc: 0 };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!token) {
      return jsonResponse({ error: "Authentification requise" }, 401);
    }

    const { data: authData, error: authError } = await supabaseAdmin.auth.getUser(token);
    if (authError || !authData?.user) {
      return jsonResponse({ error: "Session invalide ou expiree" }, 401);
    }
    const userId = authData.user.id;

    const body = await req.json();
    const action = String(body?.action ?? "");

    await supabaseAdmin.rpc("ensure_wallet_exists", { p_user_id: userId });

    // ------------------------------------------------------------------------
    // 1. ACHAT GOODIES / COSMETIQUE (ECO-02 & SHOP-03)
    // ------------------------------------------------------------------------
    if (action === "purchase_goodie") {
      const itemId = String(body?.item_id ?? "");
      const autoEquip = body?.auto_equip === true;
      const item = GOODIES_CATALOG[itemId];
      if (!item) {
        return jsonResponse({ error: "Article introuvable dans le catalogue officiel" }, 400);
      }

      const { data: existing } = await supabaseAdmin
        .from("player_cosmetics")
        .select("id")
        .eq("user_id", userId)
        .eq("item_id", item.id)
        .maybeSingle();

      if (existing) {
        return jsonResponse({ error: "Tu possedes deja cet article" }, 409);
      }

      if (item.currency === "oc") {
        // Uniquement le Goodies depart tuto (300 OC)
        const { data: wallet } = await supabaseAdmin
          .from("economy_wallets")
          .select("oc_balance")
          .eq("user_id", userId)
          .single();

        const currentOc = wallet?.oc_balance ?? 0;
        if (currentOc < item.price) {
          return jsonResponse(
            { error: `Solde Otaku Coins insuffisant (${currentOc} / ${item.price} OC)` },
            400,
          );
        }

        const newOc = currentOc - item.price;
        await supabaseAdmin
          .from("economy_wallets")
          .update({ oc_balance: newOc, updated_at: new Date().toISOString() })
          .eq("user_id", userId);

        await supabaseAdmin.from("economy_ledger").insert({
          user_id: userId,
          currency: "OC",
          delta: -item.price,
          balance_after: newOc,
          reason: `shop_purchase_${item.id}`,
          metadata: { item_id: item.id, category: item.category },
        });
      } else {
        // Depense 100% VC via RPC securisee (vc_bonus debite en 1er, puis vc_paid)
        const { error: spendErr } = await supabaseAdmin.rpc("spend_verse_coins", {
          p_user_id: userId,
          p_cost_vc: item.price,
          p_reason: `shop_purchase_${item.id}`,
          p_metadata: { item_id: item.id, category: item.category },
        });
        if (spendErr) {
          return jsonResponse({ error: spendErr.message }, 400);
        }
      }

      if (autoEquip) {
        await supabaseAdmin
          .from("player_cosmetics")
          .update({ equipped: false })
          .eq("user_id", userId)
          .eq("category", item.category);
      }

      await supabaseAdmin.from("player_cosmetics").insert({
        user_id: userId,
        item_id: item.id,
        category: item.category,
        equipped: autoEquip,
      });

      // Synchronisation retrocompatible avec player_skins si un skin correspondant existe
      if (item.category === "skin" && item.image_key) {
        const { data: legacySkin } = await supabaseAdmin
          .from("skins")
          .select("id")
          .eq("image_key", item.image_key)
          .maybeSingle();

        if (legacySkin?.id) {
          if (autoEquip) {
            await supabaseAdmin
              .from("player_skins")
              .update({ equipped: false })
              .eq("player_id", userId);
          }
          await supabaseAdmin.from("player_skins").upsert(
            {
              player_id: userId,
              skin_id: legacySkin.id,
              equipped: autoEquip,
            },
            { onConflict: "player_id,skin_id" },
          );
        }
        if (autoEquip) {
          await supabaseAdmin
            .from("profiles")
            .update({ equipped_skin_key: item.image_key })
            .eq("id", userId);
        }
      }

      return jsonResponse({
        ok: true,
        item_id: item.id,
        message: `${item.name} debloque !`,
      });
    }

    // ------------------------------------------------------------------------
    // 2. ACHAT PACK VERSE COINS (SHOP-01 — 5 PACKS EXACTEMENT CALIBRES)
    // ------------------------------------------------------------------------
    if (action === "purchase_vc_pack") {
      const packId = String(body?.pack_id ?? "");
      const pack = VC_PACKS[packId];
      if (!pack) {
        return jsonResponse({ error: "Pack de Verse Coins inconnu" }, 400);
      }

      const { data: wallet } = await supabaseAdmin
        .from("economy_wallets")
        .select("vc_paid")
        .eq("user_id", userId)
        .single();

      const newPaid = (wallet?.vc_paid ?? 0) + pack.vc;
      await supabaseAdmin
        .from("economy_wallets")
        .update({ vc_paid: newPaid, updated_at: new Date().toISOString() })
        .eq("user_id", userId);

      await supabaseAdmin.from("economy_ledger").insert({
        user_id: userId,
        currency: "VC_PAID",
        delta: pack.vc,
        balance_after: newPaid,
        reason: `iap_${packId}`,
        metadata: { fcfa: pack.fcfa, mode: "beta_sandbox" },
      });

      return jsonResponse({
        ok: true,
        vc_added: pack.vc,
        vc_paid_after: newPaid,
        message: `${pack.label} credite (+${pack.vc} VC) !`,
      });
    }

    // ------------------------------------------------------------------------
    // 3. LES 3 OFFRES MONETISATION : NO ADS 1 AN, PACK DEMARRAGE, VIP (SHOP-02)
    // ------------------------------------------------------------------------
    if (action === "purchase_offer") {
      const offerId = String(body?.offer_id ?? "");
      const { data: profile } = await supabaseAdmin
        .from("profiles")
        .select("is_vip, vip_expires_at, no_ads_expires_at, starter_pack_claimed")
        .eq("id", userId)
        .single();

      const { data: wallet } = await supabaseAdmin
        .from("economy_wallets")
        .select("oc_balance, vc_paid")
        .eq("user_id", userId)
        .single();

      const now = Date.now();
      const plusDays = (d: number) => new Date(now + d * 86400 * 1000).toISOString();

      if (offerId === "no_ads_1y") {
        const exp = plusDays(365);
        await supabaseAdmin
          .from("profiles")
          .update({ no_ads_expires_at: exp })
          .eq("id", userId);
        return jsonResponse({
          ok: true,
          message: "Pass Sans Pub 1 An active (0 pub interstitielle pendant 365 jours).",
        });
      }

      if (offerId === "starter_pack") {
        if (profile?.starter_pack_claimed) {
          return jsonResponse({ error: "Pack Demarrage limite a 1 seul achat par compte." }, 409);
        }
        const exp = plusDays(365);
        const newVcPaid = (wallet?.vc_paid ?? 0) + 400;
        const newOc = (wallet?.oc_balance ?? 0) + 500;

        await supabaseAdmin
          .from("profiles")
          .update({ starter_pack_claimed: true, no_ads_expires_at: exp })
          .eq("id", userId);

        await supabaseAdmin
          .from("economy_wallets")
          .update({
            vc_paid: newVcPaid,
            oc_balance: newOc,
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", userId);

        await supabaseAdmin.from("economy_ledger").insert([
          {
            user_id: userId,
            currency: "VC_PAID",
            delta: 400,
            balance_after: newVcPaid,
            reason: "offer_starter_pack",
          },
          {
            user_id: userId,
            currency: "OC",
            delta: 500,
            balance_after: newOc,
            reason: "offer_starter_pack",
          },
        ]);

        return jsonResponse({
          ok: true,
          message: "Pack Demarrage active : Sans Pub 1 An + 400 VC + 500 OC !",
        });
      }

      if (offerId === "vip_monthly" || offerId === "vip_yearly") {
        const isYearly = offerId === "vip_yearly";
        const isFirstMonth = !isYearly && !profile?.vip_expires_at;
        const vcGrant = isYearly ? 800 : isFirstMonth ? 200 : 250;
        const exp = plusDays(isYearly ? 365 : 30);
        const newVcPaid = (wallet?.vc_paid ?? 0) + vcGrant;

        await supabaseAdmin
          .from("profiles")
          .update({
            is_vip: true,
            vip_expires_at: exp,
            no_ads_expires_at: exp,
            active_frame: "cadre_vip_or_violet",
            ...(isYearly ? { active_title: "Architecte Suprême du Verse" } : {}),
          })
          .eq("id", userId);

        await supabaseAdmin
          .from("economy_wallets")
          .update({ vc_paid: newVcPaid, updated_at: new Date().toISOString() })
          .eq("user_id", userId);

        await supabaseAdmin.from("economy_ledger").insert({
          user_id: userId,
          currency: "VC_PAID",
          delta: vcGrant,
          balance_after: newVcPaid,
          reason: `offer_${offerId}`,
        });

        await supabaseAdmin.from("player_cosmetics").upsert(
          {
            user_id: userId,
            item_id: "cadre_vip_or_violet",
            category: "frame",
            equipped: true,
          },
          { onConflict: "user_id,item_id" },
        );

        if (isYearly) {
          await supabaseAdmin.from("player_cosmetics").upsert(
            {
              user_id: userId,
              item_id: "titre_architecte_supreme",
              category: "title",
              equipped: true,
            },
            { onConflict: "user_id,item_id" },
          );
        }

        return jsonResponse({
          ok: true,
          message: isYearly
            ? "Pass VIP Annuel active : +800 VC immediats, Sans Pub, Cadre VIP et 8 Privileges !"
            : `Pass VIP Mensuel active : +${vcGrant} VC, Sans Pub, Cadre VIP et 8 Privileges !`,
        });
      }

      return jsonResponse({ error: "Offre inconnue" }, 400);
    }

    // ------------------------------------------------------------------------
    // 4. CALENDRIER 21 JOURS (PLAFOND 150 VC/SAISON + SWAP CYCLE 2 EN 250 OC)
    // ------------------------------------------------------------------------
    if (action === "claim_calendar_day") {
      const todayIso = new Date().toISOString().slice(0, 10);
      const { data: wallet } = await supabaseAdmin
        .from("economy_wallets")
        .select("*")
        .eq("user_id", userId)
        .single();

      const { data: profile } = await supabaseAdmin
        .from("profiles")
        .select("is_vip")
        .eq("id", userId)
        .single();

      const seasonId = wallet?.season_id ?? "saison_1";

      // Verifier si deja reclame aujourd'hui
      const { data: todayClaim } = await supabaseAdmin
        .from("daily_calendar_claims")
        .select("id")
        .eq("user_id", userId)
        .eq("claimed_date", todayIso)
        .maybeSingle();

      if (todayClaim) {
        return jsonResponse({ error: "Recompense du jour deja recuperee." }, 409);
      }

      // Determiner le cycle et le jour suivant
      const { data: allClaims } = await supabaseAdmin
        .from("daily_calendar_claims")
        .select("cycle_number, day_number")
        .eq("user_id", userId)
        .eq("season_id", seasonId)
        .order("cycle_number", { ascending: false })
        .order("day_number", { ascending: false })
        .limit(1);

      let nextCycle = 1;
      let nextDay = 1;
      if (allClaims && allClaims.length > 0) {
        const last = allClaims[0];
        if (last.day_number >= 21) {
          nextCycle = last.cycle_number + 1;
          nextDay = 1;
        } else {
          nextCycle = last.cycle_number;
          nextDay = last.day_number + 1;
        }
      }

      const baseReward = getCalendarDayReward(nextDay, nextCycle);

      // Sur les jours VC, verifier qu'au moins 1 match a ete termine aujourd'hui (§2.1)
      if (baseReward.vc > 0) {
        const { count: matchesToday } = await supabaseAdmin
          .from("matches")
          .select("id", { count: "exact", head: true })
          .eq("player1_id", userId)
          .eq("status", "finished")
          .gte("ended_at", `${todayIso}T00:00:00.000Z`);

        if ((matchesToday ?? 0) < 1) {
          return jsonResponse(
            { error: "Termine au moins 1 match aujourd'hui pour debloquer la case Verse Coins !" },
            400,
          );
        }
      }

      let vcGrant = baseReward.vc;
      let ocGrant = baseReward.oc + (profile?.is_vip ? 25 : 0);

      // Respect strict du plafond de 150 VC gratuits/saison
      const currentFreeVc = wallet?.season_free_vc_earned ?? 0;
      if (vcGrant > 0 && currentFreeVc + vcGrant > 150) {
        vcGrant = Math.max(0, 150 - currentFreeVc);
        if (vcGrant === 0) ocGrant += 250;
      }

      await supabaseAdmin.from("daily_calendar_claims").insert({
        user_id: userId,
        season_id: seasonId,
        cycle_number: nextCycle,
        day_number: nextDay,
        claimed_date: todayIso,
      });

      const newOc = (wallet?.oc_balance ?? 0) + ocGrant;
      const newVcBonus = (wallet?.vc_bonus ?? 0) + vcGrant;
      const newFreeVc = currentFreeVc + vcGrant;

      await supabaseAdmin
        .from("economy_wallets")
        .update({
          oc_balance: newOc,
          vc_bonus: newVcBonus,
          season_free_vc_earned: newFreeVc,
          updated_at: new Date().toISOString(),
        })
        .eq("user_id", userId);

      if (ocGrant > 0) {
        await supabaseAdmin.from("economy_ledger").insert({
          user_id: userId,
          currency: "OC",
          delta: ocGrant,
          balance_after: newOc,
          reason: `calendar_c${nextCycle}_d${nextDay}`,
        });
      }
      if (vcGrant > 0) {
        await supabaseAdmin.from("economy_ledger").insert({
          user_id: userId,
          currency: "VC_BONUS",
          delta: vcGrant,
          balance_after: newVcBonus,
          reason: `calendar_c${nextCycle}_d${nextDay}`,
        });
      }

      const parts: string[] = [];
      if (vcGrant > 0) parts.push(`+${vcGrant} VC`);
      if (ocGrant > 0) parts.push(`+${ocGrant} OC`);

      return jsonResponse({
        ok: true,
        cycle_number: nextCycle,
        day_number: nextDay,
        oc_gained: ocGrant,
        vc_gained: vcGrant,
        message: `Jour ${nextDay}/21 reclame : ${parts.join(" & ")} !`,
      });
    }

    // ------------------------------------------------------------------------
    // 5. TUTORIEL PHASE A (+300 OC + 100 XP, UNE SEULE FOIS — §4.1)
    // ------------------------------------------------------------------------
    if (action === "complete_tutorial_phase_a") {
      const { data: profile } = await supabaseAdmin
        .from("profiles")
        .select("tutorial_phase_a_done, xp_totale")
        .eq("id", userId)
        .single();

      if (profile?.tutorial_phase_a_done) {
        return jsonResponse({ ok: true, already_done: true, message: "Phase A deja validee." });
      }

      const { data: wallet } = await supabaseAdmin
        .from("economy_wallets")
        .select("oc_balance")
        .eq("user_id", userId)
        .single();

      const newOc = (wallet?.oc_balance ?? 0) + 300;
      const newXp = (profile?.xp_totale ?? 0) + 100;

      const { data: newLvl } = await supabaseAdmin.rpc("get_level_from_xp", { p_xp: newXp });
      const level = typeof newLvl === "number" ? newLvl : 2;
      const { data: newRank } = await supabaseAdmin.rpc("get_rank_title", { p_level: level });

      // Verrou atomique : on passe tutorial_phase_a_done de false a true AVANT de crediter les OC.
      // Si la mise a jour echoue ou a deja ete faite en parallele, on ne credite jamais deux fois.
      const { data: updatedProfile, error: profileUpdateErr } = await supabaseAdmin
        .from("profiles")
        .update({
          tutorial_phase_a_done: true,
          xp_totale: newXp,
          niveau: level,
          rang: newRank ?? "Novice du Verse",
        })
        .eq("id", userId)
        .or("tutorial_phase_a_done.is.null,tutorial_phase_a_done.eq.false")
        .select("id")
        .maybeSingle();

      if (profileUpdateErr) {
        return jsonResponse(
          { error: `Impossible de valider la Phase A sur le profil : ${profileUpdateErr.message}` },
          500,
        );
      }
      if (!updatedProfile) {
        return jsonResponse({ ok: true, already_done: true, message: "Phase A deja validee." });
      }

      const { error: walletUpdateErr } = await supabaseAdmin
        .from("economy_wallets")
        .update({ oc_balance: newOc, updated_at: new Date().toISOString() })
        .eq("user_id", userId);

      if (walletUpdateErr) {
        return jsonResponse(
          { error: `Erreur credit OC Phase A : ${walletUpdateErr.message}` },
          500,
        );
      }

      await supabaseAdmin.from("economy_ledger").insert([
        {
          user_id: userId,
          currency: "OC",
          delta: 300,
          balance_after: newOc,
          reason: "tutorial_phase_a_reward",
        },
        {
          user_id: userId,
          currency: "XP",
          delta: 100,
          balance_after: newXp,
          reason: "tutorial_phase_a_reward",
        },
      ]);

      return jsonResponse({
        ok: true,
        already_done: false,
        oc_gained: 300,
        xp_gained: 100,
        message: "Bienvenue dans le Verse ! +300 OC et +100 XP credites.",
      });
    }

    // ------------------------------------------------------------------------
    // 6. TUTORIEL PHASE B (6 ETAPES VERROUILLEES REELLEMENT -> +25 VC + 100 OC + "Initié du Verse")
    // ------------------------------------------------------------------------
    if (action === "complete_tutorial_phase_b_step") {
      const step = Number(body?.step ?? 0);
      if (!Number.isInteger(step) || step < 1 || step > 6) {
        return jsonResponse({ error: "Étape Phase B invalide (1 à 6)" }, 400);
      }

      const { data: profile } = await supabaseAdmin
        .from("profiles")
        .select("tutorial_phase_b_steps, tutorial_phase_b_claimed, combats_joues, season_matches_played")
        .eq("id", userId)
        .single();

      // Verification reelle cote serveur avant validation de chaque etape (Test 6)
      if (step === 1) {
        // Etape 1 : avoir reclame au moins 1 jour du Calendrier 21 jours
        const { count: calCount } = await supabaseAdmin
          .from("daily_calendar_claims")
          .select("id", { count: "exact", head: true })
          .eq("user_id", userId);
        if ((calCount ?? 0) < 1) {
          return jsonResponse(
            { error: "Réclame d'abord le Jour 1 du Calendrier 21 jours dans la Boutique !" },
            400,
          );
        }
      } else if (step === 2) {
        // Etape 2 : avoir termine au moins 1 Combat Solo
        const { count: soloCount } = await supabaseAdmin
          .from("matches")
          .select("id", { count: "exact", head: true })
          .eq("player1_id", userId)
          .eq("mode", "solo")
          .eq("status", "finished");
        if ((soloCount ?? 0) < 1 && (profile?.combats_joues ?? 0) < 1) {
          return jsonResponse(
            { error: "Termine d'abord au moins 1 Combat Solo pour valider cette étape !" },
            400,
          );
        }
      } else if (step === 3) {
        // Etape 3 : avoir termine au moins 1 duel en Mode Division
        const { count: divCount } = await supabaseAdmin
          .from("matches")
          .select("id", { count: "exact", head: true })
          .eq("player1_id", userId)
          .eq("mode", "division")
          .eq("status", "finished");
        if ((divCount ?? 0) < 1) {
          return jsonResponse(
            { error: "Termine d'abord 1 match en Mode Division pour valider cette étape !" },
            400,
          );
        }
      } else if (step === 4 || step === 5) {
        // Etapes 4 (Boutique) & 5 (Profil/Classements) : preuve de visite reelle exigee
        if (body?.verified_visit !== true) {
          return jsonResponse(
            { error: step === 4 ? "Visite d'abord la Boutique avant de valider !" : "Consulte d'abord le Classement Division ou ton Profil !" },
            400,
          );
        }
      } else if (step === 6) {
        // Etape 6 : s'etre inscrit a au moins 1 alerte (feature_waitlist) ou avoir consulte le Guide
        const { count: waitCount } = await supabaseAdmin
          .from("feature_waitlist")
          .select("id", { count: "exact", head: true })
          .eq("user_id", userId);
        if ((waitCount ?? 0) < 1 && body?.verified_visit !== true) {
          return jsonResponse(
            { error: "Active une alerte « M'alerter » sur un mode futur ou consulte le Guide du jeu !" },
            400,
          );
        }
      }

      const currentSteps: number[] = Array.isArray(profile?.tutorial_phase_b_steps)
        ? profile.tutorial_phase_b_steps.map(Number)
        : [];

      const updatedSet = Array.from(new Set([...currentSteps, step])).sort((a, b) => a - b);
      const allSixDone = [1, 2, 3, 4, 5, 6].every((s) => updatedSet.includes(s));

      let rewardClaimedNow = false;
      let vcGranted = 0;

      if (allSixDone && !profile?.tutorial_phase_b_claimed) {
        const { data: wallet } = await supabaseAdmin
          .from("economy_wallets")
          .select("oc_balance, vc_bonus, season_free_vc_earned")
          .eq("user_id", userId)
          .single();

        const currentFreeVc = wallet?.season_free_vc_earned ?? 0;
        vcGranted = Math.min(25, Math.max(0, 150 - currentFreeVc));
        const newOc = (wallet?.oc_balance ?? 0) + 100;
        const newVcBonus = (wallet?.vc_bonus ?? 0) + vcGranted;

        await supabaseAdmin
          .from("economy_wallets")
          .update({
            oc_balance: newOc,
            vc_bonus: newVcBonus,
            season_free_vc_earned: currentFreeVc + vcGranted,
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", userId);

        await supabaseAdmin.from("economy_ledger").insert([
          {
            user_id: userId,
            currency: "OC",
            delta: 100,
            balance_after: newOc,
            reason: "tutorial_phase_b_complete",
          },
          ...(vcGranted > 0
            ? [
                {
                  user_id: userId,
                  currency: "VC_BONUS",
                  delta: vcGranted,
                  balance_after: newVcBonus,
                  reason: "tutorial_phase_b_complete",
                },
              ]
            : []),
        ]);

        await supabaseAdmin.from("player_cosmetics").upsert(
          {
            user_id: userId,
            item_id: "titre_initie_du_verse",
            category: "title",
            equipped: true,
          },
          { onConflict: "user_id,item_id" },
        );

        await supabaseAdmin
          .from("profiles")
          .update({
            tutorial_phase_b_steps: updatedSet,
            tutorial_phase_b_claimed: true,
            active_title: "Initié du Verse",
          })
          .eq("id", userId);

        rewardClaimedNow = true;
      } else {
        await supabaseAdmin
          .from("profiles")
          .update({ tutorial_phase_b_steps: updatedSet })
          .eq("id", userId);
      }

      return jsonResponse({
        ok: true,
        steps: updatedSet,
        completed_all: allSixDone,
        reward_claimed: rewardClaimedNow,
        vc_gained: vcGranted,
        oc_gained: rewardClaimedNow ? 100 : 0,
        title_granted: rewardClaimedNow ? "Initié du Verse" : null,
        message: rewardClaimedNow
          ? `Parcours d'Initiation terminé ! +${vcGranted} VC, +100 OC et Titre « Initié du Verse » !`
          : `Étape ${step}/6 validée (${updatedSet.length}/6).`,
      });
    }

    // ------------------------------------------------------------------------
    // 7. DEPENSE VC CREATION DONJON (100 VC) OU SALON LIVE (150 VC) — COMM-01
    // ------------------------------------------------------------------------
    if (action === "spend_vc_feature") {
      const feature = String(body?.feature ?? "");
      const costMap: Record<string, number> = {
        donjon: 100,
        salon_live: 150,
      };
      const baseCost = costMap[feature];
      if (!baseCost) {
        return jsonResponse({ error: "Fonctionnalite inconnue (donjon ou salon_live)" }, 400);
      }

      const { data: profile } = await supabaseAdmin
        .from("profiles")
        .select("is_vip")
        .eq("id", userId)
        .single();

      if (profile?.is_vip) {
        return jsonResponse({ ok: true, cost_vc: 0, vip_free: true });
      }

      const { error: spendErr } = await supabaseAdmin.rpc("spend_verse_coins", {
        p_user_id: userId,
        p_cost_vc: baseCost,
        p_reason: `create_${feature}`,
        p_metadata: { feature },
      });

      if (spendErr) {
        return jsonResponse({ error: spendErr.message }, 400);
      }

      return jsonResponse({ ok: true, cost_vc: baseCost, vip_free: false });
    }

    // ------------------------------------------------------------------------
    // 8. VERSE ANALYTICS — 7 STATS PRO EXCLUSIVES VIP (§2.3 #4, TEST 39)
    // ------------------------------------------------------------------------
    if (action === "get_vip_analytics") {
      const { data: profile } = await supabaseAdmin
        .from("profiles")
        .select("is_vip, vip_expires_at, combats_joues, combats_gagnes, ko_wins_season, division_id, pts_division, niveau")
        .eq("id", userId)
        .single();

      const vipActive =
        profile?.is_vip === true &&
        (!profile?.vip_expires_at || new Date(profile.vip_expires_at).getTime() > Date.now());
      if (!vipActive) {
        return jsonResponse({ locked: true, error: "Réservé aux abonnés VIP" }, 403);
      }

      const { data: recentMatches } = await supabaseAdmin
        .from("matches")
        .select(
          "mode, difficulty, malus_mode, winner_id, player1_hp, player2_hp, player1_correct, player1_errors, player1_haya_count, questions_played, elapsed_play_ms, ended_by_ko, started_at",
        )
        .eq("player1_id", userId)
        .eq("status", "finished")
        .order("started_at", { ascending: false })
        .limit(50);

      const list = recentMatches ?? [];
      let totalCorrect = 0;
      let totalAnswers = 0;
      let totalHaya = 0;
      let totalMs = 0;
      let wins = 0;
      let koWins = 0;
      let malusMatches = 0;
      let malusWins = 0;
      const byDifficulty: Record<string, { played: number; wins: number; correct: number; total: number }> = {};
      const byMode: Record<string, { played: number; wins: number; correct: number; total: number }> = {};

      const history50 = list.map((m) => {
        const c = m.player1_correct ?? 0;
        const e = m.player1_errors ?? 0;
        const q = Math.max(1, c + e);
        const won = m.winner_id === userId;
        totalCorrect += c;
        totalAnswers += q;
        totalHaya += m.player1_haya_count ?? 0;
        totalMs += m.elapsed_play_ms ?? 0;
        if (won) wins++;
        if (won && m.ended_by_ko) koWins++;
        if (m.malus_mode !== "zen") {
          malusMatches++;
          if (won) malusWins++;
        }
        const diff = m.difficulty ?? "moyen";
        if (!byDifficulty[diff]) byDifficulty[diff] = { played: 0, wins: 0, correct: 0, total: 0 };
        byDifficulty[diff].played++;
        if (won) byDifficulty[diff].wins++;
        byDifficulty[diff].correct += c;
        byDifficulty[diff].total += q;

        const md = m.mode ?? "solo";
        if (!byMode[md]) byMode[md] = { played: 0, wins: 0, correct: 0, total: 0 };
        byMode[md].played++;
        if (won) byMode[md].wins++;
        byMode[md].correct += c;
        byMode[md].total += q;

        return {
          mode: md,
          difficulty: diff,
          won,
          ko: won && m.ended_by_ko === true,
          hp: m.player1_hp ?? 0,
          accuracy: Math.round((c / q) * 100),
          started_at: m.started_at,
        };
      });

      // Carnet d'erreurs revisable (table player_question_errors si migree)
      let errorNotebook: any[] = [];
      try {
        const { data: errRows } = await supabaseAdmin
          .from("player_question_errors")
          .select("id, question_id, work_slug, arc_name, difficulty_level, question_text, chosen_answer, correct_answer, explanation, reviewed, created_at")
          .eq("user_id", userId)
          .order("created_at", { ascending: false })
          .limit(60);
        if (Array.isArray(errRows)) {
          errorNotebook = errRows;
        }
      } catch (_) {}

      // Comparateur Head-to-Head vs moyenne de la Division
      let divAvgWinRate = 52;
      let divAvgAccuracy = 64;
      try {
        const { data: peers } = await supabaseAdmin
          .from("profiles")
          .select("combats_joues, combats_gagnes, season_correct_answers, season_total_answers")
          .eq("division_id", profile?.division_id ?? 10)
          .gt("combats_joues", 0)
          .limit(100);
        if (peers && peers.length > 0) {
          let sumWr = 0;
          let sumAcc = 0;
          let accCount = 0;
          for (const p of peers) {
            const played = Math.max(1, Number(p.combats_joues || 1));
            sumWr += (Number(p.combats_gagnes || 0) / played) * 100;
            const totA = Number(p.season_total_answers || 0);
            if (totA > 0) {
              sumAcc += (Number(p.season_correct_answers || 0) / totA) * 100;
              accCount++;
            }
          }
          divAvgWinRate = Math.round(sumWr / peers.length);
          if (accCount > 0) divAvgAccuracy = Math.round(sumAcc / accCount);
        }
      } catch (_) {}

      const accuracyPct = totalAnswers > 0 ? Math.round((totalCorrect / totalAnswers) * 100) : 0;
      const avgTimeSec = totalAnswers > 0 ? Number((totalMs / totalAnswers / 1000).toFixed(2)) : 0;
      const hayaRatioPct = totalCorrect > 0 ? Math.round((totalHaya / totalCorrect) * 100) : 0;
      const malusResPct = malusMatches > 0 ? Math.round((malusWins / malusMatches) * 100) : 100;
      const winRatePct = list.length > 0 ? Math.round((wins / list.length) * 100) : 0;
      const koRatePct = wins > 0 ? Math.round((koWins / wins) * 100) : 0;

      return jsonResponse({
        locked: false,
        sample_size: list.length,
        radar_5_axes: {
          precision: accuracyPct,
          vitesse: Math.min(100, Math.max(10, Math.round(100 - avgTimeSec * 8))),
          haya: hayaRatioPct,
          resistance_malus: malusResPct,
          combativite: winRatePct,
        },
        by_difficulty: byDifficulty,
        by_mode: byMode,
        avg_reaction_sec: avgTimeSec,
        haya_ratio_pct: hayaRatioPct,
        malus_resistance_pct: malusResPct,
        history_50: history50.reverse(),
        total_errors_recent: Math.max(0, totalAnswers - totalCorrect),
        error_notebook: errorNotebook,
        head_to_head_summary: {
          matches: list.length,
          wins,
          losses: list.length - wins,
          win_rate_pct: winRatePct,
          ko_rate_pct: koRatePct,
          division_id: profile?.division_id ?? 10,
          division_avg_win_rate: divAvgWinRate,
          division_avg_accuracy: divAvgAccuracy,
        },
      });
    }

    // ------------------------------------------------------------------------
    // 9. RECHARGES OC MANQUANTES (§1.4, TEST 31, CALCUL #12)
    //    - recharge_aura_skill : 20 OC
    //    - recover_calendar_day : 40 / 80 / 160 OC (ou 0 OC VIP 1x/semaine)
    //    - buy_bonus_challenges : 50 OC (3 defis bonus)
    // ------------------------------------------------------------------------
    if (action === "recharge_aura_skill") {
      const cost = 20;
      const { data: wallet } = await supabaseAdmin
        .from("economy_wallets")
        .select("oc_balance, aura_charges")
        .eq("user_id", userId)
        .single();

      const currentOc = wallet?.oc_balance ?? 0;
      if (currentOc < cost) {
        return jsonResponse({ error: `Solde OC insuffisant (${currentOc} / ${cost} OC requis)` }, 400);
      }

      const newOc = currentOc - cost;
      const newCharges = (wallet?.aura_charges ?? 0) + 1;

      await supabaseAdmin
        .from("economy_wallets")
        .update({ oc_balance: newOc, aura_charges: newCharges, updated_at: new Date().toISOString() })
        .eq("user_id", userId);

      await supabaseAdmin.from("economy_ledger").insert({
        user_id: userId,
        currency: "OC",
        delta: -cost,
        balance_after: newOc,
        reason: "recharge_aura_skill",
      });

      return jsonResponse({
        ok: true,
        oc_balance: newOc,
        aura_charges: newCharges,
        message: "Compétence d'Aura rechargée (-20 OC) !",
      });
    }

    if (action === "recover_calendar_day") {
      const { data: wallet } = await supabaseAdmin
        .from("economy_wallets")
        .select("*")
        .eq("user_id", userId)
        .single();
      const { data: profile } = await supabaseAdmin
        .from("profiles")
        .select("is_vip, vip_expires_at, vip_free_recovery_week")
        .eq("id", userId)
        .single();

      const seasonId = wallet?.season_id ?? "saison_1";
      const { data: lastClaim } = await supabaseAdmin
        .from("daily_calendar_claims")
        .select("cycle_number, day_number")
        .eq("user_id", userId)
        .eq("season_id", seasonId)
        .order("cycle_number", { ascending: false })
        .order("day_number", { ascending: false })
        .limit(1);

      let nextCycle = 1;
      let nextDay = 1;
      if (lastClaim && lastClaim.length > 0) {
        const last = lastClaim[0];
        if (last.day_number >= 21) {
          nextCycle = last.cycle_number + 1;
          nextDay = 1;
        } else {
          nextCycle = last.cycle_number;
          nextDay = last.day_number + 1;
        }
      }

      // Nombre de jours deja reactives dans ce cycle (cout progressif : 40 / 80 / 160 OC)
      const { count: recoveredCount } = await supabaseAdmin
        .from("daily_calendar_claims")
        .select("id", { count: "exact", head: true })
        .eq("user_id", userId)
        .eq("season_id", seasonId)
        .eq("cycle_number", nextCycle)
        .eq("is_recovery", true);

      const recIdx = recoveredCount ?? 0;
      const baseCost = recIdx === 0 ? 40 : recIdx === 1 ? 80 : 160;

      // Privilege VIP #5 : 1 recharge gratuite par semaine
      const now = new Date();
      const weekKey = `${now.getUTCFullYear()}-W${Math.ceil(((now.getTime() - Date.UTC(now.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7)}`;
      const vipActive =
        profile?.is_vip === true &&
        (!profile?.vip_expires_at || new Date(profile.vip_expires_at).getTime() > now.getTime());
      const useVipFree = vipActive && profile?.vip_free_recovery_week !== weekKey;
      const finalCost = useVipFree ? 0 : baseCost;

      const currentOc = wallet?.oc_balance ?? 0;
      if (currentOc < finalCost) {
        return jsonResponse({ error: `Solde OC insuffisant (${currentOc} / ${finalCost} OC requis)` }, 400);
      }

      const baseReward = getCalendarDayReward(nextDay, nextCycle);
      let vcGrant = baseReward.vc;
      let ocGrant = baseReward.oc + (vipActive ? 25 : 0);
      const currentFreeVc = wallet?.season_free_vc_earned ?? 0;
      if (vcGrant > 0 && currentFreeVc + vcGrant > 150) {
        vcGrant = Math.max(0, 150 - currentFreeVc);
        if (vcGrant === 0) ocGrant += 250;
      }

      const newOc = currentOc - finalCost + ocGrant;
      const newVcBonus = (wallet?.vc_bonus ?? 0) + vcGrant;
      const todayIso = now.toISOString().slice(0, 10);

      await supabaseAdmin.from("daily_calendar_claims").insert({
        user_id: userId,
        season_id: seasonId,
        cycle_number: nextCycle,
        day_number: nextDay,
        claimed_date: todayIso,
        is_recovery: true,
      });

      await supabaseAdmin
        .from("economy_wallets")
        .update({
          oc_balance: newOc,
          vc_bonus: newVcBonus,
          season_free_vc_earned: currentFreeVc + vcGrant,
          updated_at: now.toISOString(),
        })
        .eq("user_id", userId);

      if (useVipFree) {
        await supabaseAdmin
          .from("profiles")
          .update({ vip_free_recovery_week: weekKey })
          .eq("id", userId);
      }

      if (finalCost > 0) {
        await supabaseAdmin.from("economy_ledger").insert({
          user_id: userId,
          currency: "OC",
          delta: -finalCost,
          balance_after: currentOc - finalCost,
          reason: `calendar_recovery_c${nextCycle}_d${nextDay}`,
        });
      }
      if (ocGrant > 0) {
        await supabaseAdmin.from("economy_ledger").insert({
          user_id: userId,
          currency: "OC",
          delta: ocGrant,
          balance_after: newOc,
          reason: `calendar_c${nextCycle}_d${nextDay}`,
        });
      }
      if (vcGrant > 0) {
        await supabaseAdmin.from("economy_ledger").insert({
          user_id: userId,
          currency: "VC_BONUS",
          delta: vcGrant,
          balance_after: newVcBonus,
          reason: `calendar_c${nextCycle}_d${nextDay}`,
        });
      }

      return jsonResponse({
        ok: true,
        cost_oc: finalCost,
        vip_free_used: useVipFree,
        day_number: nextDay,
        cycle_number: nextCycle,
        oc_gained: ocGrant,
        vc_gained: vcGrant,
        message: useVipFree
          ? `Jour ${nextDay}/21 réactivé gratuitement (Privilège VIP) !`
          : `Jour ${nextDay}/21 réactivé (-${finalCost} OC) !`,
      });
    }

    if (action === "buy_bonus_challenges") {
      const cost = 50;
      const todayIso = new Date().toISOString().slice(0, 10);
      const { data: wallet } = await supabaseAdmin
        .from("economy_wallets")
        .select("oc_balance, bonus_challenges_date")
        .eq("user_id", userId)
        .single();

      if (wallet?.bonus_challenges_date === todayIso) {
        return jsonResponse({ error: "Tu as déjà débloqué les 3 défis bonus aujourd'hui." }, 409);
      }
      const currentOc = wallet?.oc_balance ?? 0;
      if (currentOc < cost) {
        return jsonResponse({ error: `Solde OC insuffisant (${currentOc} / ${cost} OC requis)` }, 400);
      }

      const newOc = currentOc - cost;
      await supabaseAdmin
        .from("economy_wallets")
        .update({
          oc_balance: newOc,
          bonus_challenges_date: todayIso,
          updated_at: new Date().toISOString(),
        })
        .eq("user_id", userId);

      await supabaseAdmin.from("economy_ledger").insert({
        user_id: userId,
        currency: "OC",
        delta: -cost,
        balance_after: newOc,
        reason: "buy_3_bonus_challenges",
      });

      // Ajouter 3 defis bonus du jour dans daily_challenges
      const bonusDefs = [
        { defi_id: "bonus_ko_1", description: "Défi Bonus : Gagner 1 combat par K.O.", objectif: 1, type: "ko" },
        { defi_id: "bonus_rep_20", description: "Défi Bonus : Réussir 20 bonnes réponses", objectif: 20, type: "bonnes_reponses" },
        { defi_id: "bonus_win_2", description: "Défi Bonus : Remporter 2 victoires", objectif: 2, type: "victoires" },
      ];
      try {
        await supabaseAdmin.from("daily_challenges").insert(
          bonusDefs.map((d) => ({
            user_id: userId,
            date: todayIso,
            defi_id: d.defi_id,
            description: d.description,
            objectif: d.objectif,
            type: d.type,
            progres: 0,
            complete: false,
          })),
        );
      } catch (_) {}

      return jsonResponse({
        ok: true,
        oc_balance: newOc,
        message: "3 Défis Bonus débloqués pour aujourd'hui (-50 OC) !",
      });
    }

    // =========================================================================
    // PHASE C1 : SUPPRESSION DEFINITIVE DE COMPTE IN-APP (GOOGLE PLAY & APPLE)
    // =========================================================================
    if (action === "delete_account") {
      if (body.confirm !== "SUPPRIMER") {
        return jsonResponse({ error: "Confirmation explicite requise." }, 400);
      }

      // Nettoyer les tables liees avant suppression de auth.users (cascade securisee)
      const userTables = [
        { table: "question_reports", col: "user_id" },
        { table: "player_question_errors", col: "user_id" },
        { table: "daily_calendar_claims", col: "user_id" },
        { table: "daily_challenges", col: "user_id" },
        { table: "player_cosmetics", col: "user_id" },
        { table: "economy_ledger", col: "user_id" },
        { table: "economy_wallets", col: "user_id" },
        { table: "feature_waitlist", col: "user_id" },
        { table: "mailbox", col: "user_id" },
        { table: "notification_throttles", col: "user_id" },
        { table: "player_skins", col: "player_id" },
        { table: "profiles", col: "id" },
      ];

      for (const entry of userTables) {
        try {
          await supabaseAdmin.from(entry.table).delete().eq(entry.col, userId);
        } catch (_) {
          // Certaines tables historiques peuvent etre absentes selon l'environnement
        }
      }

      // Supprimer aussi les relations d'amitie dans les deux sens
      try {
        await supabaseAdmin
          .from("friendships")
          .delete()
          .or(`user_id.eq.${userId},friend_id.eq.${userId}`);
      } catch (_) {}

      const { error: authDelError } = await supabaseAdmin.auth.admin.deleteUser(userId);
      if (authDelError) {
        return jsonResponse(
          { error: `Suppression auth impossible : ${authDelError.message}` },
          500,
        );
      }

      return jsonResponse({
        ok: true,
        message: "Ton compte et toutes tes données ont été supprimés définitivement.",
      });
    }

    return jsonResponse({ error: `Action inconnue : ${action}` }, 400);
  } catch (err) {
    return jsonResponse(
      { error: err instanceof Error ? err.message : "Erreur interne shop-tutorial-engine" },
      500,
    );
  }
});
