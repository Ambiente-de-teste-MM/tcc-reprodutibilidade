# TCC Stage VIII — execução analítica completa no navegador
# Browser orchestration only. Analytical functions are sourced from exact copies
# of the canonical reproducibility modules R/01-05.

# Quarto executes this file with site/ as its working directory, while CI may
# source it from the repository root. Resolve both supported execution contexts
# explicitly instead of depending on a single working-directory assumption.
TCC_WEB_MODULE_ROOT <- if (dir.exists("recursos/execucao-web/modules")) {
  "recursos/execucao-web/modules"
} else if (dir.exists("site/recursos/execucao-web/modules")) {
  "site/recursos/execucao-web/modules"
} else {
  stop("Diretório dos módulos analíticos do navegador não localizado.")
}

TCC_WEB_MODULES <- file.path(
  TCC_WEB_MODULE_ROOT,
  c(
    "01_configuracao.R",
    "02_preparacao_dados.R",
    "03_diagnosticos.R",
    "04_estimacao_principal.R",
    "05_sensibilidades.R"
  )
)

if (!all(file.exists(TCC_WEB_MODULES))) {
  stop(
    "Módulos analíticos do navegador ausentes: ",
    paste(TCC_WEB_MODULES[!file.exists(TCC_WEB_MODULES)], collapse = ", ")
  )
}

for (f in TCC_WEB_MODULES) {
  source(f, local = .GlobalEnv, echo = FALSE, print.eval = FALSE)
}

# A rota pública do navegador parte do painel canônico já processado. Portanto,
# readxl — necessário apenas para reconstruir as planilhas-fonte WDI na rota local
# completa — não é uma dependência de execução desta superfície web.
PKG_REQUIRED_CORE <- "cointReg"

TCC_WEB_TOLERANCE <- 1e-6
TCC_WEB_EXPECTED_GROUP <- list(
  E1 = c(income = 1.286757988, income2 = 0.147584072),
  E2 = c(
    income = 1.114499578, income2 = 0.155821737,
    lnIE = 0.048050301, FFS = 0.013193687
  ),
  E3 = c(
    income = 1.107882406, income2 = 0.062383006,
    AGR = 0.012283778, IND = 0.006994105
  ),
  E4 = c(
    income = 0.974014266, income2 = -0.075128704,
    lnIE = 0.055122314, FFS = 0.010581815,
    AGR = 0.009670656, IND = 0.007620360
  )
)


tcc_web_compare_primary <- function(primary) {
  rows <- lapply(names(TCC_WEB_EXPECTED_GROUP), function(model) {
    estimate <- primary$group_coef[[model]]
    reference <- TCC_WEB_EXPECTED_GROUP[[model]]
    stopifnot(identical(names(estimate), names(reference)))

    data.frame(
      model = model,
      term = names(reference),
      estimate = as.numeric(estimate),
      reference = as.numeric(reference),
      difference = as.numeric(estimate - reference),
      abs_difference = abs(as.numeric(estimate - reference)),
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out$within_tolerance <- out$abs_difference <= TCC_WEB_TOLERANCE
  out
}


tcc_web_hypothesis_summary <- function(primary, sensitivities) {
  h2 <- primary$H2
  b09 <- sensitivities$B09

  data.frame(
    hypothesis = c("H1", "H2a", "H2b", "H3"),
    primary_supported = c(
      isTRUE(primary$H1$h1_supported),
      isTRUE(h2$primary_supported_operationally[h2$term == "lnIE"]),
      isTRUE(h2$primary_supported_operationally[h2$term == "FFS"]),
      isTRUE(primary$H3$primary_supported_operationally)
    ),
    including_lulucf_supported = c(
      isTRUE(b09$H1$h1_supported_by_estimated_shape),
      isTRUE(b09$H2$primary_supported_operationally[b09$H2$term == "lnIE"]),
      isTRUE(b09$H2$primary_supported_operationally[b09$H2$term == "FFS"]),
      isTRUE(b09$H3$primary_supported_operationally)
    ),
    stringsAsFactors = FALSE
  )
}


tcc_web_run_full <- function(data_path, validate = TRUE) {
  stopifnot(requireNamespace("cointReg", quietly = TRUE))

  ctx <- tcc_build_analysis_context(data_path)
  primary <- tcc_run_primary_analysis(ctx, y_field = "y_excl")
  diagnostics <- tcc_run_b07_diagnostics(ctx, primary, y_field = "y_excl")
  sensitivities <- tcc_run_sensitivities(ctx, primary)

  comparison <- tcc_web_compare_primary(primary)
  hypothesis_summary <- tcc_web_hypothesis_summary(primary, sensitivities)
  max_abs_diff <- max(comparison$abs_difference)

  if (isTRUE(validate)) {
    stopifnot(nrow(ctx$dat) == EXPECTED_ROW_COUNT)
    stopifnot(is.finite(max_abs_diff), max_abs_diff <= TCC_WEB_TOLERANCE)
    stopifnot(all(comparison$within_tolerance))

    # Substantive guards reproduce the accepted Stage VI/Stage VIII conclusions.
    stopifnot(identical(hypothesis_summary$primary_supported, c(FALSE, FALSE, TRUE, TRUE)))
    stopifnot(
      !isTRUE(hypothesis_summary$including_lulucf_supported[3L]),
      !isTRUE(hypothesis_summary$including_lulucf_supported[4L])
    )
  }

  list(
    context = ctx,
    primary = primary,
    diagnostics = diagnostics,
    sensitivities = sensitivities,
    comparison = comparison,
    hypothesis_summary = hypothesis_summary,
    max_abs_diff = max_abs_diff,
    tolerance = TCC_WEB_TOLERANCE
  )
}


tcc_web_primary_display <- function(result) {
  x <- result$primary$group_coefficient_table
  x$estimate <- round(x$estimate, 6)
  x
}


tcc_web_diagnostics_display <- function(result) {
  list(
    country_summary = result$diagnostics$country_residual_summary,
    residual_cd = result$diagnostics$pesaran_cd,
    e1_cpr = result$diagnostics$e1_cpr_gate,
    e1_cpr_summary = result$diagnostics$e1_cpr_gate_summary
  )
}


tcc_web_sensitivities_display <- function(result) {
  list(
    b08_model_summary = result$sensitivities$B08$model_summary,
    b08_primary_vs_reduced = result$sensitivities$B08$primary_vs_reduced,
    b09_outcome_summary = result$sensitivities$B09$outcome_summary,
    b09_primary_vs_lulucf = result$sensitivities$B09$primary_vs_lulucf,
    hypotheses = result$hypothesis_summary
  )
}
