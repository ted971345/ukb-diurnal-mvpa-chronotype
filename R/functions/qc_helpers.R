# functions/qc_helpers.R
suppressPackageStartupMessages({
  library(dplyr)
})

compute_iqr_threshold <- function(x, k = 1.5) {
  x <- x[is.finite(x)]
  q3 <- as.numeric(stats::quantile(x, 0.75, na.rm = TRUE))
  iqr <- stats::IQR(x, na.rm = TRUE)
  q3 + k * iqr
}

apply_nocturnal_error_exclusion <- function(df,
                                           nocturnal_var = "Noctural_percentage_1am_4am",
                                           error_var = "error_accelerometer",
                                           nocturnal_cut = 10,
                                           k = 1.5) {
  if (!all(c(nocturnal_var, error_var) %in% names(df))) {
    stop("QC variables not found: ", nocturnal_var, ", ", error_var)
  }
  thr <- compute_iqr_threshold(df[[error_var]], k = k)
  flag <- (df[[nocturnal_var]] > nocturnal_cut) & (df[[error_var]] > thr)
  list(
    data = df[!flag | is.na(flag), , drop = FALSE],
    excluded_n = sum(flag, na.rm = TRUE),
    threshold = thr
  )
}

as_binary01 <- function(x) {
  # returns numeric 0/1 or NA
  if (is.logical(x)) return(as.integer(x))
  if (is.numeric(x)) {
    ux <- unique(x[!is.na(x)])
    if (all(ux %in% c(0,1))) return(as.integer(x))
  }
  if (is.factor(x) || is.character(x)) {
    xx <- as.character(x)
    if (all(unique(xx[!is.na(xx)]) %in% c("0","1"))) return(as.integer(xx))
    if (all(unique(xx[!is.na(xx)]) %in% c("No","Yes"))) return(as.integer(xx == "Yes"))
  }
  stop("Cannot coerce to binary 0/1 safely. Inspect your variable coding.")
}
