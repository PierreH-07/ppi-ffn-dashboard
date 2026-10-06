-- Genre du nageur (questionnaire page 1) : 'F' = Femme, 'M' = Homme, NULL = non renseigné
ALTER TABLE public.ppi_nageurs ADD COLUMN IF NOT EXISTS genre text;
ALTER TABLE public.ppi_nageurs DROP CONSTRAINT IF EXISTS ppi_nageurs_genre_check;
ALTER TABLE public.ppi_nageurs ADD CONSTRAINT ppi_nageurs_genre_check CHECK (genre IS NULL OR genre IN ('F', 'M'));
