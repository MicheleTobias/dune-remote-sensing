#GOAL: Identify the beach in the imagery

# Set Up ------------------------------------------------------------------
setwd("C:/Users/mmtobias/Documents/GitHub/dune-remote-sensing")

source("r/load_data.R")

#  Identify Beach Area ----------------------------------------------------

# calculate NDWI
ndwi_sentinel <- ndwi(green = sentinel$`s2-2018-07-11_3`, nir = sentinel$`s2-2018-07-11_8`)
ndwi_planet <- ndwi(green = planet$green, nir = planet$nir)


water_cutoff <- -0.04
sand_cutoff <- -0.23


ndwi_reclass_matrix <- matrix(
  c(-2, sand_cutoff, 0, # R[-2, water_cutoff) = water
  sand_cutoff, water_cutoff,  1, # R[water, sand] = sand
  water_cutoff, 2, 3),  # R[sand , 2] = uploand
ncol = 3,
byrow = TRUE
)

reclass_sentinel <- classify(
  ndwi_sentinel, 
  ndwi_reclass_matrix,
  include.lowest = FALSE)

plot(reclass_sentinel)
