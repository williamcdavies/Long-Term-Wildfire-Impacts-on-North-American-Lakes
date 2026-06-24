
library(dplyr)
library(readr)
library(ggplot2)
library(tidyr)
library(tibble)
library(scales)
library(purrr)
library(stringr)

# =========================================================
# 1. LOAD DATA
# =========================================================
data_path <- "C:/Users/FacundoScordo/Box/WildfireWilliam/ResultsPaper/DataAnalyses/BurnedArea/BurneArea.csv"
burned_data <- read_csv(data_path, na = c("", "NA", "#VALUE!"))

# =========================================================
# 2. RENAME COLUMNS FOR EASIER USE
# =========================================================
burned_data <- burned_data %>%
  rename(
    Year = Year,
    Canada_ha = `Canada(Ha)`,
    USA_ha = `USA(Ha)`,
    Total_ha = `Total(Ha)`
  )

# =========================================================
# 3. FILTER YEARS 2008 TO 2024 AND REMOVE ROWS WITH NA
# =========================================================
burned_recent <- burned_data %>%
  filter(Year >= 2008 & Year <= 2024) %>%
  filter(!is.na(Canada_ha) & !is.na(USA_ha) & !is.na(Total_ha))

# =========================================================
# 4. LINEAR TREND FOR CANADA, USA, TOTAL
# =========================================================

lm_total <- lm(Total_ha ~ Year, data = burned_recent)
cat("\nTrend for Total burned area:\n")
print(summary(lm_total))

# Remove 2023 (extreme fire year)
burned_recent_no2023 <- subset(burned_recent, Year != 2023)

# Linear model without 2023
lm_total_no2023 <- lm(Total_ha ~ Year, data = burned_recent_no2023)

cat("\nTrend for Total burned area (excluding 2023):\n")
print(summary(lm_total_no2023))


# =========================================================
# 5. DETAILED LAND-COVER COLUMNS
# =========================================================
landcover_cols <- c(
  "Temp_Needle_Forest",
  "Subp_Needle_Forest",
  "Trop_Ever_Forest",
  "Trop_Deci_Forest",
  "Temp_Deci_Forest",
  "Mix_Forest",
  "Trop_Shrub",
  "Temp_Shrub",
  "Trop_Grass",
  "Temp_Grass",
  "Subp_Shrub",
  "Subp_Grass",
  "Subp_moss",
  "Wetland",
  "Cropland",
  "Barren",
  "Urban",
  "Water",
  "Ice"
)

# Cleaner labels for plots
landcover_labels <- c(
  "Temp_Needle_Forest" = "Temp Needle Forest",
  "Subp_Needle_Forest" = "Subpolar Needle Forest",
  "Trop_Ever_Forest"   = "Tropical Evergreen Forest",
  "Trop_Deci_Forest"   = "Tropical Deciduous Forest",
  "Temp_Deci_Forest"   = "Temperate Deciduous Forest",
  "Mix_Forest"         = "Mixed Forest",
  "Trop_Shrub"         = "Tropical Shrubland",
  "Temp_Shrub"         = "Temperate Shrubland",
  "Trop_Grass"         = "Tropical Grassland",
  "Temp_Grass"         = "Temperate Grassland",
  "Subp_Shrub"         = "Subpolar Shrubland",
  "Subp_Grass"         = "Subpolar Grassland",
  "Subp_moss"          = "Subpolar Moss/Lichen",
  "Wetland"            = "Wetland",
  "Cropland"           = "Cropland",
  "Barren"             = "Barren",
  "Urban"              = "Urban",
  "Water"              = "Water",
  "Ice"                = "Ice"
)


# =========================================================
# AGGREGATED LAND-COVER ANALYSIS
# =========================================================

# =========================================================
# 1. CREATE AGGREGATED CLASSES
# =========================================================
burned_agg <- burned_recent %>%
  mutate(
    FOREST = Temp_Needle_Forest + Subp_Needle_Forest +
      Trop_Ever_Forest + Trop_Deci_Forest +
      Temp_Deci_Forest + Mix_Forest,
    
    Grasslands = Trop_Grass + Temp_Grass +
      Subp_Grass + Subp_moss,
    
    Shrubland = Trop_Shrub + Temp_Shrub + Subp_Shrub,
    
    Wetland = Wetland,
    
    Others = Cropland + Barren + Urban + Water + Ice
  ) %>%
  select(Year, FOREST, Grasslands, Shrubland, Wetland, Others, Total_ha)

# =========================================================
# 2. LABELS + COLORS
# =========================================================
agg_labels <- c(
  "FOREST" = "Forest",
  "Grasslands" = "Grasslands",
  "Shrubland" = "Shrubland",
  "Wetland" = "Wetland",
  "Others" = "Others"
)

agg_colors <- c(
  "Forest" = "#238b45",
  "Grasslands" = "#dfc27d",
  "Shrubland" = "#a6611a",
  "Wetland" = "#80cdc1",
  "Others" = "#969696"
)

# =========================================================
# 3. ABSOLUTE HA DATA
# =========================================================
burned_ha_long_agg <- burned_agg %>%
  pivot_longer(
    cols = c(FOREST, Grasslands, Shrubland, Wetland, Others),
    names_to = "Class",
    values_to = "Burned_ha"
  ) %>%
  mutate(
    Class = recode(Class, !!!agg_labels),
    Class = factor(Class, levels = unname(agg_labels))
  )

# =========================================================
# 4. PLOT (HA)
# =========================================================
p_ha_agg <- ggplot(burned_ha_long_agg,
                   aes(x = factor(Year), y = Burned_ha, fill = Class)) +
  geom_col() +
  scale_fill_manual(values = agg_colors) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Burned area (ha) by aggregated land-cover class",
    x = "Year",
    y = "Burned area (ha)"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "right"
  )

print(p_ha_agg)

# =========================================================
# 5. PERCENT DATA
# =========================================================
burned_pct_agg <- burned_agg %>%
  transmute(
    Year,
    FOREST = FOREST / Total_ha,
    Grasslands = Grasslands / Total_ha,
    Shrubland = Shrubland / Total_ha,
    Wetland = Wetland / Total_ha,
    Others = Others / Total_ha
  )

burned_pct_long_agg <- burned_pct_agg %>%
  pivot_longer(
    cols = -Year,
    names_to = "Class",
    values_to = "Percent"
  ) %>%
  mutate(
    Class = recode(Class, !!!agg_labels),
    Class = factor(Class, levels = unname(agg_labels))
  )

# =========================================================
# 6. PLOT (%)
# =========================================================
p_pct_agg <- ggplot(burned_pct_long_agg,
                    aes(x = factor(Year), y = Percent, fill = Class)) +
  geom_col() +
  scale_fill_manual(values = agg_colors) +
  scale_y_continuous(labels = percent_format()) +
  labs(
    title = "Burned area composition (%) by aggregated class",
    x = "Year",
    y = "Percent of total burned area"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "right"
  )

print(p_pct_agg)

# =========================================================
# 7. % + TOTAL BURNED AREA (SECONDARY AXIS)
# =========================================================
total_burned <- burned_agg %>%
  select(Year, Total_ha)

scale_factor <- max(total_burned$Total_ha, na.rm = TRUE)

p_pct_total_agg <- ggplot(burned_pct_long_agg,
                          aes(x = factor(Year), y = Percent, fill = Class)) +
  geom_col() +
  geom_line(
    data = total_burned,
    aes(x = factor(Year), y = Total_ha / scale_factor, group = 1),
    inherit.aes = FALSE,
    color = "black",
    linewidth = 1
  ) +
  geom_point(
    data = total_burned,
    aes(x = factor(Year), y = Total_ha / scale_factor),
    inherit.aes = FALSE,
    color = "black",
    size = 3
  ) +
  scale_fill_manual(values = agg_colors) +
  scale_y_continuous(
    labels = percent_format(),
    sec.axis = sec_axis(
      ~ . * scale_factor,
      name = "Total burned area (ha)",
      labels = comma
    )
  ) +
  labs(
    title = "Burned area composition (%) + total burned area",
    x = "Year",
    y = "Percent"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "right"
  )

print(p_pct_total_agg)

ggsave(
  filename = "C:/Users/FacundoScordo/Box/WildfireWilliam/ResultsPaper/p_pct__Totalburned_detailed.svg",
  plot = p_pct_total_agg,
  width = 14,
  height = 8,
  units = "in",
  dpi = 300,
  bg = "white"
)

# =========================================================
# 8. TREND MODELS (HA)
# =========================================================
agg_cols <- c("FOREST", "Grasslands", "Shrubland", "Wetland", "Others")

trend_ha_agg <- map_dfr(agg_cols, function(cl) {
  
  formula <- as.formula(paste0(cl, " ~ Year"))
  mod <- lm(formula, data = burned_agg)
  sm <- summary(mod)
  
  tibble(
    Class = agg_labels[[cl]],
    Slope_ha_per_year = coef(mod)[2],
    SE_slope = sm$coefficients["Year", "Std. Error"],
    P_value = sm$coefficients["Year", "Pr(>|t|)"],
    R_squared = sm$r.squared
  )
})

print(trend_ha_agg)

# Remove 2023 (extreme fire year)
burned_agg_no2023 <- burned_agg %>%
  filter(Year != 2023)

agg_cols <- c("FOREST", "Grasslands", "Shrubland", "Wetland", "Others")

trend_ha_agg_no2023 <- map_dfr(agg_cols, function(cl) {
  
  formula <- as.formula(paste0(cl, " ~ Year"))
  mod <- lm(formula, data = burned_agg_no2023)
  sm <- summary(mod)
  
  tibble(
    Class = agg_labels[[cl]],
    Slope_ha_per_year = coef(mod)[2],
    SE_slope = sm$coefficients["Year", "Std. Error"],
    P_value = sm$coefficients["Year", "Pr(>|t|)"],
    R_squared = sm$r.squared
  )
})

print(trend_ha_agg_no2023)
