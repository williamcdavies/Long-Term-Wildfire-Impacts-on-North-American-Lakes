"""
utils.raster_util
"""

from typing                import cast

import numpy

from affine                import Affine
from rasterio.features     import geometry_mask
from rasterio.io           import DatasetReader
from rasterio.windows      import from_bounds, Window
from shapely.geometry.base import BaseGeometry
from utils.globals         import TRANSFORM


def get_band_data(src: DatasetReader, idx: int, window: Window) -> numpy.ndarray:
    """
    Get the band data from a :class:`rasterio.io.DatasetReader`.

    Parameters
    ----------
    src : :class:`rasterio.io.DatasetReader`
        The :class:`rasterio.io.DatasetReader`.
    idx : int
        The band index.
    window : :class:`rasterio.windows.Window`
        The region (slice) of the dataset from which data will be read.

    Returns
    -------
    :class:`numpy.ndarray`

    Notes
    -----
    See :meth:`rasterio.io.BufferedDatasetWriter.read` for additional information.
    """

    return cast(numpy.ndarray, src.read(indexes=idx, window=window))


def get_geometry_mask(geom: BaseGeometry, out_shape: tuple[int, int] | list[int], transform: Affine) -> numpy.ndarray:
    """
    Get the boolean mask from a :class:`shapely.geometry.base.BaseGeometry`

    Parameters
    ----------
    geom : :class:`shapely.geometry.base.BaseGeometry`
        The :class:`shapely.geometry.base.BaseGeometry`.
    out_shape : tuple[int, int] or list[int]
        The shape of output :class:`numpy.ndarray`.
    transform : :class:`affine.Affine`
        The transformation from pixel coordinates of source to the coordinate system of the input
       :class:`shapely.geometry.base.BaseGeometry`.

    Returns
    ----------
    :class:`numpy.ndarray`.

    Notes
    -----
    See :func:`rasterio.features.geometry_mask` for additional information.
    """

    return cast(numpy.ndarray, geometry_mask([geom], out_shape=out_shape, transform=transform))


def get_window(geom: BaseGeometry) -> Window:
    """
    Get the :class:`rasterio.windows.Window` from a :class:`shapely.geometry.base.BaseGeometry`.

    Parameters
    ----------
    geom : :class:`shapely.geometry.base.BaseGeometry`
        The :class:`shapely.geometry.base.BaseGeometry`.

    Returns
    ----------
    :class:`rasterio.windows.Window`
    """

    min_x, min_y, max_x, max_y = geom.bounds

    return cast(Window, from_bounds(min_x, min_y, max_x, max_y, transform=TRANSFORM))


def get_window_transform(src: DatasetReader, window: Window) -> Affine:
    """
    Get the :class:`affine.Affine` for a :class:`rasterio.windows.Window`.

    Parameters
    ----------
    src : :class:`rasterio.io.DatasetReader`
        The :class:`rasterio.io.DatasetReader`.
    window : :class:`rasterio.windows.Window`
        The :class:`rasterio.windows.Window`.

    Returns
    ----------
    :class:`affine.Affine`

    Notes
    -----
    See :meth:`rasterio.io.BufferedDatasetWriter.window_transform` for additional information.
    """

    return cast(Affine, src.window_transform(window))
