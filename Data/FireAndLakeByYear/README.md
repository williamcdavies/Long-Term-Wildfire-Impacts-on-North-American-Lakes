This directory contains 17 datasets spanning years 2008 -- 2024.

Each datasets was built with the following schema:

| Field              | Description                                                                                      |
|:------------------ |:------------------------------------------------------------------------------------------------ |
| id                 | Internal watershed identification number                                                         |
| hybas_id           | HydroBASINS watershed identification number                                                      |
| pfaf_id            | Pfafstetter code (hierarchical basin coding system indicating basin topology and nesting level)  |
| src_rgn            | Source region                                                                                    |
| overlap_percentage | Percentage of watershed area burned (between 0 -- 1)                                             |
| hylak_id           | HydroLAKES lake identification number                                                            |
| hylak_name         | Name of lake                                                                                     |
| hylak_country      | Country in which lake is located                                                                 |
| hylak_continent    | Continent in which lake is located                                                               |
| hylak_lon          | Longitude of lake centroid (decimal degrees)                                                     |
| hylak_lat          | Latitude of lake centroid (decimal degrees)                                                      |
| lake_type          | Lake type classification code                                                                    |
| lake_area          | Surface area of lake (km²)                                                                       |
| lake_volume        | Volume of lake (km³)                                                                             |
| lake_depth_avg     | Average depth of lake (m)                                                                        |
| lake_elevation     | Elevation of lake surface above sea level (m)                                                    |

Each dataset was built by
1. Computing the geometric union of all recorded wildfires in North America in the given year
2. Computing the percentage (represented as a float between 0 -- 1) of overlap between the geometric union and each unique watershed in North America (producing a number of records equal to the number of watersheds)
3. Expanding each watershed record to encapsulate information regarding each unique lake within its geometry (a lake belongs to a watershed if its centroid is within the geometry of that watershed) (producing a number of records equal to the number of lakes)
4. Appending watershed and lake meta-data to each record (descriptions provided above)

Generation script(s) can be found [here](https://github.com/williamcdavies/WFRTL/tree/main/scripts/fire_union_polys_over/fire_union_polys_over_hybas_polys).