library(sf)
library(tmap)
tmap_mode("view")

postcodes <- readRDS("data-output/code_point_open.Rds")
homes <- postcodes[postcodes$postcode == "HD5 9HH",]
homes <- st_buffer(homes, 100000)
#postcodes <- postcodes[homes,]
grid <- st_make_grid(postcodes, cellsize = c(1000,1000))
inter <- st_intersects(grid, postcodes)
inter <- lengths(inter)
grid_empty <- grid[inter == 0]
grid_empty <- st_union(grid_empty)

tm_shape(grid_empty) +
  tm_fill(alpha = 0.5, col = "red")

