# GOAL: find the dune crests through a transect analysis


# Set Up ------------------------------------------------------------------

setwd("C:/Users/mmtobias/Documents/GitHub/dune-remote-sensing")

source("r/load_data.R")

# load high water lines
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



# use my construct_transect() function to make transects based on the baseline
transects <- construct_transects(baseline=baseline, transect_spacing = 100, transect_length = 200)

# sample the DEM at each transect

# something odd happens with extractAlong()
# transect_elevations <- extractAlong(x = dem, y = transects)

# add vertexes along the transects to use as sample points
densify_transects <- densify(x = transects, interval = 1, equalize = FALSE, flat = FALSE)
# add a transect id number so we know which transect each point belongs to
densify_transects$transect_id <- 1:dim(transects)[1]
# turn the lines into points
transects_points <- as.points(densify_transects)
# add a point id to each point
point_ids<-c()
for(i in unique(transects_points$transect_id)){
  print(i)
  point_ids<-c(point_ids, length(transects_points[which(transects_points$transect_id==i)]):1)
} # end for loop for assigning point ids
transects_points$point_ids<-point_ids


transect_elevations <- extract(
  x = dem,
  y = transects_points
)

slopes <- terrain(dem, v="slope")
transect_slopes <- extract(
  x = slopes,
  y = transects_points
)

# topographic position index
#     Reference: https://blogs.ubc.ca/tdeenik/2021/02/16/topographic-position-index-tpi/
#     GDAL/terra uses a 3x3 window and you can't change it - small windows are good for identifying small features
#     Reference: https://landscapearchaeology.org/2019/tpi/ 
#     TPI is equivalent to a local relief model (LRM)
tpi <- terrain(dem, v="TPI")

# join the points to the elevation data (why wouldn't it keep the previous attributes?)
transects_points$elevations <- transect_elevations$Layer_1
transects_points$slopes <- transect_slopes$slope

# calculate the elevation change between points heading inland on the transects


#plotting to check results
pal <- colorRampPalette(c("lightblue", "purple4"))
diverging_pal <-colorRampPalette(c("lightblue", "white", "black"))
plotRGB(
  x = sentinel, 
  r=4, g=3, b=2, 
  stretch="lin", 
  main="Sentinel 2", 
  loc.main="topright",
  col.main="white"
)
plot(transects_points, "elevations", cex=.5, col=pal(25), add=TRUE)
plot(transects_points, "slopes", cex=.5, col=pal(25))

plot(tpi, col=diverging_pal(25))

# calculate the distance to the water line
dist_hwl <- distance(x=dem, y=hwl_sentinel)

# calculate the change in slope and find the points of inflection


terra::contour(tpi)

# Clusters with TPI and elevation
# https://stackoverflow.com/questions/76323195/clustering-a-spatial-raster-stack
rasters <- c(dem, tpi)
d <- as.data.frame(rasters, cell=T)
d$TPI[which(is.na(d$TPI))]<- -999
k.clust <- kmeans(d[,-1], centers = 20) #removing the first column which is the cell number
krast <- rast(dem, nlyr=1)
krast[d$cell] <- k.clust$cluster
plot(krast)

# try selecting cells with certain values
d$combo[which(d$Layer_1<10&d$TPI<.1)]<-1
krast[d$cell] <- d$combo
plot(krast)
#probably buffering out the upland area would help reduce the confusion.
