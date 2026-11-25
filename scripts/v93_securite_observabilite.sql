-- ============================================================================
-- OTAKU VERSE — MIGRATION SQL V9.3 (PROFIL PUBLIC 3D, PHASE B & PHASE C)
-- A executer dans Supabase > SQL Editor (script 100 % idempotent)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. RPC SECURISEE : PROFIL PUBLIC D'UN JOUEUR (3.1 — LECTURE SEULE STRICTEMENT PUBLIQUE)
--    Ne renvoie JAMAIS d'email, de soldes OC/VC ni de preferences privees.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_public_player_profile(p_target_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_prof RECORD;
  v_owned_skins JSONB := '[]'::JSONB;
  v_equipped_frame TEXT := NULL;
BEGIN
  SELECT
    id,
    pseudo,
    COALESCE(niveau, 1) AS niveau,
    COALESCE(rang, get_rank_title(COALESCE(niveau, 1))) AS rang,
    COALESCE(xp_totale, 0) AS xp_totale,
    COALESCE(combats_joues, 0) AS combats_joues,
    COALESCE(combats_gagnes, 0) AS combats_gagnes,
    COALESCE(division_id, 10) AS division_id,
    COALESCE(pts_division, 0) AS pts_division,
    COALESCE(ko_wins_season, 0) AS ko_wins_season,
    country,
    active_title,
    COALESCE(NULLIF(equipped_skin_key, ''), 'skin_kio') AS equipped_skin_key,
    (COALESCE(is_vip, false) AND (vip_expires_at IS NULL OR vip_expires_at > now())) AS is_vip_active
  INTO v_prof
  FROM profiles
  WHERE id = p_target_user_id;

  IF v_prof IS NULL THEN
    RETURN NULL;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'player_cosmetics'
  ) THEN
    SELECT COALESCE(jsonb_agg(DISTINCT item_id), '[]'::JSONB)
    INTO v_owned_skins
    FROM player_cosmetics
    WHERE user_id = p_target_user_id
      AND category = 'skin';

    SELECT item_id
    INTO v_equipped_frame
    FROM player_cosmetics
    WHERE user_id = p_target_user_id
      AND category = 'frame'
      AND equipped = true
    LIMIT 1;
  END IF;

  IF v_equipped_frame IS NULL AND v_prof.is_vip_active THEN
    v_equipped_frame := 'cadre_vip_or_violet';
  END IF;

  RETURN jsonb_build_object(
    'id', v_prof.id,
    'pseudo', COALESCE(v_prof.pseudo, 'Joueur'),
    'niveau', v_prof.niveau,
    'rang', v_prof.rang,
    'xp_totale', v_prof.xp_totale,
    'combats_joues', v_prof.combats_joues,
    'combats_gagnes', v_prof.combats_gagnes,
    'division_id', v_prof.division_id,
    'pts_division', v_prof.pts_division,
    'ko_wins_season', v_prof.ko_wins_season,
    'country', v_prof.country,
    'active_title', v_prof.active_title,
    'equipped_skin_key', v_prof.equipped_skin_key,
    'is_vip', v_prof.is_vip_active,
    'equipped_frame', v_equipped_frame,
    'owned_skins', v_owned_skins
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION get_public_player_profile(UUID) TO authenticated;

-- ----------------------------------------------------------------------------
-- 2. TABLE SIGNALEMENTS D'ERREURS QUESTIONS (PHASE B4 — RLS ACTIVE)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS question_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  question_id TEXT NOT NULL,
  work_slug TEXT NOT NULL DEFAULT 'multi_verse',
  question_text TEXT NOT NULL,
  reason TEXT NOT NULL CHECK (reason IN (
    'mauvaise_reponse',
    'faute_orthographe',
    'hors_sujet',
    'spoiler_incorrect',
    'autre'
  )),
  comment TEXT,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved', 'dismissed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_question_reports_status_created
  ON question_reports(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_question_reports_user
  ON question_reports(user_id, created_at DESC);

ALTER TABLE question_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users insert own question reports" ON question_reports;
CREATE POLICY "Users insert own question reports"
  ON question_reports FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users read own question reports" ON question_reports;
CREATE POLICY "Users read own question reports"
  ON question_reports FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 3. CONTROLE VERSION MINIMALE DANS APP_FEATURE_FLAGS (PHASE B3)
-- ----------------------------------------------------------------------------
INSERT INTO app_feature_flags (flag_key, is_enabled, mode_config, launch_label)
VALUES (
  'app_min_version',
  true,
  jsonb_build_object(
    'min_app_version', '1.0.0',
    'force_update', false,
    'update_message', 'Une nouvelle version d''Otaku Verse est disponible avec des correctifs importants.'
  ),
  'Version minimale requise'
)
ON CONFLICT (flag_key) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 4. VERROUILLAGE ANTI-TRICHE DE LA TABLE PROFILES (PHASE C2)
--    Interdit a tout client authentifie de modifier directement XP, Niveau, Rang,
--    VIP, Division ou Statuts Tutoriel (tout passe par Edge Functions / RPC).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION protect_profiles_sensitive_columns()
RETURNS TRIGGER AS $$
DECLARE
  v_jwt_role TEXT := COALESCE(
    NULLIF(current_setting('request.jwt.claim.role', true), ''),
    NULLIF((NULLIF(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role'), ''),
    ''
  );
BEGIN
  -- Autoriser les fonctions serveur (service_role) et les fonctions SQL SECURITY DEFINER (postgres)
  IF v_jwt_role = 'service_role'
     OR current_user IN ('service_role', 'postgres', 'supabase_admin', 'supabase_auth_admin')
     OR session_user IN ('service_role', 'postgres', 'supabase_admin') THEN
    RETURN NEW;
  END IF;

  IF NEW.xp_totale IS DISTINCT FROM OLD.xp_totale
     OR NEW.niveau IS DISTINCT FROM OLD.niveau
     OR NEW.rang IS DISTINCT FROM OLD.rang
     OR NEW.is_vip IS DISTINCT FROM OLD.is_vip
     OR NEW.vip_expires_at IS DISTINCT FROM OLD.vip_expires_at
     OR NEW.no_ads_expires_at IS DISTINCT FROM OLD.no_ads_expires_at
     OR NEW.starter_pack_claimed IS DISTINCT FROM OLD.starter_pack_claimed
     OR NEW.pts_division IS DISTINCT FROM OLD.pts_division
     OR NEW.division_id IS DISTINCT FROM OLD.division_id
     OR NEW.ko_wins_season IS DISTINCT FROM OLD.ko_wins_season
     OR NEW.season_matches_played IS DISTINCT FROM OLD.season_matches_played
     OR NEW.tutorial_phase_a_done IS DISTINCT FROM OLD.tutorial_phase_a_done
     OR NEW.tutorial_phase_b_claimed IS DISTINCT FROM OLD.tutorial_phase_b_claimed THEN
    RAISE EXCEPTION 'Modification directe des donnees sensibles refusee. Utilise les services serveur.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_protect_profiles_sensitive_columns ON profiles;
CREATE TRIGGER trg_protect_profiles_sensitive_columns
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION protect_profiles_sensitive_columns();
