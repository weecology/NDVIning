library(MODISTools)

source("R/get_modis_ndvi.R")


gimms_coordinates <- readRDS("data/gimms_coordinates_portal.RDS")
site <- data.frame(long = -109.08029, 
                   lat = 31.937769)

# find closest point



retrieve_modis_raw_data(lat = 31.95833, lon = -109.0417, buffer_size = 4)
