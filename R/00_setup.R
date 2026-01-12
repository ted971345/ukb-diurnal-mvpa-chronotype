# 00_setup.R
suppressPackageStartupMessages({
  library(yaml)
  library(here)
})

cfg <- yaml::read_yaml(here::here("config.yml"))

dir.create(here::here(cfg$paths$raw_data_dir), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here(cfg$paths$derived_data_dir), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here(cfg$paths$outputs_dir, "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here(cfg$paths$outputs_dir, "figures"), recursive = TRUE, showWarnings = FALSE)

message("Setup complete.")
