# TCC Stage VIII — 01_configuracao.R
# Version: 2026-10-29 v04 (Pass 02 publication-integration remediation; pending revalidation)
# Scope: bounded refactor of Stage VI frozen settings/path/package configuration.
# IMPORTANT: this file does not alter estimator design, hypotheses, sample,
# specifications E1-E4, frozen results, or interpretation.

options(stringsAsFactors = FALSE)
options(scipen = 999)

# -----------------------------------------------------------------------------
# 1. Frozen analytical settings
# -----------------------------------------------------------------------------

EXPECTED_GDP_CENTER <- 8.800807836540828

FROZEN_FM_BANDWIDTH <- 3L
FROZEN_FM_KERNEL <- "ba"
FROZEN_COUNTRIES <- c("ARG", "BOL", "BRA", "PRY", "URY")

EXPECTED_ROW_COUNT <- 170L
EXPECTED_YEAR_COUNT <- 34L
EXPECTED_START_YEAR <- 1990L
EXPECTED_END_YEAR <- 2023L

FROZEN_MODEL_EXTENSIONS <- list(
  E1 = character(0),
  E2 = c("lnIE", "FFS"),
  E3 = c("AGR", "IND"),
  E4 = c("lnIE", "FFS", "AGR", "IND")
)

ALPHA_PRIMARY <- 0.05

# Frozen B08 exclusion rules. These remain descriptive point-estimate
# sensitivity definitions, not alternative primary samples.
FROZEN_B08_EXCLUSIONS <- list(
  E2_REDUCED = list(
    list(iso3 = "BOL", year_min = 2000L, year_max = 2000L)
  ),
  E3_REDUCED = list(
    list(iso3 = "BRA", year_min = 1990L, year_max = 1994L),
    list(iso3 = "BOL", year_min = 2017L, year_max = 2023L),
    list(iso3 = "URY", year_min = 2016L, year_max = 2023L)
  )
)
FROZEN_B08_EXCLUSIONS$E4_REDUCED <- c(
  FROZEN_B08_EXCLUSIONS$E2_REDUCED,
  FROZEN_B08_EXCLUSIONS$E3_REDUCED
)

EXPECTED_B08_N <- c(E2 = 169L, E3 = 150L, E4 = 149L)

# B08 one-at-a-time E4 decompositions are the same four documented flags,
# evaluated separately. They are descriptive point-estimate checks only.
FROZEN_B08_ONE_AT_A_TIME <- list(
  E4_BOL2000_ONLY = list(
    list(iso3 = "BOL", year_min = 2000L, year_max = 2000L)
  ),
  E4_BRA1995_ONLY = list(
    list(iso3 = "BRA", year_min = 1990L, year_max = 1994L)
  ),
  E4_BOL2017_ONLY = list(
    list(iso3 = "BOL", year_min = 2017L, year_max = 2023L)
  ),
  E4_URY2016_ONLY = list(
    list(iso3 = "URY", year_min = 2016L, year_max = 2023L)
  )
)

FROZEN_B08_PRIMARY_SPECS <- c(
  E2 = "E2_REDUCED",
  E3 = "E3_REDUCED",
  E4 = "E4_REDUCED"
)

FROZEN_B08_E4_ONE_AT_A_TIME_SPECS <- c(
  BOL2000 = "E4_BOL2000_ONLY",
  BRA1995 = "E4_BRA1995_ONLY",
  BOL2017 = "E4_BOL2017_ONLY",
  URY2016 = "E4_URY2016_ONLY"
)

FROZEN_B08_ALL_RULES <- c(
  FROZEN_B08_EXCLUSIONS,
  FROZEN_B08_ONE_AT_A_TIME
)

# Complementary-null CPR critical values retained from the accepted B07/B09 code.
FROZEN_CPR_CT_CRIT_5 <- 0.2927
FROZEN_CPR_PU_CRIT_5 <- 37.8748

# -----------------------------------------------------------------------------
# 2. Package requirements
# -----------------------------------------------------------------------------

# Do not install packages inside the analytical pipeline. The execution surface
# (local R/RStudio or another compatible execution environment) must provide dependencies first.
PKG_REQUIRED_CORE <- c("cointReg", "readxl")
PKG_REQUIRED_TABLES <- c("openxlsx")
PKG_REQUIRED_FIGURES <- c("ggplot2", "scales", "svglite", "ragg", "systemfonts")

tcc_require_packages <- function(packages) {
  missing <- packages[
    !vapply(packages, requireNamespace, logical(1), quietly = TRUE)
  ]

  if (length(missing)) {
    stop(
      "Missing required R packages: ",
      paste(missing, collapse = ", "),
      "\nInstall them before running the reproducibility pipeline."
    )
  }

  invisible(TRUE)
}

# -----------------------------------------------------------------------------
# 3. Portable paths
# -----------------------------------------------------------------------------

tcc_normalize_existing <- function(path) {
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

tcc_project_root <- function() {
  explicit <- Sys.getenv("TCC_PROJECT_ROOT", unset = "")
  if (nzchar(explicit)) {
    return(tcc_normalize_existing(explicit))
  }

  tcc_normalize_existing(getwd())
}

PROJECT_ROOT <- tcc_project_root()

# TCC_DATA_DIR allows a hosted or otherwise separate execution surface to attach
# the versioned dataset outside the code working directory.
DATA_ROOT <- Sys.getenv(
  "TCC_DATA_DIR",
  unset = file.path(PROJECT_ROOT, "dados")
)

CANONICAL_INPUT_FILE <- "tcc_data_panel-canonical-mercosur_1990-2023_2026-10-21_v01.csv"
CANONICAL_INPUT_PATH <- file.path(DATA_ROOT, "processados", CANONICAL_INPUT_FILE)

# Byte-level identity for the certified CSV serialization created in R0.
EXPECTED_CANONICAL_MD5 <- "e71061bfdeb3ba8ea9f258905727718c"


# R5 source-native reconstruction contract.
RAW_SOURCE_ROOT <- Sys.getenv(
  "TCC_RAW_SOURCE_DIR",
  unset = file.path(DATA_ROOT, "fontes_originais")
)

EXTRACT_ROOT <- Sys.getenv(
  "TCC_EXTRACT_DIR",
  unset = file.path(DATA_ROOT, "extratos_csv")
)

RECONSTRUCTED_PANEL_FILE <-
  "tcc_data_panel-reconstructed-from-sources_1990-2023_2026-10-21_v01.csv"
RECONSTRUCTED_PANEL_PATH <- file.path(
  DATA_ROOT,
  "processados",
  RECONSTRUCTED_PANEL_FILE
)

FROZEN_COUNTRY_LABELS <- c(
  ARG = "Argentina",
  BOL = "Bolivia",
  BRA = "Brazil",
  PRY = "Paraguay",
  URY = "Uruguay"
)

RAW_SOURCE_FILES <- c(
  wdi_economy_composition =
    "tcc_data_source_wdi_economy-composition_2026-08-31_v01.xlsx",
  wdi_population =
    "tcc_data_source_wdi_population-plus-fossil-share_2026-08-31_v01.xlsx",
  climate_watch_ghg =
    "tcc_data_source_climate-watch_ghg-historical_2026-08-31_v01.csv",
  owid_fossil_components =
    "tcc_data_source_owid_fossil-consumption-by-fuel_2026-08-31_v01.csv",
  owid_total_energy_supply =
    "tcc_data_source_owid_total-energy-supply_2026-08-31_v01.csv"
)

RAW_SOURCE_MD5 <- c(
  wdi_economy_composition = "11cd7bb1eb11f83899625b09f1383c9f",
  wdi_population = "ffe14c2407a18794326f390650f6190b",
  climate_watch_ghg = "413f54f2016c82fb2f83c28f343bf211",
  owid_fossil_components = "e1a46c8a03d96db5aa11aefcd6b40bbb",
  owid_total_energy_supply = "1f1a5e4e0a1e3742607db37946235a65"
)

WDI_ACTIVE_CODES <- c(
  gdp_pc_const2015_usd = "NY.GDP.PCAP.KD",
  energy_intensity_kgoe_per_1000_2021ppp_gdp = "EG.USE.COMM.GD.PP.KD",
  agri_va_pct_gdp = "NV.AGR.TOTL.ZS",
  industry_va_pct_gdp = "NV.IND.TOTL.ZS",
  population_wdi = "SP.POP.TOTL"
)

EXPECTED_CANONICAL_COLUMNS <- c(
  "country", "iso3", "year",
  "population_wdi",
  "ghg_mtco2e_incl_lulucf",
  "ghg_mtco2e_excl_lulucf",
  "ghgpc_tco2e_incl_lulucf",
  "ghgpc_tco2e_excl_lulucf",
  "gdp_pc_const2015_usd",
  "energy_intensity_kgoe_per_1000_2021ppp_gdp",
  "fossil_gas_twh",
  "fossil_oil_twh",
  "fossil_coal_twh",
  "total_energy_supply_twh",
  "fossil_share_pct",
  "agri_va_pct_gdp",
  "industry_va_pct_gdp",
  "gdp_pc_sq_level_candidate"
)

RESULT_ROOT <- Sys.getenv(
  "TCC_RESULT_DIR",
  unset = file.path(PROJECT_ROOT, "resultados")
)

PATH_MODELS <- file.path(RESULT_ROOT, "modelos")
PATH_TABLES <- file.path(RESULT_ROOT, "tabelas")
PATH_FIGURES <- file.path(RESULT_ROOT, "figuras")
PATH_DIAGNOSTICS <- file.path(RESULT_ROOT, "diagnosticos")
PATH_SENSITIVITIES <- file.path(RESULT_ROOT, "sensibilidades")
PATH_LOGS <- file.path(RESULT_ROOT, "logs")
REFERENCE_ENVIRONMENT_PATH <- file.path(PROJECT_ROOT, "referencia", "ambiente_execucao_referencia.csv")
CURRENT_ENVIRONMENT_PATH <- file.path(PATH_LOGS, "ambiente_execucao.csv")
ENVIRONMENT_COMPARISON_PATH <- file.path(PATH_LOGS, "comparacao_ambiente.csv")

tcc_create_output_dirs <- function() {
  dirs <- c(
    RESULT_ROOT,
    PATH_MODELS,
    PATH_TABLES,
    PATH_FIGURES,
    PATH_DIAGNOSTICS,
    PATH_SENSITIVITIES,
    PATH_LOGS
  )

  invisible(vapply(
    dirs,
    dir.create,
    logical(1),
    recursive = TRUE,
    showWarnings = FALSE
  ))
}

# -----------------------------------------------------------------------------
# 4. Canonical-input contract
# -----------------------------------------------------------------------------

REQUIRED_INPUT_FIELDS <- c(
  "country", "iso3", "year",
  "ghgpc_tco2e_incl_lulucf",
  "ghgpc_tco2e_excl_lulucf",
  "gdp_pc_const2015_usd",
  "energy_intensity_kgoe_per_1000_2021ppp_gdp",
  "fossil_share_pct",
  "agri_va_pct_gdp",
  "industry_va_pct_gdp"
)

POSITIVE_INPUT_FIELDS <- c(
  "ghgpc_tco2e_incl_lulucf",
  "ghgpc_tco2e_excl_lulucf",
  "gdp_pc_const2015_usd",
  "energy_intensity_kgoe_per_1000_2021ppp_gdp"
)

FINITE_SHARE_FIELDS <- c(
  "fossil_share_pct",
  "agri_va_pct_gdp",
  "industry_va_pct_gdp"
)

tcc_assert_canonical_file <- function(path = CANONICAL_INPUT_PATH) {
  if (!file.exists(path)) {
    stop(
      "Canonical analytical CSV not found: ", path,
      "\nSet TCC_DATA_DIR if the dataset is attached outside the project root."
    )
  }

  actual_md5 <- unname(tools::md5sum(path))
  if (!identical(actual_md5, EXPECTED_CANONICAL_MD5)) {
    stop(
      "Canonical CSV MD5 mismatch.\n",
      "Expected: ", EXPECTED_CANONICAL_MD5, "\n",
      "Actual:   ", actual_md5, "\n",
      "Refuse to continue until the input version is resolved."
    )
  }

  invisible(TRUE)
}

# -----------------------------------------------------------------------------
# 5. Environment/provenance helper
# -----------------------------------------------------------------------------

tcc_environment_record <- function() {
  core_packages <- unique(c(
    PKG_REQUIRED_CORE,
    PKG_REQUIRED_TABLES,
    PKG_REQUIRED_FIGURES
  ))

  versions <- vapply(
    core_packages,
    function(pkg) {
      if (requireNamespace(pkg, quietly = TRUE)) {
        as.character(utils::packageVersion(pkg))
      } else {
        NA_character_
      }
    },
    character(1)
  )

  sys <- Sys.info()
  ext <- extSoftVersion()
  rstudio_version <- Sys.getenv("RSTUDIO_VERSION", unset = "")
  if (!nzchar(rstudio_version)) rstudio_version <- NA_character_

  execution_surface <- Sys.getenv("TCC_EXECUTION_SURFACE", unset = "")
  if (!nzchar(execution_surface)) {
    execution_surface <- if (identical(Sys.getenv("RSTUDIO"), "1")) {
      "RStudio"
    } else {
      "R session (surface not explicitly identified)"
    }
  }

  os_parts <- c(sys[["sysname"]], sys[["release"]], sys[["version"]])
  os_parts <- os_parts[!is.na(os_parts) & nzchar(os_parts)]

  list(
    record_type = "current_run",
    timestamp_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    execution_surface = execution_surface,
    r_version = R.version.string,
    platform = R.version$platform,
    architecture = R.version$arch,
    operating_system = if (length(os_parts)) paste(os_parts, collapse = " ") else NA_character_,
    rstudio_version = rstudio_version,
    locale = Sys.getlocale(),
    timezone = suppressWarnings(Sys.timezone()),
    blas = if ("BLAS" %in% names(ext)) unname(ext[["BLAS"]]) else NA_character_,
    lapack = if ("LAPACK" %in% names(ext)) unname(ext[["LAPACK"]]) else NA_character_,
    project_root = PROJECT_ROOT,
    data_root = DATA_ROOT,
    canonical_input = CANONICAL_INPUT_PATH,
    canonical_md5_expected = EXPECTED_CANONICAL_MD5,
    package_versions = versions
  )
}

tcc_environment_table <- function(env = tcc_environment_record()) {
  scalar_fields <- c(
    tipo_registro = env$record_type,
    data_hora_utc = env$timestamp_utc,
    superficie_execucao = env$execution_surface,
    versao_r = env$r_version,
    plataforma = env$platform,
    arquitetura = env$architecture,
    sistema_operacional = env$operating_system,
    versao_rstudio = env$rstudio_version,
    localidade = env$locale,
    fuso_horario = env$timezone,
    blas = env$blas,
    lapack = env$lapack,
    raiz_projeto = env$project_root,
    raiz_dados = env$data_root,
    entrada_canonica = env$canonical_input,
    md5_canonico_esperado = env$canonical_md5_expected
  )

  package_fields <- setNames(
    unname(env$package_versions),
    paste0("pacote::", names(env$package_versions))
  )

  values <- c(scalar_fields, package_fields)
  values[is.na(values) | !nzchar(values)] <- "NA"

  data.frame(
    campo = names(values),
    valor = unname(values),
    stringsAsFactors = FALSE
  )
}
