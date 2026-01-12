# 04_extract_results.R
source("R/functions/io_helpers.R")
source("R/functions/model_helpers.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(openxlsx)
})

df <- safe_read_rds(path_derived("analysis_dataset_post_qc.rds"))
models <- safe_read_rds(path_derived("fitted_models.rds"))

compute_cluster_summary <- function(df, time_var, status_var) {
  df %>%
    group_by(cluster) %>%
    summarise(
      n = n(),
      events = sum(.data[[status_var]], na.rm = TRUE),
      person_years = sum(.data[[time_var]], na.rm = TRUE) / 365.25,
      .groups = "drop"
    ) %>%
    mutate(
      events_n = sprintf("%d/%d", events, n),
      person_years = round(person_years, 1)
    )
}

time_var <- "survival_days_allcause"

# Aggregate summaries
cluster_summaries <- list()
for (o in names(models)) {
  status_var <- switch(o,
                       all_cause = "status_allcause",
                       cancer    = "status_cancer",
                       cvd       = "status_cvd")
  cluster_summaries[[o]] <- compute_cluster_summary(df, time_var, status_var)
}

# HR tables
extract_block <- function(model_obj, outcome, model_name) {
  extract_cluster_effects(model_obj, cluster_prefix = "cluster") %>%
    mutate(outcome = outcome, model = model_name)
}

hr_tables <- purrr::imap_dfr(models, function(mset, outcome) {
  bind_rows(
    extract_block(mset$M1, outcome, "M1"),
    extract_block(mset$M2, outcome, "M2"),
    extract_block(mset$M3, outcome, "M3")
  )
})

lrt_table <- purrr::imap_dfr(models, function(mset, outcome) {
  data.frame(
    outcome = outcome,
    LRT_cluster_by_chronotype = mset$LRT_cluster_by_chronotype
  )
})

wb <- createWorkbook()
addWorksheet(wb, "Cluster_HR"); writeData(wb, "Cluster_HR", hr_tables)
addWorksheet(wb, "LRT_Interactions"); writeData(wb, "LRT_Interactions", lrt_table)

for (o in names(cluster_summaries)) {
  sheet <- paste0("Cluster_Summary_", o)
  addWorksheet(wb, sheet)
  writeData(wb, sheet, cluster_summaries[[o]])
}

saveWorkbook(wb, path_out("tables", "model_results_aggregate.xlsx"), overwrite = TRUE)
write.csv(lrt_table, path_out("tables", "interaction_lrt_pvalues.csv"), row.names = FALSE)

message("Saved aggregate tables to outputs/tables/. Review before sharing.")
