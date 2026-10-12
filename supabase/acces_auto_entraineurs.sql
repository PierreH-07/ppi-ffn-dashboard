-- ════════════════════════════════════════════════════════════════════
-- Accès automatique des entraîneurs principaux (Supabase → SQL Editor → coller → Run)
-- À lancer APRÈS securite_rls.sql.
--
-- Un compte connecté sans ligne dans utilisateurs reçoit le rôle 'entraineur' si :
--   • son adresse e-mail a été vérifiée par Supabase (lien de connexion reçu et cliqué) ;
--   • cette adresse figure dans au moins une fiche comme entraîneur principal
--     (entraineur_email OU l'un des entraineurs_principaux, sans casse).
-- Il ne voit ensuite que ses nageurs (règle ppi_select_selon_role, inchangée).
-- Les comptes déjà présents dans utilisateurs (dtn, entraineur_national…) ne sont pas modifiés.
--
-- Réglages Supabase nécessaires (Authentication) :
--   • Sign In / Providers → « Allow new users to sign up » : activé
--   • Sign In / Providers → Email → « Confirm email » : activé
--   • URL Configuration → Redirect URLs : ajouter l'adresse du dashboard
-- ════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.ppi_activer_entraineur() RETURNS text
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_role  text;
  v_email text;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NULL;
  END IF;

  -- Compte déjà configuré : rôle inchangé
  SELECT role INTO v_role FROM public.utilisateurs WHERE id = auth.uid();
  IF FOUND THEN
    RETURN v_role;
  END IF;

  -- Adresse vérifiée uniquement (empêche de créer un compte avec l'adresse d'un autre)
  SELECT lower(trim(u.email)) INTO v_email
  FROM auth.users u
  WHERE u.id = auth.uid() AND u.email_confirmed_at IS NOT NULL;
  IF coalesce(v_email, '') = '' THEN
    RETURN NULL;
  END IF;

  -- Adresse référencée comme entraîneur principal dans au moins une fiche
  IF NOT EXISTS (
    SELECT 1 FROM public.ppi_nageurs f
    WHERE lower(trim(f.entraineur_email)) = v_email
       OR CASE WHEN jsonb_typeof(f.entraineurs_principaux) = 'array' THEN
            EXISTS (
              SELECT 1 FROM jsonb_array_elements(f.entraineurs_principaux) e
              WHERE lower(trim(e ->> 'email')) = v_email
            )
          ELSE false END
  ) THEN
    RETURN NULL;
  END IF;

  INSERT INTO public.utilisateurs (id, email, role)
  VALUES (auth.uid(), v_email, 'entraineur')
  ON CONFLICT DO NOTHING;

  RETURN 'entraineur';
END $$;

REVOKE ALL ON FUNCTION public.ppi_activer_entraineur() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.ppi_activer_entraineur() TO authenticated;

-- ════════════════════════════════════════════════════════════════════
-- Vérification (à lancer après) : comptes créés automatiquement
--   SELECT u.email, u.role FROM utilisateurs u WHERE u.role = 'entraineur' ORDER BY u.email;
-- ════════════════════════════════════════════════════════════════════
