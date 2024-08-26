# GOAL: 
#       1. identify plants in Sentinel and Planet imagery
#       2. measure how far they are from the high water line



# Set Up ------------------------------------------------------------------

setwd("C:/Users/mmtobias/Documents/GitHub/dune-remote-sensing")

source("r/load_data.R")

#load high water lines
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

