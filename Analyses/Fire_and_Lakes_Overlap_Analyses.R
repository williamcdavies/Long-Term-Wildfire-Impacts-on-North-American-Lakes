library(tidyverse)
library(stringr)

# ------------------------------------------------------------
# 1) Folder with your CSVs
# ------------------------------------------------------------
data_dir <- "C:/Users/FacundoScordo/Box/WildfireWilliam/ResultsPaper/DataAnalyses/LakesWithBasinsBurned"

# ------------------------------------------------------------
# 2) List all CSV files
# ------------------------------------------------------------
files <- list.files(data_dir, pattern = "\\.csv$", full.names = TRUE)

print(basename(files))

# ------------------------------------------------------------
# 3) Read and combine all files
# ------------------------------------------------------------
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

glimpse(all_lakes_raw)

# ------------------------------------------------------------
# 4) Country filter
# ------------------------------------------------------------
country_filter <- c("Canada", "United States")

all_lakes <- all_lakes_raw %>%
  filter(hylak_country %in% country_filter)

# ------------------------------------------------------------
# 5) Lakes overlapped (FIX: use overlap_percentage > 0)
# ------------------------------------------------------------
lakes_overlap <- all_lakes %>%
  filter(overlap_percentage > 0)

# ------------------------------------------------------------
# 6) Lakes per year per country
# ------------------------------------------------------------
lakes_per_year_country <- lakes_overlap %>%
  group_by(year, hylak_country) %>%
  summarise(
    n_lakes_overlap = n_distinct(hylak_id),
    .groups = "drop"
  )

print(lakes_per_year_country)

# Combined
lakes_per_year_combined <- lakes_overlap %>%
  group_by(year) %>%
  summarise(
    n_lakes_overlap = n_distinct(hylak_id),
    .groups = "drop"
  )



# ------------------------------------------------------------
# 9) TREND ANALYSIS (FIXED names)
# ------------------------------------------------------------

# ------------------------------------------------------------
# Filter period: 2008-2024
# ------------------------------------------------------------

# Combined
lakes_combined_2008 <- lakes_per_year_combined %>%
  filter(year >= 2008, year <= 2024)

summary(lm(n_lakes_overlap ~ year, data = lakes_combined_2008))


# Combined lakes excluding 2023
lakes_combined_no2023 <- lakes_per_year_combined %>%
  filter(year >= 2008, year <= 2024, year != 2023)

# Linear trend without 2023
summary(lm(n_lakes_overlap ~ year, data = lakes_combined_no2023))


# ------------------------------------------------------------
# 10) Overlap categories (FIXED variable name)
# ------------------------------------------------------------
all_lakes_cat <- all_lakes %>%
  filter(overlap_percentage >= 0.001) %>%
  mutate(
    overlap_cat = case_when(
      overlap_percentage <= 0.25 ~ "1-25%",
      overlap_percentage <= 0.5 ~ "26-50%",
      overlap_percentage <= 0.75 ~ "51-75%",
      TRUE ~ "76-100%"
    ),
    # Make it an ordered factor from low to high
    overlap_cat = factor(
      overlap_cat,
      levels = c("1-25%", "26-50%", "51-75%", "76-100%")
    )
  )


# ------------------------------------------------------------
# 11) TREND ANALYSIS OF DIFFERENT CATEGORIES
# ------------------------------------------------------------ 

library(dplyr)
library(ggplot2)
library(purrr)
library(broom)

# ------------------------------------------------------------
# 12) Prepare data: count lakes per year per category (2008-2024)
# ------------------------------------------------------------
lakes_year_cat_recent <- all_lakes_cat %>%
  filter(year >= 2008, year <= 2024) %>%
  group_by(year, overlap_cat) %>%
  summarise(
    n_lakes = n_distinct(hylak_id),
    .groups = "drop"
  )

# Plot
p2 <- ggplot(lakes_year_cat_recent, aes(x = year, y = n_lakes, fill = overlap_cat)) +
  geom_col() +
  theme_bw() +
  labs(
    title = "Number of Lakes Affected by Wildfire Basin Burn Percentage",
    y = "Number of Lakes",
    x = "Year",
    fill = "% Basin Burned"
  )

# Save as SVG file for Inkscape
ggsave("lakes_burned_by_category.svg", plot = p2, device = "svg", width = 10, height = 6)


write.csv(
  lakes_year_cat_recent,
  "C:/Users/FacundoScordo/Box/WildfireWilliam/ResultsPaper/lakes_year_cat_recent.csv",
  row.names = FALSE
)

# ------------------------------------------------------------
# 13) Fit linear trend for each category and extract significance
# ------------------------------------------------------------
trends <- lakes_year_cat_recent %>%
  group_by(overlap_cat) %>%
  group_split() %>%                       # split into list by category
  map_dfr(function(df_cat) {
    mod <- lm(n_lakes ~ year, data = df_cat)
    tidy_mod <- broom::tidy(mod)
    
    slope <- tidy_mod$estimate[tidy_mod$term == "year"]
    pval  <- tidy_mod$p.value[tidy_mod$term == "year"]
    
    trend_significance <- case_when(
      pval < 0.05 & slope > 0 ~ "significantly increasing",
      pval < 0.05 & slope < 0 ~ "significantly decreasing",
      TRUE ~ "not significant"
    )
    
    tibble(
      overlap_cat = df_cat$overlap_cat[1],
      slope = slope,
      p_value = pval,
      trend_significance = trend_significance
    )
  })

# ------------------------------------------------------------
# 14) Show results
# ------------------------------------------------------------
print(trends)






