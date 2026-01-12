# Diurnal MVPA Patterns, Chronotype, and Mortality (UK Biobank)

This repository contains analysis code for a UK Biobank project examining associations between diurnal MVPA pattern clusters, chronotype, and mortality outcomes (all-cause, cancer, cardiovascular).

## UK Biobank Compliance
- This repository **does not** contain UK Biobank individual-level data.
- Do **not** commit, upload, or share any UKB participant-level datasets or derived participant-level files.
- Only analysis code, documentation, and (optionally) sufficiently aggregated outputs are shared.
- See `docs/ukb-compliance.md` for details.

## Reproducibility
We use `renv` to lock package versions.
1. Open the R project.
2. Run:
   ```r
   install.packages("renv")
   renv::restore()
   ```
3. Configure local paths in `config.yml`.
4. Place your local UKB-derived files in `data/raw/` (not committed).

## Pipeline
Run scripts in order:
1. `R/00_setup.R`
2. `R/01_prepare_data.R`
3. `R/02_qc_exclusions.R`
4. `R/03_fit_models.R`
5. `R/04_extract_results.R`
6. `R/05_tables_figures.R`

## Outputs
By default, outputs are saved under `outputs/`. Ensure outputs do not contain participant-level data before sharing.
