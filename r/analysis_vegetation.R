# GOAL: 
#       1. identify plants in Sentinel and Planet imagery
#       2. measure how far they are from the high water line



# Set Up ------------------------------------------------------------------

setwd("C:/Users/mmtobias/Documents/GitHub/dune-remote-sensing")

# check to see if the dem variable (the last variable in the script) is avaialble. If it's not, run the script that loads the data to get the imagery and DEM clipped to the study site. Note that clipping the DEM takes a while.
if(exists("dem")){
  print("Load Data script is already loaded.")
} else{
  print("Loading the Load Data script. This may take a few minutes.")
  source("r/load_data.R")
  }


# load high water lines
hwl <- vect("data/vector/beach_features.gpkg", layer="coastlines")
hwl_sentinel <- hwl[which(hwl$image_source == 'sentinel'),]
hwl_planet <- hwl[which(hwl$image_source == 'planet'),]

# load beach polygons
beaches <- vect("data/vector/beach_features.gpkg", layer="beaches")
beach_sentinel <- beaches[which(beaches$image_source == 'sentinel'),]
beach_planet <- beaches[which(beaches$image_source == 'planet'),]




# Functions ---------------------------------------------------------------
# functions now load in the load_data.R script


# Identify Plant Pixels ---------------------------------------------------

# ??? is NDVI really the best option for CA beach plants? ???

# Sentinel === red = B04  nir = B08 -> NIR @ 10m resolution
ndvi_sentinel <- ndvi(
  nir = sentinel$`s2-2018-07-11_4`, 
  red = sentinel$`s2-2018-07-11_8`)

ndvi_planet <- ndvi(
  nir=planet$nir, 
  red=planet$red)

# crop NDVI to beach polygons with crop()
ndvi_sentinel_crop <- crop(ndvi_sentinel, beach_sentinel, mask=TRUE)
ndvi_planet_crop <- crop(ndvi_planet, beach_planet, mask=TRUE)

# reclassify the sentinel ndvi to reveal the plant pixels
break_reclass <- -0.04

ndwi_reclass_matrix <- matrix(
  # c(-2, 0, 0, # R[-1, 0) = land (no water)
  # 0, 2, 1),  # R[0, 1] = water
  c(-2, break_reclass, 0, # R[-1, 0) = land (no water)
    break_reclass, 2, 1),  # R[0, 1] = water
  ncol = 3,
  byrow = TRUE
)

reclass_ndvi_sentinel <- classify(
  ndvi_sentinel_crop, 
  ndwi_reclass_matrix,
  include.lowest = FALSE)

plot(reclass_ndvi_sentinel)

# reclassify the planet ndvi to reveal the plant pixels
break_reclass <- 0.08

ndwi_reclass_matrix <- matrix(
  # c(-2, 0, 0, # R[-1, 0) = land (no water)
  # 0, 2, 1),  # R[0, 1] = water
  c(-2, break_reclass, 0, # R[-1, 0) = land (no water)
    break_reclass, 2, 1),  # R[0, 1] = water
  ncol = 3,
  byrow = TRUE
)

reclass_ndvi_planet <- classify(
  ndvi_planet_crop, 
  ndwi_reclass_matrix,
  include.lowest = FALSE)

plot(reclass_ndvi_planet)
