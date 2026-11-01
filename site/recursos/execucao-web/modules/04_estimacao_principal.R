# TCC Stage VIII — 04_estimacao_principal.R
# Version: 2026-10-21 v01 (R2)
# Scope: modular reproduction of frozen Stage VI v05 primary estimation,
# covariance/inference, and H1-H3 evaluation.
#
# Methodological boundary: this is a refactor only. It preserves the accepted
# cointRegFM point estimates, fixed bandwidth/kernel, E1 source-faithful fixed-N
# covariance, and E2-E4 conditional operational covariance approximation.

# -----------------------------------------------------------------------------
# FM-OLS design + country estimation
# -----------------------------------------------------------------------------

tcc_make_rhs <- function(d, model, center_mode = c("local", "common"), common_center) {
  center_mode <- match.arg(center_mode)
  stopifnot(model %in% names(FROZEN_MODEL_EXTENSIONS))

  center_i <- if (center_mode == "local") mean(d$ln_gdp) else common_center
  z <- d$ln_gdp - center_i

  rhs <- data.frame(income = z, income2 = z^2)
  ext <- FROZEN_MODEL_EXTENSIONS[[model]]
  if (length(ext)) rhs <- cbind(rhs, d[ext])

  list(X = as.matrix(rhs), center = center_i, rhs_names = names(rhs))
}

tcc_fit_country_fm <- function(
    d,
    model,
    common_center,
    center_mode = c("local", "common"),
    y_field = "y_excl") {

  center_mode <- match.arg(center_mode)
  tcc_require_packages(PKG_REQUIRED_CORE)
  stopifnot(exists("cointRegFM", where = asNamespace("cointReg"), inherits = FALSE))
  stopifnot(y_field %in% names(d))

  rhs <- tcc_make_rhs(d, model, center_mode, common_center)
  D <- matrix(1, nrow = nrow(d), ncol = 1)
  colnames(D) <- "intercept"

  fit <- cointReg::cointRegFM(
    x = rhs$X,
    y = as.numeric(d[[y_field]]),
    deter = D,
    kernel = FROZEN_FM_KERNEL,
    bandwidth = FROZEN_FM_BANDWIDTH,
    demeaning = FALSE,
    check = TRUE
  )

  theta <- as.numeric(fit$theta)
  nm <- c("intercept", rhs$rhs_names)
  stopifnot(length(theta) == length(nm))
  names(theta) <- nm

  V <- as.matrix(fit$varmat)
  stopifnot(all(dim(V) == c(length(nm), length(nm))))
  dimnames(V) <- list(nm, nm)

  list(
    fit = fit,
    theta = theta,
    V = V,
    country_center = rhs$center,
    model = model,
    y_field = y_field,
    iso3 = unique(d$iso3)
  )
}

tcc_transform_to_common <- function(obj, common_center) {
  th <- obj$theta
  V <- obj$V
  d <- common_center - obj$country_center

  J <- diag(length(th))
  dimnames(J) <- list(names(th), names(th))
  J["intercept", c("intercept", "income", "income2")] <- c(1, d, d^2)
  J["income", c("intercept", "income", "income2")] <- c(0, 1, 2 * d)
  J["income2", c("intercept", "income", "income2")] <- c(0, 0, 1)

  th_c <- drop(J %*% th)
  names(th_c) <- names(th)
  V_c <- J %*% V %*% t(J)
  dimnames(V_c) <- list(names(th), names(th))

  obj$theta_common <- th_c
  obj$V_common <- V_c
  obj$J_common <- J
  obj$d_common_minus_local <- d
  obj
}

tcc_get_slope_vector <- function(obj) {
  obj$theta_common[names(obj$theta_common) != "intercept"]
}

# -----------------------------------------------------------------------------
# Shared Bartlett long-run covariance helper
# -----------------------------------------------------------------------------

tcc_bartlett_lrv <- function(U, bandwidth = FROZEN_FM_BANDWIDTH) {
  U <- as.matrix(U)
  n <- nrow(U)
  stopifnot(n >= 2L, bandwidth >= 1L, all(is.finite(U)))

  Omega <- crossprod(U) / n

  if (bandwidth > 1L) {
    for (lag in seq_len(bandwidth - 1L)) {
      w <- 1 - lag / bandwidth
      G <- crossprod(
        U[(lag + 1L):n, , drop = FALSE],
        U[1L:(n - lag), , drop = FALSE]
      ) / n
      Omega <- Omega + w * (G + t(G))
    }
  }

  (Omega + t(Omega)) / 2
}

# -----------------------------------------------------------------------------
# Country models, common-center reconciliation, group means, LRV health
# -----------------------------------------------------------------------------

tcc_fit_model_stack <- function(ctx, y_field = "y_excl") {
  models_local <- list()
  models_direct_common <- list()

  for (m in names(FROZEN_MODEL_EXTENSIONS)) {
    models_local[[m]] <- lapply(FROZEN_COUNTRIES, function(cc) {
      tcc_fit_country_fm(
        ctx$split_country[[cc]], m, ctx$common_gdp_center,
        center_mode = "local", y_field = y_field
      )
    })
    names(models_local[[m]]) <- FROZEN_COUNTRIES

    models_direct_common[[m]] <- lapply(FROZEN_COUNTRIES, function(cc) {
      tcc_fit_country_fm(
        ctx$split_country[[cc]], m, ctx$common_gdp_center,
        center_mode = "common", y_field = y_field
      )
    })
    names(models_direct_common[[m]]) <- FROZEN_COUNTRIES
  }

  models_common <- lapply(models_local, function(mm) {
    lapply(mm, tcc_transform_to_common, common_center = ctx$common_gdp_center)
  })

  recon_rows <- list()
  for (m in names(FROZEN_MODEL_EXTENSIONS)) {
    for (cc in FROZEN_COUNTRIES) {
      A <- models_common[[m]][[cc]]
      B <- models_direct_common[[m]][[cc]]
      recon_rows[[paste(m, cc, sep = "_")]] <- data.frame(
        model = m,
        iso3 = cc,
        max_abs_coef_diff = max(abs(A$theta_common - B$theta)),
        max_abs_vcov_diff = max(abs(A$V_common - B$V)),
        stringsAsFactors = FALSE
      )
    }
  }
  reconciliation <- do.call(rbind, recon_rows)
  row.names(reconciliation) <- NULL

  group_coef <- list()
  for (m in names(models_common)) {
    B <- do.call(rbind, lapply(models_common[[m]], tcc_get_slope_vector))
    group_coef[[m]] <- colMeans(B)
  }

  health_rows <- list()
  for (m in names(models_local)) {
    for (cc in FROZEN_COUNTRIES) {
      fit <- models_local[[m]][[cc]]$fit
      Ovv <- as.matrix(fit$Omega$vv)
      Ovv_sym <- (Ovv + t(Ovv)) / 2
      eig_raw <- eigen(Ovv_sym, symmetric = TRUE, only.values = TRUE)$values
      sd_lrv <- sqrt(diag(Ovv_sym))

      if (all(is.finite(sd_lrv)) && all(sd_lrv > 0)) {
        S_inv <- diag(1 / sd_lrv)
        Ovv_scaled <- S_inv %*% Ovv_sym %*% S_inv
        eig_scaled <- eigen(Ovv_scaled, symmetric = TRUE, only.values = TRUE)$values
        min_eig_scaled <- min(eig_scaled)
        cond_scaled <- if (min_eig_scaled > 0) {
          max(eig_scaled) / min_eig_scaled
        } else {
          Inf
        }
      } else {
        min_eig_scaled <- NA_real_
        cond_scaled <- NA_real_
      }

      health_rows[[paste(m, cc, sep = "_")]] <- data.frame(
        model = m,
        iso3 = cc,
        k_rhs = nrow(Ovv),
        min_eigen_raw = min(eig_raw),
        max_eigen_raw = max(eig_raw),
        min_eigen_scaled = min_eig_scaled,
        condition_scaled = cond_scaled,
        rcond_raw = rcond(Ovv_sym),
        stringsAsFactors = FALSE
      )
    }
  }
  fm_health <- do.call(rbind, health_rows)
  row.names(fm_health) <- NULL

  list(
    models_local = models_local,
    models_common = models_common,
    models_direct_common = models_direct_common,
    reconciliation = reconciliation,
    group_coef = group_coef,
    fm_health = fm_health
  )
}

# -----------------------------------------------------------------------------
# E1 source-faithful Wagner-Reichold fixed-N covariance
# -----------------------------------------------------------------------------

tcc_e1_fixed_n_covariance <- function(ctx, group_coef, y_field = "y_excl") {
  wr_e1 <- list()
  Uhat <- matrix(
    NA_real_,
    nrow = EXPECTED_YEAR_COUNT - 1L,
    ncol = length(FROZEN_COUNTRIES)
  )
  Vhat <- Uhat
  colnames(Uhat) <- colnames(Vhat) <- FROZEN_COUNTRIES

  for (cc in FROZEN_COUNTRIES) {
    d <- ctx$split_country[[cc]]
    d <- d[order(d$year), , drop = FALSE]
    stopifnot(identical(as.integer(d$year), EXPECTED_START_YEAR:EXPECTED_END_YEAR))

    x_full <- d$ln_gdp - ctx$common_gdp_center
    y_eff <- as.numeric(d[[y_field]][-1L])
    x_eff <- as.numeric(x_full[-1L])
    v_i <- diff(x_full)

    X_eff <- cbind(income = x_eff, income2 = x_eff^2)
    y_tilde <- y_eff - mean(y_eff)
    X_tilde <- sweep(X_eff, 2L, colMeans(X_eff), FUN = "-")

    beta_ols <- drop(solve(crossprod(X_tilde), crossprod(X_tilde, y_tilde)))
    u_hat <- drop(y_tilde - X_tilde %*% beta_ols)
    v_hat <- as.numeric(v_i - mean(v_i))

    Uhat[, cc] <- u_hat
    Vhat[, cc] <- v_hat

    wr_e1[[cc]] <- list(
      X_tilde = X_tilde,
      Mii = crossprod(X_tilde),
      beta_ols = beta_ols,
      u_hat = u_hat,
      v_hat = v_hat
    )
  }

  W_joint <- cbind(Uhat, Vhat)
  Omega_joint <- tcc_bartlett_lrv(W_joint, FROZEN_FM_BANDWIDTH)

  N_wr <- length(FROZEN_COUNTRIES)
  idx_u <- seq_len(N_wr)
  idx_v <- N_wr + seq_len(N_wr)

  Omega_uu <- Omega_joint[idx_u, idx_u, drop = FALSE]
  Omega_uv <- Omega_joint[idx_u, idx_v, drop = FALSE]
  Omega_vu <- Omega_joint[idx_v, idx_u, drop = FALSE]
  Omega_vv <- Omega_joint[idx_v, idx_v, drop = FALSE]

  a_wr <- diag(Omega_uv) / diag(Omega_vv)
  stopifnot(all(is.finite(a_wr)), all(diag(Omega_vv) > 0))

  Omega_cond <- matrix(
    NA_real_, N_wr, N_wr,
    dimnames = list(FROZEN_COUNTRIES, FROZEN_COUNTRIES)
  )
  V_e1_wr <- matrix(
    0, 2L, 2L,
    dimnames = list(c("income", "income2"), c("income", "income2"))
  )

  for (ii in seq_along(FROZEN_COUNTRIES)) {
    ci <- FROZEN_COUNTRIES[ii]
    Xi <- wr_e1[[ci]]$X_tilde
    Mii <- crossprod(Xi)

    for (jj in seq_along(FROZEN_COUNTRIES)) {
      cj <- FROZEN_COUNTRIES[jj]
      Xj <- wr_e1[[cj]]$X_tilde
      Mjj <- crossprod(Xj)
      Mij <- crossprod(Xi, Xj)

      cond_ij <-
        Omega_uu[ii, jj] -
        a_wr[ii] * Omega_vu[ii, jj] -
        a_wr[jj] * Omega_vu[jj, ii] +
        a_wr[ii] * Omega_vv[ii, jj] * a_wr[jj]

      Omega_cond[ii, jj] <- cond_ij
      V_e1_wr <- V_e1_wr + cond_ij * solve(Mii, Mij %*% solve(Mjj))
    }
  }

  V_e1_wr <- V_e1_wr / (N_wr^2)
  V_e1_wr <- (V_e1_wr + t(V_e1_wr)) / 2

  Udot <- Uhat - sweep(Vhat, 2L, a_wr, FUN = "*")
  Omega_cond_direct <- tcc_bartlett_lrv(Udot, FROZEN_FM_BANDWIDTH)
  cond_lrv_recon_diff <- max(abs(Omega_cond - Omega_cond_direct))

  cov_eigs <- eigen(V_e1_wr, symmetric = TRUE, only.values = TRUE)$values
  cov_sym_error <- max(abs(V_e1_wr - t(V_e1_wr)))

  stopifnot(
    all(is.finite(V_e1_wr)),
    cond_lrv_recon_diff < 1e-10,
    cov_sym_error < 1e-12,
    min(cov_eigs) > -1e-10
  )

  beta_e1_gm <- group_coef$E1[c("income", "income2")]
  se_e1_wr <- sqrt(diag(V_e1_wr))
  z_e1_wr <- beta_e1_gm / se_e1_wr
  p_e1_wr <- 2 * pnorm(abs(z_e1_wr), lower.tail = FALSE)

  inference <- data.frame(
    term = names(beta_e1_gm),
    estimate = as.numeric(beta_e1_gm),
    robust_se = as.numeric(se_e1_wr),
    z = as.numeric(z_e1_wr),
    p_two_sided = as.numeric(p_e1_wr),
    stringsAsFactors = FALSE
  )

  list(
    covariance = V_e1_wr,
    conditional_lrv = Omega_cond,
    conditional_lrv_direct = Omega_cond_direct,
    orthogonalization = a_wr,
    inference = inference,
    cond_lrv_recon_diff = cond_lrv_recon_diff,
    symmetry_error = cov_sym_error,
    eigenvalues = cov_eigs
  )
}

# -----------------------------------------------------------------------------
# E2-E4 adopted conditional-operational covariance approximation
# -----------------------------------------------------------------------------

tcc_operational_rhs_common <- function(d, model, common_center) {
  d <- d[order(d$year), , drop = FALSE]
  x <- d$ln_gdp - common_center
  rhs <- data.frame(income = x, income2 = x^2)
  ext <- FROZEN_MODEL_EXTENSIONS[[model]]
  if (length(ext)) rhs <- cbind(rhs, d[ext])
  as.matrix(rhs)
}

tcc_operational_group_covariance <- function(
    ctx,
    group_coef,
    model,
    y_field = "y_excl") {

  stopifnot(model %in% c("E2", "E3", "E4"))
  countries <- FROZEN_COUNTRIES
  N <- length(countries)

  X_tilde <- list()
  dX <- list()
  u_ols_eff <- list()
  rhs_names <- NULL

  for (cc in countries) {
    d <- ctx$split_country[[cc]]
    d <- d[order(d$year), , drop = FALSE]

    X <- tcc_operational_rhs_common(d, model, ctx$common_gdp_center)
    y <- as.numeric(d[[y_field]])

    if (is.null(rhs_names)) rhs_names <- colnames(X)
    stopifnot(identical(colnames(X), rhs_names))

    Z <- cbind(intercept = 1, X)
    beta_ols <- drop(solve(crossprod(Z), crossprod(Z, y)))
    u_ols <- drop(y - Z %*% beta_ols)

    dX[[cc]] <- apply(X, 2L, diff)
    if (is.null(dim(dX[[cc]]))) dX[[cc]] <- matrix(dX[[cc]], ncol = 1L)
    colnames(dX[[cc]]) <- rhs_names

    u_ols_eff[[cc]] <- as.numeric(u_ols[-1L])
    X_eff <- X[-1L, , drop = FALSE]
    X_tilde[[cc]] <- sweep(X_eff, 2L, colMeans(X_eff), FUN = "-")

    stopifnot(
      nrow(dX[[cc]]) == length(u_ols_eff[[cc]]),
      nrow(X_tilde[[cc]]) == length(u_ols_eff[[cc]]),
      all(is.finite(dX[[cc]])),
      all(is.finite(u_ols_eff[[cc]])),
      all(is.finite(X_tilde[[cc]]))
    )
  }

  k <- length(rhs_names)
  T_eff <- length(u_ols_eff[[countries[1L]]])
  Umat <- do.call(cbind, u_ols_eff)
  colnames(Umat) <- countries

  W_joint <- Umat
  for (cc in countries) W_joint <- cbind(W_joint, dX[[cc]])

  Omega_joint <- tcc_bartlett_lrv(W_joint, FROZEN_FM_BANDWIDTH)
  starts <- N + (seq_len(N) - 1L) * k + 1L

  A <- vector("list", N)
  names(A) <- countries
  for (ii in seq_len(N)) {
    idx_i <- starts[ii]:(starts[ii] + k - 1L)
    Ovv_i <- Omega_joint[idx_i, idx_i, drop = FALSE]
    Ouv_i <- Omega_joint[ii, idx_i, drop = FALSE]
    A[[ii]] <- drop(Ouv_i %*% solve(Ovv_i))
    names(A[[ii]]) <- rhs_names
  }

  Omega_cond <- matrix(NA_real_, N, N, dimnames = list(countries, countries))
  V_group <- matrix(0, k, k, dimnames = list(rhs_names, rhs_names))

  for (ii in seq_len(N)) {
    ci <- countries[ii]
    idx_i <- starts[ii]:(starts[ii] + k - 1L)
    Xi <- X_tilde[[ci]]
    Mii <- crossprod(Xi)

    for (jj in seq_len(N)) {
      cj <- countries[jj]
      idx_j <- starts[jj]:(starts[jj] + k - 1L)
      Xj <- X_tilde[[cj]]
      Mjj <- crossprod(Xj)
      Mij <- crossprod(Xi, Xj)

      ai <- matrix(A[[ii]], nrow = 1L)
      aj <- matrix(A[[jj]], nrow = 1L)

      cond_ij <-
        Omega_joint[ii, jj] -
        drop(ai %*% Omega_joint[idx_i, jj, drop = FALSE]) -
        drop(Omega_joint[ii, idx_j, drop = FALSE] %*% t(aj)) +
        drop(ai %*% Omega_joint[idx_i, idx_j, drop = FALSE] %*% t(aj))

      Omega_cond[ii, jj] <- cond_ij
      V_group <- V_group + cond_ij * solve(Mii, Mij %*% solve(Mjj))
    }
  }

  V_group <- V_group / (N^2)
  V_group <- (V_group + t(V_group)) / 2

  Uplus <- matrix(NA_real_, T_eff, N, dimnames = list(NULL, countries))
  for (ii in seq_len(N)) {
    cc <- countries[ii]
    Uplus[, cc] <- u_ols_eff[[cc]] - drop(dX[[cc]] %*% matrix(A[[ii]], ncol = 1L))
  }

  Omega_cond_direct <- tcc_bartlett_lrv(Uplus, FROZEN_FM_BANDWIDTH)
  cond_recon_diff <- max(abs(Omega_cond - Omega_cond_direct))
  sym_error <- max(abs(V_group - t(V_group)))
  eig <- eigen(V_group, symmetric = TRUE, only.values = TRUE)$values

  beta <- group_coef[[model]][rhs_names]
  se <- sqrt(diag(V_group))
  z <- beta / se
  p <- 2 * pnorm(abs(z), lower.tail = FALSE)

  inference <- data.frame(
    model = model,
    term = rhs_names,
    estimate = as.numeric(beta),
    robust_se_operational = as.numeric(se),
    z_operational = as.numeric(z),
    p_two_sided_operational = as.numeric(p),
    status = "CONDITIONAL_OPERATIONAL_INFERENCE",
    stringsAsFactors = FALSE
  )

  stopifnot(
    all(is.finite(V_group)),
    cond_recon_diff < 1e-10,
    sym_error < 1e-12,
    min(eig) > -1e-10
  )

  list(
    model = model,
    rhs_names = rhs_names,
    covariance = V_group,
    conditional_lrv = Omega_cond,
    conditional_lrv_direct = Omega_cond_direct,
    orthogonalization = A,
    cond_recon_diff = cond_recon_diff,
    symmetry_error = sym_error,
    eigenvalues = eig,
    inference = inference,
    status = "ADOPTED_OPERATIONAL_APPROXIMATION"
  )
}

tcc_compute_operational_covariances <- function(ctx, group_coef, y_field = "y_excl") {
  models <- c("E2", "E3", "E4")
  out <- lapply(models, function(m) {
    tcc_operational_group_covariance(ctx, group_coef, m, y_field = y_field)
  })
  names(out) <- models
  out
}

# -----------------------------------------------------------------------------
# Frozen H1-H3 evaluation
# -----------------------------------------------------------------------------

tcc_get_operational_row <- function(operational_covariance, model, term) {
  tab <- operational_covariance[[model]]$inference
  out <- tab[tab$term == term, , drop = FALSE]
  stopifnot(nrow(out) == 1L)
  out
}

tcc_evaluate_hypotheses <- function(ctx, group_coef, e1_covariance, operational_covariance) {
  beta_h1 <- group_coef$E1[c("income", "income2")]
  V_h1 <- e1_covariance[c("income", "income2"), c("income", "income2")]

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

  h1_lower <- slope_eval(ctx$x_lower, "positive")
  h1_upper <- slope_eval(ctx$x_upper, "negative")
  h1_iut_p <- max(h1_lower["p_one_sided"], h1_upper["p_one_sided"])

  h1_turning_x <- if (abs(beta_h1["income2"]) > .Machine$double.eps) {
    -beta_h1["income"] / (2 * beta_h1["income2"])
  } else {
    NA_real_
  }

  h1_turning_gdppc <- if (is.finite(h1_turning_x)) {
    exp(ctx$common_gdp_center + h1_turning_x)
  } else {
    NA_real_
  }

  h1_turning_in_support <- is.finite(h1_turning_x) &&
    h1_turning_x >= ctx$x_lower && h1_turning_x <= ctx$x_upper

  h1_supported <- isTRUE(beta_h1["income2"] < 0) &&
    h1_turning_in_support &&
    isTRUE(h1_lower["estimate"] > 0) &&
    isTRUE(h1_upper["estimate"] < 0) &&
    isTRUE(h1_iut_p < ALPHA_PRIMARY)

  H1 <- data.frame(
    hypothesis = "H1_EKC_inverted_U",
    beta_income = unname(beta_h1["income"]),
    beta_income2 = unname(beta_h1["income2"]),
    x_lower = ctx$x_lower,
    x_upper = ctx$x_upper,
    slope_lower = unname(h1_lower["estimate"]),
    slope_lower_se = unname(h1_lower["se"]),
    p_lower_positive = unname(h1_lower["p_one_sided"]),
    slope_upper = unname(h1_upper["estimate"]),
    slope_upper_se = unname(h1_upper["se"]),
    p_upper_negative = unname(h1_upper["p_one_sided"]),
    iut_p = unname(h1_iut_p),
    turning_x = unname(h1_turning_x),
    turning_gdppc = unname(h1_turning_gdppc),
    turning_in_support = h1_turning_in_support,
    h1_supported = h1_supported,
    inference_status = "FORMAL_E1_INFERENCE",
    stringsAsFactors = FALSE
  )

  h2_eval <- function(hypothesis, term) {
    primary <- tcc_get_operational_row(operational_covariance, "E2", term)
    stability <- tcc_get_operational_row(operational_covariance, "E4", term)

    primary_supported <- primary$estimate > 0 &&
      primary$p_two_sided_operational < ALPHA_PRIMARY
    e4_supported <- stability$estimate > 0 &&
      stability$p_two_sided_operational < ALPHA_PRIMARY

    data.frame(
      hypothesis = hypothesis,
      term = term,
      primary_model = "E2",
      primary_estimate = primary$estimate,
      primary_se = primary$robust_se_operational,
      primary_p_two_sided = primary$p_two_sided_operational,
      primary_positive = primary$estimate > 0,
      primary_supported_operationally = primary_supported,
      stability_model = "E4",
      stability_estimate = stability$estimate,
      stability_se = stability$robust_se_operational,
      stability_p_two_sided = stability$p_two_sided_operational,
      stability_positive = stability$estimate > 0,
      sign_preserved_in_e4 = sign(primary$estimate) == sign(stability$estimate),
      operational_support_preserved_in_e4 = primary_supported == e4_supported,
      e4_supported_operationally = e4_supported,
      inference_status = "CONDITIONAL_OPERATIONAL_INFERENCE",
      stringsAsFactors = FALSE
    )
  }

  H2 <- rbind(
    h2_eval("H2a_energy_intensity_positive", "lnIE"),
    h2_eval("H2b_fossil_share_positive", "FFS")
  )

  h3_wald <- function(model) {
    terms <- c("AGR", "IND")
    beta <- group_coef[[model]][terms]
    V <- operational_covariance[[model]]$covariance[terms, terms, drop = FALSE]
    W <- drop(t(beta) %*% solve(V, beta))
    p <- pchisq(W, df = length(terms), lower.tail = FALSE)

    data.frame(
      model = model,
      wald_chisq = W,
      df = length(terms),
      p_joint = p,
      reject_joint_zero_at_5pct = p < ALPHA_PRIMARY,
      inference_status = "CONDITIONAL_OPERATIONAL_INFERENCE",
      stringsAsFactors = FALSE
    )
  }

  h3_e3 <- h3_wald("E3")
  h3_e4 <- h3_wald("E4")
  H3 <- data.frame(
    hypothesis = "H3_productive_composition_joint",
    primary_model = "E3",
    primary_wald_chisq = h3_e3$wald_chisq,
    primary_df = h3_e3$df,
    primary_p_joint = h3_e3$p_joint,
    primary_supported_operationally = h3_e3$reject_joint_zero_at_5pct,
    stability_model = "E4",
    stability_wald_chisq = h3_e4$wald_chisq,
    stability_df = h3_e4$df,
    stability_p_joint = h3_e4$p_joint,
    e4_joint_support_operationally = h3_e4$reject_joint_zero_at_5pct,
    operational_support_preserved_in_e4 =
      h3_e3$reject_joint_zero_at_5pct == h3_e4$reject_joint_zero_at_5pct,
    inference_status = "CONDITIONAL_OPERATIONAL_INFERENCE",
    stringsAsFactors = FALSE
  )

  stability_source <- c(lnIE = "E2", FFS = "E2", AGR = "E3", IND = "E3")
  stability_rows <- lapply(names(stability_source), function(term) {
    pm <- stability_source[[term]]
    primary <- tcc_get_operational_row(operational_covariance, pm, term)
    e4 <- tcc_get_operational_row(operational_covariance, "E4", term)

    data.frame(
      term = term,
      primary_model = pm,
      primary_estimate = primary$estimate,
      primary_se = primary$robust_se_operational,
      primary_p = primary$p_two_sided_operational,
      e4_estimate = e4$estimate,
      e4_se = e4$robust_se_operational,
      e4_p = e4$p_two_sided_operational,
      estimate_change_e4_minus_primary = e4$estimate - primary$estimate,
      sign_preserved = sign(primary$estimate) == sign(e4$estimate),
      conventional_significance_preserved =
        (primary$p_two_sided_operational < ALPHA_PRIMARY) ==
        (e4$p_two_sided_operational < ALPHA_PRIMARY),
      inference_status = "DESCRIPTIVE_STABILITY_UNDER_OPERATIONAL_INFERENCE",
      stringsAsFactors = FALSE
    )
  })
  E4_stability <- do.call(rbind, stability_rows)
  row.names(E4_stability) <- NULL

  list(H1 = H1, H2 = H2, H3 = H3, E4_stability = E4_stability)
}

# -----------------------------------------------------------------------------
# Primary analytical entrypoint
# -----------------------------------------------------------------------------

tcc_run_primary_analysis <- function(ctx, y_field = "y_excl") {
  stack <- tcc_fit_model_stack(ctx, y_field = y_field)

  e1 <- tcc_e1_fixed_n_covariance(
    ctx = ctx,
    group_coef = stack$group_coef,
    y_field = y_field
  )

  operational <- tcc_compute_operational_covariances(
    ctx = ctx,
    group_coef = stack$group_coef,
    y_field = y_field
  )

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

  hypotheses <- tcc_evaluate_hypotheses(
    ctx = ctx,
    group_coef = stack$group_coef,
    e1_covariance = e1$covariance,
    operational_covariance = operational
  )

  group_coefficient_table <- do.call(
    rbind,
    lapply(names(stack$group_coef), function(m) {
      data.frame(
        model = m,
        term = names(stack$group_coef[[m]]),
        estimate = as.numeric(stack$group_coef[[m]]),
        stringsAsFactors = FALSE
      )
    })
  )
  row.names(group_coefficient_table) <- NULL

  list(
    y_field = y_field,
    models_local = stack$models_local,
    models_common = stack$models_common,
    models_direct_common = stack$models_direct_common,
    reconciliation = stack$reconciliation,
    group_coef = stack$group_coef,
    group_coefficient_table = group_coefficient_table,
    fm_health = stack$fm_health,
    e1 = e1,
    operational_covariance = operational,
    operational_summary = operational_summary,
    H1 = hypotheses$H1,
    H2 = hypotheses$H2,
    H3 = hypotheses$H3,
    E4_stability = hypotheses$E4_stability,
    limitation_boundary = paste(
      "E1 uses source-faithful fixed-N CPR covariance;",
      "E2-E4 retain formal full-RHS FM point estimates and an adopted",
      "numerically validated operational covariance approximation;",
      "E2-E4 inference is conditional and not claimed as exact",
      "purpose-built mixed-order CPR inference."
    )
  )
}
