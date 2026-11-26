# Questionnaire V3 : mettre en forme les analyses de la page 2 pour Supabase

La page 2 du questionnaire V3 (« Bilan de la compétition de référence ») affiche, pour chaque athlète, des données d'analyse préparées par la DTN.
Ces données sont rangées dans la table Supabase **`ppi_v3_analyse`**, une ligne par athlète (licence) et par saison.
Le questionnaire pré-rempli (bouton du dashboard) reprend la **saison la plus récente** de l'athlète.

Disciplines concernées pour l'instant : **natation course** et **eau libre**.

---

## 1. La ligne à insérer

| Colonne | Contenu | Exemple |
|---|---|---|
| `licence` | licence de l'athlète, **sans espaces, en majuscules**, identique à celle des fiches et de `ppi_v3_liste` | `1234567` |
| `saison` | saison analysée, format `AAAA-AAAA` | `2025-2026` |
| `discipline` | `natation-bassin` ou `eau-libre` | `natation-bassin` |
| `competition_reference` | compétition de référence, format « Nom — Ville Année » | `Championnats d’Europe — Paris 2026` |
| `donnees` | tout le contenu de la page, en JSON (sections 2 à 5) | |

Requête à copier (SQL Editor) :

```sql
INSERT INTO public.ppi_v3_analyse (licence, saison, discipline, competition_reference, donnees)
VALUES ('LICENCE', '2025-2026', 'natation-bassin', 'Championnats d’Europe — Paris 2026',
$json$
{ … contenu de donnees … }
$json$::jsonb)
ON CONFLICT (licence, saison) DO UPDATE SET donnees = excluded.donnees,
  competition_reference = excluded.competition_reference, discipline = excluded.discipline, maj_le = now();
```

Relancer la requête remplace la ligne : on peut corriger et réinsérer autant de fois que nécessaire.

---

## 2. Structure de `donnees` (commune aux disciplines)

```json
{
  "epreuves": "100 et 50 m papillon",
  "epreuves_liste": ["100m Papillon", "50m Papillon"],
  "saison":    { "comp": "…", "date": "…", "epr": "…", "res": "…" },
  "reference": { "tag": "…", "tagd": "…", "comp": "…", "date": "…", "epr": "…", "res": "…" },
  "sources":   [["Titre de la source", "Détail"]],
  "kpi":       [["Libellé", "Valeur"]],
  "blocs":     [ … ]
}
```

| Champ | Affichage | Règle |
|---|---|---|
| `epreuves` | sous le nom de l'athlète, sur toutes les pages | texte libre |
| `epreuves_liste` | onglets par épreuve des axes d'amélioration (page 3) | **orthographe exacte des listes du questionnaire** (section 6) |
| `saison` | tuile « Compétition de référence de la saison » | `comp` = « Nom — Ville Année » ; `date` ; `epr` (épreuves, tour) ; `res` (résultat en une ligne) |
| `reference` | tuile « comparée à » | `tag` = titre de la tuile (« Référence : top 3 des performers 2025-2026 ») ; `tagd` = précision ; `comp`, `date`, `epr`, `res` |
| `sources` | encadré « Provenance des données » | une ligne par source : [nom, ce qui en est tiré] |
| `kpi` | 3 chiffres clés en page 1 du bilan PDF | 3 lignes recommandées : [libellé, valeur] |
| `blocs` | contenu de la page, dans l'ordre | section 3 |

---

## 3. Les blocs

| Type | Champs | Effet |
|---|---|---|
| `epreuve` | `titre` | ouvre un onglet. Un bloc `epreuve` avant chaque épreuve ; aucun s'il n'y a qu'une épreuve. |
| `tableau` | `titre`, `colonnes`, `lignes`, `athlete`, `hors`, `note` | tableau. `lignes` = liste de lignes, chaque ligne = liste de textes, **dans l'ordre des colonnes**. `athlete` = numéros des lignes de l'athlète (la 1re ligne est 0) : en gras, marquées « (athlète) ». `hors` = lignes « pour information ». `note` = texte sous le tableau. |
| `texte` | `titre`, `texte` | paragraphe ; les retours à la ligne (`\n`) sont conservés |
| `barres` | `titre`, `series`, `groupes`, `note` | petits histogrammes par phase (natation course), écart de l'athlète au meilleur calculé automatiquement — section 4.3 |
| `courbe` | `titre`, `axe`, `series`, `inverse`, `etiquette_axe`, `note` | courbe (positions tour par tour en eau libre) — section 5.2 |
| `html` | `titre` (facultatif), `html` | contenu libre. Réservé aux mises en forme qu'aucun autre bloc ne permet. |

**Règle du tableau « Résultat »** : si le titre contient le mot « Résultat », le tableau est automatiquement coupé en deux groupes : « Compétition de référence de la saison » (lignes `athlete`) puis la référence (les autres lignes). Mettre donc toutes les lignes de l'athlète dans `athlete`.

Conventions d'écriture des valeurs (texte) :
- temps : `49.70`, `1:57:10.15` (point pour les centièmes) ;
- écarts : signe explicite `+0.22`, `−0.23` (signe moins typographique ou `-`) ; « — » pour une case sans objet ;
- unités dans l'en-tête de colonne (`Fréquence (c/min)`), pas dans les cases.

---

## 4. Natation course

**Compétition de l'athlète** : compétition de référence de la saison écoulée (saison 2026 : Championnats d’Europe de Paris).
**Référence** : les **3 meilleurs performers des saisons 2025 et 2026 dans la base Espadon** (meilleur temps de chaque nageur, toutes compétitions, bassin de 50 m). Si l'athlète en fait partie, on garde sa ligne de référence et celles des 2 autres.

`saison` / `reference` (exemple) :
```json
"saison":    { "comp": "Championnats d’Europe — Paris 2026", "date": "11 et 13 août 2026",
               "epr": "100 et 50 m papillon · finales", "res": "100 pap : 2e · 49.70 — 50 pap : 2e · 22.54" },
"reference": { "tag": "Référence : top 3 des performers 2025-2026", "tagd": "meilleur temps de chaque nageur, base Espadon",
               "comp": "Top 3 des performers — saisons 2025-2026", "date": "meilleur temps de chaque nageur",
               "epr": "100 et 50 m papillon · bassin de 50 m", "res": "100 : NOM1 49.48 · NOM2 49.62 · NOM3 49.93" }
```

Pour **chaque épreuve** : un bloc `epreuve`, puis les tableaux ci-dessous. Une ligne par nageur, l'athlète d'abord (avec la mention de sa compétition dans la 1re colonne, ex. `NOM CE 2026 Paris`), puis les 3 performers de référence.

### 4.1 Résultat (toutes distances)
```json
{ "type": "tableau", "titre": "1. Résultat",
  "colonnes": ["Nageur", "Place dans sa course", "Temps", "Écart au 1er performer", "Écart au 3e performer"],
  "lignes": [["NOM CE 2026 Paris", "2", "49.70", "+0.22", "−0.23"],
             ["NOM1 CE 2026 Paris", "1", "49.48", "—", "−0.45"],
             ["NOM2 CM 2025 Singapour", "1", "49.62", "+0.14", "−0.31"],
             ["NOM3 CE 2026 Paris", "3", "49.93", "+0.45", "—"]],
  "athlete": [0],
  "note": "Référence : les 3 meilleurs performers des saisons 2025 et 2026 dans la base Espadon." }
```

### 4.2 Par 50 m (100 m et plus)
Une ligne par nageur **et par 50 m** ; les lignes d'un même nageur se suivent.
```json
{ "type": "tableau", "titre": "2. Par 50 m",
  "colonnes": ["Nageur", "Segment", "Passage", "Temps segment", "Écart cumulé de l’athlète",
               "Fréquence (c/min)", "Coups de bras", "DPC (m/cycle)"],
  "lignes": [["NOM CE 2026 Paris", "0-50 m", "22.97", "22.97", "—", "55.3", "16", "2.16"],
             ["NOM CE 2026 Paris", "50-100 m", "49.70", "26.73", "—", "52.1", "19", "1.95"],
             ["NOM1 CE 2026 Paris", "0-50 m", "…", "…", "+0.15", "…", "…", "…"]],
  "athlete": [0, 1] }
```
« Écart cumulé de l’athlète » : écart de l'athlète au nageur de la ligne, au passage (vide sur les lignes de l'athlète).

### 4.2 bis Course (50 m)
```json
{ "type": "tableau", "titre": "2. Course (0-50 m)",
  "colonnes": ["Nageur", "Temps", "Réaction", "Fréquence (c/min)", "Coups de bras", "DPC (m/cycle)"],
  "lignes": [["NOM CE 2026 Paris", "22.54", "0.60", "61.3", "18", "1.96"]],
  "athlete": [0] }
```

### 4.3 Phases
Règles (décision du 2026-11-19) :
- **50 à 200 m** : détail **longueur par longueur** ; phases : départ (0-15 m, réaction comprise), coulée de départ (m), nage, approche (5 derniers m avant le mur), sortie de virage, coulée de virage (m), arrivée (5 derniers m).
- **400 m et plus** : **moyennes sur l'ensemble des virages** de l'approche, de la sortie de virage et de la coulée.
- **Sortie de virage** = du mur à +15 m pour les 50, 100 et 200 m ; du mur à +5 m pour le 400 m et au-delà.
- Nage = temps de la longueur − départ (ou sortie) − approche (ou arrivée).

Format tableau : **une ligne par phase**, une colonne par nageur, plus l'écart de l'athlète au meilleur des 3.
```json
{ "type": "tableau", "titre": "3. Phases — longueur 1 (0-50 m)",
  "colonnes": ["Phase", "NOM 2026", "NOM1 2026", "NOM2 2025", "NOM3 2026", "Écart de l’athlète au meilleur"],
  "lignes": [["Départ 0-15 m (s)", "5.65", "5.52", "5.60", "5.70", "+0.13"],
             ["Coulée de départ (m)", "13.0", "14.5", "13.8", "12.9", "−1.5"],
             ["Nage 15-45 m (s)", "…", "…", "…", "…", "…"],
             ["Approche 45-50 m (s)", "…", "…", "…", "…", "…"]],
  "note": "Temps en secondes, coulées en mètres. Écart : temps, + = plus lent ; coulée, − = plus courte." }
```
Un tableau par longueur (50 à 200 m), ou un seul tableau « 3. Phases — moyennes sur les virages » (400 m et plus).

**Version graphique (recommandée)** : bloc `barres`, un petit histogramme par phase, comme dans le prototype.
```json
{ "type": "barres", "titre": "3. Phases, longueur par longueur",
  "series": ["NOM 2026 — CE 2026 Paris", "NOM1 2026 — CE 2026 Paris", "NOM2 2025 — CM 2025 Singapour", "NOM3 2026 — CE 2026 Paris"],
  "groupes": [
    { "titre": "Longueur 1 (0-50 m)",
      "phases": [
        { "nom": "Départ 0-15 m",       "unite": "s", "valeurs": [5.32, 5.19, 5.24, 5.25] },
        { "nom": "Coulée de départ",    "unite": "m", "valeurs": [13.0, 14.5, 13.8, 12.9], "plus_haut_meilleur": true },
        { "nom": "Nage 15-45 m",        "unite": "s", "valeurs": [15.10, 15.00, 15.20, 15.30] },
        { "nom": "Approche 45-50 m",    "unite": "s", "valeurs": [2.55, 2.50, 2.60, 2.58] } ] },
    { "titre": "Longueur 2 (50-100 m)", "phases": [ … ] } ],
  "note": "Temps en secondes, coulées en mètres. Valeur à droite du titre = écart de l’athlète au meilleur des 3 performers." }
```
- `series` : **l'athlète en premier**, puis les nageurs de référence ; même ordre dans chaque `valeurs`.
- `valeurs` : des **nombres** (point décimal, sans guillemets) ; `null` si la valeur manque.
- `plus_haut_meilleur: true` pour les coulées (une plus grande valeur est meilleure) ; à omettre pour les temps.
- L'écart affiché à droite de chaque phase est calculé : athlète − meilleur des autres, en rouge s'il est défavorable.
- 400 m et plus : un seul groupe « Moyennes sur les virages » avec les phases approche, sortie de virage, coulée.

---

## 5. Eau libre

**Compétition de l'athlète** : compétition de référence de la saison écoulée.
**Référence** : **podium de la dernière compétition mondiale** (CM ou JO ; pour 2026 : CM 2025 Singapour).
Parcours et conditions différents : les temps ne se comparent pas entre compétitions ; l'indicateur commun est **l'écart en % au vainqueur**.

```json
"saison":    { "comp": "Championnats d’Europe — Paris 2026", "date": "4 août 2026", "epr": "10 km", "res": "21e · 1:57:10.15" },
"reference": { "tag": "Référence : podium CM 2025", "tagd": "Championnats du monde — Singapour 2025",
               "comp": "Championnats du monde — Singapour 2025", "date": "16 juillet 2025", "epr": "10 km",
               "res": "Podium : NOM1 · NOM2 · NOM3" }
```

### 5.1 Résultat
```json
{ "type": "tableau", "titre": "1. Résultat — 10 km",
  "colonnes": ["Nageur", "Compétition", "Place", "Temps", "Écart au vainqueur de sa compétition"],
  "lignes": [["NOM Prénom FRA", "CE 2026 Paris", "21 / 31", "1:57:10.15", "+111.76 s (+1.62 %)"],
             ["NOM1 Prénom GER", "CM 2025 Singapour", "1", "…", "—"]],
  "athlete": [0],
  "note": "Vainqueur à Paris 2026 : 1:55:18.39. Les temps ne se comparent pas entre compétitions." }
```

### 5.2 Tour par tour (athlète, puis chaque nageur du podium)
Source : Omega (passages publiés). Une ligne par tour (ou demi-tour publié).
```json
{ "type": "tableau", "titre": "2. Tour par tour — CE 2026 Paris (athlète)",
  "colonnes": ["Tour", "Position", "Écart au leader", "Fréquence (cycles/min)"],
  "lignes": [["0.5", "1", "—", ""], ["1", "3", "+0.57", "…"], ["7", "non publié", "", ""]],
  "note": "Fréquence = coups de bras par minute publiés par Omega ÷ 2 (1 cycle = 2 coups de bras en crawl)." }
```
Même tableau pour chaque nageur du podium (« 3. Podium CM 2025 — NOM1 », etc.), ou un seul tableau avec une colonne « Nageur ».
Passage non publié : écrire `non publié`. Point aberrant retiré : le signaler dans `note`.

**Version graphique (recommandée)** : bloc `courbe`, une courbe de position par nageur.
```json
{ "type": "courbe", "titre": "2. Position tour par tour — CE 2026 Paris (athlète)",
  "axe": ["0.5", "1", "1.5", "2", "2.5", "3", "3.5", "4", "4.5", "5", "5.5", "6", "6.5", "7", "7.5", "F"],
  "etiquette_axe": "tour",
  "series": [ { "nom": "NOM Prénom — CE 2026 Paris",
                "valeurs": [1, 3, 2, 6, 1, 1, 1, 4, 5, 3, 2, 3, 3, null, 19, 21] } ],
  "note": "Position : 1 en haut. Trait pointillé = passage non publié." }
```
- `axe` : les passages, dans l'ordre ; `series` : un nageur par élément, `valeurs` dans l'ordre de `axe`.
- `null` = passage non publié : la courbe le saute en pointillé.
- Position (1 en haut) par défaut. Pour une autre grandeur (écart au leader en secondes, fréquence…), ajouter `"inverse": false` (valeur haute en haut).
- Podium : un bloc `courbe` avec les 3 nageurs dans `series` (3 couleurs).

### 5.3 Niveau en bassin (50 m)
Meilleur temps de chaque nageur **sur les 24 mois précédant sa course** (jusqu'à la veille incluse), **bassin de 50 m uniquement**. Source : `historique_bassin_el.json` de l'application EL.
```json
{ "type": "tableau", "titre": "4. Niveau en bassin (50 m) — meilleurs temps sur les 24 mois précédant chaque course",
  "colonnes": ["Épreuve", "NOM", "NOM1", "NOM2", "NOM3", "Moyenne podium", "Écart de l’athlète à la moyenne"],
  "lignes": [["400 NL", "3:54.58 (2026-07)", "3:45.29 (2025-04)", "—", "4:02.25 (2024-12)", "3:53.77 (2 nageurs)", "+0.35 %"],
             ["800 NL", "…", "…", "…", "…", "…", "…"],
             ["1500 NL", "…", "…", "…", "…", "…", "…"]],
  "note": "Fenêtre : du 4 août 2024 au 3 août 2026 pour l’athlète ; du 16 juillet 2023 au 15 juillet 2025 pour le podium." }
```
Pas de temps dans la fenêtre : `—`. Moyenne calculée sur les nageurs disponibles, nombre indiqué entre parenthèses.

Les courbes de position du prototype ne sont pas reproduites par un tableau. Pour les garder, il faut un bloc `html` (voir `supabase/exemple_analyse_v3.sql`).

---

## 5 bis. Double projet natation course + eau libre

Une seule ligne dans `ppi_v3_analyse` pour l'athlète, avec `discipline` = l'une des deux (par ex. `natation-bassin`) ; les deux analyses vont dans le même `donnees` :

- `saison` / `reference` : la compétition et la référence de la **première** discipline (section 4 ou 5) ;
- `references_supplementaires` : la compétition et la référence de la **seconde** discipline, affichées dans un 2e bandeau :
  ```json
  "references_supplementaires": [
    { "saison":    { "comp": "Championnats d’Europe — Paris 2026", "date": "4 août 2026", "epr": "10 km", "res": "12e · 1:56:30.00" },
      "reference": { "tag": "Référence : podium CM 2025", "comp": "Championnats du monde — Singapour 2025",
                     "date": "16 juillet 2025", "epr": "10 km", "res": "Podium : NOM1 · NOM2 · NOM3" } } ]
  ```
- `epreuves_liste` : les épreuves des **deux** disciplines (ex. `["800m Libre", "1500m Libre", "10km"]`) ;
- `blocs` : un bloc `epreuve` par épreuve, suivi de ses tableaux et graphiques (section 4 pour les épreuves de bassin, section 5 pour l'eau libre) ;
- `sources`, `kpi` : celles des deux disciplines, dans une même liste.

`references_supplementaires` peut aussi servir hors double projet, pour toute 2e compétition de référence.

## 6. Noms d'épreuves (`epreuves_liste`)

Écrire exactement :
- natation course : `50m Libre`, `100m Libre`, `200m Libre`, `400m Libre`, `800m Libre`, `1500m Libre`, `50m Dos`, `100m Dos`, `200m Dos`, `50m Brasse`, `100m Brasse`, `200m Brasse`, `50m Papillon`, `100m Papillon`, `200m Papillon`, `200m 4 Nages`, `400m 4 Nages` ;
- eau libre : `5km`, `10km`, `25km`, `Knock-out (KO)`, `4x1500m`.

Le `titre` des blocs `epreuve` peut reprendre les mêmes noms.

---

## 7. Avant d'insérer : vérifications

1. Le JSON est valide (une virgule entre deux éléments, pas de virgule après le dernier ; guillemets droits `"` autour des textes). Un validateur en ligne ou l'éditeur Supabase signale l'erreur.
2. Aucune ligne d'un tableau n'a plus ou moins de cases que `colonnes`.
3. Les numéros de `athlete` correspondent bien aux lignes de l'athlète (la 1re ligne est 0).
4. La licence est identique dans `ppi_v3_liste`, `ppi_v3_analyse` et les fiches du dashboard.
5. Le texte ne contient pas `$json$` (délimiteur de la requête). Les apostrophes `’` et `'` ne posent pas de problème à l'intérieur de `$json$ … $json$`.

Contrôle après insertion :
```sql
SELECT licence, saison, competition_reference, jsonb_array_length(donnees->'blocs') AS nb_blocs, maj_le
FROM public.ppi_v3_analyse ORDER BY maj_le DESC;
```

Test : dans le dashboard, ouvrir la fiche de l'athlète → « Questionnaire V3 pré-rempli » → page 2.
