# 01_prepare_data.R
# This script standardizes column names and derives outcome variables.
source("R/functions/io_helpers.R")
source("R/functions/qc_helpers.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(forcats)
  library(yaml)
  library(here)
})

cfg <- read_config()

# Expect a single local RDS containing your merged analysis object
# e.g., saveRDS(分四組_Chronotype, "data/raw/analysis_object.rds")
df_raw <- safe_read_rds(path_raw(cfg$files$analysis_object))

# --- Clean and standardize names from your current object ---
df <- df_raw %>%
  rename(
    participant_id = `Participant ID`,
    age_at_accelerometry = Age_at_accelerometry,
    wear_duration_overall = Wear_duration_overall,
    sex_2g = Sex_2g,
    chronotype_2g = Chronotype_2g,
    noctural_pct_1am_4am = Noctural_percentage_1am_4am,
    survival_days_allcause = `存活天數_全死因`
  ) %>%
  mutate(
    # Cluster appears multiple times (Cluster / Cluster.x / Cluster.y). Prefer the main "Cluster" column.
    cluster = dplyr::coalesce(as.character(Cluster), as.character(`Cluster.y`), as.character(`Cluster.x`)),
    cluster = factor(cluster),
    # Prefer MVPA_150_2g.y if present, else MVPA_150_2g.x
    mvpa150_2g = dplyr::coalesce(MVPA_150_2g.y, MVPA_150_2g.x),
    mvpa150_2g = as_binary01(mvpa150_2g),
    sex_2g = factor(sex_2g),
    chronotype_2g = factor(chronotype_2g)
  )

# Set cluster reference to "0" if exists
if ("0" %in% levels(df$cluster)) df$cluster <- forcats::fct_relevel(df$cluster, "0")

# --- All-cause death indicator ---
# You have both `status` and `status.y`. We coalesce them (prefer status.y if non-missing).
if (!("status" %in% names(df_raw) || "status.y" %in% names(df_raw))) {
  stop("Neither `status` nor `status.y` exists. Please add an all-cause death indicator.")
}

status_all <- dplyr::coalesce(df_raw[["status.y"]], df_raw[["status"]])
df$status_allcause <- as_binary01(status_all)

# --- Cause-specific death indicators (derived from ICD-10 primary cause flags/fields) ---
# We treat non-missing primary-cause fields as belonging to that cause.
if ("Cause of death - ICD-10_primary_cause_cancer" %in% names(df_raw)) {
  df$status_cancer <- as.integer(df$status_allcause == 1 &
                                 !is.na(df_raw[["Cause of death - ICD-10_primary_cause_cancer"]]))
} else {
  df$status_cancer <- NA_integer_
}

if ("Cause of death - ICD-10_primary_cause_cardiovascular" %in% names(df_raw)) {
  df$status_cvd <- as.integer(df$status_allcause == 1 &
                              !is.na(df_raw[["Cause of death - ICD-10_primary_cause_cardiovascular"]]))
} else {
  df$status_cvd <- NA_integer_
}

# --- Age group for stratification ---
age_cutoff <- 65
df <- df %>%
  mutate(
    age_group = ifelse(age_at_accelerometry < age_cutoff, paste0("<", age_cutoff), paste0(">=", age_cutoff)),
    age_group = factor(age_group, levels = c(paste0("<", age_cutoff), paste0(">=", age_cutoff)))
  )

# Quick sanity checks (aggregate, safe)
message("Sanity checks:")
print(table(df$cluster, useNA = "ifany"))
print(table(df$status_allcause, useNA = "ifany"))
if (!all(is.na(df$status_cancer))) print(table(df$status_cancer, useNA = "ifany"))
if (!all(is.na(df$status_cvd))) print(table(df$status_cvd, useNA = "ifany"))

safe_write_rds(df, path_derived("analysis_dataset_pre_qc.rds"))
message("Saved: data/derived/analysis_dataset_pre_qc.rds")
