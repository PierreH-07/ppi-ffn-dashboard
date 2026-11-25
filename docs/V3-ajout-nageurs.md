# Questionnaire V3 : ajouter un nageur

Procédure pour qu'un athlète reçoive le questionnaire PPI V3 pré-rempli.
Disciplines ouvertes pour l'instant : **natation course** (`natation-bassin`) et **eau libre** (`eau-libre`).

Tout se fait dans Supabase → **SQL Editor** (coller → Run), puis dans le dashboard.

---

## Étape 0 — Prérequis (une seule fois, déjà fait le 2026-11-25)

Scripts passés : `supabase/ajout_v3.sql` et `supabase/ajout_v3_preremplissage.sql`
(tables `ppi_v3_liste`, `ppi_v3_analyse`, colonnes V3 de `ppi_nageurs`).

---

## Étape 1 — Vérifier la licence de l'athlète

La licence doit être **identique partout** : dans les fiches du dashboard, dans `ppi_v3_liste` et dans `ppi_v3_analyse`.
Format : sans espaces, en majuscules.

Retrouver la licence telle qu'elle est enregistrée dans ses fiches :

```sql
SELECT DISTINCT upper(replace(licence, ' ', '')) AS licence, nom, prenom, discipline
FROM public.ppi_nageurs
WHERE nom ILIKE 'NOM%'
ORDER BY nom, prenom;
```

- Aucune ligne : l'athlète n'a encore aucune fiche. Le bouton n'apparaîtra pas tant qu'il n'en a pas une (le bouton est sur la fiche du dashboard).
- Licence commençant par `SANS_LICENCE_` : la fiche n'a pas de licence ; la compléter d'abord (sinon pas de bouton).

---

## Étape 2 — Ajouter l'athlète à la liste V3

```sql
INSERT INTO public.ppi_v3_liste (licence, nom, prenom, discipline) VALUES
  ('LICENCE', 'NOM', 'Prénom', 'natation-bassin')
ON CONFLICT (licence) DO UPDATE
  SET actif = true, nom = excluded.nom, prenom = excluded.prenom, discipline = excluded.discipline;
```

Plusieurs athlètes d'un coup : une ligne par athlète entre `VALUES` et `ON CONFLICT`, séparées par des virgules.
`discipline` : `natation-bassin` ou `eau-libre`.

---

## Étape 3 — Déposer les données d'analyse (page 2)

Mettre en forme les analyses de la compétition de référence selon **`docs/V3-donnees-page2.md`**, puis :

```sql
INSERT INTO public.ppi_v3_analyse (licence, saison, discipline, competition_reference, donnees)
VALUES ('LICENCE', '2025-2026', 'natation-bassin', 'Championnats d’Europe — Paris 2026',
$json$
{ … }
$json$::jsonb)
ON CONFLICT (licence, saison) DO UPDATE SET donnees = excluded.donnees,
  competition_reference = excluded.competition_reference, discipline = excluded.discipline, maj_le = now();
```

Étape facultative : sans données d'analyse, le questionnaire est quand même généré (le dashboard prévient), et la page 2 affiche « données d'analyse à venir ».

---

## Étape 4 — Contrôler

```sql
SELECT l.licence, l.nom, l.prenom, l.discipline, l.actif,
       (SELECT count(*) FROM public.ppi_nageurs n
         WHERE upper(replace(n.licence, ' ', '')) = l.licence)            AS fiches,
       (SELECT max(a.saison) FROM public.ppi_v3_analyse a WHERE a.licence = l.licence) AS saison_analyse
FROM public.ppi_v3_liste l
ORDER BY l.discipline, l.nom;
```

Pour chaque athlète : `actif` = true, `fiches` ≥ 1, `saison_analyse` renseignée (ou vide si la page 2 n'est pas encore prête).

---

## Étape 5 — Générer le questionnaire

1. Dashboard → recharger la page (la liste V3 est lue à la connexion).
2. Ouvrir la fiche de l'athlète → bouton bleu **« 📄 Questionnaire V3 pré-rempli »**.
3. Le fichier `PPI-V3-NOM-Prénom.html` est téléchargé. Il contient :
   - l'administratif de la dernière fiche (licence, identité, contacts, club, structure, entraîneur, staff) ;
   - la page 2 (données d'analyse de la saison la plus récente) ;
   - le rappel du PPI précédent : objectifs de résultats et plan d'action de la dernière fiche, à évaluer (atteint / partiellement / non atteint).
4. Ouvrir le fichier pour vérifier, puis le transmettre pour l'entretien.

Le fichier ne garde pas les saisies si on recharge la page : le remplir pendant l'entretien et l'envoyer avec « Envoyer la fiche à la FFN » (page « Bilan PDF »). Chaque envoi crée une nouvelle version, visible dans le dashboard avec le badge « PPI V3 ».

---

## Retirer un athlète de la liste

Sans rien supprimer (le bouton disparaît, les fiches et les analyses restent) :

```sql
UPDATE public.ppi_v3_liste SET actif = false WHERE licence = 'LICENCE';
```

## Mettre à jour les données d'analyse

Relancer la requête de l'étape 3 avec la même licence et la même saison : la ligne est remplacée.
Nouvelle saison : même requête avec la nouvelle saison (`2026-2027`) ; le questionnaire reprend automatiquement la plus récente.

## Le bouton n'apparaît pas

| Cause | Vérification |
|---|---|
| Licence différente entre la fiche et la liste | étape 1 et étape 4 (`fiches` = 0) |
| Athlète inactif dans la liste | étape 4 (`actif`) |
| Discipline autre que natation course ou eau libre | étape 4 (`discipline`) |
| Dashboard pas rechargé après l'ajout | recharger la page (Cmd+Maj+R) |
| Compte sans droit de lecture sur la liste | la DTN voit tout ; un autre compte ne voit que les athlètes dont il voit une fiche |
