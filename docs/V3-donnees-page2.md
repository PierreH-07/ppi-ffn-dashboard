# Questionnaire V3 — données de la page 2 (table `ppi_v3_analyse`)

Une ligne par athlète (licence) et par saison. Le questionnaire pré-rempli reprend la saison la plus récente.
La colonne `donnees` (JSON) décrit tout ce qu'affiche la page 2 « Bilan de la compétition de référence ».

## Structure de `donnees`

```json
{
  "epreuves": "100 et 50 m papillon",
  "epreuves_liste": ["100m Papillon", "50m Papillon"],
  "saison":    { "comp": "Championnats d’Europe — Paris 2026", "date": "11 et 13 août 2026",
                 "epr": "100 et 50 m papillon · finales", "res": "100 pap : 2e · 49.70" },
  "reference": { "tag": "Référence : top 3 des performers 2025-2026", "tagd": "meilleur temps de chaque nageur, base Espadon",
                 "comp": "Top 3 des performers — saisons 2025-2026", "date": "meilleur temps de chaque nageur",
                 "epr": "100 et 50 m papillon · bassin de 50 m", "res": "100 : NOM1 49.48 · NOM2 49.62 · NOM3 49.93" },
  "sources":   [["Espadon (analyse vidéo FFN)", "Base BASE_FFN : analyses des saisons 2025 et 2026"]],
  "kpi":       [["100 pap · Paris 2026", "2e · 49.70"], ["100 pap · écart 1er / 3e", "+0.22 / −0.23 s"]],
  "blocs": [
    { "type": "epreuve", "titre": "100m Papillon" },
    { "type": "tableau", "titre": "1. Résultat",
      "colonnes": ["Nageur", "Place", "Temps", "Écart au 1er", "Écart au 3e"],
      "lignes":   [["NOM ATHLÈTE", "2", "49.70", "+0.22", "−0.23"],
                   ["NOM1", "1", "49.48", "—", "−0.45"]],
      "athlete":  [0],
      "note":     "Référence : les 3 meilleurs performers des saisons 2025 et 2026." },
    { "type": "texte", "titre": "Commentaire", "texte": "Texte libre, retours à la ligne conservés." },
    { "type": "html",  "titre": "3. Phases", "html": "<p>HTML libre (graphiques, tableaux mis en forme…)</p>" },
    { "type": "epreuve", "titre": "50m Papillon" }
  ]
}
```

## Champs
| Champ | Rôle |
|---|---|
| `epreuves` | texte affiché sous le nom de l'athlète |
| `epreuves_liste` | épreuves de la compétition de référence, **écrites comme dans les listes du questionnaire** (`100m Papillon`, `10km`…) : elles servent aux onglets par épreuve des axes d'amélioration. Si absent : titres des blocs `epreuve`. |
| `saison` | tuile « Compétition de référence de la saison ». `comp` au format « Nom — Ville Année » (sert à la question de satisfaction). Facultatif : `q` = fin de la question (« au tournoi de référence de 2026 »). |
| `reference` | tuile « comparée à » : `tag` (titre), `tagd` (précision), `comp`, `date`, `epr`, `res` |
| `sources` | encadré « Provenance des données » : liste de [titre, détail] |
| `kpi` | chiffres clés repris en page 1 du bilan PDF : liste de [libellé, valeur] |
| `blocs` | contenu de la page, dans l'ordre |

## Blocs
- `epreuve` : ouvre un onglet (une épreuve). Sans bloc `epreuve`, pas d'onglets.
- `tableau` : `colonnes`, `lignes` (texte de chaque case), `athlete` (numéros des lignes de l'athlète, à partir de 0 : mises en gras et marquées « (athlète) »), `hors` (lignes « hors référence »), `note`.
  Un tableau dont le titre contient « Résultat » est automatiquement séparé en « Compétition de référence de la saison » (lignes de l'athlète) et « Référence » (les autres lignes).
- `texte` : paragraphe libre.
- `html` : HTML libre. Avec `titre` : dans un cadre ; sans `titre` : inséré tel quel (permet de reprendre la mise en forme des pages du prototype).

Exemple complet prêt à insérer : `supabase/exemple_analyse_v3.sql`.
