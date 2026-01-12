# 03_fit_models.R
source("R/functions/io_helpers.R")
source("R/functions/model_helpers.R")

suppressPackageStartupMessages({
  library(dplyr)
})

df <- safe_read_rds(path_derived("analysis_dataset_post_qc.rds"))

# Define time/status vars
time_var <- "survival_days_allcause"
outcomes <- list(
  all_cause = "status_allcause",
  cancer    = "status_cancer",
  cvd       = "status_cvd"
)

# Covariate blocks (edit if needed)
rhs_m1 <- "cluster + sex_2g + age_at_accelerometry"
rhs_m2 <- paste(rhs_m1,
                "+ Cancer_history_2g + Diabetes_history_2g + Insulin_2g",
                "+ Income_5g + Shift_work_2g",
                "+ Mental_issue_2g + Vascular_heart_histotry",
                "+ BMI + Smoking_2g + Alcohol_2g",
                "+ Education_With_any_qualification + Education_With_Degree",
                "+ wear_duration_overall")
rhs_m3 <- paste(rhs_m2, "+ Sleep_perday_min + SB_perday_min + Light_perday_min + MVPA_perday_min")

models <- list()

for (o in names(outcomes)) {
  s <- outcomes[[o]]
  # skip if cause-specific status is all NA
  if (all(is.na(df[[s]]))) next

  models[[o]] <- list(
    M1 = fit_cox(df, time_var, s, rhs_m1, robust = TRUE),
    M2 = fit_cox(df, time_var, s, rhs_m2, robust = TRUE),
    M3 = fit_cox(df, time_var, s, rhs_m3, robust = TRUE),

    # Chronotype-stratified (remove chronotype term if not in RHS; we test interaction separately)
    Early_M3 = fit_cox(df, time_var, s, rhs_m3, robust = TRUE, subset_expr = (chronotype_2g == levels(chronotype_2g)[1])),
    Late_M3  = fit_cox(df, time_var, s, rhs_m3, robust = TRUE, subset_expr = (chronotype_2g == levels(chronotype_2g)[2]))
  )

  # Interaction (LRT): cluster x chronotype
  models[[o]]$LRT_cluster_by_chronotype <- lr_test_interaction(df, time_var, s, rhs_m3, "cluster:chronotype_2g")
}

safe_write_rds(models, path_derived("fitted_models.rds"))
message("Saved fitted models (local): data/derived/fitted_models.rds")
