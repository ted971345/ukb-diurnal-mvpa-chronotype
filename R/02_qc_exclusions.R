# 02_qc_exclusions.R
source("R/functions/io_helpers.R")
source("R/functions/qc_helpers.R")

df <- safe_read_rds(path_derived("analysis_dataset_pre_qc.rds"))

qc <- apply_nocturnal_error_exclusion(
  df,
  nocturnal_var = "noctural_pct_1am_4am",
  error_var     = "error_accelerometer",
  nocturnal_cut = 10,
  k = 1.5
)

df_qc <- qc$data

qc_summary <- data.frame(
  rule = "noctural_pct_1am_4am > 10 AND error_accelerometer > (Q3 + 1.5*IQR)",
  excluded_n = qc$excluded_n,
  threshold = qc$threshold
)

safe_write_rds(df_qc, path_derived("analysis_dataset_post_qc.rds"))
write.csv(qc_summary, path_out("tables", "qc_summary.csv"), row.names = FALSE)

message("Saved post-QC dataset (local): data/derived/analysis_dataset_post_qc.rds")
message("Saved QC summary (aggregate): outputs/tables/qc_summary.csv")
