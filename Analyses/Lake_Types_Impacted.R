# ============================================================
# FINAL SIMPLIFIED SCRIPT
# Compare lake characteristics of lakes with >20 and >50 smoke days
# against all lakes in Canada + United States
# Save only one summary table
# ============================================================

# ---- Packages ----
library(stringr)
library(purrr)
library(dplyr)
library(readr)
library(tidyr)
library(ggplot2)
library(scales)

# ============================================================
# INPUT / OUTPUT
# ============================================================
input_dir <- "C:/Users/FacundoScordo/Box/WildfireWilliam/ResultsPaper/DataAnalyses/LakesWithSmokeCover"
out_dir   <- "C:/Users/FacundoScordo/Box/WildfireWilliam/ResultsPaper/Type_of_lake_impacted"

if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

message("Outputs will be saved in: ", normalizePath(out_dir))

COUNTRIES_TO_KEEP <- c("Canada", "United States")

# ============================================================
# FILE LIST
# ============================================================
files <- list.files(
  input_dir,
  pattern = "^wfrtl_composite(200[8]|201[0-9]|202[0-4])\\.csv$",
  full.names = TRUE
)

if (length(files) == 0) {
  stop("No files found in: ", input_dir)
}

message("Found ", length(files), " files")
print(basename(files))

# ============================================================
# READ FUNCTION
# ============================================================
read_one <- function(path) {
  yr <- as.integer(str_extract(basename(path), "\\d{4}"))
  
  read_csv(path, show_col_types = FALSE) %>%
    transmute(
      hylak_id = hylak_id,
      Lake_name = lake_name,
      Country = country,
      Pour_long = pour_long,
      Pour_lat = pour_lat,
      lake_area = lake_area,
      lake_volume = lake_volume,
      lake_depth_avg = lake_depth_avg,
      lake_elevation = lake_elevation,
      Smoke_days_medium_point = Smoke_days_medium_point,
      Smoke_days_heavy_point = Smoke_days_heavy_point,
      year = yr
    ) %>%
    filter(
      !is.na(Pour_long),
      !is.na(Pour_lat),
      Country %in% COUNTRIES_TO_KEEP
    ) %>%
    mutate(
      Smoke_days_sum = coalesce(Smoke_days_medium_point, 0) +
        coalesce(Smoke_days_heavy_point, 0)
    ) %>%
    select(
      hylak_id, Lake_name, Country, year,
      Pour_long, Pour_lat,
      lake_area, lake_volume, lake_depth_avg, lake_elevation,
      Smoke_days_sum
    )
}

# ============================================================
# BUILD FULL DATASET
# ============================================================
all_years <- map_dfr(files, read_one)

message("Rows in all_years: ", nrow(all_years))
message("Years: ", paste(sort(unique(all_years$year)), collapse = ", "))

all_years %>%
  count(Country) %>%
  print()

# ============================================================
# PREPARE ANALYSIS DATASET
# ============================================================
lake_traits <- all_years %>%
  filter(
    !is.na(lake_area),
    !is.na(lake_volume),
    !is.na(lake_depth_avg),
    !is.na(lake_elevation),
    lake_elevation > 0
  )

message("Rows after trait filtering: ", nrow(lake_traits))

# ============================================================
# DEFINE SUBSETS
# ============================================================
subset_20 <- lake_traits %>%
  filter(Smoke_days_sum > 20)

subset_50 <- lake_traits %>%
  filter(Smoke_days_sum > 50)

message("Rows with >20 smoke days: ", nrow(subset_20))
message("Rows with >50 smoke days: ", nrow(subset_50))

# ============================================================
# ONLY TABLE THAT MATTERS
# Median + IQR summary table
# ============================================================
make_summary <- function(df, group_name) {
  tibble(
    group = group_name,
    n = nrow(df),
    
    median_area = median(df$lake_area, na.rm = TRUE),
    q25_area = quantile(df$lake_area, 0.25, na.rm = TRUE),
    q75_area = quantile(df$lake_area, 0.75, na.rm = TRUE),
    
    median_volume = median(df$lake_volume, na.rm = TRUE),
    q25_volume = quantile(df$lake_volume, 0.25, na.rm = TRUE),
    q75_volume = quantile(df$lake_volume, 0.75, na.rm = TRUE),
    
    median_depth = median(df$lake_depth_avg, na.rm = TRUE),
    q25_depth = quantile(df$lake_depth_avg, 0.25, na.rm = TRUE),
    q75_depth = quantile(df$lake_depth_avg, 0.75, na.rm = TRUE),
    
    median_elevation = median(df$lake_elevation, na.rm = TRUE),
    q25_elevation = quantile(df$lake_elevation, 0.25, na.rm = TRUE),
    q75_elevation = quantile(df$lake_elevation, 0.75, na.rm = TRUE)
  )
}

summary_table <- bind_rows(
  make_summary(lake_traits, "All lakes"),
  make_summary(subset_20, ">20 smoke days"),
  make_summary(subset_50, ">50 smoke days")
)

print(summary_table)

write_csv(
  summary_table,
  file.path(out_dir, "lake_traits_summary_all_vs_smoke_thresholds.csv")
)

# ============================================================
# PLOT DATA
# Sample before plotting for speed
# ============================================================
set.seed(123)

max_n_plot_all <- 100000
max_n_plot_20  <- 100000
max_n_plot_50  <- 100000

plot_all <- lake_traits %>%
  sample_n(min(n(), max_n_plot_all)) %>%
  mutate(group = "All lakes")

plot_20 <- subset_20 %>%
  sample_n(min(n(), max_n_plot_20)) %>%
  mutate(group = ">20 smoke days")

plot_50 <- subset_50 %>%
  sample_n(min(n(), max_n_plot_50)) %>%
  mutate(group = ">50 smoke days")

plot_df <- bind_rows(plot_all, plot_20, plot_50) %>%
  select(group, lake_area, lake_volume, lake_depth_avg, lake_elevation) %>%
  pivot_longer(
    cols = -group,
    names_to = "trait",
    values_to = "value"
  ) %>%
  filter(value > 0) %>%
  mutate(
    trait = recode(
      trait,
      lake_area = "Lake area",
      lake_volume = "Lake volume",
      lake_depth_avg = "Lake depth",
      lake_elevation = "Lake elevation"
    ),
    group = factor(
      group,
      levels = c("All lakes", ">20 smoke days", ">50 smoke days")
    )
  )

# ============================================================
# PLOT
# ============================================================
p <- ggplot(plot_df, aes(x = group, y = value, fill = group)) +
  geom_boxplot(outlier.alpha = 0.05) +
  facet_wrap(~trait, scales = "free_y", ncol = 2) +
  scale_y_log10(labels = comma) +
  scale_fill_manual(values = c(
    "All lakes" = "grey70",
    ">20 smoke days" = "#FDAE6B",
    ">50 smoke days" = "#D73027"
  )) +
  labs(
    x = "",
    y = "Value (log10 scale)",
    title = "Lake characteristics of smoke-exposed lakes compared to all lakes",
    subtitle = "Boxplots based on random samples for faster visualization"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold"),
    axis.text.x = element_text(angle = 15, hjust = 1)
  )

print(p)

ggsave(
  file.path(out_dir, "lake_traits_all_vs_smoke_thresholds_boxplots.png"),
  p, width = 11, height = 8, dpi = 300, bg = "white"
)

ggsave(
  file.path(out_dir, "lake_traits_all_vs_smoke_thresholds_boxplots.svg"),
  p, width = 11, height = 8, dpi = 300, bg = "white"
)

message("Analysis complete. Outputs saved in: ", normalizePath(out_dir))

# ============================================================
# FINAL SIMPLIFIED SCRIPT
# Compare lake characteristics of lakes with >25% and >50%
# burned watershed overlap against all lakes
# Save only one summary table
# ============================================================

# ---- Packages ----
library(tidyverse)
library(stringr)
library(scales)

# ============================================================
# INPUT / OUTPUT
# ============================================================
data_dir <- "C:/Users/FacundoScordo/Box/WildfireWilliam/ResultsPaper/DataAnalyses/LakesWithBasinsBurned"

out_dir <- "C:/Users/FacundoScordo/Box/WildfireWilliam/ResultsPaper/Type_of_lake_impacted"

if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

message("Outputs will be saved in: ", normalizePath(out_dir))

# ============================================================
# FILE LIST
# ============================================================
files <- list.files(data_dir, pattern = "\\.csv$", full.names = TRUE)

if (length(files) == 0) {
  stop("No CSV files found in: ", data_dir)
}

message("Found ", length(files), " files")
print(basename(files))

# ============================================================
# READ AND COMBINE FILES
# ============================================================
all_lakes_raw <- files %>%
  purrr::map_dfr(function(f) {
    yr <- stringr::str_extract(basename(f), "\\d{4}") %>% as.integer()
    df <- readr::read_csv(f, show_col_types = FALSE)
    df$year <- yr
    df
  }) %>%
  filter(!is.na(year)) %>%
  filter(year >= 2008 & year <= 2024) %>%
  mutate(hylak_country = str_trim(hylak_country))

message("Rows in all_lakes_raw: ", nrow(all_lakes_raw))
message("Years: ", paste(sort(unique(all_lakes_raw$year)), collapse = ", "))

# ============================================================
# FILTER CANADA + USA
# ============================================================
country_filter <- c("Canada", "United States")

all_lakes <- all_lakes_raw %>%
  filter(hylak_country %in% country_filter)

all_lakes %>%
  count(hylak_country) %>%
  print()

# ============================================================
# PREPARE ANALYSIS DATASET
# ============================================================
lake_traits <- all_lakes %>%
  filter(
    !is.na(lake_area),
    !is.na(lake_volume),
    !is.na(lake_depth_avg),
    !is.na(lake_elevation),
    !is.na(overlap_percentage),
    lake_elevation > 0
  )

message("Rows after trait filtering: ", nrow(lake_traits))

# ============================================================
# DEFINE SUBSETS
# ============================================================
subset_25 <- lake_traits %>%
  filter(overlap_percentage > 0.25)

subset_50 <- lake_traits %>%
  filter(overlap_percentage > 0.50)

message("Rows with >25% burned: ", nrow(subset_25))
message("Rows with >50% burned: ", nrow(subset_50))

# ============================================================
# ONLY TABLE THAT MATTERS
# Median + IQR summary table
# ============================================================
make_summary <- function(df, group_name) {
  tibble(
    group = group_name,
    n = nrow(df),
    
    median_area = median(df$lake_area, na.rm = TRUE),
    q25_area = quantile(df$lake_area, 0.25, na.rm = TRUE),
    q75_area = quantile(df$lake_area, 0.75, na.rm = TRUE),
    
    median_volume = median(df$lake_volume, na.rm = TRUE),
    q25_volume = quantile(df$lake_volume, 0.25, na.rm = TRUE),
    q75_volume = quantile(df$lake_volume, 0.75, na.rm = TRUE),
    
    median_depth = median(df$lake_depth_avg, na.rm = TRUE),
    q25_depth = quantile(df$lake_depth_avg, 0.25, na.rm = TRUE),
    q75_depth = quantile(df$lake_depth_avg, 0.75, na.rm = TRUE),
    
    median_elevation = median(df$lake_elevation, na.rm = TRUE),
    q25_elevation = quantile(df$lake_elevation, 0.25, na.rm = TRUE),
    q75_elevation = quantile(df$lake_elevation, 0.75, na.rm = TRUE)
  )
}

summary_table <- bind_rows(
  make_summary(lake_traits, "All lakes"),
  make_summary(subset_25, ">25% burned"),
  make_summary(subset_50, ">50% burned")
)

print(summary_table)

write_csv(
  summary_table,
  file.path(out_dir, "lake_traits_summary_all_vs_burned_thresholds.csv")
)

# ============================================================
# PLOT DATA
# Sample before plotting for speed
# ============================================================
set.seed(123)

max_n_plot_all <- 100000
max_n_plot_25  <- 100000
max_n_plot_50  <- 100000

plot_all <- lake_traits %>%
  sample_n(min(n(), max_n_plot_all)) %>%
  mutate(group = "All lakes")

plot_25 <- subset_25 %>%
  sample_n(min(n(), max_n_plot_25)) %>%
  mutate(group = ">25% burned")

plot_50 <- subset_50 %>%
  sample_n(min(n(), max_n_plot_50)) %>%
  mutate(group = ">50% burned")

plot_df <- bind_rows(plot_all, plot_25, plot_50) %>%
  select(group, lake_area, lake_volume, lake_depth_avg, lake_elevation) %>%
  pivot_longer(
    cols = -group,
    names_to = "trait",
    values_to = "value"
  ) %>%
  filter(value > 0) %>%
  mutate(
    trait = recode(
      trait,
      lake_area = "Lake area",
      lake_volume = "Lake volume",
      lake_depth_avg = "Lake depth",
      lake_elevation = "Lake elevation"
    ),
    group = factor(
      group,
      levels = c("All lakes", ">25% burned", ">50% burned")
    )
  )

# ============================================================
# PLOT
# ============================================================
p <- ggplot(plot_df, aes(x = group, y = value, fill = group)) +
  geom_boxplot(outlier.alpha = 0.05) +
  facet_wrap(~trait, scales = "free_y", ncol = 2) +
  scale_y_log10(labels = comma) +
  scale_fill_manual(values = c(
    "All lakes" = "grey70",
    ">25% burned" = "#FDAE6B",
    ">50% burned" = "#D73027"
  )) +
  labs(
    x = "",
    y = "Value (log10 scale)",
    title = "Lake characteristics of lakes with burned watersheds compared to all lakes",
    subtitle = "Boxplots based on random samples for faster visualization"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold"),
    axis.text.x = element_text(angle = 15, hjust = 1)
  )

print(p)

ggsave(
  file.path(out_dir, "lake_traits_all_vs_burned_thresholds_boxplots.png"),
  p, width = 11, height = 8, dpi = 300, bg = "white"
)

ggsave(
  file.path(out_dir, "lake_traits_all_vs_burned_thresholds_boxplots.svg"),
  p, width = 11, height = 8, dpi = 300, bg = "white"
)

message("Analysis complete. Outputs saved in: ", normalizePath(out_dir))

