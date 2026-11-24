-- ============================================================================
-- OTAKU VERSE — MIGRATION SQL V9.2 CORRECTIFS TERRAIN (RETOURS HEAT 24/11/2026)
-- A executer dans Supabase > SQL Editor (script 100 % idempotent)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. COLONNES COMPLEMENTAIRES SUR PROFILES, ECONOMY_WALLETS & CALENDRIER
-- ----------------------------------------------------------------------------
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS last_erosion_applied_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS equipped_skin_key TEXT NOT NULL DEFAULT 'skin_kio',
  ADD COLUMN IF NOT EXISTS vip_free_recovery_week TEXT;

ALTER TABLE economy_wallets
  ADD COLUMN IF NOT EXISTS daily_home_ad_oc_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS daily_home_ad_oc_date DATE,
  ADD COLUMN IF NOT EXISTS aura_charges INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS bonus_challenges_date DATE;

ALTER TABLE daily_calendar_claims
  ADD COLUMN IF NOT EXISTS is_recovery BOOLEAN NOT NULL DEFAULT false;

-- Synchroniser equipped_skin_key depuis player_skins pour les comptes existants
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'player_skins'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'skins'
  ) THEN
    UPDATE profiles p
    SET equipped_skin_key = s.image_key
    FROM player_skins ps
    JOIN skins s ON s.id = ps.skin_id
    WHERE ps.player_id = p.id
      AND ps.equipped = true
      AND s.image_key IS NOT NULL
      AND s.image_key <> '';
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 2. TABLE CARNET D'ERREURS REVISABLE POUR VERSE ANALYTICS (RLS ACTIVE)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS player_question_errors (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  match_id UUID REFERENCES matches(id) ON DELETE SET NULL,
  question_id TEXT NOT NULL,
  work_slug TEXT NOT NULL DEFAULT 'multi_verse',
  arc_name TEXT,
  difficulty_level INTEGER NOT NULL DEFAULT 2,
  question_text TEXT NOT NULL,
  chosen_answer TEXT,
  correct_answer TEXT NOT NULL,
  explanation TEXT,
  reviewed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_player_errors_user_created
  ON player_question_errors(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_player_errors_work
  ON player_question_errors(user_id, work_slug);

ALTER TABLE player_question_errors ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own question errors" ON player_question_errors;
CREATE POLICY "Users read own question errors"
  ON player_question_errors FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users mark own question errors reviewed" ON player_question_errors;
CREATE POLICY "Users mark own question errors reviewed"
  ON player_question_errors FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 3. TITRES OFFICIELS AVEC ACCENTS FRANCAIS EXACTS (TEST 6 & §1.3)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_rank_title(p_level INTEGER)
RETURNS TEXT AS $$
BEGIN
  IF p_level <= 5 THEN RETURN 'Novice du Verse';
  ELSIF p_level <= 15 THEN RETURN 'Apprenti Otaku';
  ELSIF p_level <= 30 THEN RETURN 'Érudit des Arcs';
  ELSIF p_level <= 50 THEN RETURN 'Maître de l''Encre';
  ELSIF p_level <= 75 THEN RETURN 'Seigneur du Verse';
  ELSE RETURN 'Légende Éternelle ★' || (p_level - 75)::TEXT;
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Corriger les anciens rangs sans accents ou V1 dans profiles
UPDATE profiles
SET niveau = get_level_from_xp(COALESCE(xp_totale, 0)),
    rang = get_rank_title(get_level_from_xp(COALESCE(xp_totale, 0)))
WHERE rang IS NULL
   OR rang IN ('Debutant', 'Passionne', 'Expert', 'Maitre du Verse', 'Legende', 'Erudit des Arcs', 'Maitre de l''Encre')
   OR rang LIKE 'Legende Eternelle%';

UPDATE profiles
SET active_title = 'Initié du Verse'
WHERE active_title = 'Initie du Verse';

UPDATE profiles
SET active_title = 'Architecte Suprême du Verse'
WHERE active_title = 'Architecte Supreme du Verse';

-- ----------------------------------------------------------------------------
-- 4. EROSION HEBDOMADAIRE D'XP NIV. 16+ ANTI-DOUBLE-DEBIT (TEST 32, CALCUL #9)
--    Regle : 0 perte quotidienne, 1 match/7j = 0 perte, sinon -20/-30/-40 XP/sem
--    Plancher : GREATEST(12300, seuil(level_at_last_match - 1))
--    Franchise VIP : 14 jours (2 semaines)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION apply_weekly_xp_erosion(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_prof RECORD;
  v_days_inactive INTEGER;
  v_franchise_days INTEGER;
  v_weeks_overdue INTEGER;
  v_weekly_decay INTEGER := 0;
  v_floor_xp INTEGER;
  v_new_xp INTEGER;
  v_new_level INTEGER;
  v_new_rank TEXT;
  v_delta INTEGER;
BEGIN
  SELECT id, xp_totale, niveau, level_at_last_match, last_match_at, last_erosion_applied_at, is_vip, vip_expires_at
  INTO v_prof
  FROM profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF v_prof IS NULL OR COALESCE(v_prof.niveau, 1) < 16 THEN
    RETURN 0;
  END IF;

  -- Ne jamais appliquer l'erosion plus d'une fois tous les 7 jours
  IF v_prof.last_erosion_applied_at IS NOT NULL
     AND v_prof.last_erosion_applied_at > (now() - INTERVAL '7 days') THEN
    RETURN 0;
  END IF;

  v_franchise_days := CASE
    WHEN v_prof.is_vip AND (v_prof.vip_expires_at IS NULL OR v_prof.vip_expires_at > now()) THEN 14
    ELSE 7
  END;

  v_days_inactive := FLOOR(EXTRACT(EPOCH FROM (now() - v_prof.last_match_at)) / 86400);
  IF v_days_inactive < v_franchise_days THEN
    RETURN 0;
  END IF;

  v_weeks_overdue := FLOOR((v_days_inactive - v_franchise_days) / 7) + 1;
  IF v_weeks_overdue = 1 THEN
    v_weekly_decay := 20;
  ELSIF v_weeks_overdue = 2 THEN
    v_weekly_decay := 30;
  ELSE
    v_weekly_decay := 40;
  END IF;

  -- Plancher absolu : 12 300 XP (Niv. 15) et maximum -1 niveau sur toute l'absence
  v_floor_xp := GREATEST(12300, get_level_threshold_xp(GREATEST(1, COALESCE(v_prof.level_at_last_match, v_prof.niveau) - 1)));
  v_new_xp := GREATEST(v_floor_xp, v_prof.xp_totale - v_weekly_decay);
  v_delta := v_new_xp - v_prof.xp_totale;

  IF v_delta < 0 THEN
    v_new_level := get_level_from_xp(v_new_xp);
    v_new_rank := get_rank_title(v_new_level);

    UPDATE profiles
    SET xp_totale = v_new_xp,
        niveau = v_new_level,
        rang = v_new_rank,
        last_erosion_applied_at = now()
    WHERE id = p_user_id;

    INSERT INTO economy_ledger (user_id, currency, delta, balance_after, reason, metadata)
    VALUES (
      p_user_id,
      'XP',
      v_delta,
      v_new_xp,
      'weekly_erosion',
      jsonb_build_object('weeks_overdue', v_weeks_overdue, 'days_inactive', v_days_inactive)
    );
  END IF;

  RETURN v_delta;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Batch hebdomadaire appelable par pg_cron (ex: chaque lundi 03h00 UTC)
-- SELECT cron.schedule('weekly-xp-erosion', '0 3 * * 1', $$SELECT apply_weekly_xp_erosion_all();$$);
CREATE OR REPLACE FUNCTION apply_weekly_xp_erosion_all()
RETURNS INTEGER AS $$
DECLARE
  v_user RECORD;
  v_affected INTEGER := 0;
  v_res INTEGER;
BEGIN
  FOR v_user IN
    SELECT id FROM profiles
    WHERE niveau >= 16
      AND last_match_at < (now() - INTERVAL '7 days')
  LOOP
    v_res := apply_weekly_xp_erosion(v_user.id);
    IF v_res < 0 THEN
      v_affected := v_affected + 1;
    END IF;
  END LOOP;
  RETURN v_affected;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- 5. NETTOYAGE FEATURE FLAGS (5 PALIERS OFFICIELS + COHERENCE LABELS)
-- ----------------------------------------------------------------------------
UPDATE app_feature_flags
SET launch_label = 'Ouvert · Saison 1'
WHERE flag_key = 'mode_division' AND is_enabled = true;

-- ----------------------------------------------------------------------------
-- 6. MIGRATION COMPLETE VERS LES 10 CLES ORIGINALES SANS COPYRIGHT (Kio..Cassio Vey)
-- ----------------------------------------------------------------------------
ALTER TABLE profiles ALTER COLUMN equipped_skin_key SET DEFAULT 'skin_kio';

UPDATE profiles SET equipped_skin_key = CASE equipped_skin_key
  WHEN 'skin_default' THEN 'skin_kio'
  WHEN 'skin_ninja' THEN 'skin_mazu'
  WHEN 'skin_pirate' THEN 'skin_tavik'
  WHEN 'skin_samourai' THEN 'skin_ruve'
  WHEN 'skin_ermite' THEN 'skin_hesk'
  WHEN 'skin_titan' THEN 'skin_ilka'
  WHEN 'skin_demon' THEN 'skin_vael'
  WHEN 'skin_hokage' THEN 'skin_dakore'
  WHEN 'skin_dragon' THEN 'skin_ysae'
  WHEN 'skin_roi' THEN 'skin_cassio_vey'
  ELSE equipped_skin_key
END;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'player_cosmetics'
  ) THEN
    UPDATE player_cosmetics SET item_id = CASE item_id
      WHEN 'skin_default' THEN 'skin_kio'
      WHEN 'starter_tuto_ninja' THEN 'skin_mazu'
      WHEN 'skin_ninja' THEN 'skin_mazu'
      WHEN 'skin_pirate' THEN 'skin_tavik'
      WHEN 'skin_samourai' THEN 'skin_ruve'
      WHEN 'skin_ermite' THEN 'skin_hesk'
      WHEN 'skin_titan' THEN 'skin_ilka'
      WHEN 'skin_demon' THEN 'skin_vael'
      WHEN 'skin_hokage' THEN 'skin_dakore'
      WHEN 'skin_dragon' THEN 'skin_ysae'
      WHEN 'skin_roi' THEN 'skin_cassio_vey'
      ELSE item_id
    END
    WHERE category = 'skin';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'skins'
  ) THEN
    UPDATE skins SET name = 'Kio', image_key = 'skin_kio' WHERE image_key IN ('skin_default', 'skin_kio');
    UPDATE skins SET name = 'Mazú', image_key = 'skin_mazu' WHERE image_key IN ('skin_ninja', 'skin_mazu');
    UPDATE skins SET name = 'Tavik', image_key = 'skin_tavik' WHERE image_key IN ('skin_pirate', 'skin_tavik');
    UPDATE skins SET name = 'Ruvé', image_key = 'skin_ruve' WHERE image_key IN ('skin_samourai', 'skin_ruve');
    UPDATE skins SET name = 'Hesk', image_key = 'skin_hesk' WHERE image_key IN ('skin_ermite', 'skin_hesk');
    UPDATE skins SET name = 'Ilka', image_key = 'skin_ilka' WHERE image_key IN ('skin_titan', 'skin_ilka');
    UPDATE skins SET name = 'Vael', image_key = 'skin_vael' WHERE image_key IN ('skin_demon', 'skin_vael');
    UPDATE skins SET name = 'Dakoré', image_key = 'skin_dakore' WHERE image_key IN ('skin_hokage', 'skin_dakore');
    UPDATE skins SET name = 'Ysaé', image_key = 'skin_ysae' WHERE image_key IN ('skin_dragon', 'skin_ysae');
    UPDATE skins SET name = 'Cassio Vey', image_key = 'skin_cassio_vey' WHERE image_key IN ('skin_roi', 'skin_cassio_vey');
  END IF;
END $$;
