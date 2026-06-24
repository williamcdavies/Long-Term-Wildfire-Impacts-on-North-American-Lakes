# ============================================================
# FIRE LATITUDE SHIFT ANALYSIS: USA + CANADA, 2008-2024
# ============================================================

library(tidyverse)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(ggplot2)
library(scales)


# ------------------------------------------------------------
# 1. Directory and files
# ------------------------------------------------------------

fire_dir <- "C:/Users/FacundoScordo/Box/WildfireWilliam/ResultsPaper/DataAnalyses/FireLocation"

files <- list.files(
  fire_dir,
  pattern = "\\.csv$",
  full.names = TRUE
)

# ------------------------------------------------------------
# 2. Read and combine files
# Expected columns: id, year, area_km2, lon, lat
# ------------------------------------------------------------

fires <- files %>%
  map_dfr(read_csv, show_col_types = FALSE) %>%
  filter(
    year >= 2008,
    year <= 2024,
    !is.na(lat),
    !is.na(lon),
    !is.na(area_km2)
  ) %>%
  mutate(
    period = case_when(
      year >= 2008 & year <= 2017 ~ "2008-2017",
      year >= 2018 & year <= 2024 ~ "2018-2024"
    ),
    period = factor(period, levels = c("2008-2017", "2018-2024")),
    fire_area_class = case_when(
      area_km2 < 10 ~ "<10 km²",
      area_km2 >= 10 & area_km2 < 100 ~ "10-100 km²",
      area_km2 >= 100 ~ ">100 km²"
    ),
    fire_area_class = factor(
      fire_area_class,
      levels = c("<10 km²", "10-100 km²", ">100 km²")
    )
  )
# ============================================================
# MEAN TOTAL BURNED AREA BY 0.5° LATITUDE BIN AND PERIOD
# ============================================================

library(dplyr)
library(ggplot2)

# 1. Aggregate total burned area by year and 0.5° latitude bin
fires_lat_05_year <- fires %>%
  mutate(
    lat_bin = floor(lat / 0.5) * 0.5
  ) %>%
  group_by(period, year, lat_bin) %>%
  summarise(
    total_area_km2 = sum(area_km2, na.rm = TRUE),
    .groups = "drop"
  )

# 2. Calculate mean and 95% CI across years within each period and latitude bin
fires_lat_05_period <- fires_lat_05_year %>%
  group_by(period, lat_bin) %>%
  summarise(
    mean_area_km2 = mean(total_area_km2, na.rm = TRUE),
    sd_area_km2   = sd(total_area_km2, na.rm = TRUE),
    n_years       = n(),
    se_area_km2   = sd_area_km2 / sqrt(n_years),
    ci_lower      = mean_area_km2 - qt(0.975, df = n_years - 1) * se_area_km2,
    ci_upper      = mean_area_km2 + qt(0.975, df = n_years - 1) * se_area_km2,
    .groups = "drop"
  )


# ============================================================
# SMOOTHED LATITUDINAL PROFILE (CORRECT + CLEAN)
# ============================================================

p_lat_05_period <- ggplot(
  fires_lat_05_period,
  aes(x = lat_bin, y = mean_area_km2, color = period, fill = period)
) +
  
  # Smoothed line + matching confidence interval
  geom_smooth(
    method = "loess",
    span = 0.2,      # controls smoothing for BOTH line and shadow
    se = TRUE,       # turn on shaded CI
    linewidth = 1.3,
    alpha = 0.2      # transparency of the ribbon
  ) +
  
  labs(
    title = "Latitudinal distribution of burned area by period",
    x = "Latitude (°)",
    y = "Mean annual burned area per 0.5° latitude bin (km²)",
    color = "Period",
    fill = "Period"
  ) +
  theme_minimal(base_size = 14)

print(p_lat_05_period)


ggsave(
  filename = "C:/Users/FacundoScordo/Box/WildfireWilliam/ResultsPaper/Figures/Continuous_burned_area.svg",
  plot = p_lat_05_period,
  width = 14,
  height = 8,
  units = "in",
  device = "svg"
)

# ============================================================
# TREND IN TOTAL BURNED AREA BY LATITUDE BAND (3 BANDS)
# <35°, 35-50°, >50°
# Last plot = faceted
# ============================================================
library(dplyr)
library(emmeans)

# 1. Define latitude bands
fires_bands3 <- fires %>%
  mutate(
    lat_band3 = case_when(
      lat < 35 ~ "<35°",
      lat >= 35 & lat < 50 ~ "35-50°",
      lat >= 50 ~ ">50°"
    ),
    lat_band3 = factor(lat_band3, levels = c("<35°", "35-50°", ">50°"))
  )

# 2. Aggregate burned area by year and band
area_by_band3_year <- fires_bands3 %>%
  group_by(year, lat_band3) %>%
  summarise(
    total_area_km2 = sum(area_km2, na.rm = TRUE),
    .groups = "drop"
  )

# 3. Fit interaction model
model <- lm(total_area_km2 ~ year * lat_band3,
            data = area_by_band3_year)

summary(model)

# 4. Estimate slopes (trend per latitude band)
slopes <- emtrends(model, ~ lat_band3, var = "year")
slopes



# 5. Pairwise comparisons of slopes (THIS answers your question)
pairwise_slopes <- pairs(slopes)
pairwise_slopes

# ============================================================
# TREND IN TOTAL BURNED AREA BY LATITUDE BAND (3 BANDS)
# Excluding 2023
# ============================================================

# Remove 2023 (extreme fire year)
fires_no2023 <- fires %>%
  filter(year != 2023)

# 1. Define latitude bands
fires_bands3_no2023 <- fires_no2023 %>%
  mutate(
    lat_band3 = case_when(
      lat < 35 ~ "<35°",
      lat >= 35 & lat < 50 ~ "35-50°",
      lat >= 50 ~ ">50°"
    ),
    lat_band3 = factor(lat_band3, levels = c("<35°", "35-50°", ">50°"))
  )

# 2. Aggregate burned area by year and latitude band
area_by_band3_year_no2023 <- fires_bands3_no2023 %>%
  group_by(year, lat_band3) %>%
  summarise(
    total_area_km2 = sum(area_km2, na.rm = TRUE),
    .groups = "drop"
  )

# 3. Fit interaction model
model_no2023 <- lm(total_area_km2 ~ year * lat_band3,
                   data = area_by_band3_year_no2023)

summary(model_no2023)

# 4. Estimate slopes (trend per latitude band)
slopes_no2023 <- emtrends(model_no2023, ~ lat_band3, var = "year")
slopes_no2023

# 5. Pairwise comparisons of slopes
pairwise_slopes_no2023 <- pairs(slopes_no2023)
pairwise_slopes_no2023


  
  
  

  