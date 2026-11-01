# TCC Stage VIII — 05_sensibilidades.R
# Version: 2026-10-21 v01 (R3 candidate)
# Scope: modular reproduction of frozen Stage VI B08 and B09 sensitivities.
#
# Methodological boundary:
# - B08 remains descriptive point-estimate sensitivity only.
# - The GDP center remains frozen at the full 170-observation primary value.
# - B09 remains a full-sample including-LULUCF outcome-boundary sensitivity.
# - B09 does not cross the B08 exclusions.
# - All B09 inference remains conditional sensitivity evidence after B07.
# - No estimator, hypothesis, sample, or interpretation rule is redesigned.

# -----------------------------------------------------------------------------
# B08 — predefined break/data-quality sensitivities
# -----------------------------------------------------------------------------

tcc_b08_rule_specs <- function(rule) {
  stopifnot(rule %in% names(FROZEN_B08_ALL_RULES))
  FROZEN_B08_ALL_RULES[[rule]]
}

tcc_b08_apply_rule <- function(d, rule) {
  d <- d[order(d$iso3, d$year), , drop = FALSE]
  specs <- tcc_b08_rule_specs(rule)
  keep <- rep(TRUE, nrow(d))

  for (spec in specs) {
    hit <- d$iso3 == spec$iso3 &
      d$year >= spec$year_min &
      d$year <= spec$year_max
    keep[hit] <- FALSE
  }

  d[keep, , drop = FALSE]
}

tcc_b08_gap_audit <- function(d, model, rule) {
  out <- lapply(FROZEN_COUNTRIES, function(cc) {
    x <- d[d$iso3 == cc, , drop = FALSE]
    x <- x[order(x$year), , drop = FALSE]

    gaps <- diff(x$year)
    bad <- which(gaps != 1)

    if (!length(bad)) {
      data.frame(
        model = model,
        rule = rule,
        iso3 = cc,
        n = nrow(x),
        irregular_gap_count = 0L,
        from_year = NA_integer_,
        to_year = NA_integer_,
        gap_years = NA_integer_,
        stringsAsFactors = FALSE
      )
    } else {
      do.call(
        rbind,
        lapply(bad, function(j) {
          data.frame(
            model = model,
            rule = rule,
            iso3 = cc,
            n = nrow(x),
            irregular_gap_count = length(bad),
            from_year = as.integer(x$year[j]),
            to_year = as.integer(x$year[j + 1L]),
            gap_years = as.integer(x$year[j + 1L] - x$year[j]),
            stringsAsFactors = FALSE
          )
        })
      )
    }
  })

  ans <- do.call(rbind, out)
  row.names(ans) <- NULL
  ans
}

tcc_b08_fit_model_rule <- function(ctx, model, rule) {
  stopifnot(model %in% names(FROZEN_MODEL_EXTENSIONS))
  reduced <- tcc_b08_apply_rule(ctx$dat, rule)

  country_local <- lapply(FROZEN_COUNTRIES, function(cc) {
    dcc <- reduced[reduced$iso3 == cc, , drop = FALSE]
    dcc <- dcc[order(dcc$year), , drop = FALSE]
    stopifnot(nrow(dcc) >= 20L)

    tcc_fit_country_fm(
      d = dcc,
      model = model,
      common_center = ctx$common_gdp_center,
      center_mode = "local",
      y_field = "y_excl"
    )
  })
  names(country_local) <- FROZEN_COUNTRIES

  country_common <- lapply(
    country_local,
    tcc_transform_to_common,
    common_center = ctx$common_gdp_center
  )

  slope_matrix <- do.call(
    rbind,
    lapply(country_common, tcc_get_slope_vector)
  )
  row.names(slope_matrix) <- FROZEN_COUNTRIES

  list(
    model = model,
    rule = rule,
    reduced_data = reduced,
    n_total = nrow(reduced),
    country_n = table(reduced$iso3),
    country_local = country_local,
    country_common = country_common,
    slope_matrix = slope_matrix,
    group_mean = colMeans(slope_matrix),
    gap_audit = tcc_b08_gap_audit(reduced, model, rule)
  )
}

tcc_run_b08_sensitivities <- function(ctx, primary) {
  stopifnot(identical(primary$y_field, "y_excl"))
  stopifnot(abs(ctx$common_gdp_center - EXPECTED_GDP_CENTER) < 1e-12)

  reduced <- lapply(names(FROZEN_B08_PRIMARY_SPECS), function(m) {
    tcc_b08_fit_model_rule(
      ctx = ctx,
      model = m,
      rule = unname(FROZEN_B08_PRIMARY_SPECS[[m]])
    )
  })
  names(reduced) <- names(FROZEN_B08_PRIMARY_SPECS)

  for (m in names(reduced)) {
    stopifnot(reduced[[m]]$n_total == EXPECTED_B08_N[[m]])
  }

  compare_rows <- lapply(names(reduced), function(m) {
    sens <- reduced[[m]]$group_mean
    prim <- primary$group_coef[[m]][names(sens)]

    data.frame(
      model = m,
      term = names(sens),
      primary_estimate = as.numeric(prim),
      reduced_estimate = as.numeric(sens),
      change_reduced_minus_primary = as.numeric(sens - prim),
      sign_primary = sign(as.numeric(prim)),
      sign_reduced = sign(as.numeric(sens)),
      sign_preserved = sign(as.numeric(prim)) == sign(as.numeric(sens)),
      relative_change_abs = ifelse(
        abs(as.numeric(prim)) > 1e-12,
        abs(as.numeric(sens - prim) / as.numeric(prim)),
        NA_real_
      ),
      status = "POINT_ESTIMATE_SENSITIVITY_ONLY",
      stringsAsFactors = FALSE
    )
  })
  primary_vs_reduced <- do.call(rbind, compare_rows)
  row.names(primary_vs_reduced) <- NULL

  gap_audit <- do.call(rbind, lapply(reduced, function(z) z$gap_audit))
  row.names(gap_audit) <- NULL

  bol_e2_gap <- gap_audit[
    gap_audit$model == "E2" &
      gap_audit$iso3 == "BOL" &
      !is.na(gap_audit$from_year),
    ,
    drop = FALSE
  ]
  stopifnot(
    nrow(bol_e2_gap) == 1L,
    bol_e2_gap$from_year == 1999L,
    bol_e2_gap$to_year == 2001L,
    bol_e2_gap$gap_years == 2L
  )

  e4_one_at_a_time <- lapply(
    FROZEN_B08_E4_ONE_AT_A_TIME_SPECS,
    function(rule) {
      tcc_b08_fit_model_rule(ctx, "E4", unname(rule))
    }
  )

  e4_ota_rows <- lapply(names(e4_one_at_a_time), function(nm) {
    z <- e4_one_at_a_time[[nm]]
    gm <- z$group_mean
    prim <- primary$group_coef$E4[names(gm)]

    data.frame(
      flag = nm,
      rule = unname(FROZEN_B08_E4_ONE_AT_A_TIME_SPECS[[nm]]),
      n_total = z$n_total,
      term = names(gm),
      primary_estimate = as.numeric(prim),
      sensitivity_estimate = as.numeric(gm),
      change = as.numeric(gm - prim),
      sign_primary = sign(as.numeric(prim)),
      sign_sensitivity = sign(as.numeric(gm)),
      sign_preserved = sign(as.numeric(prim)) == sign(as.numeric(gm)),
      stringsAsFactors = FALSE
    )
  })
  e4_one_at_a_time_comparison <- do.call(rbind, e4_ota_rows)
  row.names(e4_one_at_a_time_comparison) <- NULL

  e4_focused <- do.call(
    rbind,
    lapply(names(e4_one_at_a_time), function(nm) {
      z <- e4_one_at_a_time[[nm]]
      gm <- z$group_mean

      data.frame(
        flag = nm,
        n_total = z$n_total,
        income2 = unname(gm["income2"]),
        income2_positive = unname(gm["income2"] > 0),
        lnIE = unname(gm["lnIE"]),
        lnIE_positive = unname(gm["lnIE"] > 0),
        FFS = unname(gm["FFS"]),
        AGR = unname(gm["AGR"]),
        IND = unname(gm["IND"]),
        stringsAsFactors = FALSE
      )
    })
  )
  row.names(e4_focused) <- NULL

  model_summary <- do.call(
    rbind,
    lapply(names(reduced), function(m) {
      cmp <- primary_vs_reduced[
        primary_vs_reduced$model == m,
        ,
        drop = FALSE
      ]

      data.frame(
        model = m,
        primary_n = EXPECTED_ROW_COUNT,
        reduced_n = reduced[[m]]$n_total,
        all_signs_preserved = all(cmp$sign_preserved),
        max_absolute_coefficient_change =
          max(abs(cmp$change_reduced_minus_primary)),
        max_relative_change_abs =
          max(cmp$relative_change_abs, na.rm = TRUE),
        irregular_gap_present =
          any(reduced[[m]]$gap_audit$irregular_gap_count > 0),
        status = "DESCRIPTIVE_ROBUSTNESS_ONLY",
        stringsAsFactors = FALSE
      )
    })
  )
  row.names(model_summary) <- NULL

  list(
    reduced = reduced,
    primary_vs_reduced = primary_vs_reduced,
    gap_audit = gap_audit,
    e4_one_at_a_time = e4_one_at_a_time,
    e4_one_at_a_time_comparison = e4_one_at_a_time_comparison,
    e4_focused = e4_focused,
    model_summary = model_summary,
    interpretation_boundary = paste(
      "B08 is a point-estimate sensitivity block only.",
      "Primary coefficients remain frozen.",
      "BOL-2000 omission creates an irregular two-year transition and",
      "reduced-sample formal inference is not promoted.",
      "No factorial sensitivity search is authorized."
    )
  )
}

# -----------------------------------------------------------------------------
# B09 — including-LULUCF full-sample outcome-boundary sensitivity
# -----------------------------------------------------------------------------

tcc_b09_country_coefficient_table <- function(primary_incl) {
  rows <- list()

  for (m in names(primary_incl$models_common)) {
    for (cc in FROZEN_COUNTRIES) {
      b <- tcc_get_slope_vector(primary_incl$models_common[[m]][[cc]])
      for (term in names(b)) {
        rows[[paste(m, cc, term, sep = "_")]] <- data.frame(
          model = m,
          iso3 = cc,
          term = term,
          estimate = as.numeric(b[[term]]),
          outcome = "ln_GHGpc_including_LULUCF",
          stringsAsFactors = FALSE
        )
      }
    }
  }

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

tcc_b09_group_coefficient_table <- function(primary_incl) {
  out <- do.call(
    rbind,
    lapply(names(primary_incl$group_coef), function(m) {
      data.frame(
        model = m,
        term = names(primary_incl$group_coef[[m]]),
        estimate = as.numeric(primary_incl$group_coef[[m]]),
        outcome = "ln_GHGpc_including_LULUCF",
        stringsAsFactors = FALSE
      )
    })
  )
  row.names(out) <- NULL
  out
}

tcc_b09_operational_objects <- function(primary_incl) {
  out <- primary_incl$operational_covariance

  for (m in names(out)) {
    out[[m]]$inference$status <- "CONDITIONAL_LULUCF_OPERATIONAL_INFERENCE"
    out[[m]]$status <- "LULUCF_OPERATIONAL_APPROXIMATION"
  }

  out
}

tcc_b09_hypothesis_tables <- function(ctx, primary_incl, operational) {
  beta_h1 <- primary_incl$group_coef$E1[c("income", "income2")]
  V_h1 <- primary_incl$e1$covariance[
    c("income", "income2"),
    c("income", "income2"),
    drop = FALSE
  ]

  slope_eval <- function(x0, direction = c("positive", "negative")) {
    direction <- match.arg(direction)
    g <- c(1, 2 * x0)
    est <- drop(g %*% beta_h1)
    se <- sqrt(drop(g %*% V_h1 %*% g))
    z <- est / se
    p_one_sided <- if (direction == "positive") {
      pnorm(z, lower.tail = FALSE)
    } else {
      pnorm(z, lower.tail = TRUE)
    }
    c(estimate = est, se = se, z = z, p_one_sided = p_one_sided)
  }

  lower <- slope_eval(ctx$x_lower, "positive")
  upper <- slope_eval(ctx$x_upper, "negative")
  iut_p <- max(lower["p_one_sided"], upper["p_one_sided"])

  turning_x <- if (abs(beta_h1["income2"]) > .Machine$double.eps) {
    -beta_h1["income"] / (2 * beta_h1["income2"])
  } else {
    NA_real_
  }

  turning_gdppc <- if (is.finite(turning_x)) {
    exp(ctx$common_gdp_center + turning_x)
  } else {
    NA_real_
  }

  turning_in_support <- is.finite(turning_x) &&
    turning_x >= ctx$x_lower &&
    turning_x <= ctx$x_upper

  h1_supported <- isTRUE(beta_h1["income2"] < 0) &&
    turning_in_support &&
    isTRUE(lower["estimate"] > 0) &&
    isTRUE(upper["estimate"] < 0) &&
    isTRUE(iut_p < ALPHA_PRIMARY)

  H1 <- data.frame(
    hypothesis = "H1_EKC_inverted_U",
    outcome = "including_LULUCF",
    beta_income = unname(beta_h1["income"]),
    beta_income2 = unname(beta_h1["income2"]),
    x_lower = ctx$x_lower,
    x_upper = ctx$x_upper,
    slope_lower = unname(lower["estimate"]),
    slope_lower_se = unname(lower["se"]),
    p_lower_positive = unname(lower["p_one_sided"]),
    slope_upper = unname(upper["estimate"]),
    slope_upper_se = unname(upper["se"]),
    p_upper_negative = unname(upper["p_one_sided"]),
    iut_p = unname(iut_p),
    turning_x = unname(turning_x),
    turning_gdppc = unname(turning_gdppc),
    turning_in_support = turning_in_support,
    h1_supported_by_estimated_shape = h1_supported,
    inference_status = "CONDITIONAL_LULUCF_SENSITIVITY",
    stringsAsFactors = FALSE
  )

  get_op <- function(model, term) {
    tab <- operational[[model]]$inference
    z <- tab[tab$term == term, , drop = FALSE]
    stopifnot(nrow(z) == 1L)
    z
  }

  h2_eval <- function(hypothesis, term) {
    prim <- get_op("E2", term)
    e4 <- get_op("E4", term)

    data.frame(
      hypothesis = hypothesis,
      term = term,
      outcome = "including_LULUCF",
      primary_model = "E2",
      primary_estimate = prim$estimate,
      primary_se = prim$robust_se_operational,
      primary_p_two_sided = prim$p_two_sided_operational,
      primary_supported_operationally =
        prim$estimate > 0 &&
        prim$p_two_sided_operational < ALPHA_PRIMARY,
      stability_model = "E4",
      stability_estimate = e4$estimate,
      stability_se = e4$robust_se_operational,
      stability_p_two_sided = e4$p_two_sided_operational,
      e4_supported_operationally =
        e4$estimate > 0 &&
        e4$p_two_sided_operational < ALPHA_PRIMARY,
      sign_preserved_in_e4 = sign(prim$estimate) == sign(e4$estimate),
      inference_status = "CONDITIONAL_LULUCF_OPERATIONAL_INFERENCE",
      stringsAsFactors = FALSE
    )
  }

  H2 <- rbind(
    h2_eval("H2a_energy_intensity_positive", "lnIE"),
    h2_eval("H2b_fossil_share_positive", "FFS")
  )
  row.names(H2) <- NULL

  h3_wald <- function(model) {
    terms <- c("AGR", "IND")
    beta <- primary_incl$group_coef[[model]][terms]
    V <- operational[[model]]$covariance[terms, terms, drop = FALSE]
    W <- drop(t(beta) %*% solve(V, beta))
    p <- pchisq(W, df = length(terms), lower.tail = FALSE)

    list(
      model = model,
      wald_chisq = W,
      df = length(terms),
      p_joint = p,
      supported = p < ALPHA_PRIMARY
    )
  }

  e3 <- h3_wald("E3")
  e4 <- h3_wald("E4")

  H3 <- data.frame(
    hypothesis = "H3_productive_composition_joint",
    outcome = "including_LULUCF",
    primary_model = "E3",
    primary_wald_chisq = e3$wald_chisq,
    primary_df = e3$df,
    primary_p_joint = e3$p_joint,
    primary_supported_operationally = e3$supported,
    stability_model = "E4",
    stability_wald_chisq = e4$wald_chisq,
    stability_df = e4$df,
    stability_p_joint = e4$p_joint,
    e4_joint_support_operationally = e4$supported,
    inference_status = "CONDITIONAL_LULUCF_OPERATIONAL_INFERENCE",
    stringsAsFactors = FALSE
  )

  stability_source <- c(lnIE = "E2", FFS = "E2", AGR = "E3", IND = "E3")
  E4_stability <- do.call(
    rbind,
    lapply(names(stability_source), function(term) {
      pm <- stability_source[[term]]
      prim <- get_op(pm, term)
      e4row <- get_op("E4", term)

      data.frame(
        term = term,
        outcome = "including_LULUCF",
        primary_model = pm,
        primary_estimate = prim$estimate,
        primary_se = prim$robust_se_operational,
        primary_p = prim$p_two_sided_operational,
        e4_estimate = e4row$estimate,
        e4_se = e4row$robust_se_operational,
        e4_p = e4row$p_two_sided_operational,
        estimate_change_e4_minus_primary =
          e4row$estimate - prim$estimate,
        sign_preserved = sign(prim$estimate) == sign(e4row$estimate),
        status = "DESCRIPTIVE_LULUCF_STABILITY",
        stringsAsFactors = FALSE
      )
    })
  )
  row.names(E4_stability) <- NULL

  list(H1 = H1, H2 = H2, H3 = H3, E4_stability = E4_stability)
}

tcc_b09_residual_cd <- function(diag_incl) {
  x <- diag_incl$pesaran_cd

  out <- data.frame(
    model = x$model,
    outcome = "including_LULUCF",
    N = x$N,
    T = x$T,
    mean_signed_pair_rho = x$mean_signed_pair_rho,
    mean_abs_pair_rho = x$mean_abs_pair_rho,
    max_abs_pair_rho = x$max_abs_pair_rho,
    pesaran_cd = x$pesaran_cd,
    pesaran_cd_p = x$pesaran_cd_p,
    reject_cross_section_independence_at_5pct =
      x$reject_cross_section_independence_at_5pct,
    status = "LULUCF_RESIDUAL_CD_DIAGNOSTIC",
    stringsAsFactors = FALSE
  )
  row.names(out) <- NULL
  out
}

tcc_b09_cpr <- function(diag_incl) {
  x <- diag_incl$e1_cpr_gate
  gate <- data.frame(
    iso3 = x$iso3,
    outcome = "including_LULUCF",
    T = x$T,
    bandwidth = x$bandwidth,
    CT = x$CT,
    CT_crit_5pct = x$CT_crit_5pct,
    CT_reject_cointegration_null = x$CT_reject_cointegration_null,
    PU = x$PU,
    PU_crit_5pct = x$PU_crit_5pct,
    PU_reject_no_cointegration_null = x$PU_reject_no_cointegration_null,
    decision = x$decision,
    status = "LULUCF_E1_CPR_GATE_WITH_FROZEN_BW3",
    stringsAsFactors = FALSE
  )
  row.names(gate) <- NULL

  summary <- data.frame(
    outcome = "including_LULUCF",
    countries_evidence_for =
      sum(gate$decision == "EVIDENCE_FOR_CPR_COINTEGRATION"),
    countries_evidence_against =
      sum(gate$decision == "EVIDENCE_AGAINST_CPR_COINTEGRATION"),
    countries_conflicting =
      sum(gate$decision == "CONFLICTING_EVIDENCE"),
    all_countries_evidence_for =
      all(gate$decision == "EVIDENCE_FOR_CPR_COINTEGRATION"),
    any_country_evidence_against =
      any(gate$decision == "EVIDENCE_AGAINST_CPR_COINTEGRATION"),
    any_country_conflicting =
      any(gate$decision == "CONFLICTING_EVIDENCE"),
    interpretation_status = "LULUCF_SENSITIVITY_CPR_GATE",
    stringsAsFactors = FALSE
  )

  list(gate = gate, summary = summary)
}

tcc_run_b09_lulucf_sensitivity <- function(ctx, primary_excl) {
  stopifnot(identical(primary_excl$y_field, "y_excl"))
  stopifnot(nrow(ctx$dat) == EXPECTED_ROW_COUNT)

  primary_incl <- tcc_run_primary_analysis(ctx, y_field = "y_incl")
  diag_incl <- tcc_run_b07_diagnostics(
    ctx = ctx,
    primary = primary_incl,
    y_field = "y_incl"
  )

  country_coefficients <- tcc_b09_country_coefficient_table(primary_incl)
  group_coefficient_table <- tcc_b09_group_coefficient_table(primary_incl)

  cmp_rows <- lapply(names(primary_incl$group_coef), function(m) {
    sens <- primary_incl$group_coef[[m]]
    prim <- primary_excl$group_coef[[m]][names(sens)]

    data.frame(
      model = m,
      term = names(sens),
      primary_excl_lulucf = as.numeric(prim),
      sensitivity_incl_lulucf = as.numeric(sens),
      change_incl_minus_excl = as.numeric(sens - prim),
      sign_primary = sign(as.numeric(prim)),
      sign_sensitivity = sign(as.numeric(sens)),
      sign_preserved = sign(as.numeric(prim)) == sign(as.numeric(sens)),
      status = "OUTCOME_BOUNDARY_POINT_ESTIMATE_SENSITIVITY",
      stringsAsFactors = FALSE
    )
  })
  primary_vs_lulucf <- do.call(rbind, cmp_rows)
  row.names(primary_vs_lulucf) <- NULL

  e1_inference <- primary_incl$e1$inference
  e1_inference$status <- "CONDITIONAL_LULUCF_SENSITIVITY_INFERENCE"

  operational <- tcc_b09_operational_objects(primary_incl)
  operational_summary <- do.call(
    rbind,
    lapply(names(operational), function(m) {
      z <- operational[[m]]
      data.frame(
        model = m,
        k_rhs = nrow(z$covariance),
        conditional_lrv_recon_diff = z$cond_recon_diff,
        symmetry_error = z$symmetry_error,
        min_eigenvalue = min(z$eigenvalues),
        max_eigenvalue = max(z$eigenvalues),
        status = z$status,
        stringsAsFactors = FALSE
      )
    })
  )
  row.names(operational_summary) <- NULL

  hypotheses <- tcc_b09_hypothesis_tables(
    ctx = ctx,
    primary_incl = primary_incl,
    operational = operational
  )

  residual_cd <- tcc_b09_residual_cd(diag_incl)
  cpr <- tcc_b09_cpr(diag_incl)

  outcome_summary <- data.frame(
    item = c(
      "H1 estimated inverted-U shape supported",
      "H2a energy intensity operational support",
      "H2b fossil share operational support",
      "H3 composition joint operational support",
      "E4 H3 joint operational support",
      "E1 all countries CPR evidence for"
    ),
    result = c(
      as.character(hypotheses$H1$h1_supported_by_estimated_shape),
      as.character(hypotheses$H2$primary_supported_operationally[1L]),
      as.character(hypotheses$H2$primary_supported_operationally[2L]),
      as.character(hypotheses$H3$primary_supported_operationally),
      as.character(hypotheses$H3$e4_joint_support_operationally),
      as.character(cpr$summary$all_countries_evidence_for)
    ),
    status = "INCLUDING_LULUCF_SENSITIVITY",
    stringsAsFactors = FALSE
  )

  list(
    models_local = primary_incl$models_local,
    models_common = primary_incl$models_common,
    models_direct_common = primary_incl$models_direct_common,
    reconciliation = primary_incl$reconciliation,
    country_coefficients = country_coefficients,
    group_coefficients = primary_incl$group_coef,
    group_coefficient_table = group_coefficient_table,
    primary_vs_lulucf = primary_vs_lulucf,
    e1_covariance = primary_incl$e1$covariance,
    e1_conditional_lrv = primary_incl$e1$conditional_lrv,
    e1_orthogonalization = primary_incl$e1$orthogonalization,
    e1_inference = e1_inference,
    operational_covariance = operational,
    operational_covariance_summary = operational_summary,
    H1 = hypotheses$H1,
    H2 = hypotheses$H2,
    H3 = hypotheses$H3,
    E4_stability = hypotheses$E4_stability,
    residual_cd = residual_cd,
    e1_cpr_gate = cpr$gate,
    e1_cpr_gate_summary = cpr$summary,
    outcome_summary = outcome_summary,
    interpretation_boundary = paste(
      "Including-LULUCF is a full-sample outcome-boundary sensitivity.",
      "It does not replace the excluding-LULUCF primary outcome.",
      "All inferential quantities remain conditional after B07;",
      "E2-E4 retain the adopted operational approximation."
    )
  )
}

tcc_run_sensitivities <- function(ctx, primary_excl) {
  list(
    B08 = tcc_run_b08_sensitivities(ctx, primary_excl),
    B09 = tcc_run_b09_lulucf_sensitivity(ctx, primary_excl)
  )
}
