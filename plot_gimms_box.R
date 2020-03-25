
temp_raster <- rasterizeGimms("~/data/GIMMS/geo81jul15a.n07-VI3g")

site <- data.frame(long = -109.08029, 
                   lat = 31.937769)
sp::coordinates(site) <- c("long", "lat")

ndvi_values <- raster::extract(temp_raster, site, buffer = 10000, cellnumbers = TRUE)
bb <- coordinates(temp_raster)[ndvi_values[[1]][,1],] %>%
    as.data.frame()

saveRDS(bb, "gimms_coordinates_portal.RDS")

library(ggplot2)
to_plot <- bind_rows(bb %>% mutate(label = "GIMMS grid"), 
                     data.frame(x = -109.08029, y = 31.937769, label = "Portal"))
p <- ggplot(to_plot, aes(x = x, y = y, color = label)) + 
    geom_point(size = 4) + 
    scale_color_brewer(palette = "Paired") + 
    theme_bw() + 
    labs(x = "longitude", y = "latitude")
ggsave("figures/GIMMS_portal_map.pdf", p, width = 6, height = 4)

