# Questionnaire PPI V3 — parcours validé

Version à côté : `PPI-FFN-V3.html`, construit à partir de `PPI-ffnV2.html`. Les fichiers existants (`PPI-ffnV2.html`, `PPI-FFN-B.html`, `index.html`) ne sont pas modifiés.

## Périmètre
- Athlètes **Élite** uniquement, 5 disciplines, une centaine d'athlètes.
- Un fichier pré-rempli par athlète, généré en amont par la DTN (même principe que les fiches de natation artistique d'octobre 2026).
- Démarrage par la natation course ; water-polo traité plus tard.
- Base : réutiliser les colonnes existantes de `ppi_nageurs` quand la donnée est commune ; nouvelles colonnes seulement pour les nouveaux contenus.

## Parcours

| # | Page | Contenu |
|---|---|---|
| 0 | Bandeau | Identité et discipline pré-remplies. |
| 1 | Ambitions | Lignes libres : horizon (choisi par l'athlète), compétition, résultat visé. Champ « pourquoi je me lance ». Aucun moyen ni plan d'action. |
| 2 | Performances brutes | Pré-rempli, lecture seule. Athlète comparé au top 3 de la référence mondiale (voir ci-dessous). |
| 3 | Analyse conjointe entraîneur + athlète | Liste de constats : dimension (liste existante), constat, indicateurs (libellé + valeur actuelle, libres). Les dimensions sont priorisées à partir de cette liste. |
| 4 | Saison 2026-27 | Performance à réaliser. 3 actions : levier, constat(s) visé(s) de la page 3, indicateur de réussite (valeur actuelle → cible), mise en œuvre. |
| 5 | Compétitions de la saison | Planning de compétition seul (objectif de résultats / de développement). |
| 6 | Engagement | Charte. |
| 7 | Administratif et staff | Pré-remplis. Structure et entraîneur d'entraînement ; si l'athlète s'entraîne à l'étranger : structure et entraîneur de référence en France. |
| 8 | Révision et résumé | |

## Référence (toutes disciplines)
- Top 3 de la dernière compétition mondiale de référence : Championnats du monde ou Jeux olympiques, à N-1 si besoin.
- Si l'athlète est déjà dans ce top 3 : on garde ses valeurs + celles des 2 autres, et la question posée devient « comment y rester ».

## Données de la page 2, par discipline
- Natation course (base Espadon), par épreuve, sans commentaire DTN :
  1. Résultat : place, temps, écart au 1er et au 3e.
  2. Par 50 m : temps de passage, écart cumulé, fréquence, DPC ; athlète et chacun des 3 de la référence.
  3. Phases : départ 0-15 m, approches (5 m avant le mur), sorties de virage, coulées (m), arrivée 5 m ; athlète, meilleur des 3, écart.
     Sortie de virage = mur → +15 m pour les 50, 100 et 200 m ; mur → +5 m pour le 400 m et au-delà.
  Course de l'athlète = sa meilleure course de la saison écoulée ; référence = top 3 de la dernière compétition mondiale.
  4. 50, 100 et 200 m uniquement : visualisation des phases longueur par longueur.
- Eau libre : place, écart au vainqueur, écart à chaque tour, niveau de performance en bassin (profils de performance EL 2026).
- Natation artistique : notes, coefficient de difficulté (avec le détail si disponible), rang.
- Plongeon : total, notes par plongeon, coefficient de difficulté.
- Water-polo : à définir.

## Supprimé par rapport à V2
Semaine type ; vue calendrier annuel et timeline ; bilan chiffré (jours de compétition, stage, entraînement, coupure) ; ressenti global, points forts / à améliorer, état physique (relèvent désormais de l'analyse) ; « Ce qui me sépare de mes objectifs » ; projection 2027-2032 détaillée et objectifs chiffrés au-delà de l'olympiade ; classement des dimensions pour 2028.

## Impact connu sur le dashboard
Le dashboard lit `calendrier`, `semaine_type_data` et `competitions_calendrier` : il devra accepter des fiches V3 où `calendrier` et `semaine_type_data` sont vides.
