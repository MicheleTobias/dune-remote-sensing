# GOAL: find the dune crests through a transect analysis


# Set Up ------------------------------------------------------------------

setwd("C:/Users/mmtobias/Documents/GitHub/dune-remote-sensing")

# libraries
library(terra)
library(sf)
# library(devtools)
# devtools::install_github("paulhegedus/SampleBuilder")

# read data

#   AOI Polygon
aoi <- vect("data/vector/area_of_interest.gpkg")

#   dem
dem <- rast("data/elevation/USGS_one_meter_x23y382_CA_SoCal_Wildfires_B4_2018.tif")
dem <- project(dem, "EPSG:32611")

dem <- crop(
  x=dem, 
  y=aoi)

#   high water lines
hwl <- vect("data/vector/beach_features.gpkg", layer="coastlines")

hwl_sentinel <- hwl[which(hwl$image_source == 'sentinel'),]


# Analysis ----------------------------------------------------------------

# construct a baseline from the first and last vertexes of the HWL

latlong <- geom(hwl_sentinel)[c(1, dim(geom(hwl_sentinel))[1]), 3:4]

wkt_baseline <- paste0("LINESTRING(", latlong[1,1], " ", latlong[1,2], ", ", latlong[2,1], " ", latlong[2,2], ")")

baseline <- vect(wkt_baseline, crs="EPSG:32611")

# construct the transects: https://github.com/paulhegedus/SampleBuilder/ <- requires saving shapefiles... boo.
# Make your own: https://stackoverflow.com/questions/74844804/finding-a-set-of-equally-spaced-perpendicular-lines-along-boundaries-in-r 

# create an ordered (by x value) dataframe of coordinates for the baseline
coords_baseline <- data.frame(geom(baseline)[,3:4])
coords_baseline <- coords_baseline[order(coords_baseline$x),]

# slope of the line: slope =(y₂ - y₁)/(x₂ - x₁)
slope_baseline <- (coords_baseline[2, 2] - coords_baseline[1, 2]) / (coords_baseline[2,1] - coords_baseline[1,1])

# slope to angle: 90 - 180 * atan( slope ) / pi

angle_baseline <- 90-(180*atan(slope_baseline)/pi)
#angle_baseline <- (180*atan(slope_baseline))/pi

# !!! the angle for cos/sin/tan needs to be in RADIANS!!! 1rad × 180/π = 57.296°
offset_y <- 200 * cos(pi*(90 + angle_baseline)/180)
offset_x <- 200 * sin(pi*(90 + angle_baseline)/180)

start_point <- coords_baseline[1,]
end_point <- start_point + data.frame(matrix(c(offset_x, offset_y), byrow = TRUE, ncol=2))

transect_coords <- rbind(start_point, end_point)

transect_wkt <- paste0(
  "LINESTRING(", 
  transect_coords[1,1], 
  " ", 
  transect_coords[1,2], 
  ", ", 
  transect_coords[2,1], 
  " ", 
  transect_coords[2,2], ")")

transect <- vect(transect_wkt, crs="EPSG:32611")

# sample the DEM at each transect

# calculate the change in slope and find the points of inflection



