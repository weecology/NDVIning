library(MODISTools)
library(portalr)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)

#### MODIS NDVI ----
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

modis_ndvi <- portal_ndvi_test %>%
    mutate(ndvi = value * as.numeric(scale)) %>%
    group_by(calendar_date) %>%
    summarize(ndvi = mean(ndvi)) %>%
    mutate(date = as.Date(calendar_date)) %>%
    select(date, ndvi) %>%
    mutate(sensor = "MODIS", source = "MODISTools")

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

#### combine datasets and plot ----
ndvi_dat <- bind_rows(modis_ndvi, 
                      gimms_ndvi, 
                      landsat_ndvi, 
                      landsat_5, 
                      landsat_7) %>%
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
