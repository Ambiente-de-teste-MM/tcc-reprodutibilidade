# TCC Stage VIII — núcleo E1–E4 para execução web
# Pilot 01 candidate: shared by CI validation and Quarto Live/webR.
# Analytical source: validated Stage VIII preparation + primary-estimation modules.

TCC_WEB_EXPECTED_GDP_CENTER <- 8.800807836540828
TCC_WEB_FM_BANDWIDTH <- 3L
TCC_WEB_FM_KERNEL <- "ba"
TCC_WEB_COUNTRIES <- c("ARG", "BOL", "BRA", "PRY", "URY")
TCC_WEB_TOLERANCE <- 1e-6

TCC_WEB_MODEL_EXTENSIONS <- list(
  E1 = character(0),
  E2 = c("lnIE", "FFS"),
  E3 = c("AGR", "IND"),
  E4 = c("lnIE", "FFS", "AGR", "IND")
)

TCC_WEB_EXPECTED_GROUP <- list(
  E1 = c(
    income = 1.286757988,
    income2 = 0.147584072
  ),
  E2 = c(
    income = 1.114499578,
    income2 = 0.155821737,
    lnIE = 0.048050301,
    FFS = 0.013193687
  ),
  E3 = c(
    income = 1.107882406,
    income2 = 0.062383006,
    AGR = 0.012283778,
    IND = 0.006994105
  ),
  E4 = c(
    income = 0.974014266,
    income2 = -0.075128704,
    lnIE = 0.055122314,
    FFS = 0.010581815,
    AGR = 0.009670656,
    IND = 0.007620360
  )
)

tcc_web_prepare_panel <- function(dat) {
  required <- c(
    "iso3", "year",
    "ghgpc_tco2e_excl_lulucf",
    "gdp_pc_const2015_usd",
    "energy_intensity_kgoe_per_1000_2021ppp_gdp",
    "fossil_share_pct",
    "agri_va_pct_gdp",
    "industry_va_pct_gdp"
  )

  stopifnot(all(required %in% names(dat)))
  stopifnot(nrow(dat) == 170L)
  stopifnot(setequal(unique(dat$iso3), TCC_WEB_COUNTRIES))
  stopifnot(length(unique(dat$year)) == 34L)
  stopifnot(min(dat$year) == 1990L)
  stopifnot(max(dat$year) == 2023L)
  stopifnot(!anyDuplicated(dat[c("iso3", "year")]))

  dat$y_excl <- log(dat$ghgpc_tco2e_excl_lulucf)
  dat$ln_gdp <- log(dat$gdp_pc_const2015_usd)
  dat$lnIE <- log(dat$energy_intensity_kgoe_per_1000_2021ppp_gdp)
  dat$FFS <- dat$fossil_share_pct
  dat$AGR <- dat$agri_va_pct_gdp
  dat$IND <- dat$industry_va_pct_gdp

  transformed <- c("y_excl", "ln_gdp", "lnIE", "FFS", "AGR", "IND")
  stopifnot(all(vapply(
    dat[transformed],
    function(z) all(is.finite(z)),
    logical(1)
  )))

  common_center <- mean(dat$ln_gdp)
  stopifnot(abs(common_center - TCC_WEB_EXPECTED_GDP_CENTER) < 1e-12)

  list(
    dat = dat,
    split_country = split(dat, dat$iso3),
    common_center = common_center
  )
}

tcc_web_fit_country <- function(d, model, common_center) {
  stopifnot(model %in% names(TCC_WEB_MODEL_EXTENSIONS))
  stopifnot(requireNamespace("cointReg", quietly = TRUE))

  d <- d[order(d$year), , drop = FALSE]
  stopifnot(nrow(d) == 34L)
  stopifnot(identical(as.integer(d$year), 1990:2023))

  local_center <- mean(d$ln_gdp)
  z <- d$ln_gdp - local_center

  rhs <- data.frame(
    income = z,
    income2 = z^2
  )

  ext <- TCC_WEB_MODEL_EXTENSIONS[[model]]
  if (length(ext)) {
    rhs <- cbind(rhs, d[ext])
  }

  D <- matrix(1, nrow = nrow(d), ncol = 1)
  colnames(D) <- "intercept"

  fit <- cointReg::cointRegFM(
    x = as.matrix(rhs),
    y = as.numeric(d$y_excl),
    deter = D,
    kernel = TCC_WEB_FM_KERNEL,
    bandwidth = TCC_WEB_FM_BANDWIDTH,
    demeaning = FALSE,
    check = TRUE
  )

  theta <- as.numeric(fit$theta)
  names(theta) <- c("intercept", names(rhs))

  # Reexpress the income polynomial from the country-specific local center
  # to the common panel center. Extension coefficients are unchanged.
  delta <- common_center - local_center
  theta_common <- theta
  theta_common["intercept"] <-
    theta["intercept"] +
    delta * theta["income"] +
    delta^2 * theta["income2"]
  theta_common["income"] <-
    theta["income"] + 2 * delta * theta["income2"]
  theta_common["income2"] <- theta["income2"]

  theta_common
}

tcc_web_fit_group_model <- function(ctx, model) {
  fits <- lapply(TCC_WEB_COUNTRIES, function(cc) {
    tcc_web_fit_country(
      ctx$split_country[[cc]],
      model = model,
      common_center = ctx$common_center
    )
  })
  names(fits) <- TCC_WEB_COUNTRIES

  slopes <- do.call(rbind, lapply(fits, function(x) {
    x[names(x) != "intercept"]
  }))

  group <- colMeans(slopes)

  list(
    country_coefficients = fits,
    group_coefficients = group
  )
}

tcc_web_compare_group <- function(group_models) {
  rows <- list()

  for (model in names(TCC_WEB_EXPECTED_GROUP)) {
    estimate <- group_models[[model]]$group_coefficients
    reference <- TCC_WEB_EXPECTED_GROUP[[model]]

    stopifnot(identical(names(estimate), names(reference)))

    rows[[model]] <- data.frame(
      model = model,
      term = names(reference),
      estimate = as.numeric(estimate),
      reference = as.numeric(reference),
      difference = as.numeric(estimate - reference),
      abs_difference = as.numeric(abs(estimate - reference)),
      stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out$within_tolerance <- out$abs_difference <= TCC_WEB_TOLERANCE
  out
}

tcc_web_run_core <- function(data_path, validate = TRUE) {
  dat <- utils::read.csv(
    data_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  ctx <- tcc_web_prepare_panel(dat)

  group_models <- lapply(names(TCC_WEB_MODEL_EXTENSIONS), function(model) {
    tcc_web_fit_group_model(ctx, model)
  })
  names(group_models) <- names(TCC_WEB_MODEL_EXTENSIONS)

  comparison <- tcc_web_compare_group(group_models)
  max_abs_diff <- max(comparison$abs_difference)

  if (isTRUE(validate)) {
    stopifnot(is.finite(max_abs_diff))
    stopifnot(max_abs_diff <= TCC_WEB_TOLERANCE)
  }

  list(
    common_center = ctx$common_center,
    group_models = group_models,
    comparison = comparison,
    max_abs_diff = max_abs_diff,
    tolerance = TCC_WEB_TOLERANCE
  )
}

# When this file is executed directly by Rscript, validate the exact same core
# that the browser sources. When sourced by Quarto Live/webR, only definitions
# are loaded and the page controls execution explicitly.
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  data_path <- if (length(args) >= 1L) {
    args[[1L]]
  } else {
    "site/data/tcc_data_panel-canonical-mercosur_1990-2023_2026-10-21_v01.csv"
  }

  result <- tcc_web_run_core(data_path, validate = TRUE)
  print(result$comparison)
  cat(
    "common_center=", format(result$common_center, digits = 16), "\n",
    "max_abs_diff=", format(result$max_abs_diff, scientific = TRUE), "\n",
    "tolerance=", format(result$tolerance, scientific = TRUE), "\n",
    sep = ""
  )
}
