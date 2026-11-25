-- ════════════════════════════════════════════════════════════════════
-- Questionnaire PPI V3 : colonnes supplémentaires de ppi_nageurs
-- Supabase → SQL Editor → coller → Run. Idempotent (peut être relancé sans risque).
--
-- Principe
--   • Même table, une ligne par envoi (rien n'est écrasé), comme V2 et B.
--   • Les fiches existantes ne sont pas modifiées : version_questionnaire reste vide
--     (= questionnaire V2 ou B). Les fiches V3 portent version_questionnaire = 'V3',
--     ce qui permet au dashboard d'afficher les deux mises en forme.
--   • Données communes à V2 : colonnes existantes réutilisées
--       identité, licence, club, discipline, genre, entraineur_*, structure_nom,
--       entraineurs_principaux, staff_data
--       bq_satisfaction (satisfaction globale 1-10, page 2)
--       objectifs_pluriannuels (ambitions, page 1)
--       objectifs_saison + competitions_calendrier (calendrier, page 5)
--       engagement_* / nom_*_signe / date_* (charte, page 6)
--   • Nouveaux contenus V3 : colonnes ci-dessous.
-- ════════════════════════════════════════════════════════════════════

BEGIN;

ALTER TABLE public.ppi_nageurs
  ADD COLUMN IF NOT EXISTS version_questionnaire text,
  ADD COLUMN IF NOT EXISTS competition_reference text,
  ADD COLUMN IF NOT EXISTS performance_visee     jsonb,
  ADD COLUMN IF NOT EXISTS axes_amelioration     jsonb,
  ADD COLUMN IF NOT EXISTS entrainement_etranger boolean,
  ADD COLUMN IF NOT EXISTS structure_france      text,
  ADD COLUMN IF NOT EXISTS entraineur_france     text,
  ADD COLUMN IF NOT EXISTS staff_complementaire  text;

ALTER TABLE public.ppi_nageurs DROP CONSTRAINT IF EXISTS ppi_nageurs_version_check;
ALTER TABLE public.ppi_nageurs ADD CONSTRAINT ppi_nageurs_version_check
  CHECK (version_questionnaire IS NULL OR version_questionnaire IN ('V3'));

COMMENT ON COLUMN public.ppi_nageurs.version_questionnaire IS
  'Vide = questionnaire V2 ou B ; ''V3'' = questionnaire V3 (Élite).';
COMMENT ON COLUMN public.ppi_nageurs.competition_reference IS
  'Compétition de référence de la saison écoulée, analysée en page 2 (ex. « Championnats d’Europe — Paris 2026 »).';
COMMENT ON COLUMN public.ppi_nageurs.performance_visee IS
  '{competition, debut, fin, epreuves:[{epreuve, perf, classement}]} — performance visée de la saison (CM Budapest 2027).';
COMMENT ON COLUMN public.ppi_nageurs.axes_amelioration IS
  '[{id, type ''ind''|''coll'', epreuves:[…] (''*'' = toutes), observation, dimension,
     indicateurs:[{libelle, type ''num''|''ech''|''desc'', unite, actuel, requis}] (num : nombre avec point décimal, unité à part),
     progression_attendue, difficulte ''portee''|''optimal''|''hors'', priorite,
     contribution, indicateurs_individuels:[…] (collectif : rôle de l’athlète),
     action:{statut ''prio''|''mener''|''traite''|''cote'', rang, quoi, organisation, athlete,
             entraineur, federation, autres, manque, periode, dimension, indicateur,
             type_indicateur, unite, valeur_actuelle, cible, date_verification, ou_traite, raison_pas_prioritaire}}]';
COMMENT ON COLUMN public.ppi_nageurs.entrainement_etranger IS 'Vrai si l’athlète s’entraîne à l’étranger.';
COMMENT ON COLUMN public.ppi_nageurs.structure_france     IS 'Structure de référence en France (athlète à l’étranger).';
COMMENT ON COLUMN public.ppi_nageurs.entraineur_france    IS 'Entraîneur de référence en France (athlète à l’étranger).';
COMMENT ON COLUMN public.ppi_nageurs.staff_complementaire IS 'Staff complémentaire (texte libre, V3).';

COMMIT;

-- ── Contrôle (à lancer après, et à me renvoyer) ───────────────────────
-- 1. Les 8 colonnes existent :
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'ppi_nageurs'
  AND column_name IN ('version_questionnaire','competition_reference','performance_visee','axes_amelioration',
                      'entrainement_etranger','structure_france','entraineur_france','staff_complementaire')
ORDER BY column_name;

-- 2. Les anciennes fiches sont intactes (toutes sans version) :
SELECT count(*) AS fiches, count(version_questionnaire) AS fiches_v3 FROM public.ppi_nageurs;
