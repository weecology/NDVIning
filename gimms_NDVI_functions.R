# Functions for retrieving and processing GIMMS NDVI data for Portal.
# Authors: Morgan Ernest, Shawn Taylor, Hao Ye
# This uses GIMMS version 0, which spans 1981-2013.
# This code is modified from `get_gimms_NDVI.R` in 
#   https://github.com/weecology/PortalData/tree/master/DataCleaningScripts
#   which is itself modified from `get_ndvi_data.R` in 
#   https://github.com/weecology/bbs-forecasting/R/

#################################################
#This assumes we want all gimms files that are available. It queries for files
#that are available for download and compares against files already in the gimms
#data directory.
##################################################
download_gimms_files <- function(gimms_folder = "~/data/GIMMS", version = 0)
{
    download_path <- gimms::updateInventory(version = version)
    available_files_name <- basename(download_path)
    
    existing_gimms_files <- list.files(gimms_folder, pattern = "^geo[0-9]{2}")
    to_download <- download_path[!available_files_name %in% existing_gimms_files]
    
    if (length(to_download) > 0)
    {
        print('Downloading GIMMS data')
        downloadGimms(x = to_download, dsn = gimms_folder)
    }
    
    return()
}

################################################
#Extract values from a single gimms file given a set of coordinates.
#Excludes values which don't meet NDVI quality flags.
#From the GIMMS readme:
#FLAG = 7 (missing data)
#FLAG = 6 (NDVI retrieved from average seasonal profile, possibly snow)
#FLAG = 5 (NDVI retrieved from average seasonal profile)
#FLAG = 4 (NDVI retrieved from spline interpolation, possibly snow)
#FLAG = 3 (NDVI retrieved from spline interpolation)
#FLAG = 2 (Good value)
#FLAG = 1 (Good value)
################################################
extract_gimms_data <- function(gimms_file_path, site)
{
    gimmsRaster <- rasterizeGimms(gimms_file_path, keep = c(1, 2, 3))
    ndvi <- raster::extract(gimmsRaster, site, buffer = 4000)
    ndvi <- as.numeric(lapply(ndvi, mean, na.rm = TRUE))
    
    year <- as.numeric(substr(basename(gimms_file_path), 4,5))
    month <- substr(basename(gimms_file_path), 6,8)
    day <- substr(basename(gimms_file_path), 11,11)
    
    #Convert the a b to the 1st and 15th
    day <- ifelse(day == 'a', 1, 15)
    
    #Convert 2 digit year to 4 digit year
    year <- ifelse(year > 50, year + 1900, year + 2000)
    
    return(data.frame(year = year, 
                      month = month, 
                      day = day, 
                      ndvi = ndvi, 
                      stringsAsFactors = FALSE))
}

################################################
# Extract out the NDVI values from the raw gimms files, and save them as .RDS
#   This function checks against the raw raster files and the already produced 
#   processed outputs, so it can be run in batches. (There seem to be some 
#   memory issues with the way the GIMMS rasters are loaded, where the 
#   allocated memory is not freed, and eventually R needs to be restarted.)
################################################
process_gimms_files <- function(gimms_folder = "~/data/GIMMS")
{
    raster_files <- list.files(gimms_folder, pattern = "^geo[0-9]{2}.+VI3g$")
    completed_out_files <- list.files(gimms_folder, pattern = "^geo[0-9]{2}.+VI3g.RDS$")
    target_out_files <- paste0(raster_files, ".RDS")

    to_proc <- sub("(^geo[0-9]{2}.+VI3g).RDS", "\\1", 
                    setdiff(target_out_files, completed_out_files))
    
    site <- data.frame(long = -109.08029, 
                       lat = 31.937769)
    sp::coordinates(site) <- c("long", "lat")
    
    for (file in to_proc)
    {
        extract_gimms_data(file.path(gimms_folder, file), site) %>%
            saveRDS(file = file.path(gimms_folder, paste0(file, ".RDS")))
    }
    
    return()
}

# Read in all the .RDS files and assemble a single data frame
assemble_gimms_data <- function(gimms_folder = "~/data/GIMMS")
{
    completed_out_files <- list.files(gimms_folder, pattern = "^geo[0-9]{2}.+VI3g.RDS$", 
                                      full.names = TRUE)
    do.call(rbind, 
            lapply(completed_out_files, readRDS))
}

#################################################
#Get the GIMMS AVHRR ndvi bi-monthly time series
#Pulling from the sqlite DB or extracting it from raw gimms data if needed.
#################################################
get_gimms_ndvi <- function(gimms_folder = "~/data/GIMMS")
{
    dir.create(gimms_folder, showWarnings = FALSE, recursive = TRUE)
    
    download_gimms_files(gimms_folder = gimms_folder)
    process_gimms_ndvi(gimms_folder = gimms_folder)
    assemble_gimms_data(gimms_folder = gimms_folder)
}