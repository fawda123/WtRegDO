######
#' Ecosystem metabolism
#'
#' Estimate ecosystem metabolism using the Odum open-water method.  Estimates of daily integrated gross production, total respiration, and net ecosystem metabolism are returned.  A plotting method is also provided.
#'
#' @param dat_in Input data frame which must include time series of dissolved oxygen (mg L-1), see \code{\link{SAPDC}} for data structure
#' @param DO_var chr string indicating the name of the column with the dissolved oxygen variable for estimating metabolism
#' @param depth_val chr indicating the name of a column in the input data for estimating depth for volumetric integration.  This column is typically the tidal height vector.  Use \code{depth_val = NULL} if supplying an alternative depth vector to \code{depth_vec}.
#' @param metab_units chr indicating desired units of output for oxygen, either as mmol or grams
#' @param bott_stat logical if air-sea gas exchange is removed from the estimate
#' @param depth_vec numeric value for manual entry of station depth (m).  Use a single value if the integration depth is constant or a vector of depth values equal in length to the time series.  Leave \code{NULL} if estimated from \code{depth_val} column.
#'
#' @import oce plyr wq
#'
#' @export
#'
#' @details
#' Input data include both water quality and weather time series, which are typically collected with independent instrument systems.  This requires merging of the time series datasets.  These include time series of dissolved oxygen, salinity, air and water temperature, barometric pressure, and wind speed (see \code{\link{SAPDC}} for an example of the data structure for \code{ecometab}).
#'
#' The open-water method is a common approach to quantify net ecosystem metabolism using a mass balance equation that describes the change in dissolved oxygen over time from the balance between photosynthetic and respiration processes, corrected using an empirically constrained air-sea gas diffusion model (see Ro and Hunt 2006, Thebault et al. 2008).  The diffusion-corrected DO flux estimates are averaged separately over each day and night of the time series. The nighttime average DO flux is used to estimate respiration rates, while the daytime DO flux is used to estimate net primary production. To generate daily integrated rates, respiration rates are assumed constant such that hourly night time DO flux rates are multiplied by 24. Similarly, the daytime DO flux rates are multiplied by the number of daylight hours, which varies with location and time of year, to yield net daytime primary production. Respiration rates are subtracted from daily net production estimates to yield gross production rates.  The metabolic day is considered the 24 hour period between sunsets on two adjacent calendar days.
#'
#' Areal rates for gross production and total respiration are based on volumetric rates normalized to the depth of the water column at the sampling location, which is assumed to be well-mixed, such that the DO sensor is reflecting the integrated processes in the entire water column (including the benthos).  Water column depth is calculated as the mean value of the depth variable across the time series.  Depth values are floored at one meter for very shallow stations and 0.5 meters is also added to reflect the practice of placing sensors slightly off of the bottom.  Additionally, the air-sea gas exchange model is calibrated with wind data either collected at, or adjusted to, wind speed at 10 m above the surface. The metadata should be consulted for exact height.  The value can be changed manually using a \code{height} argument, which is passed to \code{\link{f_calcKL}}.
#'
#' A minimum of three records are required for both day and night periods to calculate daily metabolism estimates.  Occasional missing values for air temperature, barometric pressure, and wind speed are replaced with the climatological means (hourly means by month) for the period of record using adjacent data within the same month as the missing data.
#'
#' All DO calculations within the function are done using molar units (e.g., mmol O2 m-3).
#'
#' The specific approach for estimating metabolism with the open-water method is described in Caffrey et al. 2013 and references cited therein.
#'
#' The plotting method plots daily metabolism estimates using different aggregation periods.  Accepted aggregation periods are \code{'years'}, \code{'quarters'}, \code{'months'}, \code{'weeks'}, and \code{'days'} (if no aggregation is preferred). The default function for aggregating is the \code{\link[base]{mean}} for the periods specified by the \code{by} argument.  Setting \code{pretty = FALSE} will return the plot with minimal modifications to the \code{\link[ggplot2]{ggplot}} object.
#'
#' @return A \code{metab} object with daily integrated metabolism estimates including gross produciton (Pg), total respiration (Rt), and net ecosystem metabolism (NEM).  Attributes of the object include the raw data (\code{rawdat}), a character string indicating name of the tidal column if supplied in the raw data (\code{depth_val}), and a character string indicating name of the dissolved oxygen column in the raw data that was used to estimate metabolism (\code{DO_var}).
#'
#' The plot method returns a \code{\link[ggplot2]{ggplot}} object which can be further modified.
#'
#' @references
#' Caffrey JM, Murrell MC, Amacker KS, Harper J, Phipps S, Woodrey M. 2013. Seasonal and inter-annual patterns in primary production, respiration and net ecosystem metabolism in 3 estuaries in the northeast Gulf of Mexico. Estuaries and Coasts. 37(1):222-241.
#'
#' Odum HT. 1956. Primary production in flowing waters. Limnology and Oceanography. 1(2):102-117.
#'
#' Ro KS, Hunt PG. 2006. A new unified equation for wind-driven surficial oxygen transfer into stationary water bodies. Transactions of the American Society of Agricultural and Biological Engineers. 49(5):1615-1622.
#'
#' Thebault J, Schraga TS, Cloern JE, Dunlavey EG. 2008. Primary production and carrying capacity of former salt ponds after reconnection to San Francisco Bay. Wetlands. 28(3):841-851.
#'
#' @seealso
#' \code{\link{f_calcKL}} for estimating the oxygen mass transfer coefficient used with the air-sea gas exchange model and \code{\link{met_day_fun}} for identifying the metabolic day for each observation in the time series
#'
#' @examples
#' \dontrun{
#' data(SAPDC)
#'
#' # metadata for the location
#' tz <- 'America/Jamaica'
#' lat <- 31.39
#' long <- -89.28
#'
#' # estimate ecosystem metabolism using observed DO time series
#' metab <- ecometab(SAPDC, DO_var = 'DO_obs', tz = tz,
#'  lat = lat, long = long)
#'
#' ## plot
#' plot(metab)
#'
#' ## change alpha, aggregation period, widths
#' plot(metab, by = 'quarters', alpha = 0.1, widths = 0)
#'
#' ## plot daily raw, no aesthetics
#' plot(metab, by = 'days', pretty = FALSE)
#' }
ecometab <- function(dat_in, ...) UseMethod('ecometab')

#' @rdname ecometab
#'
#' @export
#'
#' @method ecometab default
ecometab.default <- function(dat_in, DO_var = 'DO_mgl', depth_val = 'Tide', metab_units = 'mmol',
  bott_stat = FALSE, depth_vec = NULL, ...){

  # stop if units not mmol or grams
  if(any(!(grepl('mmol|grams', metab_units))))
    stop('Units must be mmol or grams')

  ##begin calculations

  #columns to be removed prior to processing
  to.rem<-c('flag', 'dTide', 'met.date', 'variable', 'value', 'day.hrs',
    'dec_time', 'hour')
  dat_in<-dat_in[,!names(dat_in) %in% to.rem]

  #convert DO from mg/L to mmol/m3
  dat_in$DO<-dat_in[, DO_var]/32*1000

  # get change in DO per hour, as mmol m^-3 hr^-1
  # scaled to time interval to equal hourly rates
  # otherwise, mmol m^-3 0.5hr^-1
  dDO_scl <- as.numeric(diff(dat_in$DateTimeStamp)/60)
  dDO<-diff(dat_in$DO)/dDO_scl

  #take diff of each column, divide by 2, add original value
  DateTimeStamp<-diff(dat_in$DateTimeStamp)/2 + dat_in$DateTimeStamp[-c(nrow(dat_in))]
  dat_in<-apply(
    dat_in[,2:ncol(dat_in)],
    2,
    function(x) diff(x)/2 + x[1:(length(x) -1)]
    )
  dat_in<-data.frame(DateTimeStamp,dat_in)
  DO <- dat_in$DO

  ##
  # replace missing wx values with climatological means
  # only ATemp, WSpd, and BP

  # monthly and hourly averages
  months <- format(dat_in$DateTimeStamp, '%m')
  hours <- format(dat_in$DateTimeStamp, '%H')
  clim_means <- ddply(data.frame(dat_in, months, hours),
    .variables=c('months', 'hours'),
    .fun = function(x){
      data.frame(
        ATemp = mean(x$ATemp, na.rm = TRUE),
        WSpd = mean(x$WSpd, na.rm = TRUE),
        BP = mean(x$BP, na.rm = TRUE)
      )
    }
  )
  clim_means <- merge(
    data.frame(DateTimeStamp = dat_in$DateTimeStamp, months,hours),
    clim_means, by = c('months','hours'),
    all.x = TRUE
  )
  clim_means <- clim_means[order(clim_means$DateTimeStamp),]

  # DateTimeStamp order in dat_in must be ascending to match
  if(is.unsorted(dat_in$DateTimeStamp))
    stop('DateTimeStamp is unsorted')

  # reassign empty values to means, objects are removed later
  ATemp_mix <- dat_in$ATemp
  WSpd_mix <- dat_in$WSpd
  BP_mix <- dat_in$BP
  ATemp_mix[is.na(ATemp_mix)] <- clim_means$ATemp[is.na(ATemp_mix)]
  WSpd_mix[is.na(WSpd_mix)] <- clim_means$WSpd[is.na(WSpd_mix)]
  BP_mix[is.na(BP_mix)] <- clim_means$BP[is.na(BP_mix)]

  ##
  # get sigma_t estimates
  SigT<-with(dat_in,swSigmaT(Sal,Temp,mean(dat_in$BP/100,na.rm=TRUE)))

  # DOsat is a ratio between DO (mg/L) and DO at saturation (mg/L), gets around a unit conversion issue
  # oxysol returns the actual DO saturation in mg/L
  # used to get loss of O2 from diffusion
  DOsat<-with(dat_in, get(DO_var) / (oxySol(Temp * (1000 + SigT) / 1000, Sal)))


  # station depth, defaults to mean depth value plus 0.5 in case not on bottom
  # uses 'depth_val' if provided, otherwise needs 'depth_vec'
  if(!is.null(depth_val)){

    if(!depth_val %in% names(dat_in)) stop(paste(depth_val, 'column for depth_val not in dat_in'))
    H<-rep(0.5 + mean(pmax(1, dat_in[, depth_val]), na.rm = TRUE), nrow(dat_in))

  } else {

    if(is.null(depth_vec)) stop('Requires value for depth_vec if depth_val is NULL')

    if(length(depth_vec) > 1){

      depth_vec <- depth_vec[-1]
      stopifnot(length(depth_vec) == nrow(dat_in))
      H <- depth_vec

    } else {

      H<-rep(depth_vec,nrow(dat_in))

    }

  }

  #use met_day_fun to add columns indicating light/day, date, and hours of sunlight
  dat_in <- met_day_fun(dat_in, ...)

  #get air sea gas-exchange using wx data with climate means
  KL<-with(dat_in,f_calcKL(Temp,Sal,ATemp_mix,WSpd_mix,BP_mix))
  rm(list = c('ATemp_mix', 'WSpd_mix', 'BP_mix'))

  #get volumetric reaeration coefficient from KL
  Ka<-KL/24/H

  #get exchange at air water interface
  # DO/DOsat - DO reduces to Cs - C in mmol/m3 (DOsat is actually a ratio between DO and DO at saturation
  D=Ka*(DO/DOsat-DO)

  #combine all data for processing
  proc.dat<-dat_in[,!names(dat_in) %in% c('DateTimeStamp','cTide','Wdir',
    'SDWDir','ChlFluor','Turb','pH','RH',DO_var,'DO_pct','SpCond','TotPrcp',
    'CumPrcp','TotSoRad','Tide')]
  proc.dat<-data.frame(proc.dat,DOsat,dDO,SigT,H,D)

  #get daily/nightly flux estimates for Pg, Rt, NEM estimates
  out<-lapply(
    split(proc.dat,proc.dat$met.date),
    function(x){

      #filter for minimum no. of records
      if(length(with(x[x$variable=='sunrise',],na.omit(dDO))) < 3 |
         length(with(x[x$variable=='sunset',],na.omit(dDO))) < 3 ){
        DOF_d<-NA; D_d<-NA; DOF_n<-NA; D_n<-NA
        }

      else{
        #day
        DOF_d<-mean(with(x[x$variable=='sunrise',],dDO*H),na.rm=TRUE)
        D_d<-mean(with(x[x$variable=='sunrise',],D),na.rm=TRUE)

        #night
        DOF_n<-mean(with(x[x$variable=='sunset',],dDO*H),na.rm=TRUE)
        D_n<-mean(with(x[x$variable=='sunset',],D),na.rm=TRUE)
        }

      #metabolism
      #account for air-sea exchange if surface station
      #else do not
      if(!bott_stat){
        Pg<-((DOF_d-D_d) - (DOF_n-D_n))*unique(x$day.hrs)
        Rt<-(DOF_n-D_n)*24
      } else {
        Pg<-(DOF_d - DOF_n)*unique(x$day.hrs)
        Rt<-DOF_n*24
        }
      NEM<-Pg+Rt
      Pg_vol<-Pg/mean(x$H,na.rm=TRUE)
      Rt_vol<-Rt/mean(x$H,na.rm=TRUE)

      # output
      data.frame(Date=unique(x$met.date),Pg,Rt,NEM)

      }
    )

  out <- do.call('rbind',out)

  # change units to grams
  if('grams' %in% metab_units){

    # convert metab data to g m^-2 d^-1
    # 1mmolO2 = 32 mg O2, 1000mg = 1g, multiply by 32/1000
    as_grams <- apply(out[, -1], 2, function(x) x * 0.032)
    out <- data.frame(Date = out[, 'Date'], as_grams)

  }

  # make metab class
  out <- structure(
    .Data = out,
    class = c('metab', 'data.frame'),
    rawdat = dat_in,
    depth_val = depth_val,
    DO_var = DO_var
  )

  return(out)

  }
