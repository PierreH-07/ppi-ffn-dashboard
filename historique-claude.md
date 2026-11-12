# Historique détaillé des sessions Claude Code — projet PPI

Complément de `../CLAUDE.md`. Rédigé le 2026-11-11 à partir de 8 sessions extraites (dont 2 strictement identiques et 1 sous-agent), des 2 fichiers de mémoire, et de l'état réel du dossier. Les sessions sont présentées de la plus ancienne à la plus récente.

Règles de rédaction appliquées ici : aucun secret recopié (seulement leur emplacement) ; aucune situation individuelle de sportif (les fichiers et les méthodes sont décrits, pas les personnes).

Sources brutes : `~/Claude-historique/PPI/sessions/*.jsonl` et `~/Claude-historique/PPI/memoires/`.

---

## 0. Avant les sessions Claude Code (d'après les fichiers du dossier)

- Le dossier contient des fichiers datés de 2025-09 à 2026-01 (modèles Excel/Word/PDF de PPI, documents préparatoires athlète/entraîneur, `ffn_clubs.csv`, `clubs_datalist_options.txt`, `sauvegarde.html`) : le projet PPI existait avant les sessions conservées.
- Les fichiers `BRIEFING_CLAUDE_CODE_FFN.md` (2026-05-05), `instructions_claude_code_resume_PPI.md` (2026-05-10), `modification_PPI_HTML` (2026-05-11), `instructions_claude_code_budget_calendrier.md` (2026-05-11), `instructions_claude_code_supabase.md` (2026-05-11), `instructions_supabase_dashboard.md` (2026-05-12) et `CONTEXT.md` sont des cahiers des charges rédigés dans un autre chat (claude.ai) puis collés dans Claude Code. Ils décrivent des états intermédiaires :
  - `BRIEFING_CLAUDE_CODE_FFN.md` : passage du questionnaire mono-discipline à 5 disciplines (objet de configuration par discipline, pages 3 et 4 spécifiques, payload localStorage, exports CSV/PDF).
  - `instructions_claude_code_resume_PPI.md` et `modification_PPI_HTML` : page de révision et page résumé A4 (2 pages imprimables, 7 sections, typographie Barlow / Barlow Condensed, référence visuelle `Résumé PPI.html`), règle « vocabulaire du formulaire uniquement ».
  - `instructions_claude_code_budget_calendrier.md` : suppression de la page Budget (version A) et de l'événement « Entraînement » du calendrier (les jours d'entraînement sont calculés depuis la semaine type).
  - `instructions_claude_code_supabase.md` : création de la table `ppi_nageurs`, RLS, remplacement de l'envoi Google Sheets par `sendToSupabase()`, valeur de repli `SANS_LICENCE_<nom>_<prénom>`. Ce fichier contient une clé Supabase : ne pas le diffuser.
  - `instructions_supabase_dashboard.md` : lecture réservée aux comptes authentifiés (policy `select_authenticated`), invitation des utilisateurs DTN, hébergement GitHub Pages dans un dépôt `ppi-ffn-dashboard`.
- `CONTEXT.md` (mai 2026) est en grande partie périmé : il parle encore d'export Google Sheets, d'une clé localStorage `ppi_formdata_${discipline}`, d'un classement 2026-2028 et d'une page Budget en page 7. Ses cinq consignes d'en-tête restent valables (voir CLAUDE.md, section 7).

---

## 1. Session 2026-05-11 → 2026-07-28 — « Fix volume bar colors not displaying in questionnaire »

Lancée depuis `/Users/pierre.hui/Desktop/PPI` (ancien emplacement, n'existe plus). Fichier travaillé : `questionnaire-nageur-ffnV2.html` (n'existe plus sous ce nom : renommé `PPI-FFN.html`). Cette session figure deux fois dans l'historique (extraits 005 et 006, contenu identique). La plupart des demandes sont des instructions précises copiées depuis un autre chat.

2026-05-11
- Barres de volumes de la semaine type sans couleur : les dégradés passent de `background:` à `background-image:`.
- `collectProjCompetitions()` collecte aussi les épreuves visées (`oe_epreuve_N`, `oe_classement_N`, `oe_perf_N`) ; `buildTimeline()` les affiche sous la compétition (« épreuve · TOP n · perf »).
- Second donut « Répartition annuelle » (jours/an) dans le résumé : `computeAnnualStats()` et `buildAnnualDonut()`, 5 catégories (Entraînement #00AEEF, Compétition #E2001A, Stage #55CC85, Évt. personnel #FF6B9D, Coupure #D59F49). Priorité de comptage : compétition > stage > entraînement (semaine type) > personnel ; coupure = reste. Grille `.week` en `1fr auto auto`.

2026-05-12
- Ajout de « CNE INSEP » dans la liste des structures.
- Libellés du résumé : « Compétitions de référence » → « Compétitions principales saison passée » ; « Compétitions saison 2026 » → « Compétition saison en cours ».
- Dates du résumé toutes au format « 12 mai 2026 » (`toLocaleDateString('fr-FR', {day:'numeric',month:'long',year:'numeric'})`).
- Cartes de discipline de la page d'accueil : `repeat(auto-fit, minmax(140px, 1fr))` pour ne plus déborder.
- Donut « Volume total » : un arc par type d'activité au lieu du seul arc « eau ».
- Bouton « Ajouter une compétition … » libellé selon la discipline (la clé de la natation artistique est `synchro`). En eau libre, deux boutons volontairement (eau libre + bassin).
- Bouton « Réviser et exporter » → `exportEtResume()` ; `exportFinal()` devient `async` et attend `sendToSupabase()`.
- `collectCompetitionsBilan()` / `restoreCompetitionsBilan()` + ajout au payload d'autosauvegarde (délai 100 ms à la restauration).
- Envoi Supabase en échec : erreur 401 / code 42501 « new row violates row-level security policy ».

2026-05-13 — diagnostic Supabase (mené par Pierre dans le SQL Editor, Claude n'a pas d'accès)
- Policies constatées : `insert_anon` (INSERT, anon), `select_authenticated` (SELECT si authentifié), `update_public` (UPDATE, public). RLS activé. `licence` était alors NOT NULL et clé primaire.
- Cause retenue : l'en-tête `Prefer: resolution=merge-duplicates` transformait l'INSERT en upsert, donc en UPDATE refusé. Retrait de l'en-tête → l'envoi fonctionne.
- Restauration des compétitions du bilan corrigée (utilisation des vrais identifiants de bloc).
- Résumé : suppression du doublon « Entraîneur principal », retour à la ligne des e-mails longs, suppression de « Paris » / « LA » sous 2028 / 2032 (information fausse).
- Priorité des compétitions du bilan (saison passée) : seules les plus prioritaires vont dans le résumé, les autres seulement en base. Constat : les compétitions du bilan n'étaient pas envoyées à Supabase → colonne `competitions_bilan jsonb` à créer et ajout au payload. Claude a aussi proposé `UNIQUE (licence)` pour un upsert : piste abandonnée ensuite (voir 2026-06-03).

2026-07-28
- Le fichier s'appelle désormais `PPI-FFN.html`. Grille de la semaine type étendue de 32 à 34 créneaux de 30 min (jusqu'à 23 h). Pas d'impact sur la base (`semaine_type_data` est du JSON) ; dashboard à vérifier s'il dessine la grille.
- Constat du 2026-11-11 : `PPI-FFN.html` et `PPI-FFNV2.html` ont 34 créneaux, `PPI-FFN-B_1.html` en a toujours 32.

---

## 2. Session 2026-05-20 → 2026-06-03 (sans titre) + sous-agent du 2026-05-20

Même dossier d'origine, même fichier. Objet principal : pouvoir transmettre le questionnaire rempli d'une personne à une autre (le fichier circule par mail, le localStorage ne suit pas).

2026-05-20
- `saveIntoHTML()` : injecte les données dans un `<script id="embedded-save">` placé juste après `<body>` et télécharge `questionnaire-<nom>-<prenom>-<date>.html`. `restoreFromLocalStorage()` lit d'abord `window.__EMBEDDED_SAVE__`.
- `rankingsBySeasons` ajouté aux payloads de sauvegarde et restauré avant `renderMultiSaisonTable()`.
- Bug « du code HTML s'affiche à l'écran » : un commentaire JS contenait `</script>` en clair. Règle retenue : dans un bloc `<script>`, toujours écrire `<\/script>` ou construire la balise par concaténation, même dans un commentaire.
- Le fichier exporté n'était plus navigable (export du DOM rendu). Première parade : exporter le HTML d'origine + les données.
- Sous-agent (extrait 008) chargé d'un lot : bouton « Enregistrer » centré en bas et placé au-dessus des boutons Précédent/Suivant (`positionSaveButton()`), suppression de la saison 2026 des saisons à venir (`SAISONS = [2027…2032]`, `rankingsBySeasons = {2027, 2028}`, « Projection long terme 2027 – 2032 »), suppression du type « Entraînement » du calendrier pour les 5 disciplines.

2026-05-21
- Calendrier de saison d'août 2026 à août 2027 (13 mois, 4 « trimestres » : août-oct. / nov.-janv. / févr.-avr. / mai-août, le dernier à 4 mois, classe CSS `four-months`).
- « Ce qui me sépare de la médaille » → « Ce qui me sépare de mes objectifs ».
- Compétitions de la saison en cours : priorités A/B/C remplacées par « Objectif de résultats » (rouge, repris dans le résumé) et « Objectif de développement » (vert, calendrier seulement). Rétrocompatibilité gardée dans `PRIORITY_COLORS`.
- Longue série d'essais sur la réouverture d'un fichier enregistré (atterrissage sur la page de sélection de discipline, navigation bloquée) :
  - pistes abandonnées : capture de `document.documentElement.outerHTML` (fichier corrompu à la 2e sauvegarde, double `<!DOCTYPE>`), `fetch(window.location.href)` (interdit en `file://`), template encodé en base64 (`__HTML_TEMPLATE_B64__`) nécessitant une préparation depuis un serveur ;
  - corrections conservées : pas d'autosauvegarde sans discipline, `goToPage()` retombe sur la page 0 si la page n'existe pas, `clearSavedData()` vide tout le localStorage, échappement de U+2028 / U+2029 écrit sous forme ` ` dans le source, restauration du classement déplacée après la génération des pages de discipline (délai 200 ms, clones, `data-name`), `restoreFromLocalStorage()` lancé 50 ms après `renderDisciplineSelector()` ;
  - solution finale : bouton « Transmettre à quelqu'un » (`saveAndTransfer()`, données dans `#embedded-data`). Le bouton flottant « Enregistrer le document » est supprimé. Ordre de restauration : `window.__EMBEDDED_SAVE__`, puis `#embedded-data`, puis localStorage.
- Idée écartée par Pierre le jour même : colonnes de projection neutres `proj_competition_1…6` avec année calculée dynamiquement. On garde `proj_competition_2026…2032`.
- Envoi Supabase : allers-retours entre `return=minimal`, `resolution=merge-duplicates`, `?on_conflict=licence` (erreurs 409 « duplicate key … ppi_nageurs_pkey » puis 401). Tranché le 2026-06-03.

2026-06-03
- Alerte de sécurité Supabase reçue (« table publicly accessible », constat au 2026-05-31). Fichier vérifié : `PPI-FFN.html`.
- Décision de Pierre : chaque envoi crée une nouvelle ligne, pour consulter toutes les versions dans le dashboard. Dans `PPI-FFN.html` : retrait de `resolution=merge-duplicates`, `date_export = new Date().toISOString()`, suppression d'un `Content-Type` en double.
- SQL remis à Pierre, non exécuté par Claude : activer RLS, policy `insert_only_anon` (INSERT pour `anon`), colonne `date_export timestamptz DEFAULT now()`. Pierre a répondu « pour l'instant restons-en là » : exécution non confirmée dans les sessions.
- Point d'attention : des exemplaires plus anciens du questionnaire, déjà envoyés à des collègues, font encore un upsert ; avec une RLS « INSERT seulement », leur premier envoi passe mais un second envoi avec la même licence échoue.

---

## 3. Session 2026-10-01 — « Document PPI-FFN »

Dossier désormais dans `Desktop/Relève-Perf32/PPI`. Simple lecture de `PPI-FFN.html` : description des pages 0 à 9 et des fonctions (autosauvegarde, exports CSV / PDF / résumé, envoi Supabase vers `ppi_nageurs`). Remarques restées sans suite : un commentaire « ENVOI À GOOGLE SHEETS » périmé, titre d'onglet « Questionnaire Nageur - FFN », clé publique Supabase en clair (normal pour une clé `anon`, tout repose sur la RLS).

## 4. Session 2026-10-01 — « Dossier aide à la décision »

Point de départ : `Aide à la décision/ppi-analyse-decision-EL.html` (2026-05-25), page autonome d'analyse de performance en eau libre pour un nageur + partie interactive « aide à la décision » (curseurs 0-10 par compétence, radar, classement). Anomalies relevées sur la partie analyse et non corrigées : courbe « Moyenne » du classement par tour incohérente, couleurs des écarts inversées dans le tableau « Niveau bassin », une compétition absente d'une légende, rien n'est sauvegardé, page non réutilisable (données en dur), pas d'affichage mobile.

Réalisé :
1. Radar EL refait sur les 8 dimensions officielles du questionnaire (les mêmes que la page 5). Compétences mixtes réparties à parts égales, chaque compétence pèse 1, poids de chaque dimension affiché, doublons supprimés.
2. Une page « aide à la décision » par discipline (NC, EL, NA, WP, PL), sans la partie analyse individuelle, axes = dimensions de la discipline dans le questionnaire.
3. Duplication en ELITE et RELEVE (`const NIVEAU`), les 5 pages sans niveau sont supprimées.
4. Compétences issues du DLTA : période 4 = Relève, période 5 = Élite (fichiers `competences_periode_4.md` / `competences_periode_5.md`, alors sur le Bureau). Le DLTA ne donne pas le rattachement compétence → dimension.
5. Atelier d'attribution (`atelier-attribution-dimensions.html`) : tableau compétences × dimensions à cocher, 10 onglets, sauvegarde navigateur, export / import `attribution-dimensions.json`, « Pré-remplir avec la proposition », « Copier depuis l'autre niveau ». Les cases à cocher n'existent que dans l'atelier ; les pages finales affichent des dimensions fixes.
6. Générateur rangé dans `Aide à la décision/_generateur/` (`gen.py`, `gen_atelier.py`, `data_dlta.py`, `page_script.js`, `atelier_data.json`). Serveur local port 8765 ajouté dans `.claude/launch.json` (le port 8000 était pris par Docker).
7. Plongeon : dimension Artistique retirée (7 dimensions) dans `PPI-FFN.html`, l'atelier et les pages PL. Elle subsiste dans les anciens fichiers non modifiés (`PPI_Version0.html`, variantes `questionnaire-nageur-ffnV1/V2`).
8. Mise à jour de la période 5 : water-polo Élite de 27 à 56 compétences, « Ravitaillement » → « Transitions » en eau libre Élite ; le lecteur gère les notes en italique et les puces sans titre.
9. Import du JSON de Pierre ; règle « une compétence non cochée est retirée ». Résultat : NC 16/18, EL 16/19, NA 15/16, PL 15/16 (Élite / Relève), WP Élite 40 (16 retirées). WP Relève non faite (aucune case cochée) : page laissée en « proposition provisoire ». Plongeon : Récupération et Nutrition « non évaluées ».

## 5. Session 2026-10-06 → 2026-10-16 — « Questionnaire natation artistique »

2026-10-06 — natation artistique (clé `synchro`)
- Fichiers ciblés : `PPI-FFN.html` et la version B avec budget `PPI-FFN-B_1.html`. Les changements ne s'activent que pour la natation artistique :
  - plusieurs entraîneurs principaux (bouton d'ajout ; colonne `entraineurs_principaux jsonb`, le premier reste dans `entraineur_nom/email/tel`) ;
  - type « Entraînement acro » dans la semaine type (id `acro`, couleur #F28C28, compte comme jour d'entraînement) ;
  - page 5 : « Tactique » → « Stratégique », ajout d'« Acrobatie » et « Exécution » (11 dimensions) ; une ancienne sauvegarde « Tactique » est convertie ;
  - version B seulement : charges « Hébergement à l'année » (interne INSEP / externe), « Frais de transport », « Frais d'études ».
- Aide à la décision NA régénérée avec les 11 dimensions. Les fichiers DLTA n'étant plus sur le Bureau, le générateur se replie sur `_generateur/atelier_data.json` (vérifié : régénération identique à l'octet près avant modification). Rattachements ajoutés : Formation technique → Exécution ; Coordination/Agilité, Efficacité dans le milieu aquatique et (Élite seulement) Stabiliser les niveaux de force → Acrobatie. Sauvegarde : `_backups/aide-decision_avant-NA_20261006/`.
  Commande de régénération : `cd "Aide à la décision" && python3 _generateur/gen.py && python3 _generateur/gen_atelier.py`.
- `PPI-FFNV2.html` : version de `PPI-FFN.html` avec corrections venues d'ailleurs (`syncRankingsFromDOM()`, dimensions restaurées de nouveau déplaçables, compétitions en double au calendrier, et un changement de règle : une journée de préparation physique seule compte comme jour d'entraînement). Corrections ajoutées par Claude dans V2 et reportées dans B :
  - déplacer une dimension d'une case à une autre la faisait disparaître (`handleDrop` : garder la case d'origine avant de retirer l'élément) ;
  - classement effacé au 2e rechargement (l'autosauvegarde observait `.ranking-area`, qui n'existe pas ; elle observe maintenant toute la page 5) ;
  - resynchronisation du classement avant `saveIntoHTML` et, dans B, avant le résumé imprimable.
  Non reporté dans B : la règle « préparation physique = jour d'entraînement » (à valider). `PPI-FFN.html` n'a reçu aucune de ces corrections.
- Clé d'autosauvegarde propre à B : `ffn_ppi_v3_B` (reprise automatique d'une ancienne sauvegarde B faite sous `ffn_ppi_v3`, reconnue à ses champs budget).
- Audit « chaque donnée saisie a-t-elle une destination en base ? » : remplissage automatique des 5 disciplines, interception de l'envoi, contrôle en lecture seule de l'existence des colonnes. Deux blocs de la page 4 n'allaient nulle part → nouvelles colonnes `objectifs_saison` et `objectifs_pluriannuels`. Si une colonne manque en base, le questionnaire renvoie la fiche sans elle.
- `supabase/migration_20261006_colonnes_ppi.sql` : colonnes `objectifs_saison`, `objectifs_pluriannuels`, `entraineurs_principaux`, 36 colonnes budget `b_*`, reprise des fiches existantes (objectifs reconstitués depuis le calendrier et `proj_competition_*`, « Tactique » → « Stratégique » en NA), `NOTIFY pgrst, 'reload schema'`. Exécuté par Pierre : 113 fiches, 101 avec objectifs de saison, 106 avec objectifs pluriannuels, aucune fiche NA à cette date.
- La version B envoie désormais à Supabase (même table, 102 champs dont les `b_*`). Une fiche B se reconnaît à ses `b_*` non nuls.
- Regroupement des versions d'un même nageur : Claude avait proposé une vue `ppi_nageurs_derniere` (`supabase/vue_ppi_nageurs_derniere.sql`), abandonnée quand Pierre a précisé que le dashboard en ligne (`index.html`, vers la ligne 866) regroupe déjà à l'affichage par nom + date de naissance avec sélecteur de versions. Proposition transmise à la place : clé = licence valide (hors `SANS_LICENCE_…`), sinon nom + prénom + date de naissance normalisés, avec rattachement des fiches sans licence. Application côté dashboard non vérifiable d'ici.
- Champ « Genre » (page 1, sous la date de naissance) ajouté dans V2 et B, colonne `genre` ('F' / 'H'), `supabase/migration_20261006_genre.sql`. Les 113 fiches antérieures restent sans genre.
- Pierre signale qu'un autre chat a modifié le questionnaire : aucune modification étrangère trouvée dans V2 ni B. Claude s'arrête de modifier les questionnaires en attendant de savoir quel fichier est concerné. Constat du 2026-11-11 : `PPI-FFN copie.html` (daté du 2026-10-07) diffère de `PPI-FFNV2.html` d'une cinquantaine de lignes (champ genre non obligatoire, ancien code de glisser-déposer, clés `obj_competitions` / `proj_competitions` « pour le pré-remplissage » au lieu de `objectifs_saison` / `objectifs_pluriannuels`) : probablement la variante de l'autre chat.
- Sauvegardes prises avant chaque étape : `_backups/` (suffixes `_avant-NA`, `_avant-fix-dnd`, `_avant-audit-bdd`, `_avant-supabase`, `_avant-genre`, tous `_20261006`).

2026-10-16 — fiches pré-remplies de natation artistique
- Lecture d'un planning de saison Excel (hors dossier, sur le Bureau à l'époque : `MAJ SAISON 151026.xlsx`) : un bloc de colonnes par mois, une ligne par jour, colonne « SEMAINES », colonnes équipe / duo / individuelles, code couleur sans légende. Piège : le jour 1 est en ligne 4.
- Règles validées par Pierre : les dates des compétitions viennent de la colonne « SEMAINES », les colonnes équipe / duo / individuelles indiquent seulement qui participe ; tous les athlètes suivent le calendrier de l'équipe, le duo ayant une compétition en plus ; compétitions toutes en « objectif de développement » sauf Mondes et Super Finale en « objectif de résultats » ; stages et événements personnels (examens → type `scolaire`, autres → `personnel`) dans le calendrier ; pas de congrès ; structure « INSEP » ; licence `SANS_LICENCE_<NOM>_<Prénom>` faute de numéro (« pour l'instant ») ; bilan 2025-26 : finales seulement, priorité 1 pour Mondes juniors, Europe et Super Finale, priorité 2 pour les autres étapes de Coupe du monde ; noms de compétitions en français.
- Sources de données : API World Aquatics (date de naissance, genre, résultats internationaux, à regrouper par compétition ET ville car plusieurs étapes portent le même nom) ; site de résultats European Aquatics / MicroPlus (code EUCH26, JSON accessible avec le jeton public du site, apporte les épreuves par équipe et leur composition).
- `supabase/gen_fiches_NA.py` génère `supabase/insert_fiches_NA_20261016.sql` : 14 fiches, rejouable sans doublon (repère : licence + `date_export` fixe au 2026-10-16T12:00:00+02:00), `commentaire_programme` commençant par « Fiche pré-remplie par la DTN le 16/10/2026 ». Vérification structurelle seulement (Docker non démarré). Exécuté par Pierre dans le SQL Editor ; le tableau de contrôle correspond.
- Limite : le questionnaire ne relit pas la base ; une athlète qui remplit son questionnaire part d'un formulaire vide et sa nouvelle fiche masque la fiche pré-remplie. Proposition non suivie d'effet : générer un questionnaire HTML pré-rempli par athlète.
- Récapitulatif préparé pour le chat du dashboard (Pierre a demandé de ne transmettre que la partie NA du jour) : repérage des fiches, formats de `competitions_bilan`, `objectifs_saison`, `competitions_calendrier`, `calendrier`, sections laissées vides à afficher « à compléter », badge « pré-remplie DTN » en option.

## 6. Session 2026-11-10 — « Questionnaire pour jeunes nageurs »

- Demande : une version du questionnaire pour nageurs plus jeunes et moins expérimentés, qui les aide à mettre en forme leur projet et alimente la base avec les mêmes informations. Note de départ : partir du rêve ; une réussite et la force personnelle associée ; la prochaine étape de l'année ; 3 pas décrits en QPACRE (quand, pourquoi, comment, avec quoi, risques, efficacité) ; compétences DLTA période 4 (spécialisation, engagement quotidien, connaissance de la pratique, gestion de la pression, hygiène de vie et récupération, triple projet).
- Cadrage de Pierre : le nageur pré-remplit seul puis confronte avec son entraîneur dans un dialogue qui fixe l'axe ; alimentation directe de Supabase et du dashboard, aucun post-traitement par IA ; « navigation humaine » (destination connue, seules les 2-3 prochaines étapes sont représentées, nouvelle décision à chaque étape) ; le nageur remplit sur son téléphone, l'entraîneur tient un fichier unique pour tous les nageurs, le « bilan » se fait dans le questionnaire actuel.
- Architecture retenue : trois outils, un seul écrit dans Supabase (le questionnaire actuel). Schéma Supabase et dashboard inchangés.
- Créés : `PPI-Jeune-Nageur.html` (7 écrans : bienvenue, destination, où j'en suis, prochaine étape, mises en situation, 3 pas, carte de synthèse avec code à 6 chiffres, un par compétence ; clé locale `ppi_jeune_nageur_v1`) et `PPI-Jeune-Entraineur.html` (liste des nageurs, lecture de l'entraîneur sur 4 niveaux, saisie du code, écarts calculés, « ce qu'on retient pour le bilan », bouton d'enregistrement du fichier avec les données dedans ; clé locale `ppi_jeune_entraineur_v1`). Natation seulement. La liste des compétences est dupliquée dans les deux fichiers : toute modification doit être faite des deux côtés.
- Corrections demandées : ne pas écrire « mes nageurs » (devenu « Suivi des nageurs », « Liste des nageurs ») ; année de naissance et âge à la place des catégories ; objectifs au moins de niveau national (« Finale régionale » retirée) ; les 3 pas sont libres (« Ce que je veux développer »), les 6 compétences ne servent plus qu'aux mises en situation et au code.
- Reporté : refonte des 3 actions du questionnaire actuel en cartes QPACRE (6 champs assemblés dans `actionN_comment` / `actionN_attendus`). Écartés : colonnes `reve_*`, `actionN_risques`, `version_questionnaire`, statut brouillon, import d'un fichier de proposition.
- Non fait : test sur un vrai iPhone ; relecture des mises en situation et des niveaux (premier jet de Claude) ; contrainte réelle sur le niveau de l'étape (texte libre).

---

## 7. Détails techniques utiles

Table Supabase `ppi_nageurs` (d'après les sessions ; le schéma en ligne n'est pas lisible avec la clé publique)
- Identité et contexte : `licence`, `nom`, `prenom`, `date_naissance`, `genre`, `email`, `telephone`, `club`, `discipline`, `discipline_label`, `structure_nom`, `entraineur_nom/email/tel`, `entraineurs_principaux`, `commentaire_programme`, `date_export`, `created_at`, `id`.
- JSON : `staff_data`, `semaine_type_data` (`{"jour_créneau": type}`, 1 créneau = 0,5 h), `rankings_by_seasons`, `competitions_bilan` (`[{nom, date, priorite 1|2|3, epreuves:[{epreuve, classement, perf}]}]`), `objectifs_saison` (`[{nom, priorite 'resultats'|'developpement', debut, fin, commentaire, epreuves:[{epreuve, perf}]}]`), `objectifs_pluriannuels` (`[{saison, competition, isJO, epreuves:[{epreuve, classement, perf}]}]`), `competitions_calendrier` (`[{sourceId, nom, startDate, endDate, priorite, color, type:'objectif-competition', comment}]`), `calendrier` (`[{id, startDate, endDate, type 'stage'|'vacances'|'scolaire'|'personnel', comment}]`).
- Texte : `bq_*` (bilan qualitatif), `sep_*` (ce qui me sépare de mes objectifs), `action1..3_comment` / `_attendus`, `classement_objectifs`, `engagements`, `proj_competition_2026…2032`, `proj_debut_*`, `proj_fin_*` (les `*_2026` ne sont jamais remplies).
- Budget (version B) : `b_dep_comp`, `b_heb_comp`, `b_stage`, `b_equip`, `b_medical`, `b_mental`, `b_licence`, `b_autre_charge`, `b_heb_annuel` (+ `b_heb_annuel_type`), `b_transport`, `b_etudes`, `b_dotation_ffn`, `b_aide_ligue`, `b_aide_club`, `b_sponsor`, `b_autofinancement`, `b_autre_recette`, chacun avec son `_detail`, et `b_commentaire`.
- Couleurs calendrier : résultats #E2001A, développement #55CC85.

Méthode de test utilisée dans les sessions d'octobre et novembre : ouverture dans le navigateur intégré via le serveur local (port 8765), interception de l'envoi Supabase pour ne rien écrire en base, test sauvegarde / rechargement, rechargement sans cache après modification, effacement des données de test.

Outils en ligne de commande rencontrés : Supabase CLI (dossier `supabase/.temp/`, projet lié), Python 3 pour les générateurs, zsh (piège : une variable n'est pas découpée en mots dans une boucle `for`).

## Décisions de Pierre du 2026-11-12 (réponses aux questions ouvertes)
Complète et remplace les [À VÉRIFIER] correspondants ci-dessus. « Fait » = exécuté le 2026-11-12 ; « À faire » = décidé, non exécuté.
- Questionnaire de référence diffusé : celui qui se télécharge depuis le dépôt GitHub (pas `PPI-FFN copie.html`).
- Dépôt du dashboard en ligne : sur le compte GitHub PierreH-07 (nom exact du dépôt à relever [À VÉRIFIER]).
- SQL RLS du 2026-06-03 : tout est passé ; vue `ppi_nageurs_derniere` : créée.
- Version B : grille jusqu'à 23 h et règle « préparation physique seule = jour d'entraînement » : validées.
- `competences_periode_4.md` et `competences_periode_5.md` : sans importance.
