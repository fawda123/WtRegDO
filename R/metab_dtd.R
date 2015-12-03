#' Ecosystem metabolism for SAPDC from detided DO
#'
#' Ecosystem metabolism results for \link{SAPDC} from detided dissolved oxygen time series.  The dataset was created by running \code{\link{wtreg}} on the sample dataset for Sapelo Island Dean Creek station, 2012 data.  Each row represents a daily estimate or average for each metabolic day defined as the period between sunrises for two calendar days.
#'
#' @format A data frame with 367 rows and 12 variables:
#' \describe{
#'   \item{Date}{Date, metabolic day}
#'   \item{Temp}{numeric, water temperature, celsius}
#'   \item{Sal}{numeric, salinity, ppt}
#'   \item{ATemp}{numeric, air temperature, celsius}
#'   \item{BP}{numeric, barometric pressure, mb}
#'   \item{WSpd}{numeric, wind speed, m s-1}
#'   \item{Tide}{numeric, tide height, m}
#'   \item{DO}{numeric, dissolved oxygen, mmol m-3}
#'   \item{DOsat}{numeric, dissolved oxygen at saturation, proportion from 0--1}
#'   \item{Pg}{numeric, gross production, mmol m-2 d-1}
#'   \item{Rt}{numeric, total respiration, mmol m-2 d-1}
#'   \item{NEM}{numeric, net ecosytem metabolism, mmol m-2 d-1}
#' }
#'
"metab_dtd"
