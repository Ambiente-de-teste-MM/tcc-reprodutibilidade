# TCC Stage VIII — 06_tabelas.R
# Version: 2026-10-21 v01
# Scope: reporting/serialization layer over validated R2/R3 analytical objects.
#
# IMPORTANT
# - This module does not estimate or re-estimate any model.
# - It only reshapes validated objects into audit/reporting tables and writes files.
# - Numerical authority remains the validated R2/R3 objects and Stage VI oracle.

tcc_table_analysis_data <- function(ctx) {
  ctx$dat[
    ,
    c(
      "country", "iso3", "year",
      "ghgpc_tco2e_excl_lulucf",
      "ghgpc_tco2e_incl_lulucf",
      "gdp_pc_const2015_usd",
      "energy_intensity_kgoe_per_1000_2021ppp_gdp",
      "fossil_share_pct",
      "agri_va_pct_gdp",
      "industry_va_pct_gdp",
      "y_excl", "y_incl", "ln_gdp", "x", "x2",
      "lnIE", "FFS", "AGR", "IND"
    ),
    drop = FALSE
  ]
}

tcc_table_primary_coefficients <- function(primary) {
  out <- do.call(
    rbind,
    lapply(names(primary$group_coef), function(m) {
      data.frame(
        model = m,
        term = names(primary$group_coef[[m]]),
        estimate = as.numeric(primary$group_coef[[m]]),
        outcome = "excluding_LULUCF",
        coefficient_status = "PRIMARY_FROZEN",
        stringsAsFactors = FALSE
      )
    })
  )
  row.names(out) <- NULL
  out
}

tcc_table_country_coefficients <- function(primary) {
  out <- do.call(
    rbind,
    lapply(names(primary$models_common), function(m) {
      do.call(
        rbind,
        lapply(FROZEN_COUNTRIES, function(cc) {
          beta <- primary$models_common[[m]][[cc]]$theta_common
          beta <- beta[names(beta) != "intercept"]
          data.frame(
            model = m,
            iso3 = cc,
            term = names(beta),
            estimate = as.numeric(beta),
            outcome = "excluding_LULUCF",
            stringsAsFactors = FALSE
          )
        })
      )
    })
  )
  row.names(out) <- NULL
  out
}

tcc_table_primary_inference <- function(primary) {
  e1 <- primary$e1$inference
  e1$model <- "E1"
  e1$final_status <- "CONDITIONAL_AFTER_B07_CPR_DIAGNOSTIC"
  e1 <- e1[
    ,
    c("model", "term", "estimate", "robust_se", "z", "p_two_sided", "final_status"),
    drop = FALSE
  ]

  op <- do.call(
    rbind,
    lapply(c("E2", "E3", "E4"), function(m) {
      x <- primary$operational_covariance[[m]]$inference
      data.frame(
        model = m,
        term = x$term,
        estimate = x$estimate,
        robust_se = x$robust_se_operational,
        z = x$z_operational,
        p_two_sided = x$p_two_sided_operational,
        final_status = "CONDITIONAL_OPERATIONAL_INFERENCE",
        stringsAsFactors = FALSE
      )
    })
  )

  out <- rbind(e1, op)
  row.names(out) <- NULL
  out
}

tcc_table_hypotheses <- function(primary) {
  h2_row <- function(term, final_conclusion) {
    x <- primary$H2[primary$H2$term == term, , drop = FALSE]
    data.frame(
      hypothesis = x$hypothesis,
      primary_model = x$primary_model,
      statistic_or_rule = "positive coefficient + two-sided p < 0.05",
      primary_estimate = x$primary_estimate,
      primary_p = x$primary_p_two_sided,
      primary_support = x$primary_supported_operationally,
      stability_model = x$stability_model,
      stability_estimate = x$stability_estimate,
      stability_p = x$stability_p_two_sided,
      stability_support = x$e4_supported_operationally,
      final_conclusion = final_conclusion,
      final_status = "CONDITIONAL_OPERATIONAL_INFERENCE",
      stringsAsFactors = FALSE
    )
  }

  h1 <- data.frame(
    hypothesis = "H1_EKC_inverted_U",
    primary_model = "E1",
    statistic_or_rule = "negative quadratic + turning point in support + endpoint IUT",
    primary_estimate = primary$H1$beta_income2,
    primary_p = primary$H1$iut_p,
    primary_support = primary$H1$h1_supported,
    stability_model = NA_character_,
    stability_estimate = NA_real_,
    stability_p = NA_real_,
    stability_support = NA,
    final_conclusion = paste(
      "NOT SUPPORTED by estimated shape;",
      "long-run CPR interpretation not empirically confirmed by B07."
    ),
    final_status = "CONDITIONAL_AFTER_B07_CPR_DIAGNOSTIC",
    stringsAsFactors = FALSE
  )

  h2a <- h2_row(
    "lnIE",
    paste(
      "NOT SUPPORTED under primary operational inference;",
      "direction is fragile to B08 BOL-2000 deletion and remains unsupported with LULUCF."
    )
  )

  h2b <- h2_row(
    "FFS",
    paste(
      "SUPPORTED under primary excluding-LULUCF operational inference;",
      "direction robust to B08 breaks, but support disappears under including-LULUCF sensitivity."
    )
  )

  h3 <- data.frame(
    hypothesis = primary$H3$hypothesis,
    primary_model = primary$H3$primary_model,
    statistic_or_rule = "joint Wald H0: AGR = IND = 0",
    primary_estimate = primary$H3$primary_wald_chisq,
    primary_p = primary$H3$primary_p_joint,
    primary_support = primary$H3$primary_supported_operationally,
    stability_model = primary$H3$stability_model,
    stability_estimate = primary$H3$stability_wald_chisq,
    stability_p = primary$H3$stability_p_joint,
    stability_support = primary$H3$e4_joint_support_operationally,
    final_conclusion = paste(
      "SUPPORTED jointly under primary excluding-LULUCF operational inference;",
      "positive reduced-sample E3 signs survive B08, but joint support disappears with LULUCF."
    ),
    final_status = "CONDITIONAL_OPERATIONAL_INFERENCE",
    stringsAsFactors = FALSE
  )

  out <- rbind(h1, h2a, h2b, h3)
  row.names(out) <- NULL
  out
}

tcc_table_b09_hypotheses <- function(b09) {
  out <- rbind(
    data.frame(
      hypothesis = "H1_EKC_inverted_U",
      model = "E1",
      estimate_or_statistic = b09$H1$beta_income2,
      p_value = b09$H1$iut_p,
      supported = b09$H1$h1_supported_by_estimated_shape,
      status = b09$H1$inference_status,
      stringsAsFactors = FALSE
    ),
    data.frame(
      hypothesis = b09$H2$hypothesis,
      model = b09$H2$primary_model,
      estimate_or_statistic = b09$H2$primary_estimate,
      p_value = b09$H2$primary_p_two_sided,
      supported = b09$H2$primary_supported_operationally,
      status = b09$H2$inference_status,
      stringsAsFactors = FALSE
    ),
    data.frame(
      hypothesis = b09$H3$hypothesis,
      model = b09$H3$primary_model,
      estimate_or_statistic = b09$H3$primary_wald_chisq,
      p_value = b09$H3$primary_p_joint,
      supported = b09$H3$primary_supported_operationally,
      status = b09$H3$inference_status,
      stringsAsFactors = FALSE
    )
  )
  row.names(out) <- NULL
  out
}

tcc_table_raw_tests <- function(primary, diagnostics, b09) {
  rows <- list()

  e1 <- tcc_table_primary_inference(primary)
  e1 <- e1[e1$model == "E1", , drop = FALSE]
  for (i in seq_len(nrow(e1))) {
    x <- e1[i, ]
    rows[[length(rows) + 1L]] <- data.frame(
      block = "PRIMARY", test = "E1 coefficient z", model = "E1",
      iso3 = NA_character_, term = x$term, statistic_name = "z",
      statistic = x$z, p_value = x$p_two_sided,
      decision = ifelse(x$p_two_sided < ALPHA_PRIMARY, "p<0.05", "p>=0.05"),
      status = x$final_status, stringsAsFactors = FALSE
    )
  }

  for (m in c("E2", "E3", "E4")) {
    x <- primary$operational_covariance[[m]]$inference
    for (i in seq_len(nrow(x))) {
      y <- x[i, ]
      rows[[length(rows) + 1L]] <- data.frame(
        block = "PRIMARY", test = "Operational coefficient z", model = m,
        iso3 = NA_character_, term = y$term, statistic_name = "z",
        statistic = y$z_operational, p_value = y$p_two_sided_operational,
        decision = ifelse(y$p_two_sided_operational < ALPHA_PRIMARY, "p<0.05", "p>=0.05"),
        status = "CONDITIONAL_OPERATIONAL_INFERENCE", stringsAsFactors = FALSE
      )
    }
  }

  rows[[length(rows) + 1L]] <- data.frame(
    block = "PRIMARY", test = "H1 endpoint IUT", model = "E1",
    iso3 = NA_character_, term = "income_shape", statistic_name = "IUT_p",
    statistic = primary$H1$iut_p, p_value = primary$H1$iut_p,
    decision = ifelse(primary$H1$h1_supported, "H1 supported", "H1 not supported"),
    status = "CONDITIONAL_AFTER_B07_CPR_DIAGNOSTIC", stringsAsFactors = FALSE
  )

  rows[[length(rows) + 1L]] <- data.frame(
    block = "PRIMARY", test = "H3 joint Wald", model = "E3",
    iso3 = NA_character_, term = "AGR+IND", statistic_name = "chi_square",
    statistic = primary$H3$primary_wald_chisq, p_value = primary$H3$primary_p_joint,
    decision = ifelse(primary$H3$primary_supported_operationally, "reject joint zero", "fail to reject joint zero"),
    status = "CONDITIONAL_OPERATIONAL_INFERENCE", stringsAsFactors = FALSE
  )

  d <- diagnostics$country_residual_diagnostics
  for (i in seq_len(nrow(d))) {
    x <- d[i, ]
    rows[[length(rows) + 1L]] <- data.frame(
      block = "B07", test = "BG-LM(1)", model = x$model,
      iso3 = x$iso3, term = "residual", statistic_name = "LM",
      statistic = x$bg_lm1, p_value = x$bg_lm1_p,
      decision = ifelse(x$bg_reject_no_serial_at_5pct, "reject no-serial-correlation", "fail to reject"),
      status = "AUXILIARY_RESIDUAL_DIAGNOSTIC", stringsAsFactors = FALSE
    )
    rows[[length(rows) + 1L]] <- data.frame(
      block = "B07", test = "Residual trend", model = x$model,
      iso3 = x$iso3, term = "year", statistic_name = "trend_slope",
      statistic = x$trend_slope, p_value = x$trend_p,
      decision = ifelse(x$trend_reject_zero_at_5pct, "reject zero trend", "fail to reject"),
      status = "AUXILIARY_RESIDUAL_DIAGNOSTIC", stringsAsFactors = FALSE
    )
    rows[[length(rows) + 1L]] <- data.frame(
      block = "B07", test = "BP-type heteroskedasticity", model = x$model,
      iso3 = x$iso3, term = "residual_variance", statistic_name = "LM",
      statistic = x$bp_lm, p_value = x$bp_p,
      decision = ifelse(x$bp_reject_homoskedasticity_at_5pct, "reject homoskedasticity", "fail to reject"),
      status = "AUXILIARY_RESIDUAL_DIAGNOSTIC", stringsAsFactors = FALSE
    )
  }

  for (i in seq_len(nrow(diagnostics$pesaran_cd))) {
    x <- diagnostics$pesaran_cd[i, ]
    rows[[length(rows) + 1L]] <- data.frame(
      block = "B07", test = "Pesaran residual CD", model = x$model,
      iso3 = NA_character_, term = "residuals", statistic_name = "CD",
      statistic = x$pesaran_cd, p_value = x$pesaran_cd_p,
      decision = ifelse(x$reject_cross_section_independence_at_5pct, "reject cross-section independence", "fail to reject"),
      status = x$status, stringsAsFactors = FALSE
    )
  }

  for (i in seq_len(nrow(diagnostics$e1_cpr_gate))) {
    x <- diagnostics$e1_cpr_gate[i, ]
    rows[[length(rows) + 1L]] <- data.frame(
      block = "B07", test = "CPR CT", model = "E1",
      iso3 = x$iso3, term = "cointegration", statistic_name = "CT",
      statistic = x$CT, p_value = NA_real_,
      decision = ifelse(x$CT_reject_cointegration_null, "reject cointegration null", "fail to reject cointegration null"),
      status = x$status, stringsAsFactors = FALSE
    )
    rows[[length(rows) + 1L]] <- data.frame(
      block = "B07", test = "CPR P_u", model = "E1",
      iso3 = x$iso3, term = "no_cointegration", statistic_name = "P_u",
      statistic = x$PU, p_value = NA_real_,
      decision = ifelse(x$PU_reject_no_cointegration_null, "reject no-cointegration null", "fail to reject no-cointegration null"),
      status = x$decision, stringsAsFactors = FALSE
    )
  }

  for (i in seq_len(nrow(b09$residual_cd))) {
    x <- b09$residual_cd[i, ]
    rows[[length(rows) + 1L]] <- data.frame(
      block = "B09", test = "Pesaran residual CD including LULUCF", model = x$model,
      iso3 = NA_character_, term = "residuals", statistic_name = "CD",
      statistic = x$pesaran_cd, p_value = x$pesaran_cd_p,
      decision = ifelse(x$reject_cross_section_independence_at_5pct, "reject cross-section independence", "fail to reject"),
      status = x$status, stringsAsFactors = FALSE
    )
  }

  for (i in seq_len(nrow(b09$e1_cpr_gate))) {
    x <- b09$e1_cpr_gate[i, ]
    rows[[length(rows) + 1L]] <- data.frame(
      block = "B09", test = "CPR CT including LULUCF", model = "E1",
      iso3 = x$iso3, term = "cointegration", statistic_name = "CT",
      statistic = x$CT, p_value = NA_real_,
      decision = ifelse(x$CT_reject_cointegration_null, "reject cointegration null", "fail to reject cointegration null"),
      status = x$status, stringsAsFactors = FALSE
    )
    rows[[length(rows) + 1L]] <- data.frame(
      block = "B09", test = "CPR P_u including LULUCF", model = "E1",
      iso3 = x$iso3, term = "no_cointegration", statistic_name = "P_u",
      statistic = x$PU, p_value = NA_real_,
      decision = ifelse(x$PU_reject_no_cointegration_null, "reject no-cointegration null", "fail to reject no-cointegration null"),
      status = x$decision, stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

tcc_build_reporting_tables <- function(ctx, primary, diagnostics, sensitivities) {
  stopifnot(identical(primary$y_field, "y_excl"))
  b08 <- sensitivities$B08
  b09 <- sensitivities$B09

  sample_method <- data.frame(
    field = c(
      "Project", "Primary sample countries", "Period", "N countries",
      "T years", "NT primary observations", "Primary outcome",
      "Sensitivity outcome", "GDP center ln(GDPpc)",
      "GDP centered support lower", "GDP centered support upper",
      "FM kernel", "FM bandwidth", "Primary country weighting",
      "E1 final inferential status", "E2-E4 final inferential status",
      "Primary coefficient status", "B08 status", "B09 status"
    ),
    value = c(
      "P004 - TCC",
      paste(FROZEN_COUNTRIES, collapse = ", "),
      paste0(EXPECTED_START_YEAR, "-", EXPECTED_END_YEAR),
      length(FROZEN_COUNTRIES), EXPECTED_YEAR_COUNT, nrow(ctx$dat),
      "ln(GHGpc excluding LULUCF)",
      "ln(GHGpc including LULUCF)",
      ctx$common_gdp_center, ctx$x_lower, ctx$x_upper,
      FROZEN_FM_KERNEL, FROZEN_FM_BANDWIDTH,
      "Equal-country group mean (20% each)",
      "CONDITIONAL_AFTER_B07_CPR_DIAGNOSTIC",
      "CONDITIONAL_OPERATIONAL_INFERENCE",
      "FROZEN_BARRING_CODE_OR_DATA_ERROR",
      "POINT_ESTIMATE_SENSITIVITY_ONLY",
      "CONDITIONAL_OUTCOME_BOUNDARY_SENSITIVITY"
    ),
    stringsAsFactors = FALSE
  )

  run_status <- data.frame(
    block = c("PRIMARY_R2", "B07_R2", "B08_R3", "B09_R3"),
    status = c("PASS", "PASS_WITH_MATERIAL_INFERENTIAL_LIMITATION",
               "PASS_WITH_MEANINGFUL_SENSITIVITY", "PASS_OUTCOME_BOUNDARY_MATERIAL"),
    consequence = c(
      "Primary E1-E4 coefficients reproduced/frozen",
      "E1 long-run CPR inference conditional; coefficients unchanged",
      "Break sensitivities qualify robustness; coefficients unchanged",
      "Including-LULUCF materially changes associations; primary outcome unchanged"
    ),
    stringsAsFactors = FALSE
  )

  provenance <- data.frame(
    artifact_or_source = c(
      "Canonical input", "01_configuracao.R", "02_preparacao_dados.R",
      "03_diagnosticos.R", "04_estimacao_principal.R", "05_sensibilidades.R"
    ),
    path_or_value = c(
      ctx$source_path,
      "R/01_configuracao.R", "R/02_preparacao_dados.R",
      "R/03_diagnosticos.R", "R/04_estimacao_principal.R", "R/05_sensibilidades.R"
    ),
    role = c(
      "authoritative analytical input",
      "frozen settings and portable paths",
      "certified analytical-panel loader/transforms",
      "post-estimation diagnostics",
      "primary E1-E4 estimation/inference",
      "B08/B09 sensitivity analysis"
    ),
    stringsAsFactors = FALSE
  )

  list(
    Run_Status = run_status,
    Sample_Method = sample_method,
    Analysis_Data = tcc_table_analysis_data(ctx),
    Primary_Coefs = tcc_table_primary_coefficients(primary),
    Country_Coefs = tcc_table_country_coefficients(primary),
    Primary_Inference = tcc_table_primary_inference(primary),
    Hypotheses = tcc_table_hypotheses(primary),
    E4_Stability = primary$E4_stability,
    B07_Country_Diag = diagnostics$country_residual_diagnostics,
    B07_Residual_CD = diagnostics$pesaran_cd,
    B07_Pairs = diagnostics$residual_pairwise_correlations,
    B07_CPR = diagnostics$e1_cpr_gate,
    B08_Breaks = b08$primary_vs_reduced,
    B08_Drivers = b08$e4_one_at_a_time_comparison,
    B08_Summary = b08$model_summary,
    B09_Coefs = b09$group_coefficient_table,
    B09_Compare = b09$primary_vs_lulucf,
    B09_Hypotheses = tcc_table_b09_hypotheses(b09),
    B09_Residual_CD = b09$residual_cd,
    B09_CPR = b09$e1_cpr_gate,
    B09_Outcome = b09$outcome_summary,
    Raw_Tests = tcc_table_raw_tests(primary, diagnostics, b09),
    Provenance = provenance
  )
}

tcc_write_reporting_tables <- function(
    tables,
    output_dir = PATH_TABLES,
    workbook_name = "tcc_resultados-empiricos.xlsx") {

  tcc_require_packages(PKG_REQUIRED_TABLES)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  csv_dir <- file.path(output_dir, "csv")
  dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

  public_csv_names <- c(
    Primary_Inference = "inferencia_principal.csv"
  )

  csv_paths <- vapply(
    names(tables),
    function(nm) {
      file_name <- if (nm %in% names(public_csv_names)) {
        unname(public_csv_names[[nm]])
      } else {
        paste0(tolower(nm), ".csv")
      }
      p <- file.path(csv_dir, file_name)
      utils::write.csv(tables[[nm]], p, row.names = FALSE, na = "")
      p
    },
    character(1)
  )

  wb <- openxlsx::createWorkbook(creator = "P004 TCC Stage VIII")
  header <- openxlsx::createStyle(
    fontColour = "#FFFFFF", fgFill = "#1F4E78",
    halign = "center", valign = "center", textDecoration = "bold"
  )
  numeric_style <- openxlsx::createStyle(numFmt = "0.000000")

  for (nm in names(tables)) {
    sheet <- substr(nm, 1L, 31L)
    x <- tables[[nm]]
    openxlsx::addWorksheet(wb, sheet)
    openxlsx::writeData(wb, sheet, x, withFilter = TRUE, headerStyle = header)
    openxlsx::freezePane(wb, sheet, firstRow = TRUE)

    if (ncol(x)) {
      openxlsx::setColWidths(wb, sheet, cols = seq_len(ncol(x)), widths = "auto")
    }
    if (nrow(x)) {
      num_cols <- which(vapply(x, is.numeric, logical(1)))
      if (length(num_cols)) {
        openxlsx::addStyle(
          wb, sheet, numeric_style,
          rows = 2:(nrow(x) + 1L), cols = num_cols,
          gridExpand = TRUE, stack = TRUE
        )
      }
    }
  }

  workbook_path <- file.path(output_dir, workbook_name)
  openxlsx::saveWorkbook(wb, workbook_path, overwrite = TRUE)

  list(
    tables = tables,
    csv_paths = csv_paths,
    workbook_path = workbook_path,
    workbook_md5 = unname(tools::md5sum(workbook_path))
  )
}

tcc_run_tables <- function(ctx, primary, diagnostics, sensitivities, output_dir = PATH_TABLES) {
  tables <- tcc_build_reporting_tables(ctx, primary, diagnostics, sensitivities)
  tcc_write_reporting_tables(tables, output_dir = output_dir)
}
