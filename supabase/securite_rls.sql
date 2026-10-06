-- ════════════════════════════════════════════════════════════════════
-- Sécurité d'accès PPI (Supabase → SQL Editor → coller → Run)
-- Remplace TOUTES les règles (policies) existantes de ppi_nageurs et utilisateurs.
--
--  ppi_nageurs
--    • anon (questionnaire)      : création de fiche uniquement (ni lecture, ni modification)
--    • dtn                       : lecture de toutes les fiches + suppression
--    • entraineur_national       : lecture des fiches de sa discipline
--    • entraineur                : lecture de SES nageurs uniquement
--                                  (entraineur_email OU l'un des entraineurs_principaux, sans casse)
--    • personne                  : modification d'une fiche existante
--  utilisateurs
--    • chaque compte lit uniquement sa propre ligne ; aucune écriture via l'API
--      (les invitations se font dans le SQL Editor, qui n'est pas soumis à ces règles)
-- ════════════════════════════════════════════════════════════════════

BEGIN;

-- 1. Fonctions d'aide : rôle et discipline du compte connecté
CREATE OR REPLACE FUNCTION public.ppi_role() RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT role FROM public.utilisateurs WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.ppi_discipline() RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT discipline FROM public.utilisateurs WHERE id = auth.uid()
$$;

REVOKE ALL ON FUNCTION public.ppi_role(), public.ppi_discipline() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.ppi_role(), public.ppi_discipline() TO authenticated;

-- 2. Suppression de toutes les règles existantes sur les deux tables
DO $$
DECLARE p record;
BEGIN
  FOR p IN SELECT policyname, tablename FROM pg_policies
           WHERE schemaname = 'public' AND tablename IN ('ppi_nageurs', 'utilisateurs')
  LOOP
    EXECUTE format('DROP POLICY %I ON public.%I', p.policyname, p.tablename);
  END LOOP;
END $$;

ALTER TABLE public.ppi_nageurs  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.utilisateurs ENABLE ROW LEVEL SECURITY;

-- 3. Droits de base (deuxième verrou en plus des règles)
REVOKE UPDATE, DELETE, SELECT ON public.ppi_nageurs FROM anon;
REVOKE UPDATE ON public.ppi_nageurs FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.utilisateurs FROM anon, authenticated;
REVOKE SELECT ON public.utilisateurs FROM anon;

-- 4. ppi_nageurs : création par le questionnaire
CREATE POLICY ppi_insert_questionnaire ON public.ppi_nageurs
  FOR INSERT TO anon, authenticated
  WITH CHECK (true);

-- 5. ppi_nageurs : lecture selon le rôle
CREATE POLICY ppi_select_selon_role ON public.ppi_nageurs
  FOR SELECT TO authenticated
  USING (
    (SELECT public.ppi_role()) = 'dtn'
    OR (
      (SELECT public.ppi_role()) = 'entraineur_national'
      AND discipline = (SELECT public.ppi_discipline())
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

-- 6. ppi_nageurs : suppression réservée à la DTN
CREATE POLICY ppi_delete_dtn ON public.ppi_nageurs
  FOR DELETE TO authenticated
  USING ((SELECT public.ppi_role()) = 'dtn');

-- 7. utilisateurs : chacun lit sa propre ligne (nécessaire à la connexion au dashboard)
CREATE POLICY utilisateurs_select_soi ON public.utilisateurs
  FOR SELECT TO authenticated
  USING (id = auth.uid());

COMMIT;

-- ════════════════════════════════════════════════════════════════════
-- Vérification (à lancer après) :
--   SELECT tablename, policyname, cmd, roles, qual, with_check
--   FROM pg_policies WHERE tablename IN ('ppi_nageurs','utilisateurs');
-- ════════════════════════════════════════════════════════════════════
