-- ════════════════════════════════════════════════════════════════════
-- Double projet natation course + eau libre (questionnaire V3)
-- Supabase → SQL Editor → coller → Run. À lancer APRÈS securite_rls.sql, carnet_de_bord.sql,
-- ajout_v3.sql et ajout_v3_preremplissage.sql. Idempotent.
--
--  • ppi_nageurs.discipline_2  : 2e discipline d'un double projet (vide sinon). Les deux disciplines
--                                sont à égalité : discipline + discipline_2.
--  • ppi_v3_liste.discipline_2 : 2e discipline de l'athlète inscrit en V3.
--  • Accès : l'entraîneur national de l'une OU l'autre discipline voit la fiche (toute la fiche,
--    les deux disciplines), ainsi que son carnet de bord. Les autres règles sont inchangées.
-- ════════════════════════════════════════════════════════════════════

BEGIN;

-- 1. Colonnes
ALTER TABLE public.ppi_nageurs  ADD COLUMN IF NOT EXISTS discipline_2 text;
ALTER TABLE public.ppi_v3_liste ADD COLUMN IF NOT EXISTS discipline_2 text;

ALTER TABLE public.ppi_nageurs DROP CONSTRAINT IF EXISTS ppi_nageurs_discipline_2_check;
ALTER TABLE public.ppi_nageurs ADD CONSTRAINT ppi_nageurs_discipline_2_check
  CHECK (discipline_2 IS NULL OR (discipline_2 IN ('natation-bassin','eau-libre','synchro','water-polo','plongeon')
                                  AND discipline_2 IS DISTINCT FROM discipline));

ALTER TABLE public.ppi_v3_liste DROP CONSTRAINT IF EXISTS ppi_v3_liste_discipline_2_check;
ALTER TABLE public.ppi_v3_liste ADD CONSTRAINT ppi_v3_liste_discipline_2_check
  CHECK (discipline_2 IS NULL OR (discipline_2 IN ('natation-bassin','eau-libre','synchro','water-polo','plongeon')
                                  AND discipline_2 IS DISTINCT FROM discipline));

-- 2. Lecture des fiches : règle de securite_rls.sql, avec discipline_2 pour l'entraîneur national
DROP POLICY IF EXISTS ppi_select_selon_role ON public.ppi_nageurs;
CREATE POLICY ppi_select_selon_role ON public.ppi_nageurs
  FOR SELECT TO authenticated
  USING (
    (SELECT public.ppi_role()) = 'dtn'
    OR (
      (SELECT public.ppi_role()) = 'entraineur_national'
      AND (discipline = (SELECT public.ppi_discipline()) OR discipline_2 = (SELECT public.ppi_discipline()))
    )
    OR (
      (SELECT public.ppi_role()) = 'entraineur'
      AND (
        lower(trim(entraineur_email)) = lower(auth.jwt() ->> 'email')
        OR CASE WHEN jsonb_typeof(entraineurs_principaux) = 'array' THEN
             EXISTS (
               SELECT 1 FROM jsonb_array_elements(entraineurs_principaux) e
               WHERE lower(trim(e ->> 'email')) = lower(auth.jwt() ->> 'email')
             )
           ELSE false END
      )
    )
  );

-- 3. Carnet de bord : même règle (fonction de carnet_de_bord.sql, avec discipline_2)
CREATE OR REPLACE FUNCTION public.ppi_peut_lire_fiche(p_fiche_id text) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.ppi_nageurs f
    WHERE f.id::text = p_fiche_id
      AND (
        public.ppi_role() = 'dtn'
        OR (public.ppi_role() = 'entraineur_national'
            AND (f.discipline = public.ppi_discipline() OR f.discipline_2 = public.ppi_discipline()))
        OR (public.ppi_role() = 'entraineur' AND public.ppi_est_entraineur_principal(p_fiche_id))
      )
  )
$$;

COMMIT;

-- ── Contrôle (à lancer après, et à me renvoyer) ───────────────────────
SELECT table_name, column_name FROM information_schema.columns
WHERE table_schema = 'public' AND column_name = 'discipline_2' ORDER BY table_name;

SELECT policyname, qual LIKE '%discipline_2%' AS avec_discipline_2
FROM pg_policies WHERE tablename = 'ppi_nageurs' AND policyname = 'ppi_select_selon_role';
