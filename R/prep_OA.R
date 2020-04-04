# read in 2001 OAs
dir.create("tmp")
unzip("data-input/England_oa_2001_clipped.zip", exdir = "tmp")
oa <- st_read("tmp/england_oa_2001_clipped.shp")
oa <- oa[,c("label")]
unlink("tmp", recursive = TRUE)
st_crs(oa) <- 27700

saveRDS(oa,"data-output/England_oa_2001.Rds")

