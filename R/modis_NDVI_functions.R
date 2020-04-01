retrieve_modis_raw_data <- function(product = "MOD13Q1", 
                                    lat = 31.938, lon = -109.080, 
                                    buffer_size = 1)
{
    products <- mt_products()
    bands <- mt_bands(product = product)
    dates <- mt_dates(product = product, lat = lat, lon = lon)
    
    modis_ndvi <- mt_subset(product = product,
                            lat = lat,
                            lon = lon,
                            band = "250m_16_days_NDVI",
                            start = "2000-02-18",
                            end = "2018-12-19",
                            km_lr = buffer_size,
                            km_ab = buffer_size,
                            site_name = "portal")
    
    modis_vi_quality <- mt_subset(product = product,
                                  lat = lat,
                                  lon = lon,
                                  band = "250m_16_days_VI_Quality",
                                  start = "2000-02-18",
                                  end = "2018-12-19",
                                  km_lr = buffer_size,
                                  km_ab = buffer_size,
                                  site_name = "portal")
    
    saveRDS(modis_ndvi, file = "data/modis_ndvi_raw.RDS")
    saveRDS(modis_vi_quality, file = "data/modis_vi_quality.RDS")
}

# this map is taken from Table 5, describing the bit code for the VI Quality 
# scientific data set, for MOD13A1 / MOD13A1 in the 
# "MODIS Vegetation Index User's Guide", retrieved from 
# https://vip.arizona.edu/documents/MODIS/MODIS_VI_UsersGuide_June_2015_C6.pdf
map_vi_quality <- function(pixel_value)
{
    vi_quality_map <- c("VI produced with good quality", 
                        "VI produced, but check other QA", 
                        "Pixel produced, but most probably cloudy", 
                        "Pixel not produced due to other reasons than clouds")
    
    vi_usefulness_map <- c("Highest quality", 
                           "Lower quality", 
                           "Decreasing quality 2", 
                           "Decreasing quality 3", 
                           "Decreasing quality 4", 
                           "Decreasing quality 5", 
                           "Decreasing quality 6", 
                           "Decreasing quality 7", 
                           "Decreasing quality 8", 
                           "Decreasing quality 9", 
                           "Decreasing quality 10", 
                           "Decreasing quality 11", 
                           "Lowest quality", 
                           "Quality so low that it is not useful", 
                           "L1B data faulty", 
                           "Not useful for any other reason / not processed")
    
    aerosol_quantity_map <- c("Climatology", 
                              "Low", 
                              "Intermediate", 
                              "High")
    
    adjacent_cloud_detected_map <- c("No", 
                                     "Yes")
    
    atmosphere_BRDF_correction_map <- c("No", 
                                        "Yes")
    
    mixed_clouds_map <- c("No", 
                          "Yes")
    
    land_water_mask_map <- c("Shallow ocean", 
                             "Land (Nothing else but land)", 
                             "Ocean coastlines and lake shorelines", 
                             "Shallow inland water", 
                             "Ephemeral water", 
                             "Deep inland water", 
                             "Moderate or continental ocean", 
                             "Deep ocean")
    
    possible_snow_ice_map <- c("No", 
                               "Yes")
    
    possible_shadow_map <- c("No", 
                             "Yes")
    pixel_bits <- matrix(as.numeric(intToBits(pixel_value)), ncol = 32, byrow = TRUE)
    out <- data.frame(
        vi_quality = vi_quality_map[1 + pixel_bits[, 1] + 
                                        pixel_bits[, 2] * 2], 
        vi_usefulness = vi_usefulness_map[1 + pixel_bits[, 3] + 
                                              pixel_bits[, 4] * 2 + 
                                              pixel_bits[, 5] * 4 + 
                                              pixel_bits[, 6] * 8], 
        aerosol_quantity = aerosol_quantity_map[1 + pixel_bits[, 7] + 
                                                    pixel_bits[, 8] * 2], 
        adjacent_cloud_detected = adjacent_cloud_detected_map[1 + pixel_bits[, 9]], 
        atmosphere_BRDF_correction = atmosphere_BRDF_correction_map[1 + pixel_bits[, 10]], 
        mixed_clouds = mixed_clouds_map[1 + pixel_bits[, 11]], 
        land_water_mask = land_water_mask_map[1 + pixel_bits[, 12] + 
                                                  pixel_bits[, 13] * 2 + 
                                                  pixel_bits[, 14] * 4], 
        possible_snow_ice = possible_snow_ice_map[1 + pixel_bits[, 15]], 
        possible_shadow = possible_shadow_map[1 + pixel_bits[, 16]]
    )
    
    return(out)
}

process_modis_raw_data <- function()
{
    modis_ndvi_raw <- readRDS("data/modis_ndvi_raw.RDS")
    modis_vi_quality <- readRDS("data/modis_vi_quality.RDS")
    cols <- c("xllcorner", "yllcorner", "cellsize", "latitude", "longitude",
              "start", "end", "modis_date", "calendar_date", "tile")
    modis_vi_quality <- dplyr::bind_cols(dplyr::select(modis_vi_quality, dplyr::all_of(cols)),
                                         map_vi_quality(modis_vi_quality$value))
    
    if (NROW(modis_ndvi_raw) == NROW(modis_vi_quality) &&
        all.equal(modis_ndvi_raw[, cols], modis_vi_quality[, cols], check.attributes = FALSE))
    {
        modis_ndvi_raw <- dplyr::bind_cols(modis_ndvi_raw,
                                           dplyr::select(modis_vi_quality, -cols))
        
        modis_ndvi_processed <- modis_ndvi_raw %>%
            dplyr::filter(vi_usefulness == "Highest quality",
                          aerosol_quantity == "Low",
                          adjacent_cloud_detected == "No",
                          mixed_clouds == "No") %>%
            dplyr::mutate(ndvi = value * as.numeric(scale)) %>%
            dplyr::group_by(calendar_date) %>%
            dplyr::summarize(ndvi = mean(ndvi)) %>%
            dplyr::mutate(date = as.Date(calendar_date)) %>%
            dplyr::select(date, ndvi) %>%
            dplyr::mutate(sensor = "MODIS", source = "MODISTools")
        
        saveRDS(modis_ndvi_processed, file = "data/modis_ndvi_processed.RDS")
    }
}
