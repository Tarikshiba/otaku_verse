-- Ajoute la colonne image_url optionnelle a la table questions
ALTER TABLE questions
ADD COLUMN IF NOT EXISTS image_url TEXT;
