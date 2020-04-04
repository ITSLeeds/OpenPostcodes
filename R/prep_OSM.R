remotes::install_github("ITSleeds/OSMtools")
remotes::install_github("ITSleeds/geofabrik")
library(OSMtools)
library(sf)
library(geofabrik)
library(tmap)
tmap_mode("view")

# Filter osm.pbf to just objects with postcodes
osmt_convert("data-input/great-britain-latest.osm.pbf")
osmt_filter("data-input/great-britain-latest.osm.o5m",
            path_out = "data-input/gb_postcode.osm.o5m",
            keep = "postal_code= postcode=")
osmt_convert("data-input/gb_postcode.osm.o5m", format_out = "pbf")


cols <- c(make_additional_attributes("lines"), "postcode", "postal_code")
osm_lines <- read_pbf("data-input/gb_postcode.osm.pbf", layer = "lines",  attributes = cols)

cols <- c(make_additional_attributes("points"), "postcode", "postal_code")
osm_points <- read_pbf("data-input/gb_postcode.osm.pbf", layer = "points",  attributes = cols)

cols <- c(make_additional_attributes("multilinestrings"), "postcode", "postal_code")
osm_multilines <- read_pbf("data-input/gb_postcode.osm.pbf", layer = "multilinestrings",  attributes = cols)

cols <- c(make_additional_attributes("multipolygons"), "postcode", "postal_code")
osm_multipolygons <- read_pbf("data-input/gb_postcode.osm.pbf", layer = "multipolygons",  attributes = cols)

# Remove any missing postcodes
osm_lines <- osm_lines[(!is.na(osm_lines$postcode) | !is.na(osm_lines$postal_code)),]
osm_points <- osm_points[(!is.na(osm_points$postcode) | !is.na(osm_points$postal_code)),]
osm_multilines <- osm_multilines[(!is.na(osm_multilines$postcode) | !is.na(osm_multilines$postal_code)),]
osm_multipolygons <- osm_multipolygons[(!is.na(osm_multipolygons$postcode) | !is.na(osm_multipolygons$postal_code)),]

#check fo double values
summary(!is.na(osm_lines$postcode) & !is.na(osm_lines$postal_code))
summary(!is.na(osm_points$postcode) & !is.na(osm_points$postal_code))
summary(!is.na(osm_multilines$postcode) & !is.na(osm_multilines$postal_code))
summary(!is.na(osm_multipolygons$postcode) & !is.na(osm_multipolygons$postal_code))

# condence to one column of postcodes
osm_lines$postal_code <- ifelse(is.na(osm_lines$postal_code), osm_lines$postcode, osm_lines$postal_code)
osm_points$postal_code <- ifelse(is.na(osm_points$postal_code), osm_points$postcode, osm_points$postal_code)
osm_multilines$postal_code <- ifelse(is.na(osm_multilines$postal_code), osm_multilines$postcode, osm_multilines$postal_code)
osm_multipolygons$postal_code <- ifelse(is.na(osm_multipolygons$postal_code), osm_multipolygons$postcode, osm_multipolygons$postal_code)

# Valid Postcodes are between 5 and 8 characters
# M11AE to EC1A 1BB
osm_lines <- osm_lines[nchar(osm_lines$postal_code) >= 5,]
osm_lines <- osm_lines[nchar(osm_lines$postal_code) <= 8,]

osm_points <- osm_points[nchar(osm_points$postal_code) >= 5,]
osm_points <- osm_points[nchar(osm_points$postal_code) <= 8,]

osm_multilines <- osm_multilines[nchar(osm_multilines$postal_code) >= 5,]
osm_multilines <- osm_multilines[nchar(osm_multilines$postal_code) <= 8,]

osm_multipolygons <- osm_multipolygons[nchar(osm_multipolygons$postal_code) >= 5,]
osm_multipolygons <- osm_multipolygons[nchar(osm_multipolygons$postal_code) <= 8,]

# check a random sample
qtm(osm_lines[sample(1:nrow(osm_lines), 1000),])
qtm(osm_points[sample(1:nrow(osm_points), 1000),])
qtm(osm_multipolygons[sample(1:nrow(osm_multipolygons), 1000),])

# Reduce to just points
osm_lines <- osm_lines[,c("osm_id","name","postal_code")]
osm_points <- osm_points[,c("osm_id","name","postal_code")]
osm_multipolygons <- osm_multipolygons[,c("osm_id","name","postal_code")]
osm_multilines <- osm_multilines[,c("osm_id","name","postal_code")]

osm_lines <- st_cast(osm_lines, "POINT")
osm_multipolygons <- st_cast(osm_multipolygons, "POINT")
osm_multilines <- st_cast(osm_multilines, "POINT")

osm_all <- rbind(osm_points, osm_lines)
osm_all <- rbind(osm_all, osm_multipolygons)
osm_all <- rbind(osm_all, osm_multilines)

# Check for full postcodes
osm_all <- osm_all[!grepl("multiple",osm_all$postal_code),]
osm_all <- osm_all[!grepl(";",osm_all$postal_code),]

osm_all$with_space <- grepl(" ",osm_all$postal_code)
#summary(osm_all$with_space)
#foo <- osm_all[!osm_all$with_space,]

for(i in 1:nrow(osm_all)){
  if(!osm_all$with_space[i]){
    pc <- osm_all$postal_code[i]
    pc_in <- substr(pc, nchar(pc) -2 , nchar(pc))
    pc_out <- substr(pc, 1 , nchar(pc) - 3)
    pc_fin <- paste0(pc_out," ",pc_in)
    pc_fin <- toupper(pc_fin)
    message(pc," to ",pc_fin)
    osm_all$postal_code[i] <- pc_fin
  }
}

postcode_full <- function(pc){
  pc <- strsplit(pc," ")
  if(nchar(pc[[1]][2]) == 3){
    return(TRUE)
  } else {
    return(FALSE)
  }
}

osm_all$full <- sapply(osm_all$postal_code, postcode_full)

osm_all <- osm_all[osm_all$full,]
osm_all <- osm_all[,c("osm_id","name","postal_code")]
saveRDS(osm_all,"data-output/OSM_postcodes.Rds")
