library(MODISTools)
library(portalr)
library(gimms)
library(sp)
library(rgdal)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)

source("R/modis_NDVI_functions.R")
source("R/gimms_NDVI_functions.R")

# trying to match up geographical subset and coordinates from 
# https://github.com/weecology/PortalData/tree/master/NDVI

#### GIMMS NDVI ----
gimms_ndvi_file <- "data/gimms_v0_ndvi.csv"
if (file.exists(gimms_ndvi_file))
{
    gimms_ndvi <- read.csv(gimms_ndvi_file) %>%
        mutate(date = lubridate::ymd(paste(year, month, day, "-")), 
               sensor = "GIMMSv0", 
               source = "GIMMS") %>%
        select(date, ndvi, sensor, source) %>%
        arrange(date)
} else {
    gimms_ndvi_data <- get_gimms_ndvi()
    write.csv(gimms_ndvi_data, "data/gimms_v0_ndvi.csv", 
              quote = FALSE, row.names = FALSE)
}


#### MODIS NDVI ----
modis_ndvi_file <- "data/modis_ndvi_processed.RDS"
if (file.exists(modis_ndvi_file))
{
    modis_ndvi_processed <- readRDS(modis_ndvi_file)
} else {
    retrieve_modis_raw_data()
    process_modis_raw_data()
}

#### portalr NDVI ----

gimms_ndvi_portalr <- ndvi() %>%
    mutate(sensor = "GIMMSv0", source = "portalr")

landsat_ndvi <- load_datafile(file.path("NDVI", 
                                        "Landsat_monthly_NDVI.csv")) %>%
    mutate(date = as.Date(paste0(year, "-", month, "-01")), 
           ndvi = as.numeric(x)) %>%
    select(date, ndvi) %>%
    mutate(sensor = "Landsat", source = "portalr")

#### Google Earth Engine NDVI ----

read_in_GEE_landsat_NDVI <- function(file = "data/Landsat5_SR_NDVI_Portal_1984_2011.csv", 
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

landsat_5 <- read_in_GEE_landsat_NDVI("data/Landsat5_SR_NDVI_Portal_1984_2011.csv")
landsat_7 <- read_in_GEE_landsat_NDVI("data/Landsat7_SR_NDVI_Portal_1999_2020.csv")
landsat_8 <- read_in_GEE_landsat_NDVI("data/Landsat8_SR_NDVI_Portal_2013_2020.csv")

#### combine datasets and plot ----
ndvi_dat <- bind_rows(modis_ndvi_processed, 
                      gimms_ndvi, 
                      gimms_ndvi_portalr, 
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

pdf("figures/ndvi_comparison_figure.pdf", width = width, height = height)
print(p)
dev.off()

png("figures/ndvi_comparison_figure.png", width = width * 100, height = height * 100)
print(p)
dev.off()
