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

# make points along a line to use as the starting point for transects:
# terra::densify(line,interval =min(res(r))/2, flat=TRUE)



# FUNCTION construct_transects()
#     baseline = a line (a terra spatVector) composed of two vertexes (start and end) representing the line for constructing transects perpendicular to
#     transect_spacing = the distance between transects (meters for latlon, crs units for other projections)
#     transect_length = how long should the transects be?

construct_transects <- function(baseline, transect_spacing, transect_length){
  # create an ordered (by x value) dataframe of coordinates for the baseline
  coords_baseline <- data.frame(geom(baseline)[,3:4])
  coords_baseline <- coords_baseline[order(coords_baseline$x),]
  
  # create an ordered (by x value) dataframe of coordinates for the baseline
  coords_baseline <- data.frame(geom(baseline)[,3:4])
  coords_baseline <- coords_baseline[order(coords_baseline$x),]
  
  # slope of the line: slope =(y₂ - y₁)/(x₂ - x₁)
  slope_baseline <- (coords_baseline[2, 2] - coords_baseline[1, 2]) / (coords_baseline[2,1] - coords_baseline[1,1])
  
  # slope to angle: 90 - 180 * atan( slope ) / pi
  
  angle_baseline <- 90-(180*atan(slope_baseline)/pi)
  #angle_baseline <- (180*atan(slope_baseline))/pi
  
  # add points to baseline at the interval needed for the transects
  densify_baseline <- densify(x = baseline, interval = transect_spacing, equalize = FALSE, flat = FALSE)
  transect_points <- geom(densify_baseline)[, 3:4]
  
  # !!! the angle for cos/sin/tan needs to be in RADIANS!!! 1rad × 180/π = 57.296°
  offset_y <- transect_length * cos(pi*(90 + angle_baseline)/180)
  offset_x <- transect_length * sin(pi*(90 + angle_baseline)/180)
  
  # an empty spatvector to store WKT for transects as they get constructed
  transects <- vect()
  
  for(i in 1:dim(transect_points)[1]){
    start_point <- transect_points[i,]
    end_point <- start_point + data.frame(matrix(c(offset_x, offset_y), byrow = TRUE, ncol=2))
    start_point <- start_point - data.frame(matrix(c(offset_x, offset_y), byrow = TRUE, ncol=2))
    
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
    
    add_transect <- vect(transect_wkt, crs="EPSG:32611")
    #baseline <- terra::union(baseline, add_transect)
    transects <- terra::union(transects, add_transect)
    
  } # end for loop for baseline points
  
  # remove the baseline line from the vector
  #transects <- baseline[-1, ]
  
  # reset the id because we removed the first item
  #transects$ID <- transects$ID - 1
  
  return(transects)
  
} #end of function




transects <- construct_transects(baseline=baseline, transect_spacing = 100, transect_length = 200)

# sample the DEM at each transect

# transect_elevations <- extractAlong(
#   x = dem,
#   y = transects
# )

# maybe we need points along the line to be able to identify where the inflection is geographically
transect_elevations <- extract(
  x = dem,
  y = transects
)

# calculate the change in slope and find the points of inflection



