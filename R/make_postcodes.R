library(dplyr)
library(sf)
library(tmap)
tmap_mode("view")
source("R/functions.R")

# Load data
oa <- readRDS("data-output/England_oa_2001.Rds")
postcodes <- readRDS("data-output/code_point_open.Rds")
npe <- readRDS("data-output/npe_postcodes.Rds")
osm <- readRDS("data-output/OSM_postcodes.Rds")

# Unofficial sources togther
osm <- osm[,c("postal_code")]
names(osm) <- c("postcode","geometry")
st_geometry(osm) <- "geometry"
other <- rbind(npe, osm)
other$postcode <- toupper(other$postcode)
rm(npe, osm)

# Format postcodes
postcodes$postcode <- sapply(postcodes$postcode, function(pc){
  pc_in <- substr(pc, nchar(pc) -2 , nchar(pc))
  pc_out <- substr(pc, 1 , nchar(pc) - 3)
  pc_out <- gsub(" ","",pc_out)
  pc_fin <- paste0(pc_out," ",pc_in)
  return(pc_fin)
})

# Make intersect
inter <- st_intersects(oa, postcodes)

# Compress datasets
postcodes = cbind(postcodes, st_coordinates(postcodes))
postcodes = st_drop_geometry(postcodes)

other = cbind(other, st_coordinates(other))
other = st_drop_geometry(other)


# build a list of datasets
gc()
masterlist <- pbapply::pblapply(1:nrow(oa), build_list)
rm(inter, oa, other, postcodes)
gc()

postcodes_poly <- pbapply::pblapply(masterlist, make_postcodes2              )




# pb <- utils::txtProgressBar(max = nrow(oa), style = 3)
# progress <- function(n) utils::setTxtProgressBar(pb, n)
# opts <- list(progress = progress)
# cl <- parallel::makeCluster(4)
# doSNOW::registerDoSNOW(cl)
# boot <- foreach::foreach(i = 1:10, .options.snow = opts)
# postcodes_poly <- foreach::`%dopar%`(boot, make_postcodes(i))
# parallel::stopCluster(cl)
# rm(cl, boot, opts, pb, progress)
cl <- parallel::makeCluster(5)
# parallel::clusterExport(
#   cl = cl,
#   varlist = c("inter", "oa", "other", "postcodes"),
#   envir = environment()
# )
parallel::clusterExport(cl, "process_postcodes")
postcodes_poly <- pbapply::pblapply(masterlist, make_postcodes2, cl = cl)
parallel::stopCluster(cl)
rm(cl)

postcodes_poly <- pbapply::pblapply(1:nrow(oa), make_postcodes)
postcodes_fin <- dplyr::bind_rows(postcodes_poly)
postcodes_fin <- as.data.frame(postcodes_fin)
postcodes_fin <- st_as_sf(postcodes_fin)
st_crs(postcodes_fin) <- 27700
st_write(postcodes_fin,"data-output/openpostcodes_england.gpkg")
      