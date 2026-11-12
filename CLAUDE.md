# PPI — Projet de Performance Individuel (FFN)

Mémoire consolidée le 2026-11-11 à partir des anciennes sessions Claude Code. Détail session par session : `docs/historique-claude.md`.

## 1. Objectif

Outiller le Projet de Performance Individuel (PPI) des sportifs de la FFN, pour 5 disciplines (natation course, eau libre, natation artistique, water-polo, plongeon) :
- un **questionnaire HTML autonome** (un seul fichier), rempli par le nageur et son entraîneur, qui envoie une fiche dans Supabase (table `ppi_nageurs`) et produit un résumé imprimable ;
- un **dashboard PPI** réservé à la DTN, qui lit cette table (connexion par compte Supabase) et affiche les fiches et leurs versions ;
- des pages **« Aide à la décision »** (radar par dimension à partir des compétences du DLTA), en version Relève et Élite ;
- un prototype de **questionnaire pour jeunes nageurs** (outil nageur + fichier entraîneur) qui prépare le dialogue avant le questionnaire.

## 2. Dépôts GitHub liés

- Ce dossier n'est **pas un dépôt git**.
- Dashboard en ligne : dépôt GitHub Pages prévu sous le nom `ppi-ffn-dashboard` (fichier `index.html`), d'après `instructions_supabase_dashboard.md`. URL, compte, branche et dossier local inconnus : le code n'est pas sur ce Mac, il est travaillé dans un autre chat. `[À VÉRIFIER]`
- `dashboard.html` (ici) est une copie locale ancienne (2026-05-11), sans les évolutions faites en ligne.

## 3. Structure et fichiers clés

Questionnaires (HTML autonomes, environ 9 400 lignes chacun)
- `PPI-FFNV2.html` — version A la plus à jour (sans budget). Contient les corrections d'octobre 2026, le genre, les colonnes `objectifs_*`.
- `PPI-FFN-B_1.html` — version B, avec la page Budget ; envoie aussi à Supabase depuis le 2026-10-06.
- `PPI-FFN.html` — version A antérieure (ex-`questionnaire-nageur-ffnV2.html`) : modifications NA et grille jusqu'à 23 h, mais **sans** les corrections de V2.
- `PPI-FFN copie.html` — variante du 2026-10-07, d'origine non établie. `[À VÉRIFIER]`
- Anciennes versions, à ne pas modifier : `PPI_Version0.html`, `questionnaire-nageur-ffnV1.html`, `questionnaire-nageur-ffnV2 copie.html`, `questionnaire-nageur-ffnV2_avantsupabase.html`, `questionnaire-nageur-ffnV2 compétences - dimensions.html`, `sauvegarde.html`.
- `Résumé PPI.html` — référence visuelle de la page résumé (Barlow / Barlow Condensed).

Questionnaire jeunes (prototypes, natation seulement, n'écrivent pas dans Supabase)
- `PPI-Jeune-Nageur.html`, `PPI-Jeune-Entraineur.html`.

Dashboard et base
- `dashboard.html` — copie locale du dashboard (lecture de `ppi_nageurs`, connexion e-mail / mot de passe).
- `supabase/migration_20261006_colonnes_ppi.sql`, `supabase/migration_20261006_genre.sql` — migrations passées par Pierre.
- `supabase/vue_ppi_nageurs_derniere.sql` — vue proposée puis abandonnée.
- `supabase/gen_fiches_NA.py` → `supabase/insert_fiches_NA_20261016.sql` — fiches pré-remplies de natation artistique (contient des données nominatives).
- `supabase/.temp/` — fichiers de liaison de la CLI Supabase (référence du projet, URL du pooler).

Aide à la décision — `Aide à la décision/`
- `ELITE/aide-decision-{NC,EL,NA,WP,PL}-ELITE.html`, `RELEVE/aide-decision-{NC,EL,NA,WP,PL}-RELEVE.html` — pages finales générées.
- `atelier-attribution-dimensions.html` — atelier pour cocher le rattachement compétence → dimension ; `attribution-dimensions.json` (attribution validée) ; `attribution-competences-dimensions.md` (récapitulatif généré).
- `_generateur/` : `gen.py`, `gen_atelier.py`, `data_dlta.py`, `page_script.js`, `atelier_data.json`.
- `ppi-analyse-decision-EL.html` — page d'origine (analyse individuelle en eau libre + aide à la décision), sert de gabarit de style au générateur.

Contexte et divers
- `CONTEXT.md`, `BRIEFING_CLAUDE_CODE_FFN.md`, `instructions_claude_code_*.md`, `instructions_supabase_dashboard.md`, `modification_PPI_HTML` — cahiers des charges d'origine (mai 2026), en partie périmés. Ne pas les modifier.
- `_backups/` — copies prises avant chaque intervention du 2026-10-06.
- `.claude/launch.json` — serveurs locaux `python3 -m http.server` (ports 8000 et 8765).
- `PPI Eau libre/`, PDF / PPTX / DOCX / XLSX à la racine — PPI individuels et documents de travail (données nominatives), `ffn_clubs.csv`, `clubs_datalist_options.txt`, `Logo_FFN.png`.

Secrets : la clé publique Supabase (`anon`) et l'URL du projet sont écrites dans les questionnaires `PPI-FFN*.html`, `questionnaire-nageur-ffnV2 copie.html`, `dashboard.html`, leurs copies dans `_backups/`, et dans `instructions_claude_code_supabase.md`. Ne jamais les recopier ailleurs.

## 4. Décisions et conventions

Questionnaire
- Un seul fichier HTML par outil, utilisable en `file://`, sans serveur. Bibliothèques par CDN (jsPDF).
- Clé de discipline : `natation`, `eau-libre`, `synchro` (natation artistique), `water-polo`, `plongeon`.
- Pages : 0 discipline, 1 administratif, 2 environnement et semaine type, 3 bilan, 4 objectifs, 5 dimensions et 3 actions, 6 calendrier, puis charte, révision et résumé (budget en plus dans B).
- Autosauvegarde navigateur : clé `ffn_ppi_v3` (version A), `ffn_ppi_v3_B` (version B). Transmission entre personnes par le bouton « Transmettre » (`saveAndTransfer()`, données embarquées dans le fichier).
- Chaque clic sur « Réviser et exporter » fait un `POST` simple (`Prefer: return=minimal`) : **une nouvelle ligne par envoi, rien n'est écrasé**. Les versions se regroupent à l'affichage dans le dashboard.
- Licence vide → `SANS_LICENCE_<nom>_<prénom>` ; à traiter comme « pas de licence ».
- Si une colonne manque en base, le questionnaire renvoie la fiche sans elle.
- Saisons : projection 2027-2032, dimensions classées pour 2027 et 2028, calendrier d'août 2026 à août 2027.
- Compétitions de la saison : « Objectif de résultats » (rouge #E2001A, repris dans le résumé) ou « Objectif de développement » (vert #55CC85). Bilan de la saison passée : priorité 1 principale, 2 secondaire, 3 annexe.
- Semaine type : créneaux de 30 min à partir de 6 h ; types `eau`, `physique`, `scolaire`, `recup`, `kine`, `mental`, et `acro` (#F28C28) en natation artistique.
- Natation artistique : 11 dimensions (Physique, Mentale, Stratégique, Technique, Acrobatie, Exécution, Artistique, Collective, Nutrition, Récupération, Gestion de l'environnement personnel), plusieurs entraîneurs principaux. Plongeon : 7 dimensions, sans Artistique.
- Dates du résumé au format « 12 mai 2026 ». Libellés repris du vocabulaire du formulaire.
- Dans un bloc `<script>`, ne jamais écrire `</script>` en clair, même en commentaire.

Base Supabase
- Table unique `ppi_nageurs`. Insertion par la clé publique, lecture réservée aux comptes DTN authentifiés. Liste des colonnes et formats JSON : `docs/historique-claude.md`, section 7.
- Claude n'a pas d'accès en écriture : tout SQL est remis à Pierre, qui le passe dans Supabase > SQL Editor. Enregistrer chaque script dans `supabase/`.
- Colonnes genre : `'F'`, `'H'` ou vide (fiches antérieures au 2026-10-06).

Aide à la décision
- Relève = période 4 du DLTA, Élite = période 5. Axes du radar = dimensions de la discipline dans le questionnaire.
- Une compétence rattachée à plusieurs dimensions est répartie à parts égales ; chaque compétence pèse 1 ; une compétence sans dimension cochée est retirée ; une dimension sans compétence est « non évaluée ».
- Les pages finales ne se modifient pas à la main : régénérer avec
  `cd "Aide à la décision" && python3 _generateur/gen.py && python3 _generateur/gen_atelier.py`.

Questionnaire jeunes
- Trois outils, un seul écrit dans Supabase : le nageur prépare seul sur son téléphone, l'entraîneur tient un fichier pour tous les nageurs, le bilan se fait dans le questionnaire actuel. Pas de post-traitement par IA. Schéma Supabase inchangé.
- Comparaison nageur / entraîneur par un code à 6 chiffres (un par compétence). La liste des compétences est dupliquée dans les deux fichiers : modifier les deux.

## 5. État actuel et travaux en cours

- Base : 113 fiches au 2026-10-06, plus 14 fiches de natation artistique pré-remplies par la DTN le 2026-10-16 (repère : `discipline = 'synchro'` et `date_export = 2026-10-16T12:00:00+02:00`).
- Questionnaire de référence à confirmer entre `PPI-FFNV2.html`, `PPI-FFN.html` et `PPI-FFN copie.html`. Claude a cessé de modifier les questionnaires le 2026-10-06 après le signalement d'une modification par un autre chat.
- Écarts connus entre versions : grille jusqu'à 23 h absente de B (32 créneaux au lieu de 34) ; règle « préparation physique seule = jour d'entraînement » présente dans V2, pas dans B, à valider ; corrections de V2 absentes de `PPI-FFN.html`.
- Dashboard en ligne : à mettre à niveau dans l'autre chat (genre, entraîneurs multiples, type `acro`, dimensions NA, `objectifs_saison`, `objectifs_pluriannuels`, budget, clé de regroupement par licence, sections vides « à compléter »). État d'avancement inconnu. `[À VÉRIFIER]`
- Aide à la décision : water-polo Relève encore en « proposition provisoire » (aucune case cochée) ; plongeon sans compétence pour Récupération et Nutrition ; rattachements Exécution / Acrobatie en NA proposés par Claude, partiellement validés.
- Questionnaire jeunes : prototypes à relire (mises en situation et niveaux = premier jet), non testés sur un vrai téléphone. Reporté : refonte des 3 actions du questionnaire en cartes QPACRE.
- Proposé, non fait : un questionnaire pré-rempli par athlète de natation artistique.

## 6. Problèmes rencontrés et solutions retenues

- Envoi refusé (401 / 42501, puis 409) : l'upsert (`resolution=merge-duplicates`, `on_conflict=licence`) déclenchait un UPDATE interdit. Solution : insertion simple, une ligne par envoi.
- Alerte de sécurité Supabase du 2026-05-31 (table accessible publiquement) : SQL RLS remis le 2026-06-03 (insertion seule pour `anon`). Exécution non confirmée dans les sessions. `[À VÉRIFIER]`
- Fichier enregistré non navigable : abandon de l'export du DOM (`outerHTML`), de `fetch` en `file://` et du gabarit en base64 ; solution : `saveAndTransfer()`.
- Code affiché à l'écran : `</script>` dans un commentaire JS.
- Classement des dimensions perdu après rechargement, dimension qui disparaît en changeant de case, compétitions en double au calendrier : corrigés dans V2 et B (`syncRankingsFromDOM()`, autosauvegarde sur toute la page 5).
- V2 et B se partageaient la même autosauvegarde : clé distincte pour B.
- Fichiers DLTA (`competences_periode_4.md`, `competences_periode_5.md`) disparus du Bureau : le générateur se replie sur `_generateur/atelier_data.json`.
- Navigateur intégré qui n'ouvre plus les fichiers locaux ou garde l'ancienne version : passer par le serveur local (port 8765) et recharger sans cache.
- Regroupement des versions par nom + date de naissance dans le dashboard : fusionne des homonymes nés le même jour, sépare les variantes d'orthographe. Proposition transmise : licence valide, sinon nom + prénom + date de naissance normalisés.
- Planning Excel de natation artistique : le jour 1 est en ligne 4 ; les dates des compétitions se lisent dans la colonne « SEMAINES », les autres colonnes disent seulement qui participe.

## 7. Consignes de travail de Pierre

- Si c'est ambigu, demander ; ne pas choisir en silence.
- Toucher uniquement ce qui est demandé : modification minimale, pas de fonctionnalité spéculative.
- Définir ce que veut dire « terminé » avant de commencer.
- Vérifier dans le code, ne jamais faire d'hypothèse.
- Vocabulaire : ne jamais écrire « mes nageurs », « mon nageur », « ses nageurs ». Écrire « Suivi des nageurs », « Liste des nageurs », « les nageurs suivis » (mémoire du 2026-11-10).
- Pour chaque modification du questionnaire, dire l'impact sur la base et sur le dashboard, et fournir un bloc de texte à coller dans le chat du dashboard, limité à ce qui vient d'être fait.
- Fournir le SQL prêt à copier-coller ; Pierre l'exécute et renvoie le résultat du contrôle.
- Sauvegarder le fichier dans `_backups/` avant de le modifier ; tester dans le navigateur en interceptant l'envoi Supabase, pour ne rien écrire dans la vraie base.
- Une modification commune se reporte dans la version A et dans la version B.
- Questionnaire jeunes : âge ou année de naissance plutôt que catégories ; objectifs au moins de niveau national ; laisser le nageur formuler librement ce qu'il veut développer.
- Données nominatives de sportifs dans ce dossier : ne pas les diffuser ni les recopier dans des documents partagés.

## 8. Chronologie

- 2025-09 → 2026-01 : modèles et documents PPI (Excel, Word, PDF), premières versions HTML.
- 2026-05-05 → 2026-05-12 : cahiers des charges (5 disciplines, page résumé, suppression du budget en version A, Supabase, dashboard).
- 2026-05-11 → 2026-05-13 : corrections du résumé ; envoi Supabase débloqué ; priorité des compétitions du bilan.
- 2026-05-20 → 2026-05-21 : sauvegarde dans le fichier puis bouton « Transmettre » ; saison 2026 retirée ; calendrier août 2026 → août 2027 ; objectifs de résultats / de développement.
- 2026-06-03 : alerte de sécurité Supabase ; décision « une ligne par envoi ».
- 2026-07-28 : le questionnaire s'appelle `PPI-FFN.html` ; semaine type jusqu'à 23 h.
- Entre 2026-07-28 et 2026-10-01 : dossier déplacé de `Desktop/PPI` vers `Desktop/Relève-Perf32/PPI`.
- 2026-10-01 : aide à la décision par discipline, Relève / Élite, atelier d'attribution, générateur ; plongeon sans dimension Artistique.
- 2026-10-06 : natation artistique (entraîneurs multiples, acro, 11 dimensions, budget B) ; corrections V2 et B ; audit questionnaire → base ; migrations ; B branché sur Supabase ; genre.
- 2026-10-16 : 14 fiches de natation artistique pré-remplies insérées en base.
- 2026-11-10 : prototypes du questionnaire jeunes (nageur et entraîneur).

Pour le détail (récit par session, formats de données, pistes abandonnées) : `docs/historique-claude.md`.

## Décisions de Pierre du 2026-11-12 (réponses aux questions ouvertes)
Complète et remplace les [À VÉRIFIER] correspondants ci-dessus. « Fait » = exécuté le 2026-11-12 ; « À faire » = décidé, non exécuté.
- Questionnaire de référence diffusé : celui qui se télécharge depuis le dépôt GitHub (pas `PPI-FFN copie.html`).
- Dépôt du dashboard en ligne : sur le compte GitHub PierreH-07 (nom exact du dépôt à relever [À VÉRIFIER]).
- SQL RLS du 2026-06-03 : tout est passé ; vue `ppi_nageurs_derniere` : créée.
- Version B : grille jusqu'à 23 h et règle « préparation physique seule = jour d'entraînement » : validées.
- `competences_periode_4.md` et `competences_periode_5.md` : sans importance.
