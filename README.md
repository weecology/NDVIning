# NDVIning

(The name of the repo is an attempted portmanteau of "NDVI" and "divining".)

The goal of this project is to compare and understand the differences between different sources and methods for producing an NDVI (normalized difference vegetation index) time series at Portal, Arizona. The immediate goals of this analysis are to include a reference source of NDVI as part of the [`portalr`](https://github.com/weecology/portalr) project, and to support downstream projects, including [`portalcasting`](https://github.com/weecology/portalcasting).

## Data sources (historical)

The current data sources include:
* GIMMS (an ensemble product from various AVHRR instruments on NOAA satellites)
* MODIS (one instrument aboard the Terra & Aqua satellites)
* Landsat (a series of satellites)

## Data sources (ongoing)

USGS-EROS maintains an API cakked ESPA for getting satellite imagery: https://github.com/USGS-EROS/espa-api
* The account that Hao set up for weecology does successfully authenticate, which means it should be possible to automate regular updating. Unfortunately, the workflow seems to be to put in data order requests, and then at some point you get a link for downloading... (via the registered email, I'm guessing). It might be worthwhile to contact someone there about engineering a solution that *doesn't* involve the email loop.

MODISTools provides an up-to-date API for accessing MODIS data (though the server is currently down at the time of writing this -- 2020-04-01, 2:11pm EST). More importantly, MODIS has exceeded its design lifespan of 6 years (launched in 1999), so we may want to also consider the replacement data products.

The successor to MODIS is VIIRS (I think), and may be accessible through MODISTools. (I can't check at the moment, since the data server API is down, per above). According to https://ladsweb.modaps.eosdis.nasa.gov/missions-and-measurements/products/VNP13A1, there is a 500m 16-day vegetation index dataset that runs from January 2012 to present (ArchiveSet 5000).


