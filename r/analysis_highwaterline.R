# GOAL: Identify High Water Line (HWL) in the imagery for Coal Oil Point Reserve (COPR)



# Set Up ------------------------------------------------------------------

setwd("C:/Users/mmtobias/Documents/GitHub/dune-remote-sensing")

# Libraries
library(terra)


# Load Data
#     Note: both sentinel and planet data are in EPSG 32611 = WGS84/UTM Zone 11 N
sentinel <- rast("data/imagery/s2-2018-07-11.tif")

#plotRGB(x = sentinel, r=4, g=3, b=2, stretch="lin")

planet <- rast("data/imagery/COPR_2018-07-13_psscene_analytic_sr_udm2/PSScene/20180713_181431_0f3b_3B_AnalyticMS_SR_clip.tif") 

#plotRGB(x = planet, r=3, g=2, b=1, stretch="lin")



# Functions -------------------------------------------------------------------------

# NDWI = (Green - NIR) / (Green + NIR)
ndwi <- function(green, nir){
  ndwi = (green - nir)/(green + nir)
  return(ndwi)
}


# Analysis ----------------------------------------------------------------
#     Sentinel Bands: https://custom-scripts.sentinel-hub.com/custom-scripts/sentinel-2/bands/
ndwi_sentinel <- ndwi(green = sentinel$`s2-2018-07-11_3`, nir = sentinel$`s2-2018-07-11_8`)
ndwi_planet <- ndwi(green = planet$green, nir = planet$nir)


