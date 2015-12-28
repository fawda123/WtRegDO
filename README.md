
## WtRegDO

#### *Marcus W. Beck, beck.marcus@epa.gov*

Linux: [![Travis-CI Build Status](https://travis-ci.org/fawda123/WtRegDO.svg?branch=master)](https://travis-ci.org/fawda123/WtRegDO)

Windows: [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/fawda123/WtRegDO?branch=master)](https://ci.appveyor.com/project/fawda123/WtRegDO)

This is the public repository of supplementary material to accompany the manuscript "Improving estimates of ecosystem metabolism by reducing effects of tidal advection on dissolved oxygen time series", submitted to Limnology and Oceanography Methods.  The package includes a sample dataset and functions to implement weighted regression on dissolved oxygen time series to reduce the effects of tidal advection.  Functions are also available to estimate net ecosystem metabolism using the open-water method.  

The development version of this package can be installed from Github:


```r
install.packages('devtools')
library(devtools)
install_github('fawda123/WtRegDO')
```

### Citation

Please cite this package using the submitted manuscript.

*Beck MW, Hagy III JD, Murrell MC. 2015 (in press). Improving estimates of ecosystem metabolism by reducing effects of tidal advection on dissolved oxygen time series. Limnology and Oceanography Methods. DOI: [10.1002/lom3.10062](http://onlinelibrary.wiley.com/doi/10.1002/lom3.10062/abstract)*

### Functions

Load the sample dataset and run weighted regression.  See the function help files for details.


```r
# load library and sample data
library(WtRegDO)
data(SAPDC)

# run weighted regression in parallel
# requires parallel backend
library(doParallel)
registerDoParallel(cores = 7)

# metadata for the location
tz <- 'America/Jamaica'
lat <- 31.39
long <- -89.28

# weighted regression, optimal window widths for SAPDC from the paper
wtreg_res <- wtreg(SAPDC, parallel = TRUE, wins = list(3, 1, 0.6), progress = TRUE, 
  tz = tz, lat = lat, long = long)

# estimate ecosystem metabolism using observed DO time series
metab_obs <- ecometab(wtreg_res, DO_var = 'DO_obs', tz = tz, 
  lat = lat, long = long)

# estimate ecosystem metabolism using detided DO time series
metab_dtd <- ecometab(wtreg_res, DO_var = 'DO_nrm', tz = tz, 
  lat = lat, long = long)
```

The `meteval` function provides summary statistics of metabolism results to evaluate the effectiveness of weighted regression.  These estimates are mean production, standard deviation of production, percent of production estimates that were anomalous, mean respiration, standard deviation of respiration, percent of respiration estimates that were anomalous, correlation of dissolved oxygen with tidal height changes, correlation of production with tidal height changes, and the correlation of respiration with tidal height changes.  The correlation estimates are based on an average of separate correlations by each month in the time series.  Dissolved oxygen is correlated directly with tidal height at each time step.  The metabolic estimates are correlated with the tidal height ranges during the day for production and during the night for respiration.  

In general, useful results for weighted regression are those that remove the correlation of dissolved oxygen, production, and respiration with tidal changes.  Similarly, the mean estimates of metabolism should not change if a long time series is evaluated, whereas the standard deviation and percent anomalous estimates should decrease.



```r
# evaluate before weighted regression
meteval(metab_obs)
```

```
##       meanPg         sdPg       anomPg       meanRt         sdRt 
##  135.3987009  129.9935781   15.0273224 -172.6531685  143.2133236 
##       anomRt        DOcor        Pgcor        Rtcor 
##   10.9289617    0.6201999    0.4246453    0.6861376
```

```r
# evaluate after weighted regression
meteval(metab_dtd)
```

```
##        meanPg          sdPg        anomPg        meanRt          sdRt 
##  1.357661e+02  4.899728e+01  0.000000e+00 -1.740489e+02  5.851150e+01 
##        anomRt         DOcor         Pgcor         Rtcor 
##  0.000000e+00 -4.087956e-03 -1.327946e-01  8.287190e-02
```

Plot metabolism results from observed dissolved oxygen time series (see `?plot.metab` for options).  Note the periodicity with fortnightly tidal variation and instances with negative production/positive respiration.


```r
plot(metab_obs, by = 'days')
```

![](README_files/figure-html/unnamed-chunk-5-1.png) 

Plot metabolism results from detided dissolved oxygen time series.


```r
plot(metab_dtd, by = 'days')
```

![](README_files/figure-html/unnamed-chunk-7-1.png) 

The `evalcor` function can be used before weighted regression to identify locations in the time series when tidal and solar changes are not correlated.  In general, the `wtreg` will be most effective when correlations between the two are zero, whereas `wtreg` will remove both the biological and physical components of the dissolved oxygen time series when the sun and tide are correlated.   The correlation between tide change and sun angle is estimated using a moving window for the time series.  Tide changes are estimated as angular rates for the tidal height vector and sun angles are estimated from the time of day and geographic location.  Correlations are low for the sample dataset, suggesting the results from weighted regression are valid for the entire time series.


```r
data(SAPDC)

# metadata for the location
tz <- 'America/Jamaica'
lat <- 31.39
long <- -89.28

# setup parallel backend
library(doParallel)
registerDoParallel(cores = 7)

# run the function
evalcor(SAPDC, tz, lat, long, progress = TRUE)
```

![](README_files/figure-html/evalcor_ex.png) 

### License

This package is released in the public domain under the creative commons license [CC0](https://tldrlegal.com/license/creative-commons-cc0-1.0-universal). 
