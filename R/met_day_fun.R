######
#' Identify metabolic days in a swmpr time series
#'
#' Identify metabolic days in a time series based on sunrise and sunset times for a location and date.  The metabolic day is considered the 24 hour period between sunsets for two adjacent calendar days.
#'
#' @param dat_in data.frame
#' @param tz chr string for timezone, e.g., 'America/Chicago'
#' @param lat numeric for latitude
#' @param long numeric for longitude (negative west of prime meridian)
#'
#' @import StreamMetabolism
#'
#' @export
#'
#' @details This function is only used within \code{\link{ecometab}} and should not be called explicitly.
#'
#' @seealso
#' \code{\link{ecometab}}
#'
#'
met_day_fun<-function(dat_in,
  tz, lat, long
  ){

  #get sunrise/sunset times using sunrise.set function from StreamMetabolism
  start.day<-format(dat_in$DateTimeStamp[which.min(dat_in$DateTimeStamp)]-(60*60*24),format='%Y/%m/%d')
  tot.days<-1+length(unique(as.Date(dat_in$DateTimeStamp)))

  #ss.dat is matrix of sunrise/set times for each days  within period of obs
  ss.dat<-suppressWarnings(sunrise.set(lat,long,start.day,tz,tot.days))

  #remove duplicates, sometimes sunrise.set screws up
  ss.dat<-ss.dat[!duplicated(strftime(ss.dat[,1],format='%Y-%m_%d')),]
  ss.dat<-data.frame(
    ss.dat,
    met.date=as.Date(ss.dat$sunrise,tz=tz)
    )
  ss.dat<-reshape2::melt(ss.dat,id.vars='met.date')
  if(!"POSIXct" %in% class(ss.dat$value))
    ss.dat$value<-as.POSIXct(ss.dat$value, origin='1970-01-01',tz=tz)
  ss.dat<-ss.dat[order(ss.dat$value),]
  ss.dat$day.hrs<-unlist(lapply(
    split(ss.dat,ss.dat$met.date),
    function(x) rep(as.numeric(x[2,'value']-x[1,'value']),2)
    ))

  #matches is vector of row numbers indicating starting value that each
  #unique DateTimeStamp is within in ss.dat
  #output is meteorological day matches appended to dat_in
  matches<-findInterval(dat_in$DateTimeStamp,ss.dat$value)
  data.frame(dat_in,ss.dat[matches,])

  }
