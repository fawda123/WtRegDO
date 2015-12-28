# load library and sample data
# library(WtRegDO)
data(SAPDC)

# run weighted regression in parallel
# requires parallel backend
library(doParallel)
registerDoParallel(cores = 7)

# metadata for the location
tz <- 'America/Jamaica'
lat <- 31.39
long <- -89.28

# weighted regression
wtreg_res <- wtreg(SAPDC, parallel = TRUE, wins = list(3, 1, 0.6), progress = TRUE,
  tz = tz, lat = lat, long = long)

# save
save(wtreg_res, file = 'data/wtreg_res.RData', compress = 'xz')
