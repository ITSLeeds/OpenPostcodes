# Trim LSOA
library(sf)
library(dplyr)
library(future)
library(future.apply)
library(progressr)
handlers("progress")

uniongrid <- function(x){
  x <- sf::st_union(x)
  x <- sf::st_cast(x, "POLYGON")
  p()
  return(x)
}

nopostcode <- readRDS("postcodes_1km_buffer_neg.Rds")
nopostcode <- st_as_sf(data.frame(id = 1:length(nopostcode),
                                  geometry = nopostcode))
nopostcode$area <- as.numeric(st_area(nopostcode))
summary(nopostcode$area)
nopostcode <- nopostcode[nopostcode$area != max(nopostcode$area),]
summary(nopostcode$area)

landuse <- read_sf('all_union.gpkg')

dir.create("tmp")
unzip("../../creds2/CarbonCalculator/data/bounds/England_lsoa_2011_clipped.zip", exdir = "tmp")
bounds_full  <- st_read("tmp/england_lsoa_2011_clipped.shp")
unlink("tmp", recursive = TRUE)

inter_postcode <- st_intersects(nopostcode, bounds_full)
inter_landuse <- st_intersects(landuse, bounds_full)

nopostcode_sub <- nopostcode[lengths(inter_postcode) > 1,]
landuse_sub <- landuse[lengths(inter_landuse) > 1,]

all <- c(landuse_sub$geom, nopostcode_sub$geometry)
gbgrid <- st_make_grid(all, cellsize = c(10000,10000))
gbgrid <- st_as_sf(data.frame(gridid = seq(1, length(gbgrid)),
                              geometry = gbgrid))


all <- st_as_sf(data.frame(id = seq(1, length(all)),
                           geometry = all))
all <- st_join(all, gbgrid)
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


