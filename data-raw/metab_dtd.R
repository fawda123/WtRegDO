# load library and sample data
# library(WtRegDO)
data(wtreg_res)

# metadata for the location
tz <- 'America/Jamaica'
lat <- 31.39
long <- -89.28

# estimate ecosystem metabolism using detided DO time series
metab_dtd <- ecometab(wtreg_res, DO_var = 'DO_nrm', tz = tz,
  lat = lat, long = long)

# save
save(metab_dtd, file = 'data/metab_dtd.RData', compress = 'xz')
