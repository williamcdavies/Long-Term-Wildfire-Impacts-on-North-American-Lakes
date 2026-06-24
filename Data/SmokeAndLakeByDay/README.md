This directory contains 17 datasets spanning years 2008 -- 2024.

Each datasets was built with the following schema:

| Field | Description                                                      |
|:----- |:---------------------------------------------------------------- |
| date  | Date formatted in YYYY-MM-DD.                                    |
| l     | Sum of lakes that experienced "light density" smoke on date      |
| m     | Sum of lakes that experienced "medium density" smoke on date     |
| h     | Sum of lakes that experienced "heavy density" smoke on date      |
| na    | Sum of lakes that experienced "unlabelled density" smoke on date |
| sum   | Sum of "l", "m", "h", and "na"                                   |

Each dataset was built by
1. Selecting all lake point geometries (from HydroLAKES) that fall within the boundaries of the target countries (USA and Canada)
2. For each lake, performing a spatial join against HMS smoke polygons for the given year to identify which smoke plumes contain the lake point
3. Expanding each lake–smoke overlap into individual calendar days by generating a date series spanning the smoke event's start and end Julian dates
4. Where a lake appears under multiple overlapping smoke polygons on the same day, retaining only the highest smoke density (Heavy > Medium > Light)
5. Aggregating across all lakes per day, counting how many lakes fall under each density tier (Light, Medium, Heavy) and how many have no smoke coverage
6. Outputting one row per day with columns for each density tier count and a total lake count

Generation script(s) can be found [here](https://github.com/williamcdavies/WFRTL/tree/main/scripts/smokes_polys_over/smokes_polys_over_lakes_points).