"""
utils.globals
"""


import pathlib

import numpy
import rasterio


PIXEL_AREA_KM2 = 0.0009
"""
30 meters by 30 meters expressed in km2
"""

OUTPUT_CSV     = pathlib.Path.cwd() / "wfrtl-land2020.csv"
"""
Path to the output destination
"""

MAIN_SRC_DIR   = pathlib.Path(__file__).parent.parent
"""
Path to the directory containing `main.py`.
"""

SHPS_DIR       = MAIN_SRC_DIR   / pathlib.Path("shps")
"""
Path to the shps directory.
"""

COUNTRIES_DIR  = SHPS_DIR       / pathlib.Path("countries")
"""
Path to the shps/countries directory.
"""

COUNTRIES_SHP  = COUNTRIES_DIR  / pathlib.Path("countries.shp")
"""
Path to shps/countries/countries.shp.
"""

TIFS_DIR       = MAIN_SRC_DIR   / pathlib.Path("tifs")
"""
Path to the tifs directory.
"""

LAND_COVER_DIR = TIFS_DIR       / pathlib.Path("land_cover")
"""
Path to the tifs/land_cover directory.
"""

LAND_COVER_TIF = LAND_COVER_DIR / pathlib.Path("land_cover.tif")
"""
Path to tifs/land_cover/land_cover.tif.
"""

RANGE_OF_YEARS = range(1984, 2025)
"""
Range of years for which burn area geometries are available.
"""

CRS:       rasterio.crs.CRS             = None
"""
Coordinate Reference System (CRS) of :obj:`LAND_COVER_TIF`.
"""

TRANSFORM: rasterio.transform.TRANSFORM = None
"""
Transform of :obj:`LAND_COVER_TIF`.
"""

with rasterio.open(LAND_COVER_TIF) as land_cover_tif:
    CRS       = land_cover_tif.crs       # assigned here
    TRANSFORM = land_cover_tif.transform # assigned here

RAST_VALUE_TO_CLASS_ID = {i: i for i in range(1, 20)}
"""
Mapping of NALCMS raster values to land cover class IDs (not applicable for 1:1 label mappings).

- Class 1 (Forest):                        raster values 1-6
- Class 2 (Shrubland/Grassland/Cropland):  raster values 7-12, 15
- Class 3 (Urban):                         raster value 17
- Class 4 (Barren/Wetland/Water/Snow/Ice): raster values 13, 14, 16, 18, 19
"""

CLASS_ID_TO_CLASS_NAME = {
    1:  "Temperate or sub-polar needleaf forest",
    2:  "Sub-polar taiga needleleaf forest",
    3:  "Tropical or sub-tropical broadleaf evergreen forest",
    4:  "Tropical or sub-tropical broadleaf deciduous forest",
    5:  "Temperate or sub-polar broadleaf deciduous forest",
    6:  "Mixed forest",
    7:  "Tropical or sub-tropical shrubland",
    8:  "Temperate or sub-polar shrubland",
    9:  "Tropical or sub-tropical grassland",
    10: "Temperate or sub-polar grassland",
    11: "Sub-polar or polar shrubland-lichen-moss",
    12: "Sub-polar or polar grassland-lichen-moss",
    13: "Sub-polar or polar barren-lichen-moss",
    14: "Wetland",
    15: "Cropland",
    16: "Barren land",
    17: "Urban and built-up",
    18: "Water",
    19: "Snow and ice",
}
"""
Mapping of land cover class IDs to land cover class names (not applicable for 1:1 label mappings).

- Class 1 (raster values 1-6):                Forest
- Class 2 (raster values 7-12, 15):           Shrubland/Grassland/Cropland
- Class 3 (raster value 17):                  Urban
- Class 4 (raster values 13, 14, 16, 18, 19): Barren/Wetland/Water/Snow/Ice
"""

LUT = numpy.zeros(256, dtype=numpy.uint8)
"""
256-element lookup table mapping raster values to land cover class IDs. Unmapped values default to 
0.
"""

for rast_value, class_id in RAST_VALUE_TO_CLASS_ID.items():
    LUT[rast_value] = class_id # assigned here
