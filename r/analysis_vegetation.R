# GOAL: 
#       1. identify plants in Sentinel and Planet imagery
#       2. measure how far they are from the high water line



# Set Up ------------------------------------------------------------------

setwd("C:/Users/mmtobias/Documents/GitHub/dune-remote-sensing")

# Libraries
library(terra)
library(sf)



# Load Data
#   AOI Polygon
aoi <- vect("data/vector/area_of_interest.gpkg")

#   Satellite Imagery
#     Note: both sentinel and planet data are in EPSG 32611 = WGS84/UTM Zone 11 N
sentinel <- rast("data/imagery/s2-2018-07-11.tif")

planet <- rast("data/imagery/COPR_2018-07-13_psscene_analytic_sr_udm2/PSScene/20180713_181431_0f3b_3B_AnalyticMS_SR_clip.tif") 

#   Elevations
dem <- rast("data/elevation/USGS_one_meter_x23y382_CA_SoCal_Wildfires_B4_2018.tif")
dem <- project(dem, "EPSG:32611")

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

#high water lines
hwl <- vect("data/vector/beach_features.gpkg", layer="coastlines")


# Functions ---------------------------------------------------------------

# NDVI = (NIR - R) / (NIR + R)
ndvi <- function(red, nir){
  ndvi = (nir - red)/(nir + red)
  return(ndvi)
}


# Identify Plant Pixels ---------------------------------------------------

# ??? is NDVI really the best option for CA beach plants? ???

# Sentinel === red = B04  nir = B08 -> NIR @ 10m resolution
ndvi_sentinel <- ndvi(nir = sentinel$`s2-2018-07-11_4`, red = sentinel$`s2-2018-07-11_8`)

