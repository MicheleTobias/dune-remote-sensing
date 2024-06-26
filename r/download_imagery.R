# GOAL: Download S2 data for sites

# NOTE: Planet Imagery was downloaded from their online Planet Explorer interface

# References:
# https://documentation.dataspace.copernicus.eu/APIs/openEO/R_Client/R.html


# Set Up ------------------------------------------------------------------

# Libraries
library(openeo)

# Connection
connection = connect(host = "https://openeo.dataspace.copernicus.eu")

s2 = describe_collection("SENTINEL2_L2A") # or use the collection entry from the list, e.g. collections$`COPERNICUS/S2`
print(s2)

# Opens a web browser to finish auth
# you need an account on https://dataspace.copernicus.eu
login()



# Bounding Boxes

#   10 Mile Dunes
# spatial_extent_10Mile = list(west = -123.81261588386191, 
#                       south = 39.4826995752253, 
#                       east = -123.74737371621065, 
#                       north = 39.55675601496341)

#   Coal Oil Point Reserve (COPR)
spatial_extent_COPR = list(west = -119.940191145, 
                             south = 34.3987227855, 
                             east = -119.82824344, 
                             north = 34.4863293689)


# Download Data -----------------------------------------------------------

id = "SENTINEL2_L2A"
bands = c("B01","B02","B03","B04","B05","B06","B07", "B08", "B8A", "B11", "B12")
#temporal_extent_10Mile = c("2018-09-09", "2018-09-11")
temporal_extent_COPR = c("2018-07-11", "2018-07-15") #matches the date of the Lidar flight from the USGS Wildfire flight

p = processes()

datacube = p$load_collection(
  id = id,
  spatial_extent = spatial_extent_COPR,
  temporal_extent = temporal_extent_COPR,
  bands = bands #,
  #max_cloud_cover=30
)

f = list_file_formats()

# TODO: make a reduce function to get the 1st time slice
# since we know there is only 1 we'll just compute the cube and save it
res <- p$save_result(datacube, format = f$output$GTiff)
file  <- compute_result(res, output_file = "./data/imagery/s2-2018-07-11.tif")
