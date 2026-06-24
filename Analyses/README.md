Folder "BurnedArea": Year, Then HA affected by wildfires in Canada(Ha), USA(Ha), Total(Ha), and for each land cover type (Temp_Needle_Forest, Subp_Needle_Forest, Trop_Ever_Forest, Trop_Deci_Forest, Temp_Deci_Forest, Mix_Forest, Trop_Shrub, Temp_Shrub, Trop_Grass, Temp_Grass, Subp_Shrub, Subp_Grass, Subp_moss, Wetland, Cropland, Barren, Urban, Water, Ice. Use to create Panel A in Figure 1 and analyzed data related to Changes in Wildfire Burned Areas.

Folder "Fire Location": Year, areal extension, longitude and latitude of the central point, of each fire. Use in Panel B in Figure 1 and analyzed data related to the latitudinal location of fires across years.

Folder "LakesWithBasinsBurned": data for lakes in North America (Canada and USA) impacted by the buring of their basins. overlap_percentage (percentage of the basins burned by wildfires), hylak_lon (longitude), hylak_lat (latitude), lake_area (lake area km2)	lake_volume (km3), lake_depth_avg (m)	lake_elevation (m a.s.l.). Used to for the analyses corresponding to Result Section "Wildfire Burning Impacts on Lake Basins" and "Lake characteristics and wildfire exposure", it corresponding figures, tables and Supplementary Materials.

Folder "LakesWithSmokeCover": data for lakes in North America (Canada and USA) impacted by the smoke coverage over them pour_long (longitude), pour_lat (latitude),Smoke_days_light_point (number of days with light smoke coverage), Smoke_days_medium_point (number of days with medium smoke coverage), Smoke_days_heavy_point	(number of days with heavy smoke coverage), Smoke_days_undefined_point (number of days with undefined smoke coverage),	Smoke_days_aggregate_point (number of total days with smoke coverage),	lake_type  lake_area (lake area km2)	lake_volume (km3), lake_depth_avg (m)	lake_elevation (m a.s.l.). Used to for the analyses corresponding to Result Section "Smoke Impacts on Lakes " and "Lake characteristics and wildfire exposure", it corresponding figures, tables and Supplementary Materials.

Codes:
Fire_by_Years_and_Land_Cover_Type_Analyses.R:Code use to create Panel A in Figure 1 and analyzed data related to "Changes in Wildfire Burned Areas".
Fire_by_Latitudes.R: Code use to create Panel B in Figure 1 and analyzed data related to the latitudinal location of fires across years.
Fire_and_Lakes_Overlap_Analyses.R: Code use to create Panel C in Figure 1 and analyzed data related to "Wildfire Burning Impacts on Lake Basins".
Smoke_and_Lakes_Overlap_Analyses.R: Code use to create Panel D in Figure 1 and Panel A in Figure 3 and analyzed data related to "Smoke Impacts on Lakes".
Maps.R : Code used to create Figure 2
Lake_Types_Impacted.R: Code use to create Supplementary Figure 1 and analyzed data related to "Lake characteristics and wildfire exposure".