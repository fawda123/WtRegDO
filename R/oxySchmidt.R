#' Calculate Schmidt number for oxygen
#'
#' @param Temp numeric for water temperature (C)
#' @param Sal numeric for salinity (ppt)
#'
#' @return Cald Sc at given salinity for oxygen, unitless
#' @export
#'
#' @examples
#' data(SAPDC)
#' oxySchmidt(SAPDC$Temp, SAPDC$Sal)
oxySchmidt <- function(Temp, Sal){

  salt0 <- 0 #S=0
  param0 <- c(1745.1, -124.34, 4.8055, -0.10115, 0.00086842) #polynomial coeff at S=0
  salt35 <-  35 #S=35
  param35 <- c(1920.4, -135.6, 5.2122, -0.10939, 0.00093777) #polynomial coeff at S=35

  #calculate Sc at S=0"
  param <- param0
  sc0 <- (param[1]) + (param[2] * Temp) + (param[3] * Temp^2) + (param[4] * Temp^3) + (param[5] * Temp^4)

  #calculate Sc at S=35
  param <- param35
  sc35 <- param[1] + (param[2] * Temp) + (param[3] * Temp^2) + (param[4] * Temp^3) + (param[5] * Temp^4)

  #linearly interpolate to cald Sc at given S
  sc <- sc0 + (Sal * ((sc35 - sc0)/(salt35 - salt0)))

  return(sc)

}
