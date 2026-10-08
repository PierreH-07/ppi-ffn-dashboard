-- ════════════════════════════════════════════════════════════════════
-- Carnet de bord compétitions (Supabase → SQL Editor → coller → Run)
-- À lancer APRÈS securite_rls.sql (utilise ppi_role() et ppi_discipline()). Idempotent.
--
--  ppi_carnets                : un jeton secret par fiche exportée (intégré au carnet HTML)
--  ppi_bilans_competition     : bilan qualitatif libre de l'athlète, 1 par compétition
--                               (un nouvel envoi écrase le précédent)
--  ppi_suivi_entraineur       : champ libre de l'entraîneur, 1 par compétition
--
--  Accès
--    • anon (carnet HTML)     : uniquement la fonction ppi_envoyer_bilan(jeton, …), aucune lecture
--    • lecture des bilans et suivis : comptes qui voient la fiche (mêmes règles que ppi_nageurs)
--    • écriture du suivi      : entraîneur(s) principal(aux) de la fiche uniquement
--    • aucune écriture directe dans les tables : tout passe par les fonctions ci-dessous
--
--  fiche_id = id de la version de ppi_nageurs utilisée ; nageur_key = clé de regroupement
--  des versions calculée par le dashboard (L:licence ou N:nom|prénom|date de naissance).
-- ════════════════════════════════════════════════════════════════════

BEGIN;

-- 1. Tables
CREATE TABLE IF NOT EXISTS public.ppi_carnets (
  jeton      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  fiche_id   text NOT NULL UNIQUE,
  nageur_key text NOT NULL,
  cree_par   text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ppi_bilans_competition (
  nageur_key text NOT NULL,
  comp_key   text NOT NULL,
  fiche_id   text NOT NULL,
  comp_nom   text,
  comp_date  date,
  bilan      text NOT NULL,
  envoye_le  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (nageur_key, comp_key)
);

CREATE TABLE IF NOT EXISTS public.ppi_suivi_entraineur (
  nageur_key text NOT NULL,
  comp_key   text NOT NULL,
  fiche_id   text NOT NULL,
  suivi      text NOT NULL,
  auteur     text,
  modifie_le timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (nageur_key, comp_key)
);

ALTER TABLE public.ppi_carnets            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ppi_bilans_competition ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ppi_suivi_entraineur   ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.ppi_carnets, public.ppi_bilans_competition, public.ppi_suivi_entraineur
  FROM anon, authenticated;
GRANT SELECT ON public.ppi_bilans_competition, public.ppi_suivi_entraineur TO authenticated;

-- 2. Fonctions d'aide (mêmes règles que la policy ppi_select_selon_role)
-- Entraîneur principal : entraineur_email ou l'un des entraineurs_principaux (sans casse)
CREATE OR REPLACE FUNCTION public.ppi_est_entraineur_principal(p_fiche_id text) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT coalesce(auth.jwt() ->> 'email', '') <> '' AND EXISTS (
    SELECT 1 FROM public.ppi_nageurs f
    WHERE f.id::text = p_fiche_id
      AND (
        lower(trim(f.entraineur_email)) = lower(auth.jwt() ->> 'email')
        OR CASE WHEN jsonb_typeof(f.entraineurs_principaux) = 'array' THEN
             EXISTS (
               SELECT 1 FROM jsonb_array_elements(f.entraineurs_principaux) e
               WHERE lower(trim(e ->> 'email')) = lower(auth.jwt() ->> 'email')
             )
           ELSE false END
      )
  )
$$;

CREATE OR REPLACE FUNCTION public.ppi_peut_lire_fiche(p_fiche_id text) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.ppi_nageurs f
    WHERE f.id::text = p_fiche_id
      AND (
        public.ppi_role() = 'dtn'
        OR (public.ppi_role() = 'entraineur_national' AND f.discipline = public.ppi_discipline())
        OR (public.ppi_role() = 'entraineur' AND public.ppi_est_entraineur_principal(p_fiche_id))
      )
  )
$$;

-- 3. Lecture des bilans et suivis : comptes qui voient la fiche concernée
DROP POLICY IF EXISTS bilans_select_selon_fiche ON public.ppi_bilans_competition;
CREATE POLICY bilans_select_selon_fiche ON public.ppi_bilans_competition
  FOR SELECT TO authenticated
  USING (public.ppi_peut_lire_fiche(fiche_id));

DROP POLICY IF EXISTS suivi_select_selon_fiche ON public.ppi_suivi_entraineur;
CREATE POLICY suivi_select_selon_fiche ON public.ppi_suivi_entraineur
  FOR SELECT TO authenticated
  USING (public.ppi_peut_lire_fiche(fiche_id));

-- 4. Jeton du carnet (dashboard) : créé au 1er export d'une fiche, réutilisé ensuite
CREATE OR REPLACE FUNCTION public.ppi_jeton_carnet(p_fiche_id text, p_nageur_key text) RETURNS uuid
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_jeton uuid;
BEGIN
  IF NOT public.ppi_peut_lire_fiche(p_fiche_id) THEN
    RAISE EXCEPTION 'Fiche inaccessible';
  END IF;
  IF coalesce(trim(p_nageur_key), '') = '' OR length(p_nageur_key) > 300 THEN
    RAISE EXCEPTION 'Clé nageur invalide';
  END IF;
  SELECT jeton INTO v_jeton FROM public.ppi_carnets WHERE fiche_id = p_fiche_id;
  IF v_jeton IS NULL THEN
    INSERT INTO public.ppi_carnets (fiche_id, nageur_key, cree_par)
    VALUES (p_fiche_id, p_nageur_key, auth.jwt() ->> 'email')
    RETURNING jeton INTO v_jeton;
  END IF;
  RETURN v_jeton;
END $$;

-- 5. Envoi d'un bilan (carnet HTML, sans connexion) : le jeton désigne le nageur
CREATE OR REPLACE FUNCTION public.ppi_envoyer_bilan(
  p_jeton uuid, p_comp_key text, p_comp_nom text, p_comp_date date, p_bilan text
) RETURNS timestamptz
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = public AS $$
DECLARE c public.ppi_carnets%ROWTYPE; v_date timestamptz := now();
BEGIN
  SELECT * INTO c FROM public.ppi_carnets WHERE jeton = p_jeton;
  IF NOT FOUND THEN RAISE EXCEPTION 'Carnet inconnu'; END IF;
  IF coalesce(trim(p_comp_key), '') = '' OR length(p_comp_key) > 300 THEN
    RAISE EXCEPTION 'Compétition invalide';
  END IF;
  IF coalesce(trim(p_bilan), '') = '' THEN RAISE EXCEPTION 'Bilan vide'; END IF;
  IF length(p_bilan) > 20000 THEN RAISE EXCEPTION 'Bilan trop long (20 000 caractères max)'; END IF;

  INSERT INTO public.ppi_bilans_competition (nageur_key, comp_key, fiche_id, comp_nom, comp_date, bilan, envoye_le)
  VALUES (c.nageur_key, p_comp_key, c.fiche_id, left(p_comp_nom, 300), p_comp_date, p_bilan, v_date)
  ON CONFLICT (nageur_key, comp_key) DO UPDATE
    SET fiche_id = EXCLUDED.fiche_id, comp_nom = EXCLUDED.comp_nom, comp_date = EXCLUDED.comp_date,
        bilan = EXCLUDED.bilan, envoye_le = EXCLUDED.envoye_le;
  RETURN v_date;
END $$;

-- 6. Suivi entraîneur (dashboard) : réservé aux entraîneurs principaux de la fiche
CREATE OR REPLACE FUNCTION public.ppi_enregistrer_suivi(
  p_fiche_id text, p_nageur_key text, p_comp_key text, p_suivi text
) RETURNS timestamptz
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_date timestamptz := now();
BEGIN
  IF NOT public.ppi_est_entraineur_principal(p_fiche_id) THEN
    RAISE EXCEPTION 'Réservé aux entraîneurs principaux du nageur';
  END IF;
  IF coalesce(trim(p_nageur_key), '') = '' OR length(p_nageur_key) > 300
     OR coalesce(trim(p_comp_key), '') = '' OR length(p_comp_key) > 300 THEN
    RAISE EXCEPTION 'Paramètres invalides';
  END IF;
  IF length(p_suivi) > 20000 THEN RAISE EXCEPTION 'Suivi trop long (20 000 caractères max)'; END IF;

  IF coalesce(trim(p_suivi), '') = '' THEN
    DELETE FROM public.ppi_suivi_entraineur WHERE nageur_key = p_nageur_key AND comp_key = p_comp_key;
    RETURN v_date;
  END IF;
  INSERT INTO public.ppi_suivi_entraineur (nageur_key, comp_key, fiche_id, suivi, auteur, modifie_le)
  VALUES (p_nageur_key, p_comp_key, p_fiche_id, p_suivi, auth.jwt() ->> 'email', v_date)
  ON CONFLICT (nageur_key, comp_key) DO UPDATE
    SET fiche_id = EXCLUDED.fiche_id, suivi = EXCLUDED.suivi,
        auteur = EXCLUDED.auteur, modifie_le = EXCLUDED.modifie_le;
  RETURN v_date;
END $$;

REVOKE ALL ON FUNCTION public.ppi_peut_lire_fiche(text), public.ppi_est_entraineur_principal(text),
  public.ppi_jeton_carnet(text, text), public.ppi_envoyer_bilan(uuid, text, text, date, text),
  public.ppi_enregistrer_suivi(text, text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.ppi_peut_lire_fiche(text), public.ppi_est_entraineur_principal(text),
  public.ppi_jeton_carnet(text, text), public.ppi_enregistrer_suivi(text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ppi_envoyer_bilan(uuid, text, text, date, text) TO anon, authenticated;

COMMIT;
