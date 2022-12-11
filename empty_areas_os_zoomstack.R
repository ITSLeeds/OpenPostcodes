library(sf)
library(tmap)
library(sp)
library(dplyr)
tmap_mode("view")
library(future)
library(future.apply)
library(progressr)
library(osmextract)
handlers("progress")

uniongrid <- function(x){
  x <- sf::st_union(x)
  x <- sf::st_cast(x, "POLYGON")
  p()
  return(x)
}

path <- "D:/OneDrive - University of Leeds/Data/OS/ZoomStack/OSOpen_ZoomStack_GPKG/OSOpen_ZoomStack_v0_3.gpkg"

foreshore <- read_sf(path, layer = "foreshore")
greenspace <- read_sf(path, layer = "greenspace")
water <- read_sf(path, layer = "surfacewater")
wood <- read_sf(path, layer = "woodland")
sites  <- read_sf(path, layer = "sites")
sites <- st_cast(sites, 'POLYGON')

contores <- read_sf("D:/OneDrive - University of Leeds/Data/OS/Terrain50/terr50_gpkg_gb/data/terr50_gb.gpkg",
                    layer = "ContourLine")
contores <- contores[contores$propertyValue >= 470,]
contores <- contores[contores$propertyValue <= 490,]

contores_470 <- contores$geom[contores$propertyValue == 470]
contores_470 <- st_cast(contores_470, "LINESTRING")
contores_470 <- contores_470[lengths(contores_470) > 4]
contores_470 <- st_line_merge(st_combine(contores_470))
contores_470 <- st_cast(contores_470, "POLYGON")
contores_470 <- st_make_valid(contores_470)
# qtm(contores_470)
# contores <- read_sf(path, layer = "contours")
# contores <- contores[contores$height >= 470,] #Flash is 463m above sea level
# contores <- contores[contores$height <= 490,] # Allow for a few missing contors
# 
# summary(lengths(contores$geom))
# 
# contores_poly <- st_cast(contores$geom[lengths(contores$geom) > 4], "POLYGON")

# pathosm <- oe_read("data/great-britain-latest.osm.pbf",
#                    layer = "multipolygons",
#                    extra_tags = c("military", "natural"))




all <- c(foreshore$geom, greenspace$geom, water$geom, wood$geom, contores_470, sites$geom)
rm(foreshore, greenspace, water, wood, contores, contores_poly, sites)

gbgrid <- st_make_grid(all, cellsize = c(10000,10000))
gbgrid <- st_as_sf(data.frame(gridid = seq(1, length(gbgrid)),
                           geometry = gbgrid))


all <- st_as_sf(data.frame(id = seq(1, length(all)),
                           geometry = all))
all <- st_join(all, gbgrid)
qtm(gbgrid[gbgrid$gridid %in% unique(all$gridid),])

all <- all[!duplicated(all$id),]
all <- group_by(all, gridid)
all <- group_split(all)

plan(multisession)
with_progress({
  p <- progressor(along = all)
  all <- future_lapply(all, uniongrid)
})
plan(sequential)

all <- unlist(all, recursive = FALSE)
all <- st_as_sfc(all, crs = 27700)

gbgrid <- st_make_grid(all, cellsize = c(100000,100000), offset = (st_bbox(all)[c("xmin", "ymin")] - 500))
gbgrid <- st_as_sf(data.frame(gridid = seq(1, length(gbgrid)),
                              geometry = gbgrid))


all <- st_as_sf(data.frame(id = seq(1, length(all)),
                           geometry = all))
all <- st_join(all, gbgrid)
qtm(gbgrid[gbgrid$gridid %in% unique(all$gridid),])

all <- all[!duplicated(all$id),]
all <- group_by(all, gridid)
all <- group_split(all)

plan(multisession)
with_progress({
  p <- progressor(along = all)
  all <- future_lapply(all, uniongrid)
})
plan(sequential)

all <- unlist(all, recursive = FALSE)
all <- st_as_sfc(all, crs = 27700)



summary(st_geometry_type(all))

all <- st_as_sf(data.frame(id = seq(1, length(all)),
                           geometry = all))
write_sf(all,'all_union.gpkg')


