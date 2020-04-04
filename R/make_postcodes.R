library(dplyr)
library(sf)
library(tmap)
tmap_mode("view")

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
  pc_fin <- paste0(pc_out," ",pc_in)
  return(pc_fin)
})

# Make intersect
inter <- st_intersects(oa, postcodes)

make_postcodes <- function(i){
  oa_sub <- oa[i,]
  postcodes_sub <- inter[i][[1]]
  postcodes_sub <- postcodes[postcodes_sub, ]
  
  other_sub <- other[other$postcode %in% postcodes_sub$postcode,]
  if(nrow(other_sub) > 0){
    other_sub <- other_sub[oa_sub,]
  }
  
  
  #qtm(oa_sub, fill = NULL) + qtm(postcodes_sub, dots.col = "blue") + qtm(other_sub, dots.col = "red")
  
  if(nrow(postcodes_sub) == 0){
    message(paste0("No postocdes in OA: ", oa_sub$label))
    return(NULL)
  }else{
    if(nrow(other_sub) > 0){
      other_sub$quality <- NA
      postcodes_plus <- rbind(postcodes_sub, other_sub)
      postcodes_mp <- sf::st_combine(postcodes_plus)
      
    } else {
      postcodes_mp <- sf::st_combine(postcodes_sub)
    }
    
    voronoi <- try(sf::st_voronoi(postcodes_mp, envelope = oa_sub$geometry), silent = TRUE)
    if("try-error" %in% class(voronoi)){
      ennv <- sf::st_buffer(oa_sub, 1000)
      voronoi <- sf::st_voronoi(postcodes_mp, envelope = ennv$geometry)
    }
    voronoi <- sf::st_collection_extract(voronoi)
    st_crs(voronoi) <- 27700
    voronoi <- sf::st_as_sf(data.frame(id = 1:length(voronoi), geometry = voronoi))
    suppressWarnings(voronoi <- st_intersection(voronoi, oa_sub))
    if(nrow(other_sub) > 0){
      voronoi <- sf::st_join(voronoi, postcodes_plus)
    } else {
      voronoi <- sf::st_join(voronoi, postcodes_sub)
    }
    
    names(voronoi) <- c("id","oa","postcode","qua","geometry")
    voronoi <- voronoi[,c("postcode","oa")]
    
    voronoi <- dplyr::group_by(voronoi, postcode)
    voronoi <- dplyr::summarise(voronoi, oa = oa[1])
      
    #qtm(oa_sub, fill = NULL) + qtm(postcodes_sub, dots.col = "blue") + qtm(other_sub, dots.col = "red") + qtm(voronoi, fill = NULL)
    #qtm(voronoi, fill = "postcode")
    
    return(voronoi)
  }
  
}

gc()
pb <- utils::txtProgressBar(max = nrow(oa), style = 3)
progress <- function(n) utils::setTxtProgressBar(pb, n)
opts <- list(progress = progress)
cl <- parallel::makeCluster(4)
doSNOW::registerDoSNOW(cl)
boot <- foreach::foreach(i = 1:nrow(oa), .options.snow = opts)
postcodes_poly <- foreach::`%dopar%`(boot, make_postcodes(i))
parallel::stopCluster(cl)
rm(cl, boot, opts, pb, progress)

#postcodes_poly <- pbapply::pblapply(1:nrow(oa), make_postcodes)
postcodes_fin <- dplyr::bind_rows(postcodes_poly)
postcodes_fin <- as.data.frame(postcodes_fin)
postcodes_fin <- st_as_sf(postcodes_fin)
st_crs(postcodes_fin) <- 27700
st_write(postcodes_fin,"data-output/openpostcodes_england.gpkg")
      