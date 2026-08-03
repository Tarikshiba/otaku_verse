-- Table mailbox : stocke les recompenses en attente pour chaque joueur
CREATE TABLE IF NOT EXISTS mailbox (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL DEFAULT 'gift',
  titre TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  xp_amount INTEGER NOT NULL DEFAULT 0,
  claimed BOOLEAN NOT NULL DEFAULT false,
  claimed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Index pour les requetes frequentes
CREATE INDEX IF NOT EXISTS idx_mailbox_user_claimed ON mailbox(user_id, claimed);

-- RLS : chaque joueur ne voit que ses propres recompenses
ALTER TABLE mailbox ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own mailbox"
  ON mailbox FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own mailbox (claim)"
  ON mailbox FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert own mailbox"
  ON mailbox FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Fonction RPC pour ajouter de l'XP (appele quand on reclame une recompense)
-- Si la fonction existe deja, on la remplace
CREATE OR REPLACE FUNCTION ajouter_xp(p_user_id UUID, p_xp INTEGER)
RETURNS void AS $$
BEGIN
  UPDATE profiles
  SET xp_totale = xp_totale + p_xp
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
