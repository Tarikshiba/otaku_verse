-- ============================================================================
-- OTAKU VERSE — MIGRATION SQL V9.2 FINALE (SOCLE ECONOMIE, MATCHS & FLAGS)
-- A executer dans Supabase > SQL Editor (script idempotent)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. EXTENSION DE LA TABLE PROFILES (COLONNES V9.2 + RETROCOMPATIBILITE)
-- ----------------------------------------------------------------------------
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS level_at_last_match INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS last_match_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS is_vip BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS vip_expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS no_ads_expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS starter_pack_claimed BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS allow_share_pseudo_friends BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS notif_overtake_enabled BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS timezone_offset_minutes INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tutorial_phase_a_done BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS tutorial_phase_b_steps INTEGER[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS tutorial_phase_b_claimed BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS active_title TEXT,
  ADD COLUMN IF NOT EXISTS active_frame TEXT,
  ADD COLUMN IF NOT EXISTS active_ko_effect TEXT,
  ADD COLUMN IF NOT EXISTS pts_division INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS division_id INTEGER NOT NULL DEFAULT 10,
  ADD COLUMN IF NOT EXISTS pts_br INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS ko_wins_season INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS season_matches_played INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS season_correct_answers INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS season_total_answers INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_score_reached_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS abandon_streak INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS cooldown_until TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_profiles_pts_division ON profiles(pts_division DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_xp_totale ON profiles(xp_totale DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_country ON profiles(country);

-- ----------------------------------------------------------------------------
-- 2. COMPTEURS FINANCIERS ISOLES : ECONOMY_WALLETS & ECONOMY_LEDGER (ECO-01)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS economy_wallets (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  oc_balance INTEGER NOT NULL DEFAULT 0 CHECK (oc_balance >= 0),
  vc_bonus INTEGER NOT NULL DEFAULT 0 CHECK (vc_bonus >= 0),
  vc_paid INTEGER NOT NULL DEFAULT 0 CHECK (vc_paid >= 0),
  season_id TEXT NOT NULL DEFAULT 'saison_1',
  season_free_vc_earned INTEGER NOT NULL DEFAULT 0 CHECK (season_free_vc_earned >= 0 AND season_free_vc_earned <= 150),
  daily_double_oc_count INTEGER NOT NULL DEFAULT 0,
  daily_double_oc_date DATE,
  daily_rescue_oc_count INTEGER NOT NULL DEFAULT 0,
  daily_rescue_oc_date DATE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE economy_wallets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own wallet" ON economy_wallets;
CREATE POLICY "Users can read own wallet"
  ON economy_wallets FOR SELECT
  USING (auth.uid() = user_id);
-- Aucune policy INSERT/UPDATE/DELETE client : mutations 100% cote serveur

CREATE TABLE IF NOT EXISTS economy_ledger (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  currency TEXT NOT NULL CHECK (currency IN ('XP', 'OC', 'VC_BONUS', 'VC_PAID', 'PTS_DIVISION', 'PTS_BR', 'PTS_GUILD')),
  delta INTEGER NOT NULL,
  balance_after INTEGER NOT NULL,
  reason TEXT NOT NULL,
  match_id UUID,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ledger_user_created ON economy_ledger(user_id, created_at DESC);

ALTER TABLE economy_ledger ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own ledger" ON economy_ledger;
CREATE POLICY "Users can read own ledger"
  ON economy_ledger FOR SELECT
  USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 3. TABLE MATCHES V9.2 (350 PV / 40 Q / DOUBLE TIMER / ANTI-FORCE-CLOSE)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS matches (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  mode TEXT NOT NULL CHECK (mode IN ('solo', 'division', 'duel_ami', 'coop_2via', 'coop_2v2', 'battle_royale', 'donjon', 'salon_live')),
  difficulty TEXT NOT NULL DEFAULT 'moyen' CHECK (difficulty IN ('facile', 'moyen', 'difficile', 'expert', 'maitre', 'adaptatif')),
  malus_mode TEXT NOT NULL DEFAULT 'normal' CHECK (malus_mode IN ('zen', 'normal', 'malicieux')),
  player1_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  player2_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  is_ai_opponent BOOLEAN NOT NULL DEFAULT true,
  ai_tier TEXT,
  ai_pseudo TEXT,
  status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'finished', 'abandoned')),
  scenario_code INTEGER CHECK (scenario_code BETWEEN 1 AND 7),
  winner_id UUID,
  initial_hp INTEGER NOT NULL DEFAULT 350,
  player1_hp INTEGER NOT NULL DEFAULT 350,
  player2_hp INTEGER NOT NULL DEFAULT 350,
  player1_combo INTEGER NOT NULL DEFAULT 0,
  player2_combo INTEGER NOT NULL DEFAULT 0,
  player1_correct INTEGER NOT NULL DEFAULT 0,
  player1_errors INTEGER NOT NULL DEFAULT 0,
  player1_haya_count INTEGER NOT NULL DEFAULT 0,
  player1_consecutive_timeouts INTEGER NOT NULL DEFAULT 0,
  questions_played INTEGER NOT NULL DEFAULT 0,
  max_questions INTEGER NOT NULL DEFAULT 40,
  adaptive_tier INTEGER NOT NULL DEFAULT 1 CHECK (adaptive_tier BETWEEN 1 AND 5),
  elapsed_play_ms INTEGER NOT NULL DEFAULT 0,
  duration_seconds INTEGER NOT NULL DEFAULT 0,
  ended_by_ko BOOLEAN NOT NULL DEFAULT false,
  is_sudden_death BOOLEAN NOT NULL DEFAULT false,
  entry_fee_oc INTEGER NOT NULL DEFAULT 0,
  xp_insurance_active BOOLEAN NOT NULL DEFAULT false,
  confidence_pot_oc INTEGER NOT NULL DEFAULT 0 CHECK (confidence_pot_oc IN (0, 15, 30)),
  oc_questions_sum NUMERIC(10, 2) NOT NULL DEFAULT 0,
  oc_errors_penalty NUMERIC(10, 2) NOT NULL DEFAULT 0,
  xp_questions_sum INTEGER NOT NULL DEFAULT 0,
  oc_performance_net INTEGER NOT NULL DEFAULT 0,
  double_oc_claimed BOOLEAN NOT NULL DEFAULT false,
  second_chance_used BOOLEAN NOT NULL DEFAULT false,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_activity_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_matches_player1 ON matches(player1_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_matches_status_activity ON matches(status, last_activity_at);

ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own matches" ON matches;
CREATE POLICY "Users can read own matches"
  ON matches FOR SELECT
  USING (auth.uid() = player1_id OR auth.uid() = player2_id);

-- ----------------------------------------------------------------------------
-- 4. PILOTAGE A DISTANCE : APP_FEATURE_FLAGS & FEATURE_WAITLIST (LAUNCH-01)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app_feature_flags (
  flag_key TEXT PRIMARY KEY,
  is_enabled BOOLEAN NOT NULL DEFAULT false,
  mode_config JSONB NOT NULL DEFAULT '{}'::jsonb,
  launch_label TEXT NOT NULL DEFAULT 'Bientot disponible',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE app_feature_flags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read feature flags" ON app_feature_flags;
CREATE POLICY "Authenticated users can read feature flags"
  ON app_feature_flags FOR SELECT
  TO authenticated
  USING (true);

-- Seed Palier 1 (Semaine 1 : seuls Tutoriel, Solo, Division AI_ONLY et Boutique ouverts)
INSERT INTO app_feature_flags (flag_key, is_enabled, mode_config, launch_label)
VALUES
  ('mode_solo', true, '{"initial_hp": 350, "max_questions": 40, "global_timer_sec": 120}'::jsonb, 'Ouvert'),
  ('mode_division', true, '{"division_matchmaking_mode": "AI_ONLY", "initial_hp": 350, "max_questions": 40}'::jsonb, 'Ouvert — Saison 1'),
  ('mode_duel_ami', false, '{"max_rewarded_duels_per_friend_day": 3}'::jsonb, 'Ouverture Semaine 2 !'),
  ('share_card_916', false, '{}'::jsonb, 'Ouverture Semaine 2 !'),
  ('notif_friend_overtake', false, '{"throttle_hours": 24, "max_per_day": 2}'::jsonb, 'Ouverture Semaine 2 !'),
  ('mode_salon_live', false, '{"cost_vc_non_vip": 150, "max_players": 10}'::jsonb, 'Ouverture Semaine 3 !'),
  ('mode_guildes', false, '{"max_members": 4}'::jsonb, 'Ouverture Semaine 5 !'),
  ('mode_coop', false, '{"cost_vc": 0, "team_hp": 525}'::jsonb, 'Ouverture Semaine 5 !'),
  ('mode_donjons', false, '{"cost_vc_non_vip": 100}'::jsonb, 'Ouverture Semaine 5 !'),
  ('mode_battle_royale', false, '{"max_players": 10, "fill_bots_after_seconds": 8}'::jsonb, 'Ouverture Semaine 6 !'),
  ('mode_events_tournois', false, '{}'::jsonb, 'Ouverture Semaine 6 !')
ON CONFLICT (flag_key) DO NOTHING;

CREATE TABLE IF NOT EXISTS feature_waitlist (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  flag_key TEXT NOT NULL REFERENCES app_feature_flags(flag_key) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, flag_key)
);

ALTER TABLE feature_waitlist ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own waitlist" ON feature_waitlist;
CREATE POLICY "Users manage own waitlist"
  ON feature_waitlist FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 5. THROTTLE NOTIFICATIONS, COSMETIQUES & CALENDRIER 21 JOURS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notification_throttles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  actor_friend_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notif_type TEXT NOT NULL DEFAULT 'friend_overtake',
  last_sent_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(recipient_id, actor_friend_id, notif_type)
);

ALTER TABLE notification_throttles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own throttles" ON notification_throttles;
CREATE POLICY "Users read own throttles"
  ON notification_throttles FOR SELECT
  USING (auth.uid() = recipient_id);

CREATE TABLE IF NOT EXISTS player_cosmetics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('skin', 'frame', 'ko_effect', 'emote', 'title')),
  equipped BOOLEAN NOT NULL DEFAULT false,
  acquired_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, item_id)
);

ALTER TABLE player_cosmetics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own cosmetics" ON player_cosmetics;
CREATE POLICY "Users read own cosmetics"
  ON player_cosmetics FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users equip own cosmetics" ON player_cosmetics;
CREATE POLICY "Users equip own cosmetics"
  ON player_cosmetics FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS daily_calendar_claims (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  season_id TEXT NOT NULL DEFAULT 'saison_1',
  cycle_number INTEGER NOT NULL DEFAULT 1,
  day_number INTEGER NOT NULL CHECK (day_number BETWEEN 1 AND 21),
  claimed_date DATE NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE(user_id, season_id, cycle_number, day_number)
);

ALTER TABLE daily_calendar_claims ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own calendar claims" ON daily_calendar_claims;
CREATE POLICY "Users read own calendar claims"
  ON daily_calendar_claims FOR SELECT
  USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 6. FONCTIONS SQL OFFICIELLES V9.2 (SEUILS, RANGS, DIVISIONS, FRAIS, VC)
-- ----------------------------------------------------------------------------

-- Seuil XP cumule exact pour atteindre le niveau p_level (§1.3)
CREATE OR REPLACE FUNCTION get_level_threshold_xp(p_level INTEGER)
RETURNS INTEGER AS $$
DECLARE
  v_lvl INTEGER := 1;
  v_total INTEGER := 0;
BEGIN
  IF p_level <= 1 THEN
    RETURN 0;
  END IF;

  WHILE v_lvl < p_level LOOP
    IF v_lvl <= 5 THEN
      v_total := v_total + (100 * v_lvl);
    ELSIF v_lvl <= 15 THEN
      v_total := v_total + (120 * v_lvl);
    ELSIF v_lvl <= 30 THEN
      v_total := v_total + (130 * v_lvl);
    ELSIF v_lvl <= 50 THEN
      v_total := v_total + (140 * v_lvl);
    ELSIF v_lvl <= 75 THEN
      v_total := v_total + 7000;
    ELSE
      v_total := v_total + 25000;
    END IF;
    v_lvl := v_lvl + 1;
  END LOOP;

  RETURN v_total;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Calcul du niveau exact depuis xp_totale (autorise la retrogradation §1.3)
CREATE OR REPLACE FUNCTION get_level_from_xp(p_xp INTEGER)
RETURNS INTEGER AS $$
DECLARE
  v_lvl INTEGER := 1;
  v_acc INTEGER := 0;
  v_step INTEGER;
BEGIN
  IF p_xp <= 0 THEN
    RETURN 1;
  END IF;

  LOOP
    IF v_lvl <= 5 THEN
      v_step := 100 * v_lvl;
    ELSIF v_lvl <= 15 THEN
      v_step := 120 * v_lvl;
    ELSIF v_lvl <= 30 THEN
      v_step := 130 * v_lvl;
    ELSIF v_lvl <= 50 THEN
      v_step := 140 * v_lvl;
    ELSIF v_lvl <= 75 THEN
      v_step := 7000;
    ELSE
      v_step := 25000;
    END IF;

    EXIT WHEN v_acc + v_step > p_xp;
    v_acc := v_acc + v_step;
    v_lvl := v_lvl + 1;
  END LOOP;

  RETURN v_lvl;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Titre et badge de rang officiel permanent (§1.3)
CREATE OR REPLACE FUNCTION get_rank_title(p_level INTEGER)
RETURNS TEXT AS $$
BEGIN
  IF p_level <= 5 THEN RETURN 'Novice du Verse';
  ELSIF p_level <= 15 THEN RETURN 'Apprenti Otaku';
  ELSIF p_level <= 30 THEN RETURN 'Erudit des Arcs';
  ELSIF p_level <= 50 THEN RETURN 'Maitre de l''Encre';
  ELSIF p_level <= 75 THEN RETURN 'Seigneur du Verse';
  ELSE RETURN 'Legende Eternelle ★' || (p_level - 75)::TEXT;
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Division (10 a 1) selon les seuils V9.2 (§6.1)
CREATE OR REPLACE FUNCTION get_division_from_points(p_pts INTEGER)
RETURNS INTEGER AS $$
BEGIN
  IF p_pts >= 1900 THEN RETURN 1;
  ELSIF p_pts >= 1570 THEN RETURN 2;
  ELSIF p_pts >= 1270 THEN RETURN 3;
  ELSIF p_pts >= 1000 THEN RETURN 4;
  ELSIF p_pts >= 760 THEN RETURN 5;
  ELSIF p_pts >= 550 THEN RETURN 6;
  ELSIF p_pts >= 370 THEN RETURN 7;
  ELSIF p_pts >= 220 THEN RETURN 8;
  ELSIF p_pts >= 100 THEN RETURN 9;
  ELSE RETURN 10;
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Arbitrage officiel des frais d'arene OC (§1.4 / ECO-05)
CREATE OR REPLACE FUNCTION get_arena_entry_fee(p_user_id UUID, p_game_mode TEXT)
RETURNS INTEGER AS $$
DECLARE
  v_level INTEGER;
  v_division INTEGER;
BEGIN
  SELECT niveau, division_id INTO v_level, v_division
  FROM profiles
  WHERE id = p_user_id;

  IF v_level IS NULL OR v_level <= 5 THEN
    RETURN 0;
  END IF;

  -- En Mode Division (des Niv. 6), la Division prevaut exclusivement
  IF p_game_mode = 'division' THEN
    IF v_division >= 9 THEN RETURN 10;
    ELSIF v_division >= 6 THEN RETURN 15;
    ELSIF v_division >= 3 THEN RETURN 30;
    ELSE RETURN 50;
    END IF;
  END IF;

  -- Dans tous les autres modes (des Niv. 6), le Niveau prevaut exclusivement
  IF v_level <= 15 THEN RETURN 15;
  ELSIF v_level <= 30 THEN RETURN 30;
  ELSE RETURN 50;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Initialiser le portefeuille s'il est absent (0 VC offert au depart hors tuto/calendrier)
CREATE OR REPLACE FUNCTION ensure_wallet_exists(p_user_id UUID)
RETURNS void AS $$
BEGIN
  INSERT INTO economy_wallets (user_id, oc_balance, vc_bonus, vc_paid)
  VALUES (p_user_id, 0, 0, 0)
  ON CONFLICT (user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Depense securisee de Verse Coins : debite TOUJOURS vc_bonus en 1er, puis vc_paid (§1.1)
CREATE OR REPLACE FUNCTION spend_verse_coins(
  p_user_id UUID,
  p_cost_vc INTEGER,
  p_reason TEXT,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS JSONB AS $$
DECLARE
  v_bonus INTEGER;
  v_paid INTEGER;
  v_bonus_spent INTEGER;
  v_paid_spent INTEGER;
BEGIN
  IF p_cost_vc <= 0 THEN
    RAISE EXCEPTION 'Le cout en Verse Coins doit etre strictement positif';
  END IF;

  PERFORM ensure_wallet_exists(p_user_id);

  SELECT vc_bonus, vc_paid INTO v_bonus, v_paid
  FROM economy_wallets
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF (v_bonus + v_paid) < p_cost_vc THEN
    RAISE EXCEPTION 'Solde Verse Coins insuffisant (% disponibles pour % requis)', (v_bonus + v_paid), p_cost_vc;
  END IF;

  v_bonus_spent := LEAST(v_bonus, p_cost_vc);
  v_paid_spent := p_cost_vc - v_bonus_spent;

  UPDATE economy_wallets
  SET vc_bonus = vc_bonus - v_bonus_spent,
      vc_paid = vc_paid - v_paid_spent,
      updated_at = now()
  WHERE user_id = p_user_id;

  IF v_bonus_spent > 0 THEN
    INSERT INTO economy_ledger (user_id, currency, delta, balance_after, reason, metadata)
    VALUES (p_user_id, 'VC_BONUS', -v_bonus_spent, v_bonus - v_bonus_spent, p_reason, p_metadata);
  END IF;

  IF v_paid_spent > 0 THEN
    INSERT INTO economy_ledger (user_id, currency, delta, balance_after, reason, metadata)
    VALUES (p_user_id, 'VC_PAID', -v_paid_spent, v_paid - v_paid_spent, p_reason, p_metadata);
  END IF;

  RETURN jsonb_build_object(
    'vc_bonus_spent', v_bonus_spent,
    'vc_paid_spent', v_paid_spent,
    'vc_bonus_after', v_bonus - v_bonus_spent,
    'vc_paid_after', v_paid - v_paid_spent
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Erosion hebdomadaire douce d'XP des le Niveau 16 (§1.2 / ECO-03)
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
  SELECT id, xp_totale, niveau, level_at_last_match, last_match_at, is_vip, vip_expires_at
  INTO v_prof
  FROM profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF v_prof IS NULL OR v_prof.niveau < 16 THEN
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

  -- Plancher absolu : 12 300 XP (Niv 15) et maximum 1 niveau perdu sur toute l'absence
  v_floor_xp := GREATEST(12300, get_level_threshold_xp(GREATEST(1, v_prof.level_at_last_match - 1)));
  v_new_xp := GREATEST(v_floor_xp, v_prof.xp_totale - v_weekly_decay);
  v_delta := v_new_xp - v_prof.xp_totale;

  IF v_delta < 0 THEN
    v_new_level := get_level_from_xp(v_new_xp);
    v_new_rank := get_rank_title(v_new_level);

    UPDATE profiles
    SET xp_totale = v_new_xp,
        niveau = v_new_level,
        rang = v_new_rank
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

-- Soft-Reset de fin de saison (8 semaines) : FLOOR(pts_division * 0.60) (§6.1)
CREATE OR REPLACE FUNCTION apply_season_soft_reset()
RETURNS void AS $$
BEGIN
  UPDATE profiles
  SET pts_division = FLOOR(pts_division * 0.60),
      division_id = get_division_from_points(FLOOR(pts_division * 0.60)::INTEGER),
      ko_wins_season = 0,
      season_matches_played = 0,
      season_correct_answers = 0,
      season_total_answers = 0;

  UPDATE economy_wallets
  SET season_free_vc_earned = 0,
      updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Bandeau dynamique d'affluence et cagnotte de classement (§6.5 / Ticket UI-04)
CREATE OR REPLACE FUNCTION get_leaderboard_pot_info(
  p_mode TEXT DEFAULT 'division',
  p_country TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_qualified INTEGER;
  v_tier INTEGER;
  v_next_threshold INTEGER;
  v_top1_vc INTEGER;
  v_top2_vc INTEGER;
  v_top3_vc INTEGER;
  v_next_top1_vc INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_qualified
  FROM profiles
  WHERE season_matches_played >= 10
    AND (p_country IS NULL OR country = p_country);

  IF v_qualified < 10 THEN
    v_tier := 1; v_top1_vc := 25; v_top2_vc := 15; v_top3_vc := 10; v_next_threshold := 10; v_next_top1_vc := 50;
  ELSIF v_qualified < 20 THEN
    v_tier := 2; v_top1_vc := 50; v_top2_vc := 30; v_top3_vc := 20; v_next_threshold := 20; v_next_top1_vc := 90;
  ELSIF v_qualified < 30 THEN
    v_tier := 3; v_top1_vc := 90; v_top2_vc := 55; v_top3_vc := 35; v_next_threshold := 30; v_next_top1_vc := 140;
  ELSIF v_qualified < 40 THEN
    v_tier := 4; v_top1_vc := 140; v_top2_vc := 85; v_top3_vc := 55; v_next_threshold := 40; v_next_top1_vc := 190;
  ELSIF v_qualified < 50 THEN
    v_tier := 5; v_top1_vc := 190; v_top2_vc := 115; v_top3_vc := 75; v_next_threshold := 50; v_next_top1_vc := 250;
  ELSE
    v_tier := 6; v_top1_vc := 250; v_top2_vc := 150; v_top3_vc := 100; v_next_threshold := NULL; v_next_top1_vc := NULL;
  END IF;

  RETURN jsonb_build_object(
    'mode', p_mode,
    'qualified_players', v_qualified,
    'active_tier', v_tier,
    'top1_vc', v_top1_vc,
    'top2_vc', v_top2_vc,
    'top3_vc', v_top3_vc,
    'next_threshold', v_next_threshold,
    'next_top1_vc', v_next_top1_vc
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
