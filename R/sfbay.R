######
#' San Francisco Bay water quality data
#'
#' Selected observations and variables from U.S. Geological Survey water quality stations in south San Francisco Bay. Data include \acronym{CTD} and nutrient measurements. Data and documentation herein are from archived wq package: \url{https://cran.r-project.org/web/packages/wq/index.html}
#'
#' @format
#'
#' \code{sfbay} is a data frame with 23207 observations (rows) of 12 variables (columns):
#'
#' \tabular{rll}{
#' 	 \code{[, 1]} \tab \code{date} \tab date\cr
#' 	 \code{[, 2]} \tab \code{time} \tab time\cr
#' 	 \code{[, 3]} \tab \code{stn} \tab station code\cr
#' 	 \code{[, 4]} \tab \code{depth} \tab measurement depth\cr
#' 	 \code{[, 5]} \tab \code{chl} \tab chlorophyll \emph{a}\cr
#' 	 \code{[, 6]} \tab \code{dox.pct} \tab dissolved oxygen\cr
#' 	 \code{[, 7]} \tab \code{spm} \tab suspended particulate matter\cr
#' 	 \code{[, 8]} \tab \code{ext} \tab extinction coefficient\cr
#' 	 \code{[, 9]} \tab \code{sal} \tab salinity\cr
#' 	 \code{[, 10]} \tab \code{temp} \tab water temperature\cr
#' 	 \code{[, 11]} \tab \code{nox} \tab nitrate + nitrite\cr
#' 	 \code{[, 12]} \tab \code{nhx} \tab ammonium\cr
#' }
#'
#' @details
#' The original downloaded dataset was modified by taking a subset of six well-sampled stations and the period 1985--2004. Variable names were also simplified.
#'
#' @source 	Downloaded from \url{http://sfbay.wr.usgs.gov/access/wqdata} on 2009-11-17.
"sfbay"
