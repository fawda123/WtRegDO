#' Evaluate tide and sun correlation
#'
#' Evaluation correlation between tide change and sun angle to determine effectiveness of weighted regression
#'
#' @param dat_in Input \code{data.frame}
#' @param tz chr string for timezone, e.g., 'America/Chicago'
#' @param lat numeric for latitude
#' @param long numeric for longitude (negative west of prime meridian)
#' @param depth_val chr indicating name of the tidal height column in \code{dat_in}
#' @param daywin numeric for half-window width used in moving window correlatin
#' @param method chr string for corrrelation method, passed to \code{\link[stats]{cor}}
#' @param plot logical to return a plot
#' @param lims two element numeric vector indicating y-axis limits on plot
#' @param progress logical if progress saved to a txt file names 'log.txt' in the working directory
#'
#' @details
#' This function can be used before weighted regression to identify locations in the time series when tidal and solar changes are not correlated.  In general, the \code{\link{wtreg}} will be most effective when correlations between the two are zero, whereas \code{\link{wtreg}} will remove both the biological and physical components of the dissolved oxygen time series when the sun and tide are correlated.   The correlation between tide change and sun angle is estimated using a moving window for the time series, where the window width is defined by \code{daywin}.  Tide changes are estimated as angular rates for the tidal height vector and sun angles are estimated from the time of day and geographic location.
#'
#' The \code{\link[foreach]{foreach}} function is used to execute the moving window correlation in parallel and will be run automatically if a backend is created.
#' Figure 9 in Beck et al. 2015 was created using this function.
#'
#' @return A \code{\link[ggplot2]{ggplot}} object if \code{plot = TRUE}, otherwise a numeric vector of the correlations for each row in the input dataset.
#'
#' @export
#'
#' @import foreach ggplot2
#'
#' @seealso \code{\link{wtreg}}
#'
#' @references
#' Beck MW, Hagy III JD, Murrell MC. 2015. Improving estimates of ecosystem metabolism by reducing effects of tidal advection on dissolved oxygen time series. Limnology and Oceanography Methods. DOI: 10.1002/lom3.10062
#'
#' @examples
#' \dontrun{
#'
#' data(SAPDC)
#'
#' # metadata
#' tz <- 'America/Jamaica'
#' lat <- 31.39
#' long <- -89.28
#'
#' # setup parallel backend
#' library(doParallel)
#' registerDoParallel(cores = 7)
#'
#' evalcor(SAPDC, tz, lat, long, progress = TRUE)
#'
#' }
evalcor <- function(dat_in, tz, lat, long, depth_val = 'Tide', daywin = 6, method = 'pearson', plot = TRUE, lims = c(-0.5, 0.5), progress = FALSE){

  names(dat_in)[names(dat_in) %in% depth_val] <- 'Tide'

  # get decimal time
  tocor <- met_day_fun(dat_in, tz, lat, long)
  tocor <- dectime(tocor)

  # sun angle
  locs <- c(long, lat)
  utc_time <- as.POSIXlt(tocor$DateTimeStamp, tz = 'UTC')
  sun_angle <- oce::sunAngle(utc_time, locs[1], locs[2])$altitude

  # polar coords for tidal height, in degrees
  tocor$dTide <- with(tocor, c(diff(Tide)[1], diff(Tide)))
  tide_angle <- with(tocor, atan(dTide/c(diff(dec_time)[1], diff(dec_time))) * 180/pi)

  # for weights
  tocor$hour <- as.numeric(strftime(tocor$DateTimeStamp, '%H', tz = tz))
  tocor$hour <- tocor$hour + as.numeric(strftime(tocor$DateTimeStamp, '%M', tz = tz))/60

  #for counter
  strt <- Sys.time()

  # moving window correlations given daywin
  cor_out <- foreach(row = 1:nrow(tocor)) %dopar% {

    # progress
    if(progress){
      sink('log.txt')
      cat('Log entry time', as.character(Sys.time()), '\n')
      cat(row, ' of ', nrow(tocor), '\n')
      print(Sys.time() - strt)
      sink()
      }

    ref_in <- tocor[row, ]

    wts <- WtRegDO::wtfun(ref_in, tocor, wins = list(daywin, 1e6, 1e6))
    gr_zero <- which(wts > 0)

    sun_in <- (sun_angle)[gr_zero]
    tide_in <- (tide_angle)[gr_zero]

    cor(sun_in, tide_in, method = method)

  }

  cor_out <- unlist(cor_out)

  # create plot
  toplo <- data.frame(tocor, Correlation = cor_out)

  p <- ggplot(toplo, aes_string(x = 'DateTimeStamp', y = 'Correlation')) +
    geom_line() +
    scale_y_continuous(limits = lims) +
    geom_hline(yintercept = 0, linetype = 'dashed') +
    theme_bw()

  if(plot) return(p)

  return(cor_out)

}
