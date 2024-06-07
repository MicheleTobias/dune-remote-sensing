# Download S2 data for 10 Mile Dunes
# https://documentation.dataspace.copernicus.eu/APIs/openEO/R_Client/R.html
library(openeo)
connection = connect(host = "https://openeo.dataspace.copernicus.eu")

s2 = describe_collection("SENTINEL2_L2A") # or use the collection entry from the list, e.g. collections$`COPERNICUS/S2`
print(s2)

# Opens a web browser to finish auth
# you need an account on https://dataspace.copernicus.eu
login()



spatial_extent = list(west = -123.81261588386191, 
                      south = 39.4826995752253, 
                      east = -123.74737371621065, 
                      north = 39.55675601496341)
id = "SENTINEL2_L2A"
bands = c("B01","B02","B03","B04","B05","B06","B07")
temporal_extent = c("2018-09-09", "2018-09-11")

p = processes()

datacube = p$load_collection(
  id = id,
  spatial_extent = spatial_extent,
  temporal_extent = temporal_extent,
  bands = bands,
  max_cloud_cover=30
)

f = list_file_formats()

# TODO: make a reduce function to get the 1st time slice
# since we know there is only 1 we'll just compute the cube and save it
res <- p$save_result(datacube, format = f$output$GTiff)
file  <- compute_result(res, output_file = "s2-2018-09-10.tif")
