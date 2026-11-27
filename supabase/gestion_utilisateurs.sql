-- ════════════════════════════════════════════════════════════════════
-- Gestion des utilisateurs du dashboard PPI (Supabase → SQL Editor)
-- Chaque cas est autonome : copier UNIQUEMENT le bloc voulu, remplacer les valeurs entre < >, puis Run.
-- Prérequis : securite_rls.sql, acces_auto_entraineurs.sql (et ajout_v3_double_projet.sql pour le cas 3 bis).
--
-- Rôles (table public.utilisateurs : id = compte Supabase, email, role, discipline)
--   dtn                  : toutes les fiches, suppression de fiches, liste et analyses V3
--   entraineur_national  : fiches de SA discipline (discipline OU discipline_2 en double projet)
--   entraineur           : fiches dont il est entraîneur principal (entraineur_email ou entraineurs_principaux)
--   (aucune ligne)       : accès refusé, sauf activation automatique d'un entraîneur principal
--
-- Codes discipline (contrainte en base) : natation-bassin | eau-libre | synchro | water-polo | plongeon
--
-- Le compte de connexion (auth.users) ne se crée pas en SQL. Deux façons :
--   a) Supabase → Authentication → Users → « Invite user » → e-mail (la personne choisit son mot de passe) ;
--   b) la personne clique « Première connexion… » sur le dashboard avec son e-mail ; le compte est créé
--      mais refusé tant qu'il n'a pas de rôle (sauf entraîneur principal, activé automatiquement).
-- Ensuite seulement, passer le bloc du rôle ci-dessous ; la personne se reconnecte.
-- ════════════════════════════════════════════════════════════════════


-- ─── 1. Lister les comptes et leur rôle ─────────────────────────────
-- (comptes sans rôle = connectés au moins une fois, ou invités, mais refusés)
SELECT a.email, u.role, u.discipline,
       a.created_at::date AS cree_le, a.last_sign_in_at::date AS derniere_connexion,
       a.email_confirmed_at IS NOT NULL AS email_verifie
FROM auth.users a
LEFT JOIN public.utilisateurs u ON u.id = a.id
ORDER BY u.role NULLS FIRST, a.email;


-- ─── 2. Ajouter (ou passer) un compte DTN ───────────────────────────
WITH c AS (SELECT id, lower(trim(email)) AS email FROM auth.users WHERE lower(trim(email)) = lower(trim('<adresse@ffnatation.fr>')))
, maj AS (UPDATE public.utilisateurs u SET role = 'dtn', discipline = NULL, email = c.email FROM c WHERE u.id = c.id RETURNING u.id)
INSERT INTO public.utilisateurs (id, email, role, discipline)
SELECT c.id, c.email, 'dtn', NULL FROM c WHERE NOT EXISTS (SELECT 1 FROM maj);
-- 0 ligne insérée ET aucun compte modifié : l'adresse n'a pas de compte (voir en-tête, étape a ou b).


-- ─── 3. Ajouter (ou passer) un entraîneur national ──────────────────
WITH c AS (SELECT id, lower(trim(email)) AS email FROM auth.users WHERE lower(trim(email)) = lower(trim('<adresse@ffnatation.fr>')))
, maj AS (UPDATE public.utilisateurs u SET role = 'entraineur_national', discipline = '<natation-bassin>', email = c.email
          FROM c WHERE u.id = c.id RETURNING u.id)
INSERT INTO public.utilisateurs (id, email, role, discipline)
SELECT c.id, c.email, 'entraineur_national', '<natation-bassin>' FROM c WHERE NOT EXISTS (SELECT 1 FROM maj);
-- Remplacer les DEUX '<natation-bassin>' par le même code discipline.

-- 3 bis. Double projet natation course + eau libre : rien à faire.
-- L'entraîneur national eau libre voit les fiches dont discipline OU discipline_2 = 'eau-libre' (idem natation course).
-- Un même compte ne peut avoir qu'UNE discipline ; pour suivre deux disciplines entières, utiliser le rôle dtn.


-- ─── 4. Ajouter un entraîneur de club à la main ─────────────────────
-- Normalement inutile : un entraîneur dont l'e-mail figure comme entraîneur principal dans une fiche
-- est activé automatiquement à sa première connexion. À utiliser si l'activation automatique échoue.
-- Il ne verra que les fiches où son e-mail est entraîneur principal.
WITH c AS (SELECT id, lower(trim(email)) AS email FROM auth.users WHERE lower(trim(email)) = lower(trim('<adresse@club.fr>')))
, maj AS (UPDATE public.utilisateurs u SET role = 'entraineur', discipline = NULL, email = c.email FROM c WHERE u.id = c.id RETURNING u.id)
INSERT INTO public.utilisateurs (id, email, role, discipline)
SELECT c.id, c.email, 'entraineur', NULL FROM c WHERE NOT EXISTS (SELECT 1 FROM maj);


-- ─── 5. Changer la discipline d'un entraîneur national ──────────────
UPDATE public.utilisateurs SET discipline = '<eau-libre>'
WHERE lower(email) = lower(trim('<adresse@ffnatation.fr>')) AND role = 'entraineur_national';


-- ─── 6. Retirer l'accès au dashboard ────────────────────────────────
-- 6 a. DTN ou entraîneur national : supprimer le rôle (le compte de connexion reste, mais est refusé).
DELETE FROM public.utilisateurs WHERE lower(email) = lower(trim('<adresse@ffnatation.fr>'));

-- 6 b. Entraîneur de club ENCORE inscrit comme entraîneur principal dans une fiche :
--      supprimer son rôle ne suffit pas (il serait réactivé à sa connexion suivante).
--      Le passer en rôle 'bloque' : il se connecte mais ne voit aucune fiche.
UPDATE public.utilisateurs SET role = 'bloque', discipline = NULL WHERE lower(email) = lower(trim('<adresse@club.fr>'));
--      (Si la base refuse 'bloque' à cause d'une contrainte sur role, me renvoyer le message d'erreur.)

-- 6 c. Supprimer aussi le compte de connexion : Supabase → Authentication → Users → … → Delete user
--      (supprime d'abord sa ligne utilisateurs avec 6 a si la base le demande).


-- ─── 7. Contrôles ───────────────────────────────────────────────────
-- Entraîneurs nationaux sans discipline (ne voient rien) ou avec un code inconnu :
SELECT email, role, discipline FROM public.utilisateurs
WHERE role = 'entraineur_national'
  AND (discipline IS NULL OR discipline NOT IN ('natation-bassin','eau-libre','synchro','water-polo','plongeon'));

-- Rôles inconnus :
SELECT email, role FROM public.utilisateurs WHERE role NOT IN ('dtn','entraineur_national','entraineur','bloque');

-- Lignes utilisateurs dont le compte de connexion n'existe plus :
SELECT u.email, u.role FROM public.utilisateurs u LEFT JOIN auth.users a ON a.id = u.id WHERE a.id IS NULL;

-- Ce que voit un entraîneur national (nombre de fiches, double projet compris) :
SELECT u.email, u.discipline,
       (SELECT count(DISTINCT upper(replace(n.licence, ' ', ''))) FROM public.ppi_nageurs n
         WHERE n.discipline = u.discipline OR n.discipline_2 = u.discipline) AS nageurs_visibles
FROM public.utilisateurs u WHERE u.role = 'entraineur_national' ORDER BY u.discipline, u.email;
