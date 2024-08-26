# GOAL: 
#       1. identify plants in Sentinel and Planet imagery
#       2. measure how far they are from the high water line



# Set Up ------------------------------------------------------------------

setwd("C:/Users/mmtobias/Documents/GitHub/dune-remote-sensing")

source("r/load_data.R")

# load high water lines
hwl <- vect("data/vector/beach_features.gpkg", layer="coastlines")
hwl_sentinel <- hwl[which(hwl$image_source == 'sentinel'),]
hwl_planet <- hwl[which(hwl$image_source == 'planet'),]

# load beach polygons
beaches <- vect("data/vector/beach_features.gpkg", layer="beaches")
beach_sentinel <- beaches[which(beaches$image_source == 'sentinel'),]
beach_planet <- beaches[which(beaches$image_source == 'planet'),]

# crop images to beach polygons with crop()



# Functions ---------------------------------------------------------------
# functions now load in the load_data.R script



# Identify Plant Pixels ---------------------------------------------------

# ??? is NDVI really the best option for CA beach plants? ???

# Sentinel === red = B04  nir = B08 -> NIR @ 10m resolution
ndvi_sentinel <- ndvi(nir = sentinel$`s2-2018-07-11_4`, red = sentinel$`s2-2018-07-11_8`)
ndvi_planet <- ndvi(nir=planet$nir, red=planet$red)

