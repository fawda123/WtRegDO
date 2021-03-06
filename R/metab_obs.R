#' Ecosystem metabolism for SAPDC from observed DO
#'
#' Ecosystem metabolism results for \link{SAPDC} from observed dissolved oxygen time series.  The dataset was created by running \code{\link{wtreg}} on the sample dataset for Sapelo Island Dean Creek station, 2012 data.  Each row represents a daily estimate or average for each metabolic day defined as the period between sunrises for two calendar days.  See documentation for \code{\link{ecometab}} for a description of the object attributes.
#'
#' @format A metab object with 367 rows and 4 variables:
#' \describe{
#'   \item{Date}{Date, metabolic day}
#'   \item{Pg}{numeric, gross production, mmol m-2 d-1}
#'   \item{Rt}{numeric, total respiration, mmol m-2 d-1}
#'   \item{NEM}{numeric, net ecosytem metabolism, mmol m-2 d-1}
#' }
#'
"metab_obs"
