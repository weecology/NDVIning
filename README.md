# NDVIning

(The name of the repo is an attempted portmanteau of "NDVI" and "divining".)

The goal of this project is to compare and understand the differences between different sources and methods for producing an NDVI (normalized difference vegetation index) time series at Portal, Arizona. The immediate goals of this analysis are to include a reference source of NDVI as part of the [`portalr`](https://github.com/weecology/portalr) project, and to support downstream projects, including [`portalcasting`](https://github.com/weecology/portalcasting).

## Data sources

The current data sources include:
* GIMMS (an ensemble product from various AVHRR instruments on NOAA satellites)
* MODIS (one instrument aboard the Terra & Aqua satellites)
* Landsat (a series of satellites)