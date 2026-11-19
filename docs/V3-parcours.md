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
| 2 | Bilan de la compétition de référence | Pré-rempli, lecture seule. Athlète comparé au top 3 de la référence mondiale (voir ci-dessous). |
| 3 | Analyse conjointe entraîneur + athlète | Liste de constats : dimension (liste existante), constat, indicateurs (libellé + valeur actuelle, libres). Les dimensions sont priorisées à partir de cette liste. |
| 4 | Saison 2026-27 | Performance à réaliser. 3 actions : levier, constat(s) visé(s) de la page 3, indicateur de réussite (valeur actuelle → cible), mise en œuvre. |
| 5 | Compétitions de la saison | Planning de compétition seul (objectif de résultats / de développement). |
| 6 | Engagement | Charte. |
| 7 | Administratif et staff | Pré-remplis. Structure et entraîneur d'entraînement ; si l'athlète s'entraîne à l'étranger : structure et entraîneur de référence en France. |
| 8 | Révision et résumé | |

## Référence (toutes disciplines)
- Données de l'athlète : compétition de référence de la saison écoulée (saison 2026 : Championnats d'Europe de Paris, résultats microplus).
- Comparaison : top 3 de la dernière compétition mondiale (Championnats du monde ou Jeux olympiques ; pour 2026 : CM 2025 Singapour).
- Si l'athlète est déjà dans ce top 3 : on garde ses valeurs + celles des 2 autres, et la question posée devient « comment y rester ».

## Données de la page 2, par discipline
- Natation course (base Espadon), par épreuve, sans commentaire DTN :
  1. Résultat : place, temps, écart au 1er et au 3e.
  2. Par 50 m : temps de passage, écart cumulé, fréquence, DPC ; athlète et chacun des 3 de la référence.
  3. Phases :
     - 50 à 200 m : détail phase par phase, longueur par longueur (départ, coulées, nage, approche, sortie de virage, arrivée), en petits histogrammes ; écart de l'athlète au meilleur de la référence. Pas de tableau en double.
     - 400 m et plus : moyennes, sur l'ensemble des virages, de l'approche, de la sortie et de la coulée.
     Sortie de virage = mur → +15 m pour les 50, 100 et 200 m ; mur → +5 m pour le 400 m et au-delà.
- Eau libre : place, écart au vainqueur, position et fréquence (cycles/min) à chaque tour (Omega) ; niveau en bassin (400, 800, 1500 NL, 50 m) de l'athlète et du podium mondial, meilleur temps sur les 24 mois précédant la course de chacun (veille de la course incluse), source `historique_bassin_el.json` de l'application EL.
- Natation artistique : notes, coefficient de difficulté (avec le détail si disponible), rang.
- Plongeon : total, notes par plongeon, coefficient de difficulté.
- Water-polo : à définir.

## Supprimé par rapport à V2
Semaine type ; vue calendrier annuel et timeline ; bilan chiffré (jours de compétition, stage, entraînement, coupure) ; ressenti global, points forts / à améliorer, état physique (relèvent désormais de l'analyse) ; « Ce qui me sépare de mes objectifs » ; projection 2027-2032 détaillée et objectifs chiffrés au-delà de l'olympiade ; classement des dimensions pour 2028.

## Impact connu sur le dashboard
Le dashboard lit `calendrier`, `semaine_type_data` et `competitions_calendrier` : il devra accepter des fiches V3 où `calendrier` et `semaine_type_data` sont vides.

## Décisions complémentaires (prototype)
- Ambitions : objectif aux prochains Jeux olympiques (2028) obligatoire ; autres ambitions facultatives (championnats du monde ou JO). Plus de champ « Pourquoi je me lance ».
- Constats : « Ce qui est observé, et pourquoi c'est important pour la performance » ; indicateurs chiffrés, sur échelle de 1 à 5 (évaluation entraîneur) ou descriptifs ; valeur actuelle, niveau requis pour l'objectif, écart ; « Ce qui sépare de l'objectif » ; difficulté de l'écart (à portée / exigeant mais atteignable / hors de portée cette saison), sans contrainte imposée à l'entraîneur.
- Performance visée 2026-27 : Championnats du monde de Budapest 2027, dates de la discipline (World Aquatics) : natation 10-18 juillet, natation artistique 10-17 juillet, plongeon 26 juin-4 juillet, eau libre 3-8 juillet, water-polo 26 juin-9 juillet.
- Natation artistique : comparaison au top 3 de la compétition de référence de la saison (CE 2026 Paris).
- Natation course : comparaison aux 3 meilleurs performers des saisons 2025 et 2026 dans la base Espadon (meilleur temps de chaque nageur, toutes compétitions, bassin de 50 m).
- Épreuves collectives : partie 1 collective (bilan collectif, constats collectifs, en séance avec le collectif) puis partie 2 individuelle (« ma contribution » à chaque constat collectif avec au moins un indicateur individuel, actions individuelles rattachées aux constats collectifs). Référence collective = meilleure équipe de la compétition ; référence individuelle (water-polo) en attente.
- Plusieurs épreuves : liste des épreuves du projet = épreuves de la compétition de référence + épreuves de la performance visée. Chaque constat est rattaché à une ou plusieurs épreuves, ou à toutes (constat global).
- Actions : une action par constat (1 pour 1), avec un statut : prioritaire (rang sur l'ensemble du projet), à mener, déjà traité ailleurs, mise de côté pour l'instant (raison facultative). Rien n'est obligatoire. Bilan PDF regroupé par épreuve, chaque constat une seule fois ; constats écartés listés en une ligne.
- En attente : appliquer à toutes les disciplines la référence « meilleurs performers de la saison » (fait en natation course).
