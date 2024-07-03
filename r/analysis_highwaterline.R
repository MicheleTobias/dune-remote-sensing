# GOAL: Identify High Water Line (HWL) in the imagery for Coal Oil Point Reserve (COPR)



# Set Up ------------------------------------------------------------------

setwd("C:/Users/mmtobias/Documents/GitHub/dune-remote-sensing")

# Libraries
library(terra)
library(sf)


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


# Analysis: HWL ----------------------------------------------------------------
#     Sentinel Bands: https://custom-scripts.sentinel-hub.com/custom-scripts/sentinel-2/bands/
#     Sentinel 2 L2A data are "Bottom of the Atmosphere (BOA)" reflectance data: https://docs.sentinel-hub.com/api/latest/data/sentinel-2-l2a/ 
# reflectance values might be stored without the decimal point to save space - i.e. a value of 2000 might actually be a reflectance of 0.2000 because reflectance should probably R[0,1]


# what is the cutoff for band 8 to separate water from land?
# is NDWI helpful?






# Analysis: NDWI --------------------------------------------------------------------

# R[-1, 0] = land (no water)
# R[0, 1] = water
 
# NDWI
ndwi_sentinel <- ndwi(green = sentinel$`s2-2018-07-11_3`, nir = sentinel$`s2-2018-07-11_8`)
ndwi_planet <- ndwi(green = planet$green, nir = planet$nir)

# classify the NDWI into water vs. land pixels: https://rdrr.io/cran/terra/man/classify.html

ndwi_reclass_matrix <- matrix(
  c(-2, 0, 0, # R[-1, 0) = land (no water)
  0, 2, 1),  # R[0, 1] = water
  ncol = 3,
  byrow = TRUE
)

reclass_sentinel <- classify(
  ndwi_sentinel, 
  ndwi_reclass_matrix,
  include.lowest = FALSE)

reclass_planet <- classify(
  ndwi_planet, 
  ndwi_reclass_matrix,
  include.lowest = FALSE
)

# make the line with a contour tool? https://rdrr.io/cran/terra/man/contour.html

contours_sentinel <- as.contour(reclass_sentinel, levels = c(0,1))
contours_planet <- as.contour(reclass_planet, levels = c(0,1))

lines_sentinel<-disagg(contours_sentinel)
lines_planet<-disagg(contours_planet)

coast_sentinel <-lines_sentinel[which(perim(lines_sentinel) == max(perim(lines_sentinel)))]
coast_planet <-lines_planet[which(perim(lines_planet) == max(perim(lines_planet)))]


#look at the results in all their glory
par(mfrow=c(2,1))

plotRGB(
  x = sentinel, 
  r=4, g=3, b=2, 
  stretch="lin", 
  main="Sentinel 2", 
  loc.main="topleft",
  col.main="white"
  )
plot(coast_sentinel, col = "hot pink", lwd = 3, add=TRUE)

plotRGB(
  x = planet, 
  r=3, g=2, b=1, 
  stretch="lin", 
  main="Planet",
  loc.main="topleft",
  col.main="white"  
  )
plot(coast_planet, col = "hot pink", lwd = 3, add=TRUE)
