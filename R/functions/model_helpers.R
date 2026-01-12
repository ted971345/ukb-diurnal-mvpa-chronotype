# functions/model_helpers.R
suppressPackageStartupMessages({
  library(survival)
  library(broom)
  library(dplyr)
  library(stringr)
})

fit_cox <- function(df, time_var, status_var, rhs_terms, robust = TRUE, subset_expr = NULL) {
  fml <- as.formula(paste0("Surv(", time_var, ", ", status_var, ") ~ ", rhs_terms))
  if (is.null(subset_expr)) {
    survival::coxph(fml, data = df, robust = robust, na.action = na.omit)
  } else {
    survival::coxph(fml, data = df, robust = robust, subset = subset_expr, na.action = na.omit)
  }
}

extract_cluster_effects <- function(model, cluster_prefix = "cluster") {
  broom::tidy(model, exponentiate = TRUE, conf.int = TRUE) %>%
    filter(str_detect(term, paste0("^", cluster_prefix))) %>%
    mutate(
      HR_CI = sprintf("%.2f (%.2f, %.2f)", estimate, conf.low, conf.high),
      p_value = case_when(
        is.na(p.value) ~ NA_character_,
        p.value < 0.001 ~ "<0.001",
        TRUE ~ sprintf("%.3f", p.value)
      )
    ) %>%
    select(term, HR_CI, p_value)
}

lr_test_interaction <- function(df, time_var, status_var, rhs_terms, interaction_term) {
  base <- survival::coxph(as.formula(paste0("Surv(", time_var, ", ", status_var, ") ~ ", rhs_terms)),
                          data = df, robust = FALSE, na.action = na.omit)
  intm <- survival::coxph(as.formula(paste0("Surv(", time_var, ", ", status_var, ") ~ ", rhs_terms, " + ", interaction_term)),
                          data = df, robust = FALSE, na.action = na.omit)
  a <- anova(base, intm, test = "LRT")
  pcol <- grep("P\(|Pr\(", colnames(a), value = TRUE, ignore.case = TRUE)[1]
  as.numeric(a[2, pcol])
}
