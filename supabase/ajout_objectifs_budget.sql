-- Colonnes envoyées par les questionnaires PPI-ffnV2 et PPI-FFN-B (idempotent)

-- Détail des objectifs (sert aussi au questionnaire pré-rempli)
--   objectifs_saison       : [{ nom, priorite, debut, fin, commentaire, epreuves:[{epreuve, perf}] }]
--   objectifs_pluriannuels : [{ saison, competition, epreuves:[{epreuve, classement, perf}], isJO }]
ALTER TABLE public.ppi_nageurs ADD COLUMN IF NOT EXISTS objectifs_saison       jsonb;
ALTER TABLE public.ppi_nageurs ADD COLUMN IF NOT EXISTS objectifs_pluriannuels jsonb;

-- Budget prévisionnel (version B : toutes disciplines ; V2 : natation artistique)
ALTER TABLE public.ppi_nageurs
  ADD COLUMN IF NOT EXISTS b_dep_comp numeric,        ADD COLUMN IF NOT EXISTS b_dep_comp_detail text,
  ADD COLUMN IF NOT EXISTS b_heb_comp numeric,        ADD COLUMN IF NOT EXISTS b_heb_comp_detail text,
  ADD COLUMN IF NOT EXISTS b_stage numeric,           ADD COLUMN IF NOT EXISTS b_stage_detail text,
  ADD COLUMN IF NOT EXISTS b_equip numeric,           ADD COLUMN IF NOT EXISTS b_equip_detail text,
  ADD COLUMN IF NOT EXISTS b_medical numeric,         ADD COLUMN IF NOT EXISTS b_medical_detail text,
  ADD COLUMN IF NOT EXISTS b_mental numeric,          ADD COLUMN IF NOT EXISTS b_mental_detail text,
  ADD COLUMN IF NOT EXISTS b_licence numeric,         ADD COLUMN IF NOT EXISTS b_licence_detail text,
  ADD COLUMN IF NOT EXISTS b_heb_annuel_type text,
  ADD COLUMN IF NOT EXISTS b_heb_annuel numeric,      ADD COLUMN IF NOT EXISTS b_heb_annuel_detail text,
  ADD COLUMN IF NOT EXISTS b_transport numeric,       ADD COLUMN IF NOT EXISTS b_transport_detail text,
  ADD COLUMN IF NOT EXISTS b_etudes numeric,          ADD COLUMN IF NOT EXISTS b_etudes_detail text,
  ADD COLUMN IF NOT EXISTS b_autre_charge numeric,    ADD COLUMN IF NOT EXISTS b_autre_charge_detail text,
  ADD COLUMN IF NOT EXISTS b_dotation_ffn numeric,    ADD COLUMN IF NOT EXISTS b_dotation_ffn_detail text,
  ADD COLUMN IF NOT EXISTS b_aide_ligue numeric,      ADD COLUMN IF NOT EXISTS b_aide_ligue_detail text,
  ADD COLUMN IF NOT EXISTS b_aide_club numeric,       ADD COLUMN IF NOT EXISTS b_aide_club_detail text,
  ADD COLUMN IF NOT EXISTS b_sponsor numeric,         ADD COLUMN IF NOT EXISTS b_sponsor_detail text,
  ADD COLUMN IF NOT EXISTS b_autofinancement numeric, ADD COLUMN IF NOT EXISTS b_autofinancement_detail text,
  ADD COLUMN IF NOT EXISTS b_autre_recette numeric,   ADD COLUMN IF NOT EXISTS b_autre_recette_detail text,
  ADD COLUMN IF NOT EXISTS b_commentaire text;
