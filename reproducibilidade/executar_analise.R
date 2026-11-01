# TCC Stage VIII — executar_analise.R (distribuição pública)
# Purpose: reproduce the published analysis from the distributed canonical panel.
# The private canonical implementation additionally certifies reconstruction from
# preserved provider snapshots; those third-party snapshots are not redistributed.

options(stringsAsFactors = FALSE)
options(scipen = 999)

MODULES <- file.path(
  "R",
  c(
    "01_configuracao.R",
    "02_preparacao_dados.R",
    "03_diagnosticos.R",
    "04_estimacao_principal.R",
    "05_sensibilidades.R",
    "06_tabelas.R",
    "07_figuras.R"
  )
)

if (!all(file.exists(MODULES))) {
  stop("Missing reproducibility modules: ", paste(MODULES[!file.exists(MODULES)], collapse = ", "))
}

for (f in MODULES) source(f, local = .GlobalEnv, echo = FALSE, print.eval = FALSE)

# readxl is required only by the private raw-source reconstruction path.
PKG_REQUIRED_CORE <- "cointReg"

tcc_require_packages(unique(c(
  PKG_REQUIRED_CORE,
  PKG_REQUIRED_TABLES,
  PKG_REQUIRED_FIGURES
)))

tcc_create_output_dirs()

# Operational helpers ----------------------------------------------------------
tcc_relpath <- function(paths, root = PROJECT_ROOT) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  paths <- normalizePath(paths, winslash = "/", mustWork = TRUE)
  prefix <- paste0(root, "/")
  ifelse(startsWith(paths, prefix), substring(paths, nchar(prefix) + 1L), paths)
}

tcc_file_manifest <- function(paths, root = PROJECT_ROOT) {
  paths <- sort(unique(paths[file.exists(paths) & !dir.exists(paths)]))
  if (!length(paths)) {
    return(data.frame(
      path = character(0), bytes = numeric(0), md5 = character(0),
      stringsAsFactors = FALSE
    ))
  }
  data.frame(
    path = tcc_relpath(paths, root = root),
    bytes = as.numeric(file.info(paths)$size),
    md5 = unname(tools::md5sum(paths)),
    stringsAsFactors = FALSE
  )
}

tcc_write_df <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(x, path, row.names = FALSE, na = "")
  invisible(path)
}

input_paths <- c(
  MODULES,
  "executar_analise.R",
  CANONICAL_INPUT_PATH,
  if (file.exists("README.md")) "README.md" else character(0)
)
input_manifest_pre <- tcc_file_manifest(input_paths)
tcc_write_df(input_manifest_pre, file.path(PATH_LOGS, "input_manifest_pre.csv"))

cat("[1/6] validar painel canônico + preparar transformações\n")
ctx <- tcc_build_analysis_context(CANONICAL_INPUT_PATH)
stopifnot(nrow(ctx$dat) == EXPECTED_ROW_COUNT)
stopifnot(identical(unname(tools::md5sum(CANONICAL_INPUT_PATH)), EXPECTED_CANONICAL_MD5))

cat("[2/6] estimação principal E1-E4\n")
primary <- tcc_run_primary_analysis(ctx, y_field = "y_excl")

cat("[3/6] diagnósticos B07\n")
diagnostics <- tcc_run_b07_diagnostics(ctx, primary, y_field = "y_excl")

cat("[4/6] sensibilidades B08/B09\n")
sensitivities <- tcc_run_sensitivities(ctx, primary)

cat("[5/6] tabelas e figuras\n")
table_result <- tcc_run_tables(
  ctx, primary, diagnostics, sensitivities,
  output_dir = PATH_TABLES
)
figure_result <- tcc_run_figures(
  ctx, primary,
  output_dir = PATH_FIGURES,
  font_requested = "Times New Roman"
)

cat("[6/6] ambiente, estado consolidado e manifestos\n")
env <- tcc_environment_record()
environment_table <- tcc_environment_table(env)
tcc_write_df(environment_table, CURRENT_ENVIRONMENT_PATH)

if (file.exists(REFERENCE_ENVIRONMENT_PATH)) {
  reference_environment <- utils::read.csv(
    REFERENCE_ENVIRONMENT_PATH,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  stopifnot(all(c("campo", "valor") %in% names(reference_environment)))

  environment_comparison <- merge(
    reference_environment[, c("campo", "valor")],
    environment_table[, c("campo", "valor")],
    by = "campo",
    all = TRUE,
    suffixes = c("_referencia", "_execucao")
  )
  environment_comparison$igual <- with(
    environment_comparison,
    !is.na(valor_referencia) & !is.na(valor_execucao) &
      valor_referencia == valor_execucao
  )
  tcc_write_df(environment_comparison, ENVIRONMENT_COMPARISON_PATH)
}

package_versions <- data.frame(
  package = names(env$package_versions),
  version = unname(env$package_versions),
  stringsAsFactors = FALSE
)
tcc_write_df(package_versions, file.path(PATH_LOGS, "package_versions.csv"))
writeLines(capture.output(sessionInfo()), file.path(PATH_LOGS, "sessionInfo.txt"), useBytes = TRUE)

run_summary <- data.frame(
  item = c(
    "analysis_source",
    "canonical_md5",
    "gdp_center",
    "x_lower",
    "x_upper",
    "h1_supported",
    "h2a_lnIE_supported",
    "h2b_FFS_supported",
    "h3_supported",
    "b07_cpr_for",
    "b07_cpr_against",
    "b07_cpr_conflicting",
    "b09_cpr_for",
    "b09_cpr_against",
    "b09_cpr_conflicting",
    "reporting_table_count",
    "figure_manifest_rows"
  ),
  value = c(
    "distributed_canonical_panel",
    unname(tools::md5sum(CANONICAL_INPUT_PATH)),
    format(ctx$common_gdp_center, digits = 17),
    format(ctx$x_lower, digits = 17),
    format(ctx$x_upper, digits = 17),
    as.character(primary$H1$h1_supported),
    as.character(primary$H2$primary_supported_operationally[primary$H2$term == "lnIE"]),
    as.character(primary$H2$primary_supported_operationally[primary$H2$term == "FFS"]),
    as.character(primary$H3$primary_supported_operationally),
    as.character(diagnostics$e1_cpr_gate_summary$countries_evidence_for),
    as.character(diagnostics$e1_cpr_gate_summary$countries_evidence_against),
    as.character(diagnostics$e1_cpr_gate_summary$countries_conflicting),
    as.character(sensitivities$B09$e1_cpr_gate_summary$countries_evidence_for),
    as.character(sensitivities$B09$e1_cpr_gate_summary$countries_evidence_against),
    as.character(sensitivities$B09$e1_cpr_gate_summary$countries_conflicting),
    as.character(length(table_result$tables)),
    as.character(nrow(figure_result$manifest))
  ),
  stringsAsFactors = FALSE
)
tcc_write_df(run_summary, file.path(PATH_LOGS, "run_summary.csv"))

# Substantive publication guards.
stopifnot(
  identical(
    c(
      isTRUE(primary$H1$h1_supported),
      isTRUE(primary$H2$primary_supported_operationally[primary$H2$term == "lnIE"]),
      isTRUE(primary$H2$primary_supported_operationally[primary$H2$term == "FFS"]),
      isTRUE(primary$H3$primary_supported_operationally)
    ),
    c(FALSE, FALSE, TRUE, TRUE)
  )
)
stopifnot(
  !isTRUE(sensitivities$B09$H2$primary_supported_operationally[sensitivities$B09$H2$term == "FFS"]),
  !isTRUE(sensitivities$B09$H3$primary_supported_operationally)
)

run_state <- list(
  run_version = "2026-10-30-public-distribution-v01",
  certification_status = "PUBLIC_CANONICAL_PANEL_ROUTE",
  analysis_source = "distributed_canonical_panel",
  environment = env,
  context = list(
    common_gdp_center = ctx$common_gdp_center,
    x_lower = ctx$x_lower,
    x_upper = ctx$x_upper,
    source_path = ctx$source_path,
    source_md5 = ctx$source_md5
  ),
  primary = primary,
  diagnostics = diagnostics,
  sensitivities = sensitivities,
  tables = list(
    csv_paths = table_result$csv_paths,
    workbook_path = table_result$workbook_path,
    workbook_md5 = table_result$workbook_md5
  ),
  figures = list(
    metadata = figure_result$figures$metadata,
    manifest = figure_result$manifest,
    manifest_path = figure_result$manifest_path
  ),
  run_summary = run_summary
)

run_rds <- file.path(PATH_MODELS, "tcc_reproducibility_run_state.rds")
saveRDS(run_state, run_rds)

input_manifest_post <- tcc_file_manifest(input_paths)
tcc_write_df(input_manifest_post, file.path(PATH_LOGS, "input_manifest_post.csv"))
stopifnot(identical(input_manifest_pre, input_manifest_post))

output_manifest_path <- file.path(PATH_LOGS, "output_manifest.csv")
output_files <- list.files(RESULT_ROOT, recursive = TRUE, full.names = TRUE)
output_files <- output_files[file.exists(output_files) & !dir.exists(output_files)]
output_files <- setdiff(
  normalizePath(output_files, winslash = "/", mustWork = TRUE),
  normalizePath(output_manifest_path, winslash = "/", mustWork = FALSE)
)
output_manifest <- tcc_file_manifest(output_files)
tcc_write_df(output_manifest, output_manifest_path)

cat("============================================================\n")
cat("TCC PUBLIC REPRODUCIBILITY PIPELINE PASS\n")
cat("Analysis source: distributed canonical panel\n")
cat("Canonical MD5:", unname(tools::md5sum(CANONICAL_INPUT_PATH)), "\n")
cat("Reporting tables:", length(table_result$tables), "\n")
cat("Figure files in manifest:", nrow(figure_result$manifest), "\n")
cat("Run state:", run_rds, "\n")
cat("Results root:", RESULT_ROOT, "\n")
cat("============================================================\n")
