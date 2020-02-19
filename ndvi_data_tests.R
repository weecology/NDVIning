library(MODISTools)
library(portalr)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)

# trying to match up geographical subset and coordinates from 
# https://github.com/weecology/PortalData/tree/master/NDVI

#### MODIS NDVI ----
# products <- mt_products()
# bands <- mt_bands(product = "MOD13Q1")
# dates <- mt_dates(product = "MOD13Q1", lat = 32, lon = -109)
# 
# modis_ndvi <- mt_subset(product = "MOD13Q1",
#                         lat = 31.937769,
#                         lon = -109.08029,
#                         band = "250m_16_days_NDVI",
#                         start = "2000-02-18",
#                         end = "2018-12-19",
#                         km_lr = 8,
#                         km_ab = 8,
#                         site_name = "portal")
# 
# modis_vi_quality <- mt_subset(product = "MOD13Q1",
#                               lat = 31.937769,
#                               lon = -109.08029,
#                               band = "250m_16_days_VI_Quality",
#                               start = "2000-02-18",
#                               end = "2018-12-19",
#                               km_lr = 8,
#                               km_ab = 8,
#                               site_name = "portal")
# 
# saveRDS(modis_ndvi, file = "data/modis_ndvi_raw.RDS")
# saveRDS(modis_vi_quality, file = "data/modis_vi_quality.RDS")

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

# modis_ndvi_raw <- readRDS("data/modis_ndvi_raw.RDS")
# modis_vi_quality <- readRDS("data/modis_vi_quality.RDS")
# cols <- c("xllcorner", "yllcorner", "cellsize", "latitude", "longitude", 
#           "start", "end", "modis_date", "calendar_date", "tile")
# modis_vi_quality <- bind_cols(select(modis_vi_quality, cols), 
#                               map_vi_quality(modis_vi_quality$value))
# 
# if (NROW(modis_ndvi_raw) == NROW(modis_vi_quality) && 
#     all.equal(modis_ndvi_raw[, cols], modis_vi_quality[, cols], check.attributes = FALSE))
# {
#     modis_ndvi_raw <- bind_cols(modis_ndvi_raw, 
#                                 select(modis_vi_quality, -cols))
#     
#     modis_ndvi_processed <- modis_ndvi_raw %>%
#         filter(vi_usefulness == "Highest quality", 
#                aerosol_quantity == "Low", 
#                adjacent_cloud_detected == "No", 
#                mixed_clouds == "No") %>%
#         mutate(ndvi = value * as.numeric(scale)) %>%
#         group_by(calendar_date) %>%
#         summarize(ndvi = mean(ndvi)) %>%
#         mutate(date = as.Date(calendar_date)) %>%
#         select(date, ndvi) %>%
#         mutate(sensor = "MODIS", source = "MODISTools")
#     
#     saveRDS(modis_ndvi_processed, file = "data/modis_ndvi_processed.RDS")
# }

modis_ndvi_processed <- readRDS("data/modis_ndvi_processed.RDS")

#### portalr NDVI ----

gimms_ndvi <- ndvi() %>%
    mutate(sensor = "GIMMS", source = "portalr")

landsat_ndvi <- load_datafile(file.path("NDVI", 
                                        "Landsat_monthly_NDVI.csv")) %>%
    mutate(date = as.Date(paste0(year, "-", month, "-01")), 
           ndvi = as.numeric(x)) %>%
    select(date, ndvi) %>%
    mutate(sensor = "Landsat", source = "portalr")

#### Google Earth Engine NDVI ----

read_in_GEE_landsat_NDVI <- function(file = "Landsat5_SR_NDVI_Portal_1984_2011.csv", 
                                     sensor = str_extract(file, "Landsat[0-9]"))
{
    read.csv(file = file) %>%
        select(idx = "system.index", pixel_count = NDVI_count, ndvi = NDVI_mean) %>%
        extract(idx, c("year", "month", "day"), "[A-Z0-9]{4}_034038_([0-9]{4})([0-9]{2})([0-9]{2})") %>%
        mutate(date = as.Date(paste(year, month, day, sep = "-"))) %>% 
        select(date, pixel_count, ndvi) %>%
        filter(pixel_count > 350) %>%
        select(-pixel_count) %>%
        mutate(sensor = sensor, source = "Google Earth Engine")
}

landsat_5 <- read_in_GEE_landsat_NDVI("Landsat5_SR_NDVI_Portal_1984_2011.csv")
landsat_7 <- read_in_GEE_landsat_NDVI("Landsat7_SR_NDVI_Portal_1999_2020.csv")
landsat_8 <- read_in_GEE_landsat_NDVI("Landsat8_SR_NDVI_Portal_2013_2020.csv")

#### combine datasets and plot ----
ndvi_dat <- bind_rows(modis_ndvi_processed, 
                      gimms_ndvi, 
                      landsat_ndvi, 
                      landsat_5, 
                      landsat_7, 
                      landsat_8) %>%
    mutate(label = paste0(sensor, " (", source, ")"))

p <- ggplot(ndvi_dat, aes(x = date, y = ndvi, color = label)) + 
    geom_line() + 
    scale_color_viridis_d() + 
    theme_bw() + 
    guides(color = guide_legend(title = "source"))

width <- 8
height <- 5

pdf("ndvi_comparison_figure.pdf", width = width, height = height)
print(p)
dev.off()

png("ndvi_comparison_figure.png", width = width * 100, height = height * 100)
print(p)
dev.off()
