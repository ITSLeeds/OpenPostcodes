library(sf)

npe <- readr::read_csv("data-input/npemap_all.txt", skip = 7)
names(npe) <- c("outward", "inward", "easting", "northing", "lat", "long", "NGR", "grid",  "sources")

npe <- npe[,c("outward", "inward", "easting", "northing", "lat", "long")]
summary(is.na(npe$easting))
summary(is.na(npe$lat))

npe <- npe[!is.na(npe$inward), ]
npe <- st_as_sf(npe, coords = c("easting","northing"), crs = 27700)

npe$postcode <- paste0(npe$outward," ",npe$inward)
npe <- npe[,c("postcode")]
saveRDS(npe,"data-output/npe_postcodes.Rds")
