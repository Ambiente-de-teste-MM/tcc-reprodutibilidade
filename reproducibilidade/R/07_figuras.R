# TCC Stage VIII — 07_figuras.R
# Version: 2026-10-21 v01
# Scope: Figures 1-3 from certified analytical data and validated result objects.
#
# IMPORTANT
# - This module does not estimate or re-estimate any model.
# - Figure 1 MUST consume the validated E1 group coefficients and covariance.
# - There is no hard-coded coefficient/covariance production fallback.
# - Figures 2-3 are descriptive series from the certified analytical panel.

TCC_COUNTRY_LABELS <- c(
  ARG = "Argentina",
  BOL = "Bolívia",
  BRA = "Brasil",
  PRY = "Paraguai",
  URY = "Uruguai"
)

TCC_LINE_TYPES <- c(
  "Argentina" = "solid",
  "Bolívia" = "dashed",
  "Brasil" = "dotdash",
  "Paraguai" = "longdash",
  "Uruguai" = "twodash"
)

tcc_resolve_figure_font <- function(requested = "Times New Roman") {
  tcc_require_packages("systemfonts")
  font_path <- tryCatch(
    systemfonts::match_font(requested)$path,
    error = function(e) ""
  )
  if (is.character(font_path) && length(font_path) && nzchar(font_path)) {
    list(requested = requested, used = requested, exact = TRUE)
  } else {
    list(requested = requested, used = "serif", exact = FALSE)
  }
}

tcc_figure_theme <- function(font_family) {
  ggplot2::theme_minimal(base_family = font_family, base_size = 10) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      axis.title = ggplot2::element_text(size = 10),
      axis.text = ggplot2::element_text(size = 9),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(size = 8.5),
      legend.key.width = grid::unit(1.25, "cm"),
      plot.margin = ggplot2::margin(8, 8, 8, 8)
    )
}

tcc_figure1_data <- function(ctx, primary, grid_n = 400L) {
  stopifnot(identical(primary$y_field, "y_excl"))
  beta <- primary$group_coef$E1[c("income", "income2")]
  V <- primary$e1$covariance[c("income", "income2"), c("income", "income2"), drop = FALSE]

  stopifnot(
    length(beta) == 2L,
    all(is.finite(beta)),
    all(is.finite(V)),
    nrow(V) == 2L,
    ncol(V) == 2L,
    grid_n >= 2L
  )

  x_grid <- seq(ctx$x_lower, ctx$x_upper, length.out = as.integer(grid_n))
  gdppc_grid <- exp(ctx$common_gdp_center + x_grid)
  slope <- beta[["income"]] + 2 * beta[["income2"]] * x_grid
  slope_var <-
    V["income", "income"] +
    4 * x_grid * V["income", "income2"] +
    4 * (x_grid^2) * V["income2", "income2"]

  stopifnot(all(is.finite(slope_var)), all(slope_var >= -1e-12))
  slope_se <- sqrt(pmax(slope_var, 0))
  z95 <- stats::qnorm(0.975)

  data.frame(
    gdppc = gdppc_grid,
    x = x_grid,
    elasticity = slope,
    ci95_lower = slope - z95 * slope_se,
    ci95_upper = slope + z95 * slope_se,
    stringsAsFactors = FALSE
  )
}

tcc_ghg_figure_data <- function(ctx, value_field) {
  stopifnot(value_field %in% c(
    "ghgpc_tco2e_excl_lulucf",
    "ghgpc_tco2e_incl_lulucf"
  ))

  country <- factor(
    TCC_COUNTRY_LABELS[ctx$dat$iso3],
    levels = unname(TCC_COUNTRY_LABELS[FROZEN_COUNTRIES])
  )

  data.frame(
    year = ctx$dat$year,
    country = country,
    value = ctx$dat[[value_field]],
    stringsAsFactors = FALSE
  )
}

tcc_build_ghg_series_plot <- function(plot_data, font_family) {
  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = year, y = value, group = country,
      color = country, linetype = country
    )
  ) +
    ggplot2::geom_line(linewidth = 0.70) +
    ggplot2::scale_color_grey(start = 0.15, end = 0.72) +
    ggplot2::scale_linetype_manual(values = TCC_LINE_TYPES) +
    ggplot2::scale_x_continuous(
      breaks = seq(1990, 2020, by = 5),
      minor_breaks = NULL,
      limits = c(1990, 2023),
      expand = ggplot2::expansion(mult = c(0.005, 0.01))
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_number(
        decimal.mark = ",", big.mark = ".", accuracy = 0.1
      ),
      expand = ggplot2::expansion(mult = c(0.03, 0.07))
    ) +
    ggplot2::labs(
      x = "Ano",
      y = "Emissões de GEE per capita (tCO₂e per capita)",
      color = NULL, linetype = NULL
    ) +
    tcc_figure_theme(font_family)
}

tcc_build_figures <- function(
    ctx,
    primary,
    font_requested = "Times New Roman",
    grid_n = 400L) {

  tcc_require_packages(c("ggplot2", "scales", "systemfonts"))

  font <- tcc_resolve_figure_font(font_requested)
  f1_data <- tcc_figure1_data(ctx, primary, grid_n = grid_n)
  f2_data <- tcc_ghg_figure_data(ctx, "ghgpc_tco2e_excl_lulucf")
  f3_data <- tcc_ghg_figure_data(ctx, "ghgpc_tco2e_incl_lulucf")

  f1 <- ggplot2::ggplot(
    f1_data,
    ggplot2::aes(x = gdppc, y = elasticity)
  ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = ci95_lower, ymax = ci95_upper),
      fill = "grey85", color = NA
    ) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.35, linetype = "dashed") +
    ggplot2::geom_vline(
      xintercept = exp(ctx$common_gdp_center),
      linewidth = 0.35, linetype = "dotted"
    ) +
    ggplot2::geom_line(linewidth = 0.75) +
    ggplot2::scale_x_continuous(
      breaks = scales::breaks_pretty(n = 6),
      labels = scales::label_number(
        big.mark = ".", decimal.mark = ",", accuracy = 1
      )
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_number(decimal.mark = ",", accuracy = 0.1)
    ) +
    ggplot2::labs(
      x = "PIB real per capita (US$ constantes de 2015)",
      y = "Elasticidade marginal estimada"
    ) +
    tcc_figure_theme(font$used)

  list(
    data = list(
      figure_1 = f1_data,
      figure_2 = f2_data,
      figure_3 = f3_data
    ),
    plots = list(
      figure_1 = f1,
      figure_2 = tcc_build_ghg_series_plot(f2_data, font$used),
      figure_3 = tcc_build_ghg_series_plot(f3_data, font$used)
    ),
    metadata = list(
      font_requested = font$requested,
      font_used = font$used,
      exact_font_match = font$exact,
      e1_coefficient_source = "validated_primary_object",
      e1_covariance_source = "validated_primary_object",
      common_gdp_center = ctx$common_gdp_center,
      x_lower = ctx$x_lower,
      x_upper = ctx$x_upper
    )
  )
}

tcc_write_figures <- function(
    figures,
    output_dir = PATH_FIGURES,
    width_in = 6.30,
    height_in = 3.80,
    png_dpi = 600L) {

  tcc_require_packages(PKG_REQUIRED_FIGURES)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  stems <- c(
    figure_1 = "figura-01_elasticidade-marginal-e1",
    figure_2 = "figura-02_gee-per-capita_excl-lulucf_1990-2023",
    figure_3 = "figura-03_gee-per-capita_incl-lulucf_1990-2023"
  )

  files <- list()
  for (nm in names(stems)) {
    svg_path <- file.path(output_dir, paste0(stems[[nm]], ".svg"))
    png_path <- file.path(output_dir, paste0(stems[[nm]], ".png"))
    data_path <- file.path(output_dir, paste0(stems[[nm]], "_plot-data.csv"))

    ggplot2::ggsave(
      svg_path, figures$plots[[nm]], device = svglite::svglite,
      width = width_in, height = height_in, units = "in", bg = "white"
    )
    ggplot2::ggsave(
      png_path, figures$plots[[nm]], device = ragg::agg_png,
      width = width_in, height = height_in, units = "in",
      dpi = as.integer(png_dpi), bg = "white"
    )
    utils::write.csv(figures$data[[nm]], data_path, row.names = FALSE)

    files[[nm]] <- c(svg = svg_path, png = png_path, data = data_path)
  }

  flat <- unlist(files, use.names = FALSE)
  stopifnot(
    all(file.exists(flat)),
    all(file.info(flat)$size > 0)
  )

  manifest <- do.call(
    rbind,
    lapply(names(files), function(nm) {
      p <- files[[nm]]
      data.frame(
        figure = nm,
        type = names(p),
        path = as.character(p),
        md5 = unname(tools::md5sum(p)),
        bytes = as.numeric(file.info(p)$size),
        stringsAsFactors = FALSE
      )
    })
  )
  row.names(manifest) <- NULL

  manifest_path <- file.path(output_dir, "figures_manifest.csv")
  utils::write.csv(manifest, manifest_path, row.names = FALSE)

  list(
    figures = figures,
    files = files,
    manifest = manifest,
    manifest_path = manifest_path
  )
}

tcc_run_figures <- function(
    ctx,
    primary,
    output_dir = PATH_FIGURES,
    font_requested = "Times New Roman") {

  figures <- tcc_build_figures(
    ctx = ctx,
    primary = primary,
    font_requested = font_requested
  )
  tcc_write_figures(figures, output_dir = output_dir)
}
