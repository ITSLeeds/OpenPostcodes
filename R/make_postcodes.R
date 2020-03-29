library(dplyr)
library(sf)
library(tmap)
tmap_mode("view")
# read in postcodes
dir.create("tmp")
unzip("data/codepo_gb.zip", exdir = "tmp")

files <- list.files("tmp/Data/CSV", full.names = TRUE)

postcodes <- list()

for(i in 1:length(files)){
  sub <- read.csv(files[i], header = FALSE, stringsAsFactors = FALSE)
  postcodes[[i]] <- sub
  rm(sub)
}

postcodes <- bind_rows(postcodes)
names(postcodes) <- c("postcode","quality","easting","northing","foo1","foo2","foo3","foo4","foo5","foo6")
postcodes <- postcodes[,1:4]
postcodes <- st_as_sf(postcodes, coords = c("easting","northing"), crs = 27700)
unlink("tmp", recursive = TRUE)

# read in 2001 OAs
dir.create("tmp")
unzip("data/England_oa_2001.zip", exdir = "tmp")
oa <- st_read("tmp/england_oa_2001.shp")
oa <- oa[,c("label")]

# Make intersect
st_crs(oa) <- 27700
inter <- st_intersects(oa, postcodes)

make_postcodes <- function(i){
  oa_sub <- oa[i,]
  postcodes_sub <- inter[i][[1]]
  postcodes_sub <- postcodes[postcodes_sub, ]
  if(nrow(postcodes_sub) == 0){
    message(paste0("No postocdes in OA: ", oa_sub$label))
    return(NULL)
  }else{
    postcodes_mp <- st_combine(postcodes_sub)
    voronoi <- try(st_voronoi(postcodes_mp, envelope = oa_sub$geometry), silent = TRUE)
    if(class(voronoi) %in% "try-error"){
      ennv <- st_buffer(oa_sub, 1000)
      voronoi <- st_voronoi(postcodes_mp, envelope = ennv$geometry)
    }
    voronoi <- st_collection_extract(voronoi)
    st_crs(voronoi) <- 27700
    voronoi <- st_as_sf(data.frame(id = 1:length(voronoi), geometry = voronoi))
    suppressWarnings(voronoi <- st_intersection(voronoi, oa_sub))
    voronoi <- st_join(voronoi, postcodes_sub)
    names(voronoi) <- c("id","oa","postcode","qua","geometry")
    voronoi <- voronoi[,c("postcode","oa")]
    return(voronoi)
  }
  
}

postcodes_poly <- pbapply::pblapply(1:nrow(oa), make_postcodes)
postcodes_fin <- dplyr::bind_rows(postcodes_poly)
postcodes_fin <- as.data.frame(postcodes_fin)
postcodes_fin <- st_as_sf(postcodes_fin)
st_crs(postcodes_fin) <- 27700
st_write(postcodes_fin,"data/openpostcodes_england.gpkg")
      