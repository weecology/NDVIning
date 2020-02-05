Getting NDVI from LANDSAT satellites using Google Earth Engine
by Erica Christensen erica.christensen@weecology.org
1/16/19

In order to use GEE, you need to sign up with a google account https://earthengine.google.com/ (top right corner of this page)

Once signed in, go to code.earthengine.google.com
The left panel has some examples and documentation on built-in functions; the middle panel is for writing and running code; and the right panel displays any output from the code
Supposedly there is a way to interact with GEE using Python, but I couldn't figure it out, so this is the Java version.


The script I've written (gee_NDVI_Landsat_SR_Portal.txt) does the following steps:
  - define the area of interest: I used a 1000m buffer around the center of the plots (will display on map when code is run)
  - load the Landsat images and filter by dates and locations indicated
  - apply a cloud mask to filter out bad pixels
  - calculate NDVI at each pixel from the bands
  - calculate mean NDVI per image, and number of good pixels per image
  - export table to your google drive


Decisions I made:
  - There is no single satellite that was operational for the whole Portal time series. Landsat5 goes from 1984-2011; Landsat7 goes from 1999-present; Landsat8 goes from 2013-present. Landsat8 has different sensors than L5 and L7 so I avoided it, but L5 and L7 are pretty much the same so their data should be comparable. However L7 had an equipment failure in 2003 so the data may be a little funky after that (look up Landsat 7 SLC failure). Landsat 7 is scheduled to be replaced by Landsat 9 in late 2020 (reportedly)
  - I used the T1_SR (tier 1, surface reflectance) data product and then calculated NDVI from bands 3 and 4. It is possible to get NDVI directly as a data product, but it does not come with a pixel QA layer and therefore it was not possible to apply the cloud filter
  - I used the built in function "normalizedDifference" to calculate NDVI, with bands 3 and 4 as inputs. If you're using a different satellite (e.g. L8) you may need to select different bands
  - For cloud masking, I copied the example in Examples > Cloud Masking > Landsat457 Surface Reflectance.
  - Exporting to google drive is the only way I could figure out to get the data out. After running the script, you have to go to the "Tasks" tab on the right panel and click RUN in order to do this. It may take a few minutes.

Output files have the following columns:
  - "system:index" is the name of the image; contains the satellite name, row and column of image, and date
  - "NDVI_count" was calculated by my script, essentially the number of good pixels that went into the NDVI_mean after cloud masking. You can use this to set a threshhold of what NDVI values you want to keep. If you have a mean NDVI calculated from only 10 good pixels, it's probably not useful
  - "NDVI_mean" also calculated by my script, mean NDVI of the image
  - ".geo" some garbage describing the geometry of the clipped image