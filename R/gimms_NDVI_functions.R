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
download_gimms_files <- function(data_folder = "~/data/GIMMS-raw", version = 0)
{
    if (!file.exists(data_folder))
    {
        dir.create(data_folder)
    }
    
    download_paths <- updateInventory(version = version)
    filenames <- basename(download_paths)
    
    existing_gimms_files <- list.files(data_folder, pattern = "^geo[0-9]{2}|^ndvi3g_geo_v1_[0-9]{4}")
    to_download <- download_paths[!download_files %in% existing_gimms_files]
    
    if (length(to_download) > 0)
    {
        message("Downloading GIMMS data to ", data_folder, ":\n")
        message("  ", length(to_download), " files in total.")
        pb <- progress::progress_bar$new(format = "  [:bar] :percent eta: :eta",
                               total = length(to_download), clear = FALSE, width= 60, 
                               show_after = 0)
        pb$tick(0)
        for (curr_download in to_download)
        {
            pb$tick()
            # Sys.sleep(0.05)
            curl::curl_download(url = curr_download, 
                                destfile = file.path(data_folder, basename(curr_download)))
        }
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
process_gimms_files <- function(data_folder = "~/data/GIMMS-raw", 
                                out_folder = "~/data/GIMMS-proc")
{
    if (!file.exists(out_folder))
    {
        dir.create(out_folder)
    }
    raster_files <- list.files(data_folder, pattern = "^geo[0-9]{2}.+VI3g$")
    completed_out_files <- list.files(out_folder, pattern = "^geo[0-9]{2}.+VI3g.RDS$")
    target_out_files <- paste0(raster_files, ".RDS")

    to_proc <- sub("(^geo[0-9]{2}.+VI3g).RDS", "\\1", 
                    setdiff(target_out_files, completed_out_files))
    
    site <- data.frame(long = -109.08029, 
                       lat = 31.937769)
    sp::coordinates(site) <- c("long", "lat")
    
    for (file in to_proc)
    {
        extract_gimms_data(file.path(data_folder, file), site) %>%
            saveRDS(file = file.path(out_folder, paste0(file, ".RDS")))
    }
    
    return()
}

# Read in all the .RDS files and assemble a single data frame
assemble_gimms_data <- function(out_folder = "~/data/GIMMS-proc")
{
    completed_out_files <- list.files(out_folder, pattern = "^geo[0-9]{2}.+VI3g.RDS$", 
                                      full.names = TRUE)
    do.call(rbind, 
            lapply(completed_out_files, readRDS))
}

#################################################
#Get the GIMMS AVHRR ndvi bi-monthly time series
#Pulling from the sqlite DB or extracting it from raw gimms data if needed.
#################################################
get_gimms_ndvi <- function(data_folder = "~/data/GIMMS-raw", 
                           proc_folder = "~/data/GIMMS-proc")
{
    dir.create(data_folder, showWarnings = FALSE, recursive = TRUE)
    
    download_gimms_files(data_folder = data_folder)
    process_gimms_ndvi(data_folder = data_folder, 
                       out_folder = proc_folder)
    assemble_gimms_data(out_folder = proc_folder)
}