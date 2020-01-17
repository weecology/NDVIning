library(MODISTools)
library(portalr)
library(dplyr)
library(ggplot2)

products <- mt_products()
bands <- mt_bands(product = "MOD13Q1")
dates <- mt_dates(product = "MOD13Q1", lat = 32, lon = -109)

# trying to match up geographical subset and coordinates from 
# https://github.com/weecology/PortalData/tree/master/NDVI

# portal_ndvi_test <- mt_subset(product = "MOD13Q1", 
#                               lat = 31.937769, 
#                               lon = -109.08029, 
#                               band = "250m_16_days_NDVI", 
#                               start = "2000-02-18", 
#                               end = "2012-12-19", 
#                               km_lr = 8, 
#                               km_ab = 8, 
#                               site_name = "portal")

portal_ndvi_test <- readRDS("modis_downloaded_ndvi.RDS")

df <- portal_ndvi_test %>%
    mutate(ndvi = value * as.numeric(scale)) %>%
    group_by(calendar_date) %>%
    summarize(ndvi = mean(ndvi)) %>%
    mutate(date = as.Date(calendar_date)) %>%
    select(date, ndvi)

gimms_ndvi <- ndvi()

landsat_ndvi <- load_datafile(file.path("NDVI", "Landsat_monthly_NDVI.csv")) %>%
    mutate(date = as.Date(paste0(year, "-", month, "-01")), 
           ndvi = as.numeric(x)) %>%
    select(date, ndvi)

ggplot(gimms_ndvi, aes(x = date, y = ndvi)) + 
    geom_line() + 
    geom_line(data = df, color = "red") + 
    geom_line(data = landsat_ndvi, color = "blue") + 
    theme_bw()
