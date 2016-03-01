
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

Please cite this package using the manuscript.

*Beck MW, Hagy III JD, Murrell MC. 2015. Improving estimates of ecosystem metabolism by reducing effects of tidal advection on dissolved oxygen time series. Limnology and Oceanography Methods. 13(12):731-745. DOI: [10.1002/lom3.10062](http://onlinelibrary.wiley.com/doi/10.1002/lom3.10062/abstract)*

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
## $meanPg
## [1] 135.3987
## 
## $sdPg
## [1] 129.9936
## 
## $anomPg
## [1] 15.02732
## 
## $meanRt
## [1] -172.6532
## 
## $sdRt
## [1] 143.2133
## 
## $anomRt
## [1] 10.92896
## 
## $DOcor.month
##  [1] "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12"
## 
## $DOcor.cor
##  [1] 0.6637291 0.6190974 0.6004334 0.4983921 0.5289581 0.5894151 0.7458457
##  [8] 0.7261328 0.6739781 0.5297470 0.6395344 0.6271354
## 
## $month
##  [1] "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12"
## 
## $Pgcor
##  [1]  0.58665768  0.31821146 -0.35562800  0.48818007  0.84510266
##  [6]  0.79158487  0.71184720  0.18093929  0.06116896  0.47522981
## [11]  0.52853113  0.46391903
## 
## $Rtcor
##  [1] 0.7190483 0.4623587 0.7775887 0.6197052 0.7694675 0.7486285 0.7676385
##  [8] 0.7452710 0.8045039 0.6167957 0.6648443 0.5378011
```

```r
# evaluate after weighted regression
meteval(metab_dtd)
```

```
## $meanPg
## [1] 135.7661
## 
## $sdPg
## [1] 48.99728
## 
## $anomPg
## [1] 0
## 
## $meanRt
## [1] -174.0489
## 
## $sdRt
## [1] 58.5115
## 
## $anomRt
## [1] 0
## 
## $DOcor.month
##  [1] "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12"
## 
## $DOcor.cor
##  [1]  0.07870710  0.01131530 -0.06937389 -0.18395007 -0.10768210
##  [6] -0.05824140  0.01614504  0.06841365  0.10683226  0.11684338
## [11]  0.07392343 -0.10198817
## 
## $month
##  [1] "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12"
## 
## $Pgcor
##  [1] -0.47682101  0.02910631 -0.07309105 -0.02250082  0.60347387
##  [6]  0.27516584 -0.23198078 -0.61985764 -0.53092717 -0.36783649
## [11] -0.11080474 -0.06746171
## 
## $Rtcor
##  [1]  0.21066000  0.28724434 -0.11942154  0.03122116  0.11521264
##  [6]  0.08881729  0.11571877  0.16399793  0.76315897 -0.49940414
## [11]  0.17771218 -0.34045483
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
