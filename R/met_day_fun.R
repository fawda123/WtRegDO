
######
#' Identify metabolic days in a swmpr time series
#'
#' Identify metabolic days in a time series based on sunrise and sunset times for a location and date.  The metabolic day is considered the 24 hour period between sunsets for two adjacent calendar days.
#'
#' @param dat_in data.frame
#' @param tz chr string for timezone, e.g., 'America/Chicago', must match the time zone in \code{dat_in$DateTimeStamp}
#' @param lat numeric for latitude
#' @param long numeric for longitude (negative west of prime meridian)
#'
#' @import maptools
#'
#' @export
#'
#' @details This function is only used within \code{\link{ecometab}} and should not be called explicitly.
#'
#' @seealso
#' \code{\link{ecometab}}
#'
#'
met_day_fun<-function(dat_in, tz, lat, long){

  # sanity check
  chktz <- attr(dat_in$DateTimeStamp, 'tzone')
  if(tz != chktz)
    stop('dat_in timezone differs from tz argument')

  dtrng <- range(as.Date(dat_in$DateTimeStamp), na.rm = TRUE)
  start_day <- dtrng[1] - 1
  end_day <- dtrng[2] + 1
  lat.long <- matrix(c(long, lat), nrow = 1)
  sequence <- seq(
    from = as.POSIXct(start_day, tz = tz),
    to = as.POSIXct(end_day, tz = tz),
    by = "days"
    )
  sunrise <- sunriset(lat.long, sequence, direction = "sunrise",
      POSIXct = TRUE)
  sunset <- sunriset(lat.long, sequence, direction = "sunset",
      POSIXct = TRUE)
  ss_dat <- data.frame(sunrise, sunset)
  ss_dat <- ss_dat[, -c(1, 3)]
  colnames(ss_dat) <- c("sunrise", "sunset")

  # remove duplicates, if any
  ss_dat <- ss_dat[!duplicated(strftime(ss_dat[, 1], format = '%Y-%m_%d')), ]
  ss_dat <- data.frame(
    ss_dat,
    metab_date = as.Date(ss_dat$sunrise, tz = tz)
    )
  ss_dat <- reshape2::melt(ss_dat, id.vars = 'metab_date')
  if(!"POSIXct" %in% class(ss_dat$value))
    ss_dat$value <- as.POSIXct(ss_dat$value, origin='1970-01-01', tz = tz)
  ss_dat <- ss_dat[order(ss_dat$value),]
  ss_dat$day_hrs <- unlist(lapply(
    split(ss_dat, ss_dat$metab_date),
    function(x) rep(as.numeric(x[2, 'value'] - x[1, 'value']), 2)
    ))
  names(ss_dat)[names(ss_dat) %in% c('variable', 'value')] <- c('solar_period', 'solar_time')

  # matches is vector of row numbers indicating starting value that each
  # unique DateTimeStamp is within in ss_dat
  # output is meteorological day matches appended to dat_in
  matches <- findInterval(dat_in$DateTimeStamp, ss_dat$solar_time)
  out <- data.frame(dat_in, ss_dat[matches, ])
  row.names(out) <- 1:nrow(out)
  return(out)

}
