#' Smooth a plot of metabolism data
#'
#' Smooth a plot of metabolism data using a moving window average
#'
#' @param x input object
#' @param window numeric vector defining size of the smoothing window, passed to \code{filter}
#' @param sides numeric vector defining method of averaging, passed to \code{filter}
#' @param ... additional arguments passed to \code{\link[stats]{filter}}
#'
#' @concept analyze
#'
#' @export smoother
#'
#' @return Returns a \code{data.frame} of the smoothed metabolism data.
#'
#' @details This function uses a moving window average to smooth metabolism data for plotting.  It has nothing to do with weighted regression (\code{\link{wtreg}}) and is meant only for plotting aesthetics. The function is a simple wrapper to \code{\link[stats]{filter}}. The window argument specifies the number of observations included in the moving average. The sides argument specifies how the average is calculated for each observation (see the documentation for \code{\link[stats]{filter}}). A value of 1 will filter observations within the window that are previous to the current observation, whereas a value of 2 will filter all observations within the window centered at zero lag from the current observation.
#'
#' @seealso \code{\link[stats]{filter}}
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
#' # smooth metabolism data with 20 day moving window average
#' tosmooth <- metab[, c('Pg', 'Rt', 'NEM')]
#' smoother(tosmooth, window = 20)
#' }
smoother <- function(x, ...) UseMethod('smoother')

#' @rdname smoother
#'
#' @export
#'
#' @method smoother default
smoother.default <- function(x, window = 5, sides = 2, ...){

  window <- rep(1, window)/window
  nms <- names(x)
  out <- stats::filter(x, window, sides, method = 'convolution', ...)
  out <- as.data.frame(out)
  names(out) <- nms

  return(out)

}
