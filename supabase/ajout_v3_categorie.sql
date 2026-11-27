-- ════════════════════════════════════════════════════════════════════
-- Questionnaire V3 : catégorie de l'athlète (Supabase → SQL Editor → coller → Run). Idempotent.
-- À lancer APRÈS ajout_v3_preremplissage.sql.
--
--  • ppi_v3_liste.categorie : Elite | Senior | Relève | Espoir | Collectifs nationaux (texte libre).
--  • Relève et Espoir (natation course, eau libre) : ambition libre dans le questionnaire
--    (Championnats d'Europe juniors, Championnats du monde juniors, Championnats du monde, Jeux olympiques, 2027-2032).
--  • Autres catégories, ou catégorie vide : Championnats du monde 2027 et Jeux olympiques 2028 imposés.
-- Le remplissage par athlète (licences) est remis par le chat, hors dépôt (CLAUDE.md, section 0).
-- ════════════════════════════════════════════════════════════════════

ALTER TABLE public.ppi_v3_liste ADD COLUMN IF NOT EXISTS categorie text;

-- Contrôle
SELECT column_name, data_type FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'ppi_v3_liste' AND column_name = 'categorie';
