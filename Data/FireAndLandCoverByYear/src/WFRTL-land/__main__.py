"""
__main__.py
"""


import pathlib
import sys
import time

import geopandas
import numpy
import pandas
import rasterio

from utils.geometry_util import get_geom_by_key_value_pair
from utils.globals       import COUNTRIES_SHP, CRS, LAND_COVER_TIF, LUT, OUTPUT_CSV, PIXEL_AREA_KM2, RANGE_OF_YEARS, SHPS_DIR
from utils.raster_util   import get_band_data, get_geometry_mask, get_window, get_window_transform
from utils.print_util    import print_progress_bar


def main() -> int:
    """
    main
    """

    countries_gdf      = geopandas.read_file(COUNTRIES_SHP).to_crs(CRS)
    canada_geom        = get_geom_by_key_value_pair(countries_gdf, "NAME", "Canada"       )
    united_states_geom = get_geom_by_key_value_pair(countries_gdf, "NAME", "United States")
    error_count        = 0
    shape_count        = 0 

    with rasterio.open(LAND_COVER_TIF) as land_cover_tif:
        # Open handle to land_cover.tif.

        records = []
        # Initialise an empty array to accumulate records for the for the subject (year, country). -
        # Record schema is described in README.md.

        for year in RANGE_OF_YEARS:
            # Do the following for each year in the range (1984, 2025):

            fire_polys_shp   = SHPS_DIR / pathlib.Path(f"fire_polys/fire_polys{year}/fire_polys{year}.shp")
            fire_polys_gdf   = geopandas.read_file(fire_polys_shp).to_crs(CRS)
            fire_polys_count = len(fire_polys_gdf)

            for country_name, country_geom in [
                ("Canada",        canada_geom       ),
                ("United States", united_states_geom),
            ]:
                # Do the following for each country in ("Canada", "United States"):

                class_id_counts = numpy.zeros(20, dtype=numpy.int64)
                # Initialise a 1-indexed array to accumulate class id counts for the subject (year,-
                #  country). Index 0 is unused.

                i = 0
                t = time.time()

                for _, fire_poly in fire_polys_gdf.iterrows():
                    # Do the following for each fire_poly object in fire_polys_gdf:

                    i += 1

                    fire_poly_geom = fire_poly.geometry
                    if not fire_poly_geom.is_valid:
                        error_count += 1
                        continue
                    # If the fire_poly geometry is invalid, continue.

                    if not fire_poly_geom.intersects(country_geom):
                        continue
                    # If the fire_poly geometry does not intersect the country geometry, continue.

                    clipped_fire_poly_geom = fire_poly_geom.intersection(country_geom)
                    # fire_poly geometries can intersect multiple country geometries. To avoid coun-
                    # t duplication, clip the fire_poly geometry to the subject country geometry.

                    if clipped_fire_poly_geom.is_empty:
                        continue
                    # If the clipped fire_poly geometry does not contain any vertices, continue. Th-
                    # is can occur if the unclipped fire_poly geometry touches the subject country -
                    # geometry, resulting in fire_poly_goem.intersects returning true, but there is-
                    #  no overlap, resulting in fire_poly_geom.intersection returning a shapely.Geo-
                    # metry with 0 vertices.

                    window = get_window(clipped_fire_poly_geom)

                    if not window.width > 1 or not window.height > 1:
                        continue
                    # If the bounding box of the clipped fire_poly geometry cannot be represented a-
                    # s a positive integer, continue. This can occur if the clipped fire_poly goemt-
                    # ry is smaller than 30 meters by 30 meters.

                    window_transform = get_window_transform(land_cover_tif, window)
                    band_data        = get_band_data(land_cover_tif, 1, window)

                    if not band_data.shape[0] > 1 or not band_data.shape[1] > 1:
                        continue
                    # If the shape of the band data cannot be represented as a positive integer, co-
                    # ntinue. This can occur if the clipped fire_poly goemtry is smaller than 30 me-
                    # ters by 30 meters.

                    geometry_mask            = get_geometry_mask(clipped_fire_poly_geom, band_data.shape, window_transform) # pylint: disable=no-member
                    band_data[geometry_mask] = 0
                    class_id_data            = LUT[band_data]

                    for class_id in range(1, 20):
                        # Do the following for each land cover class in the range (1, 20):

                        class_id_counts[class_id] += numpy.sum(class_id_data == class_id)

                    print_progress_bar(str(year), i - 1, fire_polys_count, country_name, "Processed", time.time() - t, False)

                shape_count += i

                record = {
                    "YEAR":    year, 
                    "COUNTRY": country_name
                }

                for class_id in range(1, 20):
                    class_id_count = class_id_counts[class_id]
                    burn_area_km2  = class_id_count * PIXEL_AREA_KM2
                    burn_area_pct  = burn_area_km2  / (country_geom.area / 1e6)

                    record.update({
                        f"CLASS_{class_id}_BURN_AREA_KM2": burn_area_km2,
                        f"CLASS_{class_id}_BURN_AREA_PCT": burn_area_pct,
                    })

                records.append(record)

                print_progress_bar(str(year), fire_polys_count, fire_polys_count, country_name, "Processed", time.time() - t, True)

    print(f"Invalidity rate: {(error_count/shape_count) * 100:.1f}%")
    
    pandas.DataFrame(records).to_csv(OUTPUT_CSV, index=False)

    return 0


if __name__ == '__main__':
    sys.exit(main())
