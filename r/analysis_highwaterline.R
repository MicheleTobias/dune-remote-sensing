# GOAL: Identify High Water Line (HWL) in the imagery for Coal Oil Point Reserve (COPR)



# Set Up ------------------------------------------------------------------
setwd("C:/Users/mmtobias/Documents/GitHub/dune-remote-sensing")

# check to see if the dem variable (the last variable in the script) is available. If it's not, run the script that loads the data to get the imagery and DEM clipped to the study site. Note that clipping the DEM takes a while.
if(exists("dem")){
  print("Load Data script is already loaded.")
} else{
  print("Loading the Load Data script. This may take a few minutes.")
  source("r/load_data.R")
}


# Functions -------------------------------------------------------------------------

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

break_reclass <- -0.04

ndwi_reclass_matrix <- matrix(
  # c(-2, 0, 0, # R[-1, 0) = land (no water)
  # 0, 2, 1),  # R[0, 1] = water
  c(-2, break_reclass, 0, # R[-1, 0) = land (no water)
    break_reclass, 2, 1),  # R[0, 1] = water
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
par(mfrow=c(1,2))

plotRGB(
  x = sentinel, 
  r=4, g=3, b=2, 
  stretch="lin", 
  main="Sentinel 2", 
  loc.main="topright",
  col.main="white"
  )
plot(coast_sentinel, col = "hot pink", lwd = 3, add=TRUE)

plotRGB(
  x = planet, 
  r=3, g=2, b=1, 
  stretch="lin", 
  main="Planet",
  loc.main="topright",
  col.main="white"  
  )
plot(coast_planet, col = "hot pink", lwd = 3, add=TRUE)

par(mfrow=c(1,1))



# Extract Single Elevation Coastline --------------------------------------

# sample the raster along the line
dem_extract_sentinel <- extract(
  x = dem,
  y = coast_sentinel
)

dem_extract_planet <- extract(
  x = dem,
  y = coast_planet
)

# the maximum elevation of the coastline identified with the NDWI analysis
elev_sentinel <- max(dem_extract_sentinel$Layer_1)
elev_planet <- max(dem_extract_planet$Layer_1)

# reclassification matrix that breaks the DEM at the elevation of the coastline
elev_sentinel_reclass_matrix <- matrix(
  # c(-2, 0, 0, # R[-1, 0) = land (no water)
  # 0, 2, 1),  # R[0, 1] = water
  c(-10, elev_sentinel, 0, # R[-1, 0) = land (no water)
    elev_sentinel, 10000, 1),  # R[0, 1] = water
  ncol = 3,
  byrow = TRUE
)

elev_planet_reclass_matrix <- matrix(
  # c(-2, 0, 0, # R[-1, 0) = land (no water)
  # 0, 2, 1),  # R[0, 1] = water
  c(-10, elev_planet, 0, # R[-1, 0) = land (no water)
    elev_planet, 10000, 1),  # R[0, 1] = water
  ncol = 3,
  byrow = TRUE
)

# reclassify the DEM using the reclassification matrix
reclass_elev_sentinel <- classify(
  dem, 
  elev_sentinel_reclass_matrix,
  include.lowest = FALSE)

reclass_elev_planet <- classify(
  dem, 
  elev_planet_reclass_matrix,
  include.lowest = FALSE)

# turn the classified DEM into contour lines
contours_elev_sentinel <- as.contour(reclass_elev_sentinel, levels = c(0,1))

contours_elev_planet <- as.contour(reclass_elev_planet, levels = c(0,1))

# disaggregate the result (break up the geometries into lines instead of one polyline)
lines_elev_sentinel<-disagg(contours_elev_sentinel)

lines_elev_planet<-disagg(contours_elev_planet)

# find and keep the longest line because it's most likely to be the coastline
coastline_elev_sentinel <-lines_elev_sentinel[which(perim(lines_elev_sentinel) == max(perim(lines_elev_sentinel)))]

coastline_elev_planet <-lines_elev_planet[which(perim(lines_elev_planet) == max(perim(lines_elev_planet)))]


par(mfrow=c(1,2))
plotRGB(
  x = sentinel, 
  r=4, g=3, b=2, 
  stretch="lin", 
  main="Sentinel 2", 
  loc.main="topright",
  col.main="white"
  )
plot(coastline_elev_sentinel, add = TRUE, col = "darkorchid", lwd = 2)
plot(coast_sentinel, add = TRUE, col = "blue", lwd = 2)

plotRGB(
  x = planet, 
  r=3, g=2, b=1, 
  stretch="lin", 
  main="Planet",
  loc.main="topright",
  col.main="white"  
)
plot(coastline_elev_planet, add = TRUE, col = "darkorchid", lwd = 2)
plot(coast_planet, add = TRUE, col = "blue", lwd = 2)

par(mfrow=c(1,1))

# save the coastlines

coastlines <- rbind(coastline_elev_sentinel, coastline_elev_planet)
coastlines$image_source <- c("sentinel", "planet")

writeVector(
  x = coastlines,
  filename = "data/vector/beach_features.gpkg",
  layer = "coastlines"
)


