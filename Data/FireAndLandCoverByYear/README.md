This directory contains 17 datasets spanning years 2008 -- 2024.

Each datasets was built with the following schema:

| Field                  | Type  | Description                                                                |
|:---------------------- |:----- |:-------------------------------------------------------------------------- |
| YEAR                   | int   | Year of record, in the range [1984, 2024]                                  |
| COUNTRY                | str   | One of "Canada" or "United States"                                         |
| CLASS_1_BURN_AREA_KM2  | km²   | Burn area classified as Temperate or Subpolar Needleaf Forest              |
| CLASS_2_BURN_AREA_KM2  | km²   | Burn area classified as Subpolar Taiga Needleleaf Forest                   |
| CLASS_3_BURN_AREA_KM2  | km²   | Burn area classified as Tropical or Subtropical Broadleaf Evergreen Forest |
| CLASS_4_BURN_AREA_KM2  | km²   | Burn area classified as Tropical or Subtropical Broadleaf Deciduous Forest |
| CLASS_5_BURN_AREA_KM2  | km²   | Burn area classified as Temperate or Subpolar Broadleaf Deciduous Forest   |
| CLASS_6_BURN_AREA_KM2  | km²   | Burn area classified as Mixed Forest                                       |
| CLASS_7_BURN_AREA_KM2  | km²   | Burn area classified as Tropical or Subtropical Shrubland                  |
| CLASS_8_BURN_AREA_KM2  | km²   | Burn area classified as Temperate or Subpolar Shrubland                    |
| CLASS_9_BURN_AREA_KM2  | km²   | Burn area classified as Tropical or Subtropical Grassland                  |
| CLASS_10_BURN_AREA_KM2 | km²   | Burn area classified as Temperate or Subpolar Grassland                    |
| CLASS_11_BURN_AREA_KM2 | km²   | Burn area classified as Subpolar or Polar Shrubland-Lichen-Moss            |
| CLASS_12_BURN_AREA_KM2 | km²   | Burn area classified as Subpolar or Polar Grassland-Lichen-Moss            |
| CLASS_13_BURN_AREA_KM2 | km²   | Burn area classified as Subpolar or Polar Barren-Lichen-Moss               |
| CLASS_14_BURN_AREA_KM2 | km²   | Burn area classified as Wetland                                            |
| CLASS_15_BURN_AREA_KM2 | km²   | Burn area classified as Cropland                                           |
| CLASS_16_BURN_AREA_KM2 | km²   | Burn area classified as Barren Land                                        |
| CLASS_17_BURN_AREA_KM2 | km²   | Burn area classified as Urban and Built-up                                 |
| CLASS_18_BURN_AREA_KM2 | km²   | Burn area classified as Water                                              |
| CLASS_19_BURN_AREA_KM2 | km²   | Burn area classified as Snow and Ice                                       |
| CLASS_1_BURN_AREA_PCT  | float | Class 1 burn area as a proportion of total country area                    |
| CLASS_2_BURN_AREA_PCT  | float | Class 2 burn area as a proportion of total country area                    |
| CLASS_3_BURN_AREA_PCT  | float | Class 3 burn area as a proportion of total country area                    |
| CLASS_4_BURN_AREA_PCT  | float | Class 4 burn area as a proportion of total country area                    |
| CLASS_5_BURN_AREA_PCT  | float | Class 5 burn area as a proportion of total country area                    |
| CLASS_6_BURN_AREA_PCT  | float | Class 6 burn area as a proportion of total country area                    |
| CLASS_7_BURN_AREA_PCT  | float | Class 7 burn area as a proportion of total country area                    |
| CLASS_8_BURN_AREA_PCT  | float | Class 8 burn area as a proportion of total country area                    |
| CLASS_9_BURN_AREA_PCT  | float | Class 9 burn area as a proportion of total country area                    |
| CLASS_10_BURN_AREA_PCT | float | Class 10 burn area as a proportion of total country area                   |
| CLASS_11_BURN_AREA_PCT | float | Class 11 burn area as a proportion of total country area                   |
| CLASS_12_BURN_AREA_PCT | float | Class 12 burn area as a proportion of total country area                   |
| CLASS_13_BURN_AREA_PCT | float | Class 13 burn area as a proportion of total country area                   |
| CLASS_14_BURN_AREA_PCT | float | Class 14 burn area as a proportion of total country area                   |
| CLASS_15_BURN_AREA_PCT | float | Class 15 burn area as a proportion of total country area                   |
| CLASS_16_BURN_AREA_PCT | float | Class 16 burn area as a proportion of total country area                   |
| CLASS_17_BURN_AREA_PCT | float | Class 17 burn area as a proportion of total country area                   |
| CLASS_18_BURN_AREA_PCT | float | Class 18 burn area as a proportion of total country area                   |
| CLASS_19_BURN_AREA_PCT | float | Class 19 burn area as a proportion of total country area                   |

Each dataset was built by
1. Loading fire perimeter polygons for the given year and reprojecting to the raster CRS
2. For each fire polygon, clipping to the country boundary to avoid double-counting fires that cross international borders
3. For each clipped fire polygon, deriving a raster window from its bounding box and reading only that subset of the land cover raster into memory
4. Rasterizing the clipped fire polygon into a boolean mask and applying it to the window to discard pixels outside the fire perimeter
4. Mapping remaining pixel values to land cover class IDs using a lookup table
5. Accumulating pixel counts per land cover class across all fire polygons for the given (year, country) combination
6. Converting pixel counts to burn area in km² using the known pixel area
7. Expressing burn area as a proportion of total country area derived from the country boundary geometry

Generation script(s) can be found [here](https://github.com/williamcdavies/WFRTL-land).