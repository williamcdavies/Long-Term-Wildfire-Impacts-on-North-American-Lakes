# ---- Packages ----
library(stringr)
library(purrr)
library(tidyr)
library(forcats)
library(ggplot2)
library(dplyr)
library(readr)
library(trend)
library(broom)
library(scales)

# =========================
# INPUT
# =========================
input_dir <- "C:/Users/FacundoScordo/Box/WildfireWilliam/ResultsPaper/DataAnalyses/LakesWithSmokeCover"

COUNTRIES_TO_KEEP <- c("Canada", "United States")

# =========================
# FILE LIST (2010-2024)
# =========================
files <- list.files(
  input_dir,
  pattern = "^wfrtl_composite(200[8]|201[0-9]|202[0-4])\\.csv$",
  full.names = TRUE
)

if (length(files) == 0) {
  stop("No files found in: ", input_dir)
}

message("Found ", length(files), " files")

# =========================
# BIN FUNCTION
# =========================
smoke_breaks <- c(0, 1, 11, 21, 31, 41, 51, Inf)
smoke_labels <- c("0", "1-10", "11-20", "21-30", "31-40", "41-50", ">=51")

bin_smoke <- function(x) {
  cut(
    x,
    breaks = smoke_breaks,
    labels = smoke_labels,
    right = FALSE,
    include.lowest = TRUE
  )
}

# =========================
# DISCRETE PALETTE
# =========================
grad_cols <- c("#FFF7BC", "#FEC44F", "#FD8D3C", "#E31A1C")
pal_discrete <- colorRampPalette(grad_cols)(length(smoke_labels))
names(pal_discrete) <- smoke_labels
pal_discrete[["0"]] <- "#FFFFE5"

# =========================
# READ FUNCTION
# =========================
read_one <- function(path) {
  
  yr <- as.integer(str_extract(basename(path), "\\d{4}"))
  df <- read_csv(path, show_col_types = FALSE)
  
  df %>%
    rename(
      Country = country,
      Lake_name = lake_name,
      Pour_long = pour_long,
      Pour_lat = pour_lat
    ) %>%
    filter(
      !is.na(Pour_long),
      !is.na(Pour_lat),
      Country %in% COUNTRIES_TO_KEEP
    ) %>%
    mutate(
      year = yr,
      Smoke_days_sum = rowSums(
        across(c(Smoke_days_medium_point, Smoke_days_heavy_point)),
        na.rm = TRUE
      ),
      smoke_cat = bin_smoke(Smoke_days_sum)
    )
}

# =========================
# BUILD FULL DATASET
# =========================
all_years <- map_dfr(files, read_one)

message("Rows: ", nrow(all_years), 
        " | Years: ", paste(range(all_years$year, na.rm = TRUE), collapse = "-"))

# Quick check
all_years %>%
  count(Country) %>%
  print()

# =========================
# COUNTS BY YEAR & CATEGORY
# =========================
counts_year_cat <- all_years %>%
  count(year, smoke_cat, name = "n_lakes") %>%
  arrange(year, smoke_cat)

write_csv(
  counts_year_cat,
  file.path(input_dir, "lake_counts_by_year_smokecat_2005_2024.csv")
)

counts_year_cat$smoke_cat <- fct_relevel(counts_year_cat$smoke_cat, smoke_labels)

# =========================
# STACKED BAR PLOT
# =========================
p_counts <- ggplot(
  counts_year_cat,
  aes(x = factor(year), y = n_lakes, fill = smoke_cat)
) +
  geom_col() +
  scale_fill_manual(
    values = pal_discrete,
    drop = FALSE,
    guide = guide_legend(title = "Smoke days (Medium + Heavy)")
  ) +
  labs(
    x = "Year",
    y = "Number of lakes",
    title = "Lakes by smoke exposure category (2005-2024)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "right",
    plot.title = element_text(face = "bold")
  )

print(p_counts)

ggsave(
  file.path(input_dir, "lake_counts_by_year_smokecat_2010_2024.png"),
  p_counts, width = 10, height = 6, dpi = 300, bg = "white"
)

ggsave(
  file.path(input_dir, "lake_counts_by_year_smokecat_2010_2024.svg"),
  p_counts, width = 10, height = 6, dpi = 300, bg = "white"
)

# =========================
# SUMMARY PER YEAR
# =========================
days_in_year <- function(y) {
  ifelse((y %% 4 == 0 & y %% 100 != 0) | (y %% 400 == 0), 366, 365)
}

smoke_summary_year <- all_years %>%
  group_by(year) %>%
  summarise(
    mean_smoke_days = mean(Smoke_days_sum, na.rm = TRUE),
    max_smoke_days  = max(Smoke_days_sum, na.rm = TRUE),
    n_lakes = n(),
    total_smoke_days_all_lakes = sum(Smoke_days_sum, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    mean_lakes_exposed_per_day = total_smoke_days_all_lakes / days_in_year(year)
  )

write_csv(
  smoke_summary_year,
  file.path(input_dir, "mean_max_lakes_exposed_per_year_2005_2024.csv")
)

# =========================
# TREND ANALYSIS
# =========================
lm_mean <- lm(mean_smoke_days ~ year, data = smoke_summary_year)
lm_max  <- lm(max_smoke_days ~ year, data = smoke_summary_year)

cat("\n=== Linear trend (mean smoke days) ===\n")
print(summary(lm_mean))

cat("\n=== Linear trend (max smoke days) ===\n")
print(summary(lm_max))

trend_lm_summary <- bind_rows(
  tidy(lm_mean) %>% mutate(metric = "Mean smoke days (lakes)"),
  tidy(lm_max)  %>% mutate(metric = "Max smoke days (lakes)")
) %>%
  select(metric, term, estimate, std.error, statistic, p.value)

write_csv(
  trend_lm_summary,
  file.path(input_dir, "trend_linear_regression_mean_max_smokedays_lakes_2005_2024.csv")
)


# =========================
# LAKES WITH > 20 SMOKE DAYS
# =========================
smoke_threshold <- 20

lakes_smoke_year_country <- all_years %>%
  mutate(exposed = Smoke_days_sum >= smoke_threshold) %>%
  group_by(year, Country) %>%
  summarise(
    n_lakes_smoke = n_distinct(hylak_id[exposed]),
    .groups = "drop"
  ) %>%
  tidyr::complete(
    year = full_seq(sort(unique(all_years$year)), 1),
    Country = COUNTRIES_TO_KEEP,
    fill = list(n_lakes_smoke = 0)
  ) %>%
  arrange(year, Country)

print(lakes_smoke_year_country)

# Combined Canada + USA
lakes_smoke_year_combined <- all_years %>%
  mutate(exposed = Smoke_days_sum > smoke_threshold) %>%
  group_by(year) %>%
  summarise(
    n_lakes_smoke = n_distinct(hylak_id[exposed]),
    .groups = "drop"
  ) %>%
  tidyr::complete(
    year = full_seq(sort(unique(all_years$year)), 1),
    fill = list(n_lakes_smoke = 0)
  ) %>%
  arrange(year)

print(lakes_smoke_year_combined)

# Save tables
write_csv(
  lakes_smoke_year_country,
  file.path(input_dir, "lakes_more_than_20_smokedays_by_year_country.csv")
)

write_csv(
  lakes_smoke_year_combined,
  file.path(input_dir, "lakes_more_than_20_smokedays_by_year_combined.csv")
)


# =========================
# TREND ANALYSIS
# =========================

smoke_combined_lm <- lm(n_lakes_smoke ~ year, data = lakes_smoke_year_combined)
cat("\n=== Linear trend in lakes with > 20 smoke days - Canada + USA combined ===\n")
print(summary(smoke_combined_lm))

# Exclude 2023
lakes_smoke_year_combined_no2023 <- lakes_smoke_year_combined %>%
  filter(year != 2023)

# Linear trend without 2023
smoke_combined_lm_no2023 <- lm(n_lakes_smoke ~ year, 
                               data = lakes_smoke_year_combined_no2023)

cat("\n=== Linear trend in lakes with >20 smoke days - Canada + USA combined (excluding 2023) ===\n")
print(summary(smoke_combined_lm_no2023))

# =========================
# LAKES WITH > 90 SMOKE DAYS IN 2023
# =========================

threshold_90 <- 120

lakes_90_2023 <- all_years %>%
  filter(year == 2023) %>%
  mutate(exposed_90 = Smoke_days_sum > threshold_90) %>%
  summarise(
    n_lakes_90 = n_distinct(hylak_id[exposed_90])
  )

cat("\n===== LAKES WITH > 90 SMOKE DAYS IN 2023 =====\n")
print(lakes_90_2023)

# ============================================================
# Lakes affected by smoke per day
# ============================================================

library(dplyr)
library(ggplot2)
library(lubridate)
library(tidyr)
library(viridis)

# ---- Set working directory ----
setwd("C:/Users/FacundoScordo/Box/WildfireWilliam/ResultsPaper/DataAnalyses/LakesWithSmokeCover/ByDay")

# ---- Load data ----
df <- read.csv("smokes_over_lakes_united_state_and_canada2.csv", stringsAsFactors = FALSE) %>%
  mutate(date = as.Date(date))

# optional check
sum(is.na(df$date))

# ---- Extract year and fill missing dates within each year ----
df_complete <- df %>%
  filter(!is.na(date)) %>%
  mutate(year = year(date)) %>%
  group_by(year) %>%
  complete(date = seq.Date(min(date), max(date), by = "day")) %>%
  mutate(
    l    = replace_na(l, 0),
    m    = replace_na(m, 0),
    h    = replace_na(h, 0),
    na   = replace_na(na, 0),
    sum  = replace_na(sum, 0),
    year = year(date),
    yday = yday(date)
  ) %>%
  ungroup()

# ============================================================
# Lakes affected by smoke per day in periods 2010-2017 and 2018-2024
# ============================================================

# ---- Assign time period labels ----
df_periods <- df_complete %>%
  mutate(
    period = case_when(
      year >= 2008 & year <= 2017 ~ "2010-2017",
      year >= 2018 & year <= 2024 ~ "2017-2024",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(period))

# ---- Compute mean and 95% CI by day-of-year for each period ----
df_stats <- df_periods %>%
  group_by(period, yday) %>%
  summarise(
    mean_sum = mean(sum, na.rm = TRUE),
    sd_sum   = sd(sum, na.rm = TRUE),
    n        = n(),
    se       = sd_sum / sqrt(n),
    ci_lower = mean_sum - 1.96 * se,
    ci_upper = mean_sum + 1.96 * se,
    .groups = "drop"
  )

# ---- Plot with custom colors ----
p <- ggplot(df_stats, aes(x = yday, y = mean_sum, color = period, fill = period)) +
  
  # Confidence interval ribbons (lighter red, stronger orange)
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              alpha = 0.2,
              color = NA) +
  
  # Mean lines (stronger for visibility)
  geom_line(linewidth = 1.3) +
  
  # Improved color palette (better contrast)
  scale_color_manual(
    name = "",
    values = c(
      "2010-2016" = "#E69F00",   # darker orange
      "2017-2024" = "#D73027"    # softer red
    )
  ) +
  
  scale_fill_manual(
    name = "",
    values = c(
      "2010-2016" = "#E69F00",
      "2017-2024" = scales::alpha("#D73027", 0.6)  # reduce red dominance
    )
  ) +
  
  # Y axis formatting
  scale_y_continuous(
    limits = c(-100000, 710000),
    breaks = seq(-100000, 710000, by = 100000),
    labels = scales::comma
  ) +
  
  labs(
    x = "Day of Year",
    y = "Number of lakes affected by smoke",
    title = "Mean Daily Smoke Exposure Across Lakes with 95% Confidence Interval",
    subtitle = "Comparison between 2010-2016 and 2017-2024"
  ) +
  
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "right",
      )

p
# ---- Save outputs ----
ggsave("smoke_mean_lakes_CI_by_period.png", p,
       width = 10, height = 7, dpi = 300, bg = "white")
ggsave("smoke_mean_lakes_CI_by_period.svg", p,
       width = 10, height = 7, dpi = 300, bg = "white")



# ============================================================
# Smoke season timing by year
# Threshold: days with more than 20 lakes affected
# ============================================================

yearly_season <- df_periods %>%
  group_by(year) %>%
  filter(sum > 1000) %>%
  summarise(
    start = min(date),
    end   = max(date),
    mean_lakes = mean(sum, na.rm = TRUE),
    max_lakes  = max(sum, na.rm = TRUE),
    .groups = "drop"
  )

# ---- Compute mean start/end day-of-year per period ----
season_summary <- yearly_season %>%
  mutate(
    period = case_when(
      year >= 2008 & year <= 2017 ~ "2008-2017",
      year >= 2018 & year <= 2024 ~ "2018-2024"
    )
  ) %>%
  group_by(period) %>%
  summarise(
    mean_start_doy = round(mean(yday(start), na.rm = TRUE)),
    mean_end_doy   = round(mean(yday(end), na.rm = TRUE)),
    mean_lakes     = mean(mean_lakes, na.rm = TRUE),
    max_lakes      = max(max_lakes, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    season_start_md = format(as.Date(mean_start_doy - 1, origin = "2001-01-01"), "%b-%d"),
    season_end_md   = format(as.Date(mean_end_doy - 1, origin = "2001-01-01"), "%b-%d")
  )

print(season_summary)

# ---- Compute mean start/end day-of-year per period excluding 2023 ----

season_summary_no2023 <- yearly_season %>%
  filter(year != 2023) %>%   # Remove extreme 2023 year
  mutate(
    period = case_when(
      year >= 2008 & year <= 2017 ~ "2008-2017",
      year >= 2018 & year <= 2024 ~ "2018-2024"
    )
  ) %>%
  group_by(period) %>%
  summarise(
    mean_start_doy = round(mean(yday(start), na.rm = TRUE)),
    mean_end_doy   = round(mean(yday(end), na.rm = TRUE)),
    mean_lakes     = mean(mean_lakes, na.rm = TRUE),
    max_lakes      = max(max_lakes, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    season_start_md = format(as.Date(mean_start_doy - 1, origin = "2001-01-01"), "%b-%d"),
    season_end_md   = format(as.Date(mean_end_doy - 1, origin = "2001-01-01"), "%b-%d")
  )

print(season_summary_no2023)

