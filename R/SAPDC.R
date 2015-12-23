#' Sample dataset for weighted regression
#'
#' Sample dataset for weighted regression, Sapelo Island Dean Creek station, 2012 data.  Only DateTimeSTamp, DO_obs, and Tide are needed for weighted regression, whereas all remaining columns are needed for estimating ecosystem metabolism.  Metadata about the location should also be available including the timezone and lat/long coordinates.
#'
#' @format A data frame with 17568 rows and 9 variables:
#' \describe{
#'   \item{DateTimeStamp}{POSIXct, timestamp of water quality observation}
#'   \item{Temp}{numeric, water temperature, celsius}
#'   \item{Sal}{numeric, salinity, ppt}
#'   \item{DO_obs}{numeric, dissolved oxygen, mg L-1}
#'   \item{ATemp}{numeric, air temperature, celsius}
#'   \item{BP}{numeric, barometric pressure, mb}
#'   \item{WSpd}{numeric, wind speed, m s-1}
#'   \item{Tide}{numeric, tide height, m, estimated from pressure data using harmonic regression}
#' }
#'
"SAPDC"
