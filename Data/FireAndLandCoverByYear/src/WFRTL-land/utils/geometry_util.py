"""
utils.geometry_util
"""


import geopandas

from shapely.geometry.base import BaseGeometry


def get_geom_by_idx(gdf: geopandas.GeoDataFrame, idx: int) -> BaseGeometry:
    """
    Get the :class:`shapely.geometry.base.BaseGeometry` from a :obj:`geopandas.GeoDataFrame`.

    Parameters
    ----------
    gdf : :obj:`geopandas.GeoDataFrame`
        The :obj:`geopandas.GeoDataFrame`.
    idx : int
        The positional index.

    Returns
    ----------
    :class:`shapely.geometry.base.BaseGeometry`
    """

    return gdf.geometry.iloc[idx]


def get_geom_by_key_value_pair(gdf: geopandas.GeoDataFrame, key: str, value: str) -> BaseGeometry:
    """
    Get the  :class:`shapely.geometry.base.BaseGeometry` from a :obj:`geopandas.GeoDataFrame`.

    Parameters
    ----------
    gdf : :obj:`geopandas.GeoDataFrame`
        The :obj:`geopandas.GeoDataFrame`.
    key : str
        The column label.
    value : str
        The unique cell value in subject column.

    Returns
    ----------
    :class:`shapely.geometry.base.BaseGeometry`

    Notes
    -----
    Asserts that exactly one record matches the given (key, value) pair.
    """

    idx = gdf[gdf[key] == value].index

    assert len(idx) == 1, f"count of records having ({key}, {value}) expected to equal 1, got: {len(idx)}"
    return get_geom_by_idx(gdf, int(idx[0]))
