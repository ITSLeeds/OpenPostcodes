process_postcodes <- function(oa_sub, postcodes_sub, other_sub){
  #qtm(oa_sub, fill = NULL) + qtm(postcodes_sub, dots.col = "blue") + qtm(other_sub, dots.col = "red")
  
  postcodes_sub <- sf::st_as_sf(postcodes_sub, coords = c("X","Y"), crs = 27700)
  
  if(nrow(other_sub) > 0){
    other_sub <- sf::st_as_sf(other_sub, coords = c("X","Y"), crs = 27700)
    other_sub <- other_sub[oa_sub,]
  }
  
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
    sf::st_crs(voronoi) <- 27700
    voronoi <- sf::st_as_sf(data.frame(id = 1:length(voronoi), geometry = voronoi))
    suppressWarnings(voronoi <- sf::st_intersection(voronoi, oa_sub))
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
    sf::st_crs(voronoi) <- 27700
    voronoi <- sf::st_as_sf(data.frame(id = 1:length(voronoi), geometry = voronoi))
    suppressWarnings(voronoi <- sf::st_intersection(voronoi, oa_sub))
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


build_list <- function(i){
  oa_sub <- oa[i,]
  postcodes_sub <- inter[i][[1]]
  postcodes_sub <- postcodes[postcodes_sub, ]
  
  other_sub <- other[other$postcode %in% postcodes_sub$postcode,]
  res <- list(oa_sub = oa_sub, postcodes_sub = postcodes_sub, other_sub = other_sub)
  return(res)
}

build_postcodes_list <- function(i){
  oa_sub <- oa[i,]
  postcodes_sub <- inter[i][[1]]
  postcodes_sub <- postcodes[postcodes_sub, ]
  # if nrow == 0!!!
  postcodes_sub = cbind(postcodes_sub, sf::st_coordinates(postcodes_sub))
  postcodes_sub = sf::st_drop_geometry(postcodes_sub)
  return(postcodes_sub)
}

build_other_list <- function(postcodes_sub){
  other_sub <- other[other$postcode %in% postcodes_sub$postcode,]
  other_sub = cbind(other_sub, sf::st_coordinates(other_sub))
  other_sub = sf::st_drop_geometry(other_sub)
  return(other_sub)
}

make_postcodes2 <- function(sub){
  res <- process_postcodes(oa_sub = sub$oa_sub, postcodes_sub = sub$postcodes_sub, other_sub = sub$other_sub)
  return(res)
}


make_postcodes3 <- function(i){
  oa_sub <- oa[i,]
  postcodes_sub <- postcodes_list[[i]]
  other_sub <- other_list[[i]]
  
  if(nrow(postcodes_sub) > 0){
    postcodes_sub <- st_as_sf(postcodes_sub, coords = c("X", "Y"), crs = 27700)
  }
  
  
  if(nrow(other_sub) > 0){
    other_sub <- st_as_sf(other_list[[i]], coords = c("X", "Y"), crs = 27700)
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
    sf::st_crs(voronoi) <- 27700
    voronoi <- sf::st_as_sf(data.frame(id = 1:length(voronoi), geometry = voronoi))
    suppressWarnings(voronoi <- sf::st_intersection(voronoi, oa_sub))
    if(nrow(other_sub) > 0){
      voronoi <- sf::st_join(voronoi, postcodes_plus)
    } else {
      voronoi <- sf::st_join(voronoi, postcodes_sub)
    }
    
    names(voronoi) <- c("id","oa","postcode","qua","geometry")
    voronoi <- voronoi[,c("postcode","oa")]
    
    if(any(duplicated(voronoi$postcode))){
      voronoi <- dplyr::group_by(voronoi, postcode)
      voronoi <- dplyr::summarise(voronoi, oa = oa[1])
    }
    #qtm(oa_sub, fill = NULL) + qtm(postcodes_sub, dots.col = "blue") + qtm(other_sub, dots.col = "red") + qtm(voronoi, fill = NULL)
    #qtm(voronoi, fill = "postcode")
    
    return(voronoi)
  }
  
}
