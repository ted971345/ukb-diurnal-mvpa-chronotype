# functions/io_helpers.R
suppressPackageStartupMessages({
  library(here)
  library(yaml)
})

read_config <- function() yaml::read_yaml(here::here("config.yml"))

path_raw <- function(filename) {
  cfg <- read_config()
  here::here(cfg$paths$raw_data_dir, filename)
}

path_derived <- function(filename) {
  cfg <- read_config()
  here::here(cfg$paths$derived_data_dir, filename)
}

path_out <- function(...) {
  cfg <- read_config()
  here::here(cfg$paths$outputs_dir, ...)
}

safe_read_rds <- function(path) {
  if (!file.exists(path)) stop("File not found: ", path)
  readRDS(path)
}

safe_write_rds <- function(x, path) saveRDS(x, path)
