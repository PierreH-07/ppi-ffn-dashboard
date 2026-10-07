-- Détail complet des objectifs, pour le questionnaire pré-rempli :
--   obj_competitions  : objectifs compétitions de la saison
--                       [{ nom, priorite, debut, fin, commentaire, epreuves:[{epreuve, perf}] }]
--   proj_competitions : objectifs pluriannuels
--                       [{ saison, competition, epreuves:[{epreuve, classement, perf}], isJO }]
ALTER TABLE public.ppi_nageurs ADD COLUMN IF NOT EXISTS obj_competitions  jsonb;
ALTER TABLE public.ppi_nageurs ADD COLUMN IF NOT EXISTS proj_competitions jsonb;
