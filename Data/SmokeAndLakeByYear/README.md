This directory contains 17 datasets spanning years 2008 -- 2024.

Each datasets was built with the following schema:

| Field                      | Description                                                                                                            |
|:-------------------------- |:---------------------------------------------------------------------------------------------------------------------- |
| hylak_id                   | HydroBASINS watershed identification number                                                                            |
| country                    | Country in which lake is located                                                                                       |
| lake_name                  | Name of lake                                                                                                           |
| pour_long                  | Longitude of lake centroid (decimal degrees)                                                                           |
| pour_lat                   | Latitude of lake centroid (decimal degrees)                                                                            |
| Smoke_days_light_point     | Number of days in year lake experienced light-density smoke                                                            |
| Smoke_days_medium_point    | Number of days in year lake experienced medium-density smoke                                                           |
| Smoke_days_heavy_point     | Number of days in year lake experienced heavy-density smoke                                                            |
| Smoke_days_undefined_point | Number of days in year lake intersected smoke with no density classification                                           |
| Smoke_days_aggregate_point | Sum of "Smoke_days_light_point", "Smoke_days_medium_point", "Smoke_days_heavy_point", and "Smoke_days_undefined_point" |
| lake_type                  | Lake type classification code                                                                                          |
| lake_area                  | Surface area of lake (km²)                                                                                             |
| lake_volume                | Volume of lake (km³)                                                                                                   |
| lake_depth_avg             | Average depth of lake (m)                                                                                              |
| lake_elevation             | Elevation of lake surface above sea level (m)                                                                          |

Each dataset was built by
1. Joining lake attributes (HydroLAKES) to their corresponding polygon geometries and grouping to produce one geometry per lake
2. Expanding each HMS smoke polygon for the given year into individual calendar days by generating a date series spanning the smoke event's start and end Julian dates
3. For each day, spatially intersecting lake polygons against smoke polygons to identify which lakes fall within a smoke plume
4. Where a lake intersects multiple overlapping smoke polygons on the same day, retaining only the highest smoke density (Heavy > Medium > Light)
5. Aggregating across all days per lake, counting the number of days each lake was exposed under each density tier and how many days had no density classification
6. Outputting one row per lake with smoke day counts for each density tier and a total aggregate smoke day count

Generation script(s) can be found [here](https://github.com/williamcdavies/WFRTL/tree/main/scripts/smokes_polys_over/verbose/smokes_polys_over_lakes_polys_corrected).