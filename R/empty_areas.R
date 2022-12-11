library(sf)
library(tmap)
tmap_mode("view")

#postcodes <- readRDS("data-output/code_point_open.Rds")
postcodes <- readRDS("D:/OneDrive - University of Leeds/Data/Postcodes/code_point_open.Rds")

# homes <- postcodes[postcodes$postcode == "HD5 9HH",]
# homes <- st_buffer(homes, 10000)
# postcodes_sub <- postcodes[homes,]
# grid <- st_make_grid(postcodes, cellsize = c(1000,1000))
# inter <- st_intersects(grid, postcodes)
# inter <- lengths(inter)
# grid_empty <- grid[inter == 0]
# grid_empty <- st_union(grid_empty)


postcodes_area <- st_buffer(postcodes, 1000)
postcodes_area <- st_union(postcodes_area)

saveRDS(postcodes_area, "postcodes_1km_buffer.Rds")
foo <- st_simplify(postcodes_area, 100, preserveTopology = TRUE)
tm_shape(foo) +
  tm_fill(alpha = 0.5, col = "red")


gb_box <- st_make_grid(postcodes_area, n = c(1,1))

nopostcode <- st_difference(gb_box, postcodes_area)
nopostcode <- st_cast(nopostcode, "POLYGON")
saveRDS(nopostcode, "postcodes_1km_buffer_neg.Rds")
write_sf(nopostcode, "postcodes_1km_buffer_neg.gpkg")
