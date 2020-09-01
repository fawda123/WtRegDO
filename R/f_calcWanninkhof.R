#' Calculate gas transfer velocity for Wanninkhof equation
#'
#' @param Temp numeric for water temperature (C)
#' @param Sal numeric for salinity (ppt)
#' @param WSpd numeric for wind speed (m/s)
#'
#' @return numeric vector of Kw in m/d
#' @export
#'
#' @details
#' Output is Kw vector that is alternative to calculating KL using Thiebault et al. 2008 (\code{\link{f_calcKL}}). Interpreted as oxygen mass transfer coefficient.
#'
#' @references
#' Wanninkhof, R. 2014. Relationship between wind speed and gas exchange over the ocean revisited. Limnology and Oceanograpy Methods. 12(6):351-362. 10.4319/lom.2014.12.351
#'
#' @examples
#' data(SAPDC)
#' f_calcWanninkhof(SAPDC$Temp, SAPDC$Sal, SAPDC$WSpd)
f_calcWanninkhof <- function(Temp, Sal, WSpd){

  # calculate u10^2
  windmag2 <- WSpd^2

  # Schmidt number for oxygen
  sc <- oxySchmidt(Temp, Sal)

  a <- 0.251 #DO NOT CHANGE ~ Wannikof 2014

  kw <- a * windmag2 * ((sc / 660) ^ (0.5)) # cm/hr
  kw  <- kw / (100 * 60 * 60) # convert from cm/hr to m/s
  kw <- kw * 60 * 60 * 24 # convert to m/d, 60 * 60 * 24 seconds per day

  return(kw)

}
