# WFRTL-land

## Overview

This project computes annual wildfire burn area statistics by land cover class for Canada and the United States over the period 1984–2024. For each year and country, the following metrics are produced:

| Field                     | Type  | Description                                             |
|:------------------------- |:----- |:------------------------------------------------------- |
| `YEAR`                    | `int` | Year of record, in the range [1984, 2024]               |
| `COUNTRY`                 | `str` | One of `"Canada"` or `"United States"`                  |
| `CLASS_1_BURN_AREA`       | `km²` | Burn area classified as Forest                          |
| `CLASS_2_BURN_AREA`       | `km²` | Burn area classified as Shrubland/Grassland/Cropland    |
| `CLASS_3_BURN_AREA`       | `km²` | Burn area classified as Urban                           |
| `CLASS_4_BURN_AREA`       | `km²` | Burn area classified as Barren/Wetland/Water/Snow/Ice   |
| `CLASS_1_BURN_PERCENTAGE` | `%`   | Class 1 burn area as a percentage of total country area |
| `CLASS_2_BURN_PERCENTAGE` | `%`   | Class 2 burn area as a percentage of total country area |
| `CLASS_3_BURN_PERCENTAGE` | `%`   | Class 3 burn area as a percentage of total country area |
| `CLASS_4_BURN_PERCENTAGE` | `%`   | Class 4 burn area as a percentage of total country area |

Land cover classification is derived from the 2015 NALCMS 30m land cover product and is held constant across all years.

## Data

The datasets required by this program are not included in this repository due to their size. They must be downloaded and placed according to the project structure outlined below.

| Dataset                 | Source                                                                                                                                                   |
|:----------------------- |:-------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Land cover raster       | [NALCMS 2015 30m](https://www.cec.org/files/atlas/?z=3&x=-119.4434&y=48.5748&lang=en&layers=polbounds%2Clandcover2015ls&opacities=100%2C100&labels=true) |
| Country boundaries      | [ArcGIS](https://www.arcgis.com/home/item.html?id=fa510018bdd044b08fc64d2a16bc680a)                                                                      |
| Fire perimeter polygons | No source provided                                                                                                                                       |

## Project Structure

The following directory structure is required for all file paths to resolve correctly at runtime:

```
.
├── __main__.py
├── shps
│   ├── countries
│   │   ├── countries.cpg
│   │   ├── countries.dbf
│   │   ├── countries.prj
│   │   ├── countries.shp
│   │   └── countries.shx
│   └── fire_polys
│       ├── fire_polys1984
│       │   ├── fire_polys1984.cpg
│       │   ├── fire_polys1984.dbf
│       │   ├── fire_polys1984.prj
│       │   ├── fire_polys1984.shp
│       │   └── fire_polys1984.shx
│       │   ...
│       └── fire_polys2024
│           ├── fire_polys2024.cpg
│           ├── fire_polys2024.dbf
│           ├── fire_polys2024.prj
│           ├── fire_polys2024.shp
│           └── fire_polys2024.shx
├── tifs
│   └── land_cover
│       └── land_cover.tif
```

## Setup & Execution

The following commands will create a virtual environment, install dependencies, and run the program. It is assumed that the current working directory contains `__main__.py` and that the required project structure is in place.

```sh
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
python3 __main__.py
```