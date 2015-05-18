
## WtRegDO

#### *Marcus W. Beck, mbafs2012@gmail.com*

Linux: [![Travis-CI Build Status](https://travis-ci.org/fawda123/WtRegDO.svg?branch=master)](https://travis-ci.org/fawda123/WtRegDO)

Windows: [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/fawda123/WtRegDO?branch=master)](https://ci.appveyor.com/project/fawda123/WtRegDO)

This is the public repository of supplementary material to accompany the manuscript "Improving estimates of ecosystem metabolism by reducing effects of tidal advection on dissolved oxygen time series", submitted to Limnology and Oceanography Methods.  The package includes a sample dataset and functions to implement weighted regression on dissolved oxygen time series to reduce the effects of tidal advection.  Functions are also available to estimate net ecosystem metabolism using the open-water method.  

The development version of this package can be installed from Github:


```r
install.packages('devtools')
library(devtools)
install_github('fawda123/WtRegDO')
library(WtRegDO)
```

### Citation

Please cite this package using the submitted manuscript.

*Beck MW, Hagy III JD, Murrell MC. Conditionally accepted. Improving estimates of ecosystem metabolism by reducing effects of tidal advection on dissolved oxygen time series. Limnology and Oceanography Methods.*

### Functions

Load the sample dataset and run weighted regression.  See the function help files for arguments.


```r
data(SAPDC)

# run weighted regression in parallel
# requires parallel backend
library(doParallel)
registerDoParallel(cores = 4)

res <- wtreg(SAPDC, parallel = TRUE, progress = TRUE)

# estimate ecosystem metabolism using observed DO time series
metab_obs <- ecometab(res, DO_var = 'DO_obs', tz = 'America/Jamaica', lat = 31.39, 
  long = -81.28)

# estimate ecosystem metabolism using detided DO time series
metab_dtd <- ecometab(res, DO_var = 'DO_nrm', tz = 'America/Jamaica', lat = 31.39, 
  long = -81.28)
```

### License

This package is released in the public domain under the creative commons license [CC0](https://tldrlegal.com/license/creative-commons-cc0-1.0-universal). 
