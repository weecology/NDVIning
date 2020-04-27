# NDVIning

(The name of the repo is an attempted portmanteau of "NDVI" and "divining".)

The goal of this project is to compare and understand the differences between different sources and methods for producing an NDVI (normalized difference vegetation index) time series at Portal, Arizona. The immediate goals of this analysis are to include a reference source of historical NDVI (i.e. going back to 1981) as part of the [`portalr`](https://github.com/weecology/portalr) project, and to support downstream projects, including [`portalcasting`](https://github.com/weecology/portalcasting).

## NDVI calculations

NDVI is defined based on the reflectance in two spectral bands, Near Infrared (NIR) and Red:

NDVI = (NIR - Red) / (NIR + Red)

Since the individual reflectance values range between 0 and 1, NDVI ranges between -1 and 1, though usually positive over land.

# Data

## Remote Sensing

NIR and Red reflectances are generally obtained from remote sensing (often satellite-based). Generally, the datasets that are available come at 1 or more levels of processing:

* processed NDVI output (pre-calculated NDVI values)
* processed surface reflectance (band-specific reflectance at the Earth's surface)
* raw satellite images

## Data sources

The current data sources include:

* GIMMS (an ensemble product from various AVHRR instruments on NOAA satellites)
* MODIS (one instrument aboard the Terra & Aqua satellites)
* Landsat (a series of satellites)


| Satellite | Program | Start Date | End Date  | Spatial Resolution | Temporal Resolution |
|-----------|---------|------------|-----------|--------------------|---------------------|
| Terra     | MODIS   | 2000-02-18 | (ongoing) | 250m               | 16 days             |
| Aqua      | MODIS   | 2002-07-04 | (ongoing) | 250m               | 16 days             |
| Landsat 3*| Landsat | 1978-03-05 | 1983-03-31| 60m                | 18 days             |
| Landsat 4&dagger;| Landsat | 1982-07-16 | 1993| 60m               | 16 days             |
| Landsat 5 | Landsat | 1984-03-01 | 2013-06-05| 60m                | 16 days             |
| Landsat 6&Dagger; | Landsat | NA | NA        | NA                 | NA                  |
| Landsat 7 | Landsat | 1999-04-15 | (ongoing) | 30m                | 16 days             |
| Landsat 8 | Landsat | 2013-02-11 | (ongoing) | 30m                | 16 days             |
| NOAA-7, 9, 11, 14, 16, 18   | NOAA CDR | 1981 | ongoing (some) | 0.05 deg (~4 km)  | 1 day               |


\* Landsat 3 does not have the (Extended) Thematic Mapper of later satellites, and only has the Multispectral Scanner (MSS) that was on Landsats 1-5.  
Landsat 3 does not seem to have Surface Reflectance (SR) outputs of the later Landsats. (possibly related to its different instrumentation).

&dagger; Landsat 4 suffered an equipment malfunction early:  
https://landsat.gsfc.nasa.gov/landsat-4/
> Within a year of launch, Landsat 4 lost the use of two of its solar panels and both of its direct downlink transmitters. So, the downlink of data was not possible until the Tracking and Data Relay Satellite System (TDRSS) became operational: Landsat 4 could then transmit data to TDRSS using its Ku-band transmitter and TDRSS could then relay that information to its ground stations.
> In 1987, after the Landsat 5 primary TM X-band direct downlink path was switched off due to a traveling-wave tube amplifier  (TWTA) power trip anomaly, Landsat 4 again began to use its functional Ku-transmitter to downlink acquired international data via the TDRSS. This continued until 1993, when this last remaining science data downlink capability failed on Landsat 4.

&Dagger; Landsat 6 failed to reach orbit.

| Satellite | Red band ID | Red band range | NIR band ID | NIR band range |
|-----------|-------------|----------------|-------------|----------------|
| Landsat 3 | Band 5      | 600-700 nm     | Band 6      | 700-800 nm     |
| Landsat 4 | Band 3      | 630-690 nm     | Band 4      | 770-900 nm     |
| Landsat 5 | Band 3      | 630-690 nm     | Band 4      | 770-900 nm     |
| Landsat 7 | Band 3      | 630-690 nm     | Band 4      | 770-900 nm     |
| Landsat 8 | Band 3      | 636-673 nm     | Band 5      | 851-879 nm     |
| MODIS     | ??          | 620-670 nm     | ??          | 841-876 nm     |
| NOAA-#    | Band 1      | 580-680 nm     | Band 2      | 725-1110 nm    |

## Data sources (ongoing)

USGS-EROS maintains an API cakked ESPA for getting satellite imagery: https://github.com/USGS-EROS/espa-api
* The account that Hao set up for weecology does successfully authenticate, which means it should be possible to automate regular updating. Unfortunately, the workflow seems to be to put in data order requests, and then at some point you get a link for downloading... (via the registered email, I'm guessing). It might be worthwhile to contact someone there about engineering a solution that *doesn't* involve the email loop.

MODISTools provides an up-to-date API for accessing MODIS data (though the server is currently down at the time of writing this -- 2020-04-01, 2:11pm EST). More importantly, MODIS has exceeded its design lifespan of 6 years (launched in 1999), so we may want to also consider the replacement data products.

The successor to MODIS is VIIRS (I think), and may be accessible through MODISTools. (I can't check at the moment, since the data server API is down, per above). According to https://ladsweb.modaps.eosdis.nasa.gov/missions-and-measurements/products/VNP13A1, there is a 500m 16-day vegetation index dataset that runs from January 2012 to present (ArchiveSet 5000).


