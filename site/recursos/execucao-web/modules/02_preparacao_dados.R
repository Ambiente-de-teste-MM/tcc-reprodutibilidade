# TCC Stage VIII — 02_preparacao_dados.R
# Version: 2026-10-21 v03 (R5 raw-source reconstruction extension)
# Scope: load the certified processed panel and reproduce the analytical
# transformations used by the frozen Stage VI pipeline.
#
# This module preserves the validated certified-panel loader and adds the R5
# deterministic source-native -> normalized extracts -> reconstructed-panel path.
# No source repair, interpolation, row deletion, or methodological redesign is
# permitted here.

# Load and validate the certified distribution-format panel.
tcc_load_canonical_panel <- function(path = CANONICAL_INPUT_PATH) {
  tcc_assert_canonical_file(path)

  dat <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  stopifnot(all(REQUIRED_INPUT_FIELDS %in% names(dat)))
  stopifnot(nrow(dat) == EXPECTED_ROW_COUNT)
  stopifnot(setequal(unique(dat$iso3), FROZEN_COUNTRIES))
  stopifnot(length(unique(dat$year)) == EXPECTED_YEAR_COUNT)
  stopifnot(min(dat$year) == EXPECTED_START_YEAR)
  stopifnot(max(dat$year) == EXPECTED_END_YEAR)
  stopifnot(!anyDuplicated(dat[c("iso3", "year")]))

  stopifnot(all(vapply(
    dat[POSITIVE_INPUT_FIELDS],
    function(z) all(is.finite(z) & z > 0),
    logical(1)
  )))

  stopifnot(all(vapply(
    dat[FINITE_SHARE_FIELDS],
    function(z) all(is.finite(z)),
    logical(1)
  )))

  dat
}

# Reproduce exactly the Stage VI analytical transformations.
tcc_prepare_analysis_panel <- function(dat, source_path = CANONICAL_INPUT_PATH) {
  dat <- as.data.frame(dat, stringsAsFactors = FALSE)

  dat$y_excl <- log(dat$ghgpc_tco2e_excl_lulucf)
  dat$y_incl <- log(dat$ghgpc_tco2e_incl_lulucf)
  dat$ln_gdp <- log(dat$gdp_pc_const2015_usd)

  calculated_gdp_center <- mean(dat$ln_gdp)
  gdp_center_replication_diff <- calculated_gdp_center - EXPECTED_GDP_CENTER
  stopifnot(abs(gdp_center_replication_diff) < 1e-12)

  common_gdp_center <- calculated_gdp_center

  dat$x <- dat$ln_gdp - common_gdp_center
  dat$x2 <- dat$x^2
  dat$lnIE <- log(dat$energy_intensity_kgoe_per_1000_2021ppp_gdp)
  dat$FFS <- dat$fossil_share_pct
  dat$AGR <- dat$agri_va_pct_gdp
  dat$IND <- dat$industry_va_pct_gdp

  transformed_fields <- c(
    "y_excl", "y_incl", "ln_gdp", "x", "x2", "lnIE", "FFS", "AGR", "IND"
  )

  stopifnot(all(vapply(
    dat[transformed_fields],
    function(z) all(is.finite(z)),
    logical(1)
  )))

  split_country <- split(dat, dat$iso3)
  stopifnot(identical(sort(names(split_country)), sort(FROZEN_COUNTRIES)))

  list(
    dat = dat,
    split_country = split_country,
    common_gdp_center = common_gdp_center,
    gdp_center_replication_diff = gdp_center_replication_diff,
    x_lower = min(dat$x),
    x_upper = max(dat$x),
    transformed_fields = transformed_fields,
    source_path = source_path,
    source_md5 = unname(tools::md5sum(source_path))
  )
}

# Convenience entrypoint used by the orchestrator and validation gates.
tcc_build_analysis_context <- function(path = CANONICAL_INPUT_PATH) {
  tcc_prepare_analysis_panel(
    tcc_load_canonical_panel(path),
    source_path = path
  )
}


# -----------------------------------------------------------------------------
# R5 source-native reconstruction
# -----------------------------------------------------------------------------

tcc_order_country_year <- function(dat) {
  dat <- as.data.frame(dat, stringsAsFactors = FALSE)
  dat <- dat[
    order(match(dat$iso3, FROZEN_COUNTRIES), dat$year),
    ,
    drop = FALSE
  ]
  row.names(dat) <- NULL
  dat
}

tcc_add_country_label <- function(dat) {
  dat <- tcc_order_country_year(dat)
  dat$country <- unname(FROZEN_COUNTRY_LABELS[dat$iso3])
  stopifnot(!anyNA(dat$country))
  dat <- dat[c("country", setdiff(names(dat), "country"))]
  dat
}

tcc_write_csv_precise <- function(dat, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  old <- options(digits = 17)
  on.exit(options(old), add = TRUE)

  utils::write.csv(
    dat,
    path,
    row.names = FALSE,
    na = "",
    quote = TRUE
  )

  invisible(normalizePath(path, winslash = "/", mustWork = TRUE))
}

tcc_assert_raw_sources <- function(source_dir = RAW_SOURCE_ROOT) {
  paths <- file.path(source_dir, unname(RAW_SOURCE_FILES))
  names(paths) <- names(RAW_SOURCE_FILES)

  missing <- names(paths)[!file.exists(paths)]
  if (length(missing)) {
    stop(
      "R5 raw-source files missing: ",
      paste(missing, collapse = ", "),
      "\nExpected directory: ", source_dir
    )
  }

  actual_md5 <- unname(tools::md5sum(paths))
  names(actual_md5) <- names(paths)

  mismatch <- names(paths)[actual_md5 != RAW_SOURCE_MD5[names(paths)]]
  if (length(mismatch)) {
    stop(
      "R5 raw-source MD5 mismatch: ",
      paste(mismatch, collapse = ", ")
    )
  }

  data.frame(
    source_key = names(paths),
    filename = unname(RAW_SOURCE_FILES[names(paths)]),
    path = unname(normalizePath(
      paths,
      winslash = "/",
      mustWork = TRUE
    )),
    size_bytes = as.numeric(file.info(paths)$size),
    md5_expected = unname(RAW_SOURCE_MD5[names(paths)]),
    md5_actual = unname(actual_md5),
    stringsAsFactors = FALSE
  )
}

tcc_extract_wdi <- function(path, code_map) {
  tcc_require_packages("readxl")

  raw <- as.data.frame(
    readxl::read_excel(
      path,
      sheet = "Data",
      na = c("..", "")
    ),
    stringsAsFactors = FALSE
  )

  required_meta <- c(
    "Series Name", "Series Code", "Country Name", "Country Code"
  )
  years <- EXPECTED_START_YEAR:EXPECTED_END_YEAR
  year_cols <- paste0(years, " [YR", years, "]")

  stopifnot(all(required_meta %in% names(raw)))
  stopifnot(all(year_cols %in% names(raw)))

  pieces <- vector("list", length(code_map))
  names(pieces) <- names(code_map)

  for (out_name in names(code_map)) {
    code <- unname(code_map[[out_name]])

    sub <- raw[
      raw[["Series Code"]] == code &
        raw[["Country Code"]] %in% FROZEN_COUNTRIES,
      ,
      drop = FALSE
    ]

    stopifnot(nrow(sub) == length(FROZEN_COUNTRIES))
    stopifnot(!anyDuplicated(sub[["Country Code"]]))

    rows <- lapply(seq_len(nrow(sub)), function(i) {
      vals <- as.numeric(unlist(
        sub[i, year_cols, drop = FALSE],
        use.names = FALSE
      ))

      data.frame(
        iso3 = as.character(sub[["Country Code"]][i]),
        year = as.integer(years),
        value = vals,
        stringsAsFactors = FALSE
      )
    })

    z <- do.call(rbind, rows)
    names(z)[names(z) == "value"] <- out_name
    z <- tcc_order_country_year(z)

    stopifnot(nrow(z) == EXPECTED_ROW_COUNT)
    stopifnot(all(is.finite(z[[out_name]])))

    pieces[[out_name]] <- z
  }

  out <- pieces[[1L]]
  if (length(pieces) > 1L) {
    for (i in 2:length(pieces)) {
      out <- merge(
        out,
        pieces[[i]],
        by = c("iso3", "year"),
        all = TRUE,
        sort = FALSE
      )
    }
  }

  out <- tcc_order_country_year(out)
  stopifnot(nrow(out) == EXPECTED_ROW_COUNT)
  stopifnot(!anyDuplicated(out[c("iso3", "year")]))
  out
}

tcc_extract_climate_watch <- function(path) {
  raw <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  required <- c("ISO", "Country", "Sector", "Gas", "Unit")
  years <- EXPECTED_START_YEAR:EXPECTED_END_YEAR
  year_cols <- as.character(years)

  stopifnot(all(required %in% names(raw)))
  stopifnot(all(year_cols %in% names(raw)))

  sector_map <- c(
    ghg_mtco2e_incl_lulucf = "Total including LULUCF",
    ghg_mtco2e_excl_lulucf = "Total excluding LULUCF"
  )

  pieces <- vector("list", length(sector_map))
  names(pieces) <- names(sector_map)

  for (out_name in names(sector_map)) {
    sector <- unname(sector_map[[out_name]])

    rows <- lapply(FROZEN_COUNTRIES, function(cc) {
      z <- raw[
        raw$ISO == cc &
          raw$Sector == sector &
          raw$Gas == "All GHG",
        ,
        drop = FALSE
      ]

      stopifnot(nrow(z) == 1L)
      stopifnot(identical(as.character(z$Unit), "MtCO₂e"))

      vals <- as.numeric(unlist(
        z[1L, year_cols, drop = FALSE],
        use.names = FALSE
      ))

      data.frame(
        iso3 = cc,
        year = as.integer(years),
        value = vals,
        stringsAsFactors = FALSE
      )
    })

    z <- do.call(rbind, rows)
    names(z)[names(z) == "value"] <- out_name
    pieces[[out_name]] <- tcc_order_country_year(z)
  }

  out <- merge(
    pieces[[1L]],
    pieces[[2L]],
    by = c("iso3", "year"),
    all = TRUE,
    sort = FALSE
  )
  out <- tcc_order_country_year(out)

  stopifnot(nrow(out) == EXPECTED_ROW_COUNT)
  stopifnot(!anyDuplicated(out[c("iso3", "year")]))
  stopifnot(all(is.finite(out$ghg_mtco2e_incl_lulucf)))
  stopifnot(all(is.finite(out$ghg_mtco2e_excl_lulucf)))
  out
}

tcc_extract_owid_fossil <- function(path) {
  raw <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  stopifnot(all(c("Entity", "Code", "Year", "Gas", "Oil", "Coal") %in% names(raw)))

  z <- raw[
    raw$Code %in% FROZEN_COUNTRIES &
      raw$Year >= EXPECTED_START_YEAR &
      raw$Year <= EXPECTED_END_YEAR,
    c("Code", "Year", "Gas", "Oil", "Coal"),
    drop = FALSE
  ]

  names(z) <- c(
    "iso3", "year",
    "fossil_gas_twh",
    "fossil_oil_twh",
    "fossil_coal_twh"
  )

  z$year <- as.integer(z$year)
  z <- tcc_order_country_year(z)

  stopifnot(nrow(z) == EXPECTED_ROW_COUNT)
  stopifnot(!anyDuplicated(z[c("iso3", "year")]))
  stopifnot(all(vapply(
    z[c("fossil_gas_twh", "fossil_oil_twh", "fossil_coal_twh")],
    function(x) all(is.finite(x)),
    logical(1)
  )))
  z
}

tcc_extract_owid_total_energy <- function(path) {
  raw <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  stopifnot(all(c("Entity", "Code", "Year", "Total energy supply") %in% names(raw)))

  z <- raw[
    raw$Code %in% FROZEN_COUNTRIES &
      raw$Year >= EXPECTED_START_YEAR &
      raw$Year <= EXPECTED_END_YEAR,
    c("Code", "Year", "Total energy supply"),
    drop = FALSE
  ]

  names(z) <- c("iso3", "year", "total_energy_supply_twh")
  z$year <- as.integer(z$year)
  z <- tcc_order_country_year(z)

  stopifnot(nrow(z) == EXPECTED_ROW_COUNT)
  stopifnot(!anyDuplicated(z[c("iso3", "year")]))
  stopifnot(all(is.finite(z$total_energy_supply_twh)))
  stopifnot(all(z$total_energy_supply_twh > 0))
  z
}

tcc_join_source_extracts <- function(extracts) {
  stopifnot(length(extracts) >= 1L)

  out <- extracts[[1L]]
  if (length(extracts) > 1L) {
    for (i in 2:length(extracts)) {
      out <- merge(
        out,
        extracts[[i]],
        by = c("iso3", "year"),
        all = TRUE,
        sort = FALSE
      )
    }
  }

  out <- tcc_order_country_year(out)
  stopifnot(nrow(out) == EXPECTED_ROW_COUNT)
  stopifnot(!anyDuplicated(out[c("iso3", "year")]))
  out
}

tcc_derived_identity_audit <- function(panel) {
  checks <- c(
    ghgpc_incl = max(abs(
      panel$ghgpc_tco2e_incl_lulucf -
        panel$ghg_mtco2e_incl_lulucf * 1e6 / panel$population_wdi
    )),
    ghgpc_excl = max(abs(
      panel$ghgpc_tco2e_excl_lulucf -
        panel$ghg_mtco2e_excl_lulucf * 1e6 / panel$population_wdi
    )),
    fossil_share = max(abs(
      panel$fossil_share_pct -
        (
          panel$fossil_gas_twh +
            panel$fossil_oil_twh +
            panel$fossil_coal_twh
        ) / panel$total_energy_supply_twh * 100
    )),
    gdp_sq = max(abs(
      panel$gdp_pc_sq_level_candidate -
        panel$gdp_pc_const2015_usd^2
    ))
  )

  stopifnot(all(is.finite(checks)))
  stopifnot(max(checks) < 1e-10)
  checks
}

tcc_compare_panels <- function(
  reconstructed,
  canonical,
  relative_tolerance = 1e-12
) {
  reconstructed <- tcc_order_country_year(reconstructed)
  canonical <- tcc_order_country_year(canonical)

  stopifnot(identical(names(reconstructed), EXPECTED_CANONICAL_COLUMNS))
  stopifnot(identical(names(canonical), EXPECTED_CANONICAL_COLUMNS))
  stopifnot(nrow(reconstructed) == EXPECTED_ROW_COUNT)
  stopifnot(nrow(canonical) == EXPECTED_ROW_COUNT)

  char_cols <- c("country", "iso3")
  int_cols <- "year"
  numeric_cols <- setdiff(
    EXPECTED_CANONICAL_COLUMNS,
    c(char_cols, int_cols)
  )

  character_pass <- vapply(
    char_cols,
    function(nm) identical(
      as.character(reconstructed[[nm]]),
      as.character(canonical[[nm]])
    ),
    logical(1)
  )

  integer_pass <- vapply(
    int_cols,
    function(nm) identical(
      as.integer(reconstructed[[nm]]),
      as.integer(canonical[[nm]])
    ),
    logical(1)
  )

  rows <- lapply(numeric_cols, function(nm) {
    a <- as.numeric(reconstructed[[nm]])
    b <- as.numeric(canonical[[nm]])

    abs_diff <- abs(a - b)
    scaled_diff <- abs_diff / pmax(1, abs(b))

    data.frame(
      field = nm,
      max_abs_difference = max(abs_diff),
      max_scaled_difference = max(scaled_diff),
      tolerance = relative_tolerance,
      pass = max(scaled_diff) <= relative_tolerance,
      stringsAsFactors = FALSE
    )
  })

  numeric_audit <- do.call(rbind, rows)
  row.names(numeric_audit) <- NULL

  stopifnot(all(character_pass))
  stopifnot(all(integer_pass))
  stopifnot(all(numeric_audit$pass))

  list(
    character_pass = character_pass,
    integer_pass = integer_pass,
    numeric = numeric_audit,
    max_scaled_difference = max(numeric_audit$max_scaled_difference)
  )
}

tcc_reconstruct_canonical_panel <- function(
  source_dir = RAW_SOURCE_ROOT,
  extract_dir = EXTRACT_ROOT,
  write_extracts = TRUE
) {
  source_manifest <- tcc_assert_raw_sources(source_dir)
  paths <- setNames(source_manifest$path, source_manifest$source_key)

  wdi_main <- tcc_extract_wdi(
    paths[["wdi_economy_composition"]],
    WDI_ACTIVE_CODES[c(
      "gdp_pc_const2015_usd",
      "energy_intensity_kgoe_per_1000_2021ppp_gdp",
      "agri_va_pct_gdp",
      "industry_va_pct_gdp"
    )]
  )

  wdi_population <- tcc_extract_wdi(
    paths[["wdi_population"]],
    WDI_ACTIVE_CODES["population_wdi"]
  )

  climate_watch <- tcc_extract_climate_watch(
    paths[["climate_watch_ghg"]]
  )

  owid_fossil <- tcc_extract_owid_fossil(
    paths[["owid_fossil_components"]]
  )

  owid_total_energy <- tcc_extract_owid_total_energy(
    paths[["owid_total_energy_supply"]]
  )

  extracts <- list(
    wdi_economy_composition = wdi_main,
    wdi_population = wdi_population,
    climate_watch_ghg = climate_watch,
    owid_fossil_components = owid_fossil,
    owid_total_energy_supply = owid_total_energy
  )

  if (isTRUE(write_extracts)) {
    extract_files <- c(
      wdi_economy_composition =
        "wdi_economy-composition_mercosur_1990-2023.csv",
      wdi_population =
        "wdi_population_mercosur_1990-2023.csv",
      climate_watch_ghg =
        "climate-watch_ghg-totals_mercosur_1990-2023.csv",
      owid_fossil_components =
        "owid_fossil-components_mercosur_1990-2023.csv",
      owid_total_energy_supply =
        "owid_total-energy-supply_mercosur_1990-2023.csv"
    )

    dir.create(extract_dir, recursive = TRUE, showWarnings = FALSE)

    for (nm in names(extracts)) {
      tcc_write_csv_precise(
        tcc_add_country_label(extracts[[nm]]),
        file.path(extract_dir, extract_files[[nm]])
      )
    }
  }

  panel <- tcc_join_source_extracts(extracts)
  panel$country <- unname(FROZEN_COUNTRY_LABELS[panel$iso3])
  stopifnot(!anyNA(panel$country))

  panel$ghgpc_tco2e_incl_lulucf <-
    panel$ghg_mtco2e_incl_lulucf * 1e6 / panel$population_wdi

  panel$ghgpc_tco2e_excl_lulucf <-
    panel$ghg_mtco2e_excl_lulucf * 1e6 / panel$population_wdi

  panel$fossil_share_pct <-
    (
      panel$fossil_gas_twh +
        panel$fossil_oil_twh +
        panel$fossil_coal_twh
    ) / panel$total_energy_supply_twh * 100

  panel$gdp_pc_sq_level_candidate <-
    panel$gdp_pc_const2015_usd^2

  panel <- panel[EXPECTED_CANONICAL_COLUMNS]
  panel <- tcc_order_country_year(panel)

  stopifnot(nrow(panel) == EXPECTED_ROW_COUNT)
  stopifnot(!anyDuplicated(panel[c("iso3", "year")]))
  stopifnot(all(vapply(
    panel[setdiff(EXPECTED_CANONICAL_COLUMNS, c("country", "iso3"))],
    function(x) all(is.finite(x)),
    logical(1)
  )))
  stopifnot(all(panel$fossil_share_pct >= 0 & panel$fossil_share_pct <= 100))
  stopifnot(all(panel$agri_va_pct_gdp >= 0 & panel$agri_va_pct_gdp <= 100))
  stopifnot(all(panel$industry_va_pct_gdp >= 0 & panel$industry_va_pct_gdp <= 100))

  identity_audit <- tcc_derived_identity_audit(panel)

  list(
    panel = panel,
    extracts = extracts,
    source_manifest = source_manifest,
    identity_audit = identity_audit
  )
}

tcc_build_analysis_context_from_raw <- function(
  source_dir = RAW_SOURCE_ROOT,
  extract_dir = EXTRACT_ROOT,
  reconstructed_path = RECONSTRUCTED_PANEL_PATH,
  canonical_path = CANONICAL_INPUT_PATH,
  relative_tolerance = 1e-12
) {
  rec <- tcc_reconstruct_canonical_panel(
    source_dir = source_dir,
    extract_dir = extract_dir,
    write_extracts = TRUE
  )

  canonical <- tcc_load_canonical_panel(canonical_path)
  comparison <- tcc_compare_panels(
    rec$panel,
    canonical,
    relative_tolerance = relative_tolerance
  )

  tcc_write_csv_precise(rec$panel, reconstructed_path)

  # Re-read the emitted reconstruction to ensure serialization retains the
  # validated data surface within the same strict scale-aware tolerance.
  emitted <- utils::read.csv(
    reconstructed_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  emitted_comparison <- tcc_compare_panels(
    emitted,
    canonical,
    relative_tolerance = relative_tolerance
  )

  ctx <- tcc_prepare_analysis_panel(
    rec$panel,
    source_path = reconstructed_path
  )

  list(
    context = ctx,
    reconstructed_panel = rec$panel,
    source_extracts = rec$extracts,
    source_manifest = rec$source_manifest,
    identity_audit = rec$identity_audit,
    canonical_comparison = comparison,
    emitted_comparison = emitted_comparison,
    reconstructed_path = normalizePath(
      reconstructed_path,
      winslash = "/",
      mustWork = TRUE
    ),
    reconstructed_md5 = unname(tools::md5sum(reconstructed_path))
  )
}
