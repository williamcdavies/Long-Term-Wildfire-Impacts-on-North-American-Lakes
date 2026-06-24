# ---- Packages ----
# install.packages(c("sf","dplyr","readr","ggplot2","rnaturalearth","rnaturalearthdata","ggspatial"))
library(sf)
library(dplyr)
library(readr)
library(ggplot2)
library(rnaturalearth)
library(rnaturalearthdata)
library(ggspatial)

# ---- User inputs ----
data_dir     <- "C:/Users/FacundoScordo/Box/WildfireWilliam/ResultsPaper/DataAnalyses/LakesWithSmokeCover"
year_to_plot <- 2008   # <--- change this to 2005, 2010, etc. as needed

csv_path <- file.path(data_dir, sprintf("wfrtl_composite%d.csv", year_to_plot))
out_png  <- file.path(data_dir, sprintf("Lakes_Smoke_POLYS_%d.png", year_to_plot))

# ---- CRS and extent (LAEA "round hemisphere") ----
crs_laea <- "+proj=laea +lat_0=40 +lon_0=-96 +datum=WGS84 +units=m +no_defs"

# Lon/lat ranges just for graticules (in degrees)
lon_min <- -135; lon_max <- -60
lat_min <-   5;  lat_max <-  80

# ---- Read polygon-composite lake data and compute summed smoke variable ----
# Structure based on wfrtl_composite2005:
# Hylak_id, Lake_name, Pour_long, Pour_lat,
# Smoke_days_light_poly, Smoke_days_medium_poly,
# Smoke_days_heavy_poly, Smoke_days_undefined_poly,
# Smoke_days_aggregate_poly, Country

dat <- read_csv(
  csv_path,
  show_col_types = FALSE,
  col_select = c(
    lake_name,
    pour_long,
    pour_lat,
    Smoke_days_medium_point,
    Smoke_days_heavy_point,
    country
  )
) %>%
  # You can include Mexico here if polygon files ever contain it
  filter(
    country %in% c("United States", "Canada"),
    !is.na(pour_long), !is.na(pour_lat)
  ) %>%
  mutate(
    # Option A: Medium + Heavy (consistent with earlier city map)
    Smoke_days_sum = Smoke_days_medium_point + Smoke_days_heavy_point
    # Option B (if you later prefer): use Smoke_days_aggregate_poly instead
    # Smoke_days_sum = Smoke_days_aggregate_poly
  )

# ---- Convert to sf points using Pour_long / Pour_lat ----
pts_wgs84 <- st_as_sf(dat, coords = c("pour_long","pour_lat"), crs = 4326, remove = FALSE)
pts_proj  <- st_transform(pts_wgs84, crs_laea)

# ---- Country polygons (North America) ----
na_countries <- ne_countries(
  scale = "medium",
  continent = "North America",
  returnclass = "sf"
) %>%
  st_transform(crs_laea)

# ---- Bounding box in projected coordinates for coord_sf ----
bb   <- st_bbox(na_countries)
xlim <- c(bb["xmin"], bb["xmax"])
ylim <- c(bb["ymin"], bb["ymax"])

# ---- Graticules every 10° (built in lon/lat, then projected) ----
grat_laea <- st_graticule(
  lon = seq(lon_min, lon_max, by = 10),
  lat = seq(lat_min, lat_max, by = 10)
) %>%
  st_transform(crs_laea)

# ---- Pastel yellow ??? orange ??? red palette for smoke ----
smoke_pal <- scale_color_gradientn(
  colours = c("#FFF7BC", "#FEC44F", "#FD8D3C", "#E31A1C"),
  name    = "Smoke days",
  limits  = c(0, 50),
  oob     = scales::squish
)

# ---- Build map ----
p <- ggplot() +
  theme_minimal(base_size = 11) +
  theme(
    panel.background = element_rect(fill = "#D6ECFF", color = NA),  # sea
    panel.grid.major = element_blank(),
    axis.title = element_blank(),
    axis.text  = element_text(color = "black", size = 7)
  ) +
  # Graticules
  geom_sf(data = grat_laea, color = "white", linewidth = 0.28) +
  # Land polygons
  geom_sf(data = na_countries, fill = "white", color = "grey65", linewidth = 0.25) +
  # Summed smoke at lake pour points
  geom_sf(
    data = pts_proj,
    aes(color = Smoke_days_sum),
    size = 0.3, alpha = 1, show.legend = TRUE
  ) +
  smoke_pal +
  coord_sf(
    crs = crs_laea,
    default_crs = NULL,
    xlim = xlim, ylim = ylim,
    expand = FALSE,
    label_graticule = "NESW",
    label_axes = "NESW"
  ) +
  annotation_scale(
    location = "bl",
    bar_length = 1000e3,     # 1000 km scale
    width_hint = 0.2,
    line_width = 0.6,
    text_cex = 1.2,
    unit_category = "metric",
    bar_cols = c("white", "grey30"),
    pad_x = unit(0.8, "cm"),
    pad_y = unit(0.8, "cm")
  ) +
  labs(
    title = sprintf(
      "Weighted mean number of smoke days (Medium + Heavy), lakes %d",
      year_to_plot
    )
  ) +
  theme(
    legend.position   = c(0.15, 0.32),
    legend.text       = element_text(size = 12),
    legend.title      = element_text(size = 13),
    legend.background = element_rect(fill = scales::alpha("white", 1), color = NA),
    plot.title        = element_text(face = "bold", hjust = 0, margin = margin(0,0,8,0))
  )

print(p)
# ---- Save high-res PNG ----
ggsave(out_png, p, width = 8, height = 10, dpi = 300, bg = "white")
message("Saved: ", normalizePath(out_png))

out_svg <- sub("\\.png$", ".svg", out_png)

ggsave(
  filename = out_svg,
  plot = p,
  width = 8,
  height = 10,
  bg = "white"
)

message("Saved: ", normalizePath(out_svg))

# ============================================================
# PACKAGES
# ============================================================

library(sf)
library(dplyr)
library(readr)
library(ggplot2)
library(rnaturalearth)
library(rnaturalearthdata)
library(ggspatial)
library(purrr)
library(grid)
library(scales)

# ============================================================
# USER INPUTS
# ============================================================

data_dir  <- "C:/Users/FacundoScordo/Box/WildfireWilliam/ResultsPaper/DataAnalyses/LakesWithBasinsBurned"
years     <- 2008
out_png   <- file.path(data_dir, "FireArea_Lakes_USA_CAN_2008.png")

# Lambert Azimuthal Equal Area (continental)
crs_laea <- "+proj=laea +lat_0=45 +lon_0=-100 +datum=WGS84 +units=m +no_defs"

# ============================================================
# LOAD & AGGREGATE FIRE-LAKE DATA
# ============================================================

load_fire_csv <- function(yr) {
  path <- file.path(data_dir, sprintf("fire_polys_over_hybas%d.csv", yr))
  if (!file.exists(path)) return(NULL)
  read_csv(path, show_col_types = FALSE) %>% mutate(year = yr)
}

fire_lake_all <- map_df(years, load_fire_csv) %>%
  filter(
    hylak_country %in% c("United States", "Canada"),
    !is.na(hylak_lon),
    !is.na(hylak_lat)
  ) %>%
  mutate(overlap_pct = overlap_percentage * 100) %>%
  group_by(hylak_name, hylak_country, hylak_lon, hylak_lat) %>%
  summarise(
    overlap_pct = max(overlap_pct, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    overlap_cat = case_when(
      overlap_pct < 1                        ~ "<1%",
      overlap_pct >= 1  & overlap_pct <= 25  ~ "1-25%",
      overlap_pct > 25 & overlap_pct <= 50   ~ "26-50%",
      overlap_pct > 50 & overlap_pct <= 75   ~ "51-75%",
      overlap_pct > 75                       ~ "76-100%",
      TRUE                                   ~ NA_character_
    ),
    overlap_cat = factor(
      overlap_cat,
      levels = c("<1%", "1-25%", "26-50%", "51-75%", "76-100%")
    ),
    # <<--- HERE is Option 1: reduce point sizes
    point_size = if_else(overlap_cat == "<1%", 0.2, 1.2)
  )
# ============================================================
# COLOR SCALE
# ============================================================

overlap_pal <- scale_color_manual(
  name   = "Fire buffer\noverlap (%)",
  values = c(
    "<1%"     = "#6BAED6",  # color for <1%
    "1-25%"   = "#FFF7BC",
    "26-50%"  = "#FEC44F",
    "51-75%"  = "#FD8D3C",
    "76-100%" = "#E31A1C"
  ),
  drop = FALSE
)
# ============================================================
# CONVERT TO SF AND ORDER FOR PLOTTING
# ============================================================

pts_wgs84 <- st_as_sf(
  fire_lake_all,
  coords = c("hylak_lon", "hylak_lat"),
  crs = 4326,
  remove = FALSE
)

pts_proj <- st_transform(pts_wgs84, crs_laea)

# <<--- Order points so that largest overlap is plotted last (on top)
pts_proj <- pts_proj %>%
  arrange(overlap_cat)  # factor levels already <1%, 1-25%, 26-50%, 51-75%, 76-100%


# ============================================================
# BASE MAPS
# ============================================================
p2 <- ggplot() +
  theme_minimal(base_size = 11) +
  theme(
    panel.background = element_rect(fill = "#D6ECFF", color = NA),  # same sea color as p
    panel.grid.major = element_blank(),
    axis.title = element_blank(),
    axis.text  = element_text(color = "black", size = 7)            # same as p
  ) +
  
  # Optional graticules if you already created them for p
  geom_sf(data = grat_laea, color = "white", linewidth = 0.28) +
  
  # Land polygons styled like p
  geom_sf(data = na_countries, fill = "white", color = "grey65", linewidth = 0.25) +
  
  # Fire-affected lake points
  geom_sf(
    data = pts_proj,
    aes(color = overlap_cat, size = point_size),
    alpha = 1,
    show.legend = TRUE
  ) +
  scale_size_identity() +
  overlap_pal +
  
  guides(color = guide_legend(
    override.aes = list(size = c(0.5, 1.2, 1.2, 1.2, 1.2))
  )) +
  
  coord_sf(
    crs = crs_laea,
    default_crs = NULL,
    xlim = xlim, ylim = ylim,
    expand = FALSE,
    label_graticule = "NESW",
    label_axes = "NESW"
  ) +
  
  annotation_scale(
    location = "bl",                 # same corner as p
    bar_length = 1000e3,             # same length as p
    width_hint = 0.2,
    line_width = 0.6,
    text_cex = 1.2,
    unit_category = "metric",
    bar_cols = c("white", "grey30"),
    pad_x = unit(0.8, "cm"),
    pad_y = unit(0.8, "cm")
  ) +
  
  labs(
    title = "Wildfire-Affected Lakes 2023\nNorth America"
  ) +
  
  theme(
    legend.position   = c(0.15, 0.32),   # same general location as p
    legend.text       = element_text(size = 12),
    legend.title      = element_text(size = 13),
    legend.background = element_rect(fill = scales::alpha("white", 1), color = NA),
    plot.title        = element_text(face = "bold", hjust = 0, margin = margin(0, 0, 8, 0))
  )

print(p2)

# ============================================================
# SAVE
# ============================================================

ggsave(filename = out_png, plot = p2, width = 10, height = 8, dpi = 300, bg = "white")
message("Saved: ", normalizePath(out_png))

out_svg <- sub("\\.png$", ".svg", out_png)

ggsave(
  filename = out_svg,
  plot = p2,
  width = 10,
  height = 8,
  bg = "white"
)

message("Saved: ", normalizePath(out_svg))
