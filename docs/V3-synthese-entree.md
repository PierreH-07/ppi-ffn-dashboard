# Questionnaire V3 : fichier de synthèse à remettre à Claude pour le SQL

Un seul fichier par discipline et par saison, produit par les outils d'extraction (Espadon, scraper MicroPlus / Omega / SwimRankings), complété par Pierre, puis transmis à Claude.
Claude le convertit au format de `docs/V3-donnees-page2.md` et rend les requêtes de `docs/V3-ajout-nageurs.md` (étapes 2 et 3).

- Nom du fichier : `synthese_NC_2025-2026.xlsx` ou `synthese_EL_2025-2026.xlsx` (un CSV par feuille est accepté, séparateur `;`, UTF-8).
- Une feuille par tableau ci-dessous, **noms de feuilles et de colonnes exacts**, dans cet ordre.
- Valeur manquante : case vide. Passage non publié (eau libre) : `non publié`. Rien d'estimé ni d'interpolé.
- Temps : point pour les centièmes (`49.70`, `1:57:10.15`). Dates : `AAAA-MM-JJ`.
- Épreuves : orthographe exacte de `docs/V3-donnees-page2.md`, section 6 (`100m Papillon`, `10km`…).
- Compétition abrégée : sigle, année, ville (`CE 2026 Paris`, `CEJ 2026 Munich`, `CEJ 2026 Sukoró`, `CM 2025 Singapour`, `FRA Élite 2026 <ville>`).

Colonnes communes à toutes les feuilles de données (`id`) :

| Colonne | Contenu |
|---|---|
| `licence` | licence de l'athlète. Lignes de référence : licence de l'athlète auquel elles se rattachent, ou vide si elles valent pour tous les athlètes de l'épreuve et du sexe |
| `type_ligne` | `athlete` ou `reference` |
| `rang_reference` | 1, 2 ou 3 (lignes `reference`), vide sinon |
| `nageur` | `NOM Prénom` (référence étrangère : `NOM Prénom NAT`) |
| `sexe` | `F` ou `H` |
| `epreuve` | nom de l'épreuve |
| `competition` | compétition abrégée de la course |

---

## Feuille `nageurs` (commune)

| licence | nom | prenom | sexe | discipline | competition_reference | dates | statut | remarque |
|---|---|---|---|---|---|---|---|---|

- `discipline` : `natation-bassin` ou `eau-libre`.
- `competition_reference` : format long « Championnats d’Europe — Paris 2026 ».
- `dates` : dates des courses de l'athlète à cette compétition, en toutes lettres (« 11 et 13 août 2026 »).
- `statut` : `trouvé`, `introuvable`, `doublon`, `ambigu`.
- `licence` : à compléter par Pierre si l'outil ne la fournit pas (sans espaces, en majuscules).

## Feuille `sources` (commune)

| source | ce_qui_en_est_tire | date_extraction |
|---|---|---|

## Feuille `kpi` (commune, facultative)

| licence | libelle | valeur |
|---|---|---|

Feuille ignorée pour l'instant : les chiffres clés sont calculés par `supabase/gen_analyse_v3.py` (règle validée par Pierre le 2026-11-26) :
- natation course : les 3 premières épreuves de l'athlète, « place · temps (écart au 1er / au 3e performer) » ;
- eau libre : place et temps à la compétition de référence (10 km en priorité), écart au vainqueur, écart du 3e du podium CM au vainqueur si l'athlète nage cette épreuve ;
- double projet : les deux listes réunies (eau libre puis natation course).

---

## Natation course

### `resultats`
`id` + `date` · `tour` (`série`, `demi-finale`, `finale A`…) · `place` · `temps` · `reaction`

### `par50`
`id` + `segment` (`0-50 m`, `50-100 m`…) · `passage` · `temps_segment` · `frequence_c_min` · `coups_bras` · `dpc_m_cycle`

### `phases`
`id` + `longueur` (`1`, `2`… ; `moyenne virages` pour 400 m et plus) · `phase` · `valeur` · `unite` (`s` ou `m`)

Libellés de `phase`, exacts : `Départ 0-15 m`, `Coulée de départ`, `Nage`, `Approche`, `Sortie de virage`, `Coulée de virage`, `Arrivée`.
Règles : départ réaction comprise ; sortie de virage = mur → +15 m (50 à 200 m), mur → +5 m (400 m et plus) ; approche et arrivée = 5 derniers m.

Référence : 3 meilleurs performers des saisons 2025 et 2026 dans Espadon (meilleur temps de chaque nageur, toutes compétitions, bassin de 50 m), données de la course de ce meilleur temps. Si l'athlète en fait partie, il reste en `athlete` et les 2 autres en `reference`.

---

## Eau libre

### `resultats`
`id` + `date` · `place` · `nb_classes` · `temps` · `temps_vainqueur` · `ecart_vainqueur_s` · `ecart_vainqueur_pct`

### `tours`
`id` + `passage` (`0.5`, `1`… `F`) · `position` · `temps_passage` · `ecart_leader_s` · `coups_bras_min`

### `bassin`
`id` + `epreuve_bassin` (`400 NL`, `800 NL`, `1500 NL`) · `temps` · `date` · `competition_bassin` · `fenetre_debut` · `fenetre_fin`

Pour `bassin`, la colonne `epreuve` de `id` reste l'épreuve d'eau libre de référence (`10km`…).
Référence : podium du 10 km des derniers championnats du monde (saison 2025-2026 : CM 2025 Singapour), hommes pour les athlètes H, dames pour les athlètes F.

---

## Contrôles avant envoi

1. Chaque `licence` des feuilles de données existe dans `nageurs`.
2. Chaque athlète `trouvé` a au moins une ligne dans `resultats`.
3. Pas de ligne en double (même `licence`, `nageur`, `epreuve`, `competition`, segment / phase / passage).

---

## Double projet natation course + eau libre

L'athlète figure dans les deux synthèses (même licence). Générer avec `--double=LICENCE,LICENCE` :
eau libre en 1re discipline, natation course en `references_supplementaires` (`docs/V3-donnees-page2.md`, section 5 bis).
