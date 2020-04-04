library(dplyr)

# read in postcodes
dir.create("tmp")
unzip("data-input/codepo_gb.zip", exdir = "tmp")

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
saveRDS(postcodes,"data-output/code_point_open.Rds")
