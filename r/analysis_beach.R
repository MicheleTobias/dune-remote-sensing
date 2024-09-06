#GOAL: Identify the beach in the imagery

# Set Up ------------------------------------------------------------------
setwd("C:/Users/mmtobias/Documents/GitHub/dune-remote-sensing")

# check to see if the dem variable (the last variable in the script) is avaialble. If it's not, run the script that loads the data to get the imagery and DEM clipped to the study site. Note that clipping the DEM takes a while.
if(exists("dem")){
  print("Load Data script is already loaded.")
} else{
  print("Loading the Load Data script. This may take a few minutes.")
  source("r/load_data.R")
}

#  Identify Beach Area ----------------------------------------------------

# calculate NDWI
ndwi_sentinel <- ndwi(green = sentinel$`s2-2018-07-11_3`, nir = sentinel$`s2-2018-07-11_8`)
ndwi_planet <- ndwi(green = planet$green, nir = planet$nir)

# set the thresholds for water and sand for NDWI
water_cutoff <- -0.04
sand_cutoff <- -0.23

# write the reclassification matrix
ndwi_reclass_matrix <- matrix(
  c(-2, sand_cutoff, 0, # R[-2, water_cutoff) = water
  sand_cutoff, water_cutoff,  1, # R[water, sand] = sand
  water_cutoff, 2, 3),  # R[sand , 2] = upland
ncol = 3,
byrow = TRUE
)

# reclassify the imagery
reclass_sentinel <- classify(
  ndwi_sentinel, 
  ndwi_reclass_matrix,
  include.lowest = FALSE)

reclass_planet <- classify(
  ndwi_planet, 
  ndwi_reclass_matrix,
  include.lowest = FALSE)


# just keep the pixels with a value of 1 (sand)
reclass_sentinel[which(reclass_sentinel[,,1]!=1)] <- NA
reclass_planet[which(reclass_planet[,,1]!=1)] <- NA

# make polygons of the sand area
sand_sentinel <- disagg(fillHoles(as.polygons(reclass_sentinel)))
sand_planet <- disagg(fillHoles(as.polygons(reclass_planet)))

# just keep the polygon with the largest area (get rid of the small polygons that aren't meaningful)
beach_sentinel <- sand_sentinel[which(expanse(sand_sentinel) == max(expanse(sand_sentinel)))]
beach_planet <- sand_planet[which(expanse(sand_planet) == max(expanse(sand_planet)))]



# Write the Data ----------------------------------------------------------

# put both beach polygons into the same dataframe
beaches <- rbind(beach_sentinel, beach_planet)
beaches$image_source <- c("sentinel", "planet")
beaches <- beaches[, 3] #keep the one column that we need (image_source)

# write the beach data to a geopackage
# Note: if you need to remove a layer from a geopackage, use vector_layers()
writeVector(
  x = beaches,
  filename = "data/vector/beach_features.gpkg",
  layer = "beaches",
  insert = TRUE
)

