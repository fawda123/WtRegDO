# load library and data
# library(WtRegDO)
data(wtreg_res)

# metadata for the location
tz <- 'America/Jamaica'
lat <- 31.39
long <- -89.28

# estimate ecosystem metabolism using observed DO time series
metab_obs <- ecometab(wtreg_res, DO_var = 'DO_obs', tz = tz,
  lat = lat, long = long)

# save
save(metab_obs, file = 'data/metab_obs.RData', compress = 'xz')
