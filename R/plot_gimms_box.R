compute_gimms_bounding_pixels <- function(gimms_raster_file = "~/data/GIMMS/geo81jul15a.n07-VI3g", 
                                          bounding_pixels_RDS = "data/gimms_coordinates_portal.RDS", 
                                          bounding_pixels_figure = "figures/GIMMS_portal_map.pdf")
{
    temp_raster <- gimms::rasterizeGimms(gimms_raster_file)
    site <- data.frame(long = -109.08029, 
                       lat = 31.937769)
    sp::coordinates(site) <- c("long", "lat")
    
    # compute bounding pixels
    ndvi_values <- raster::extract(temp_raster, site, buffer = 10000, cellnumbers = TRUE)
    bb <- sp::coordinates(temp_raster)[ndvi_values[[1]][,1],] %>%
        as.data.frame() %>%
        setNames(c("long", "lat"))
    
    saveRDS(bb, bounding_pixels_RDS)
    
    # generate plot
    to_plot <- bind_rows(bb %>% mutate(label = "GIMMS grid"), 
                         site %>% mutate(label = "Portal"))
    p <- ggplot(to_plot, aes(x = long, y = lat, color = label)) + 
        geom_point(size = 4) + 
        scale_color_brewer(palette = "Paired") + 
        theme_bw() + 
        labs(x = "longitude", y = "latitude")
    ggsave(bounding_pixels_figure, p, width = 6, height = 4)
}