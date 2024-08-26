#GOAL: This file loads the data that are needed by multiple scripts, performs the processses needed to set up the data for use such as clipping and reprojecting





# LOAD LIBRARIES ----------------------------------------------------------

library(terra)
library(sf)



#  LOAD FUNCTIONS ---------------------------------------------------------


# NDWI = (Green - NIR) / (Green + NIR)
ndwi <- function(green, nir){
  ndwi = (green - nir)/(green + nir)
  return(ndwi)
}


# NDVI = (NIR - R) / (NIR + R)
ndvi <- function(red, nir){
  ndvi = (nir - red)/(nir + red)
  return(ndvi)
}



# LOAD DATA ---------------------------------------------------------------

# AOI Polygon
aoi <- vect("data/vector/area_of_interest.gpkg")


# Satellite Imagery
#     Note: both sentinel and planet data are in EPSG 32611 = WGS84/UTM Zone 11 N
sentinel <- rast("data/imagery/s2-2018-07-11.tif")

#plotRGB(x = sentinel, r=4, g=3, b=2, stretch="lin")

planet <- rast("data/imagery/COPR_2018-07-13_psscene_analytic_sr_udm2/PSScene/20180713_181431_0f3b_3B_AnalyticMS_SR_clip.tif") 

#plotRGB(x = planet, r=3, g=2, b=1, stretch="lin")


# Elevations
dem <- rast("data/elevation/USGS_one_meter_x23y382_CA_SoCal_Wildfires_B4_2018.tif")
dem <- project(dem, "EPSG:32611")



# PROCESS DATA ------------------------------------------------------------

#crop rasters 
sentinel <- crop(
  x=sentinel, 
  y=aoi)
planet <- crop(
  x=planet, 
  y=aoi)
dem <- crop(
  x=dem, 
  y=aoi)






