-- Genre du nageur : 'F' = Femme, 'H' = Homme, NULL = non renseigné
-- Idempotent : fonctionne que la colonne existe déjà ou non, et corrige
-- une éventuelle première contrainte ('F','M').
ALTER TABLE public.ppi_nageurs ADD COLUMN IF NOT EXISTS genre text;
ALTER TABLE public.ppi_nageurs DROP CONSTRAINT IF EXISTS ppi_nageurs_genre_check;
UPDATE public.ppi_nageurs SET genre = 'H' WHERE genre = 'M';
ALTER TABLE public.ppi_nageurs ADD CONSTRAINT ppi_nageurs_genre_check CHECK (genre IS NULL OR genre IN ('F', 'H'));
