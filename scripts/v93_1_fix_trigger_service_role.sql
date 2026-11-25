-- ============================================================================
-- OTAKU VERSE : CORRECTIF V9.3.1 DU TRIGGER ANTI-TRICHE SUR PROFILES
-- Autorise explicitement le role PostgreSQL 'service_role' (Edge Functions)
-- tout en gardant le verrouillage strict contre tout client authenticated/anon.
-- Script 100 % idempotent a executer dans Supabase > SQL Editor.
-- ============================================================================

CREATE OR REPLACE FUNCTION protect_profiles_sensitive_columns()
RETURNS TRIGGER AS $$
DECLARE
  v_jwt_role TEXT := COALESCE(
    NULLIF(current_setting('request.jwt.claim.role', true), ''),
    NULLIF((NULLIF(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role'), ''),
    ''
  );
BEGIN
  -- Autoriser les Edge Functions (service_role) et les RPC SECURITY DEFINER (postgres)
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
