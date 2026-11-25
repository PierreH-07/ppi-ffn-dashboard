-- ════════════════════════════════════════════════════════════════════
-- Questionnaire V3 pré-rempli depuis le dashboard
-- Supabase → SQL Editor → coller → Run. À lancer APRÈS securite_rls.sql et ajout_v3.sql. Idempotent.
--
--  ppi_v3_liste    : athlètes qui reçoivent le questionnaire V3 (bouton « Questionnaire V3 pré-rempli »
--                    sur leur fiche du dashboard). Une ligne par licence. actif = false pour retirer sans supprimer.
--  ppi_v3_analyse  : données de la page 2 (bilan de la compétition de référence), une ligne par licence et par saison.
--                    Le questionnaire reprend la saison la plus récente.
--  ppi_nageurs.bilan_plan_precedent : ce qui a été réalisé du PPI précédent (rappel en page 2).
--
--  Accès : lecture par les comptes connectés qui voient au moins une fiche de cette licence
--          (mêmes règles que ppi_nageurs), et par la DTN pour toutes les lignes.
--          Aucune écriture par l'API : la DTN remplit ces tables dans le SQL Editor.
-- ════════════════════════════════════════════════════════════════════

BEGIN;

-- 1. Tables
CREATE TABLE IF NOT EXISTS public.ppi_v3_liste (
  licence     text PRIMARY KEY,
  nom         text,
  prenom      text,
  discipline  text NOT NULL CHECK (discipline IN ('natation-bassin','eau-libre','synchro','water-polo','plongeon')),
  actif       boolean NOT NULL DEFAULT true,
  commentaire text,
  ajoute_le   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ppi_v3_analyse (
  licence               text NOT NULL,
  saison                text NOT NULL,              -- ex. '2025-2026'
  discipline            text,
  competition_reference text,                       -- ex. 'Championnats d’Europe — Paris 2026'
  donnees               jsonb NOT NULL,             -- format : voir docs/V3-donnees-page2.md
  maj_le                timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (licence, saison)
);

ALTER TABLE public.ppi_nageurs ADD COLUMN IF NOT EXISTS bilan_plan_precedent jsonb;
COMMENT ON COLUMN public.ppi_nageurs.bilan_plan_precedent IS
  '{date_fiche, version, items:[{type ''objectif''|''action'', libelle, cible, realise ''atteint''|''partiel''|''non''|'''', commentaire}]}';

-- 2. Droits : lecture seule pour les comptes connectés, rien pour anon
ALTER TABLE public.ppi_v3_liste   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ppi_v3_analyse ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ppi_v3_liste, public.ppi_v3_analyse FROM anon, authenticated;
GRANT SELECT ON public.ppi_v3_liste, public.ppi_v3_analyse TO authenticated;

DROP POLICY IF EXISTS ppi_v3_liste_lecture   ON public.ppi_v3_liste;
DROP POLICY IF EXISTS ppi_v3_analyse_lecture ON public.ppi_v3_analyse;

-- Le sous-select sur ppi_nageurs applique les règles de lecture de ppi_nageurs du compte connecté
CREATE POLICY ppi_v3_liste_lecture ON public.ppi_v3_liste FOR SELECT TO authenticated
  USING ((SELECT public.ppi_role()) = 'dtn'
         OR EXISTS (SELECT 1 FROM public.ppi_nageurs n
                    WHERE upper(replace(n.licence, ' ', '')) = upper(replace(ppi_v3_liste.licence, ' ', ''))));

CREATE POLICY ppi_v3_analyse_lecture ON public.ppi_v3_analyse FOR SELECT TO authenticated
  USING ((SELECT public.ppi_role()) = 'dtn'
         OR EXISTS (SELECT 1 FROM public.ppi_nageurs n
                    WHERE upper(replace(n.licence, ' ', '')) = upper(replace(ppi_v3_analyse.licence, ' ', ''))));

COMMIT;

-- ── Contrôle (à lancer après, et à me renvoyer) ───────────────────────
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_name IN ('ppi_v3_liste', 'ppi_v3_analyse');
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'ppi_nageurs' AND column_name = 'bilan_plan_precedent';

-- ════════════════════════════════════════════════════════════════════
-- Modèles d'utilisation (à adapter, ne pas lancer tels quels)
--
-- Ajouter ou réactiver un athlète dans la liste :
--   INSERT INTO public.ppi_v3_liste (licence, nom, prenom, discipline)
--   VALUES ('LICENCE', 'NOM', 'Prénom', 'natation-bassin')
--   ON CONFLICT (licence) DO UPDATE SET actif = true, nom = excluded.nom, prenom = excluded.prenom,
--                                       discipline = excluded.discipline;
--
-- Retirer un athlète de la liste (sans rien supprimer) :
--   UPDATE public.ppi_v3_liste SET actif = false WHERE licence = 'LICENCE';
--
-- Déposer ou remplacer les données de la page 2 d'un athlète pour une saison :
--   INSERT INTO public.ppi_v3_analyse (licence, saison, discipline, competition_reference, donnees)
--   VALUES ('LICENCE', '2025-2026', 'natation-bassin', 'Championnats d’Europe — Paris 2026',
--           $json$ { … voir docs/V3-donnees-page2.md … } $json$::jsonb)
--   ON CONFLICT (licence, saison) DO UPDATE SET donnees = excluded.donnees,
--     competition_reference = excluded.competition_reference, discipline = excluded.discipline, maj_le = now();
-- ════════════════════════════════════════════════════════════════════
