# TCC Stage VIII — 03_diagnosticos.R
# Version: 2026-10-21 v01 (R2)
# Scope: modular reproduction of the frozen Stage VI B07 post-estimation
# residual diagnostics and E1 CPR complementary-null gate.
#
# Interpretation boundary is unchanged: these diagnostics qualify the frozen
# primary estimates; they do not silently mutate the estimator or hypotheses.

B07_ALPHA <- 0.05

# Reconstruct fitted residuals from the frozen/direct-common FM point estimates.
tcc_b07_design_and_residual <- function(ctx, primary, model, cc, y_field = "y_excl") {
  d <- ctx$split_country[[cc]]
  d <- d[order(d$year), , drop = FALSE]

  rhs <- tcc_make_rhs(d, model, "common", ctx$common_gdp_center)
  X <- rhs$X
  Z <- cbind(intercept = 1, X)

  theta <- primary$models_direct_common[[model]][[cc]]$theta
  stopifnot(identical(colnames(Z), names(theta)))

  y <- as.numeric(d[[y_field]])
  u <- drop(y - Z %*% theta)
  stopifnot(length(u) == nrow(d), all(is.finite(u)))

  list(d = d, y = y, X = X, Z = Z, theta = theta, residual = u)
}

# B07-A + B07-B residual diagnostics.
tcc_b07_residual_diagnostics <- function(ctx, primary, y_field = "y_excl") {
  diag_rows <- list()
  residuals <- list()

  for (m in names(FROZEN_MODEL_EXTENSIONS)) {
    residuals[[m]] <- list()

    for (cc in FROZEN_COUNTRIES) {
      z <- tcc_b07_design_and_residual(ctx, primary, m, cc, y_field = y_field)
      u <- z$residual
      yrs <- z$d$year
      n <- length(u)
      residuals[[m]][[cc]] <- u

      ar_df <- data.frame(u = u[-1L], u_lag = u[-n])
      ar_fit <- lm(u ~ u_lag, data = ar_df)
      ar_tab <- summary(ar_fit)$coefficients
      ar1_rho <- unname(coef(ar_fit)["u_lag"])
      ar1_p <- unname(ar_tab["u_lag", "Pr(>|t|)"])

      Z_eff <- z$Z[-1L, , drop = FALSE]
      bg_df <- data.frame(
        u = u[-1L],
        u_lag = u[-n],
        Z_eff[, colnames(Z_eff) != "intercept", drop = FALSE],
        check.names = FALSE
      )
      bg_rhs_names <- c("u_lag", colnames(Z_eff)[colnames(Z_eff) != "intercept"])
      bg_formula <- as.formula(paste("u ~", paste(bg_rhs_names, collapse = " + ")))
      bg_fit <- lm(bg_formula, data = bg_df)
      bg_lm <- nrow(bg_df) * summary(bg_fit)$r.squared
      bg_p <- pchisq(bg_lm, df = 1L, lower.tail = FALSE)

      trend_fit <- lm(u ~ yrs)
      trend_tab <- summary(trend_fit)$coefficients
      trend_slope <- unname(coef(trend_fit)["yrs"])
      trend_p <- unname(trend_tab["yrs", "Pr(>|t|)"])

      bp_df <- data.frame(u2 = u^2, z$X, check.names = FALSE)
      bp_formula <- as.formula(paste("u2 ~", paste(colnames(z$X), collapse = " + ")))
      bp_fit <- lm(bp_formula, data = bp_df)
      bp_df_test <- length(colnames(z$X))
      bp_lm <- n * summary(bp_fit)$r.squared
      bp_p <- pchisq(bp_lm, df = bp_df_test, lower.tail = FALSE)

      diag_rows[[paste(m, cc, sep = "_")]] <- data.frame(
        model = m,
        iso3 = cc,
        n = n,
        residual_mean = mean(u),
        residual_sd = sd(u),
        ar1_rho = ar1_rho,
        ar1_p_conventional = ar1_p,
        bg_lm1 = bg_lm,
        bg_lm1_p = bg_p,
        bg_reject_no_serial_at_5pct = bg_p < B07_ALPHA,
        trend_slope = trend_slope,
        trend_p = trend_p,
        trend_reject_zero_at_5pct = trend_p < B07_ALPHA,
        bp_lm = bp_lm,
        bp_df = bp_df_test,
        bp_p = bp_p,
        bp_reject_homoskedasticity_at_5pct = bp_p < B07_ALPHA,
        status = "AUXILIARY_RESIDUAL_DIAGNOSTIC",
        stringsAsFactors = FALSE
      )
    }
  }

  country_diagnostics <- do.call(rbind, diag_rows)
  row.names(country_diagnostics) <- NULL

  country_summary <- do.call(
    rbind,
    lapply(names(FROZEN_MODEL_EXTENSIONS), function(m) {
      x <- country_diagnostics[country_diagnostics$model == m, , drop = FALSE]
      data.frame(
        model = m,
        mean_ar1_rho = mean(x$ar1_rho),
        max_abs_ar1_rho = max(abs(x$ar1_rho)),
        countries_bg_reject_5pct = sum(x$bg_reject_no_serial_at_5pct),
        countries_trend_reject_5pct = sum(x$trend_reject_zero_at_5pct),
        countries_bp_reject_5pct = sum(x$bp_reject_homoskedasticity_at_5pct),
        stringsAsFactors = FALSE
      )
    })
  )
  row.names(country_summary) <- NULL

  cd_rows <- list()
  pair_rows <- list()

  for (m in names(FROZEN_MODEL_EXTENSIONS)) {
    U <- do.call(cbind, residuals[[m]])
    colnames(U) <- FROZEN_COUNTRIES

    stopifnot(
      nrow(U) == EXPECTED_YEAR_COUNT,
      ncol(U) == length(FROZEN_COUNTRIES),
      all(is.finite(U))
    )

    R <- cor(U)
    pairs <- combn(FROZEN_COUNTRIES, 2L, simplify = FALSE)
    pair_rho <- vapply(pairs, function(p) R[p[1L], p[2L]], numeric(1))

    for (ii in seq_along(pairs)) {
      p <- pairs[[ii]]
      pair_rows[[paste(m, p[1L], p[2L], sep = "_")]] <- data.frame(
        model = m,
        country_i = p[1L],
        country_j = p[2L],
        residual_correlation = pair_rho[ii],
        stringsAsFactors = FALSE
      )
    }

    N <- ncol(U)
    Tn <- nrow(U)
    CD <- sqrt(2 * Tn / (N * (N - 1))) * sum(pair_rho)
    CD_p <- 2 * pnorm(abs(CD), lower.tail = FALSE)

    cd_rows[[m]] <- data.frame(
      model = m,
      N = N,
      T = Tn,
      pair_count = length(pair_rho),
      mean_signed_pair_rho = mean(pair_rho),
      mean_abs_pair_rho = mean(abs(pair_rho)),
      max_abs_pair_rho = max(abs(pair_rho)),
      pesaran_cd = CD,
      pesaran_cd_p = CD_p,
      reject_cross_section_independence_at_5pct = CD_p < B07_ALPHA,
      status = "RESIDUAL_CROSS_SECTION_DIAGNOSTIC",
      stringsAsFactors = FALSE
    )
  }

  pairwise <- do.call(rbind, pair_rows)
  row.names(pairwise) <- NULL
  pesaran_cd <- do.call(rbind, cd_rows)
  row.names(pesaran_cd) <- NULL

  list(
    residuals = residuals,
    country_diagnostics = country_diagnostics,
    country_summary = country_summary,
    residual_pairwise_correlations = pairwise,
    pesaran_cd = pesaran_cd
  )
}

# B07-C E1-only complementary-null CPR gate.
tcc_b07_e1_cpr_test <- function(ctx, primary, cc, y_field = "y_excl") {
  z <- tcc_b07_design_and_residual(ctx, primary, "E1", cc, y_field = y_field)
  d <- z$d
  Tn <- nrow(d)

  x <- as.numeric(d$ln_gdp - ctx$common_gdp_center)
  y <- as.numeric(d[[y_field]])
  v <- diff(x)

  u_fm <- as.numeric(z$residual)
  joint_ct <- cbind(
    u = u_fm[-1L] - mean(u_fm[-1L]),
    v = v - mean(v)
  )
  Omega_ct <- tcc_bartlett_lrv(joint_ct, FROZEN_FM_BANDWIDTH)
  omega_u_v <- drop(
    Omega_ct["u", "u"] -
      Omega_ct["u", "v"] * (1 / Omega_ct["v", "v"]) * Omega_ct["v", "u"]
  )
  stopifnot(is.finite(omega_u_v), omega_u_v > 0)

  partial_fm <- cumsum(u_fm) / sqrt(Tn)
  CT <- sum(partial_fm^2) / (Tn * omega_u_v)
  CT_reject <- CT > FROZEN_CPR_CT_CRIT_5

  Z_ols <- cbind(intercept = 1, income = x, income2 = x^2)
  beta_ols <- drop(solve(crossprod(Z_ols), crossprod(Z_ols, y)))
  u_ols <- drop(y - Z_ols %*% beta_ols)

  M <- cbind(y = y, x = x)
  M_now <- M[-1L, , drop = FALSE]
  M_lag <- M[-Tn, , drop = FALSE]
  VAR_X <- cbind(intercept = 1, M_lag)
  VAR_B <- solve(crossprod(VAR_X), crossprod(VAR_X, M_now))
  xi <- M_now - VAR_X %*% VAR_B
  stopifnot(ncol(xi) == 2L, all(is.finite(xi)))
  colnames(xi) <- c("w", "v")

  Omega_var <- tcc_bartlett_lrv(xi, FROZEN_FM_BANDWIDTH)
  omega_w_v <- drop(
    Omega_var["w", "w"] -
      Omega_var["w", "v"] * (1 / Omega_var["v", "v"]) * Omega_var["v", "w"]
  )
  stopifnot(is.finite(omega_w_v), omega_w_v > 0)

  PU_denom <- sum(u_ols^2) / (Tn^2)
  PU <- omega_w_v / PU_denom
  PU_reject <- PU > FROZEN_CPR_PU_CRIT_5

  decision <- if (!CT_reject && PU_reject) {
    "EVIDENCE_FOR_CPR_COINTEGRATION"
  } else if (CT_reject && !PU_reject) {
    "EVIDENCE_AGAINST_CPR_COINTEGRATION"
  } else {
    "CONFLICTING_EVIDENCE"
  }

  data.frame(
    iso3 = cc,
    T = Tn,
    bandwidth = FROZEN_FM_BANDWIDTH,
    CT = CT,
    CT_crit_5pct = FROZEN_CPR_CT_CRIT_5,
    CT_reject_cointegration_null = CT_reject,
    PU = PU,
    PU_crit_5pct = FROZEN_CPR_PU_CRIT_5,
    PU_reject_no_cointegration_null = PU_reject,
    decision = decision,
    status = "FORMAL_E1_CPR_GATE_WITH_FROZEN_BW3",
    stringsAsFactors = FALSE
  )
}

tcc_run_b07_diagnostics <- function(ctx, primary, y_field = "y_excl") {
  residual <- tcc_b07_residual_diagnostics(ctx, primary, y_field = y_field)

  e1_cpr <- do.call(
    rbind,
    lapply(FROZEN_COUNTRIES, function(cc) {
      tcc_b07_e1_cpr_test(ctx, primary, cc, y_field = y_field)
    })
  )
  row.names(e1_cpr) <- NULL

  e1_cpr_summary <- data.frame(
    countries_evidence_for = sum(e1_cpr$decision == "EVIDENCE_FOR_CPR_COINTEGRATION"),
    countries_evidence_against = sum(e1_cpr$decision == "EVIDENCE_AGAINST_CPR_COINTEGRATION"),
    countries_conflicting = sum(e1_cpr$decision == "CONFLICTING_EVIDENCE"),
    all_countries_evidence_for = all(e1_cpr$decision == "EVIDENCE_FOR_CPR_COINTEGRATION"),
    any_country_evidence_against = any(e1_cpr$decision == "EVIDENCE_AGAINST_CPR_COINTEGRATION"),
    any_country_conflicting = any(e1_cpr$decision == "CONFLICTING_EVIDENCE"),
    interpretation_status = "DIAGNOSTIC_GATE_DO_NOT_AUTO_REOPEN_PRIMARY_RESULTS",
    stringsAsFactors = FALSE
  )

  list(
    country_residual_diagnostics = residual$country_diagnostics,
    country_residual_summary = residual$country_summary,
    residual_pairwise_correlations = residual$residual_pairwise_correlations,
    pesaran_cd = residual$pesaran_cd,
    e1_cpr_gate = e1_cpr,
    e1_cpr_gate_summary = e1_cpr_summary,
    interpretation_boundary = paste(
      "B07 is post-freeze diagnostic evidence.",
      "Serial correlation/heteroskedasticity/trend and residual CD qualify interpretation",
      "but do not automatically reopen the FM estimator.",
      "Formal CPR complementary-null testing is restricted to E1;",
      "E2-E4 remain conditional-operational under the v05 limitation boundary."
    )
  )
}
