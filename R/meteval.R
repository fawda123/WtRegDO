#' Evaluate metabolism results
#'
#' Evaluation metabolism results before and after weighted regression
#'
#' @param dat_in Input \code{data.frame}
#' @param tz chr string for timezone, e.g., 'America/Chicago'
#' @param lat numeric for latitude
#' @param long numeric for longitude (negative west of prime meridian)
#' @param daywin numeric for half-window width used in moving window correlatin
#' @param method chr string for corrrelation method, passed to \code{\link[stats]{cor}}
#' @param plot logical to return a plot
#' @param lims two element numeric vector indicating y-axis limits on plot
#' @param progress logical if progress saved to a txt file names 'log.txt' in the working directory
#'
#' @details
#' This function provides summary statistics of metabolism results to evaluate the effectiveness of weighted regression. Summary statistics include the correlation of dissolved oxygen time series with predicted tidal height change, the correlation of metabolism estimates with mean tidal height change between observations during day or night periods for production and respiration (respectively), mean and standard deviation of metabolism estimates across all daily integrated values, and percent `anomalous' estimates of metabolism.
#'
#' Statistics are estimated for the dissolved oxygen time series in the input dataset specified by the user (observed or filtered), whereas summary  before and after use of weighted regression and metabolism estimates based
#'
#' In general, useful results for weighted regression are those that remove the correlation of dissolved oxygen, production, and respiration with tidal changes.  Similarly, the mean estimates of metabolism should not change, whereas the standard deviation and percent anomalous should decrease.
#'
#' Tables 2 and 3 in Beck et al. 2015 were created using similar functions.
#'
#' @return A \code{data.frame} of summary statistics...
#'
#' @export
#'
#' @seealso \code{\link{ecometab}}
#'
#' @references
#' Beck MW, Hagy III JD, Murrell MC. 2015. Improving estimates of ecosystem metabolism by reducing effects of tidal advection on dissolved oxygen time series. Limnology and Oceanography Methods. DOI: 10.1002/lom3.10062
#'
#' @examples
#' \dontrun{
#'
#' # load library and sample data
#' # metab_obs and metab_dtd
#'  library(WtRegDO)
#'  data(metab_obs)
#'  data(metab_dtd)
#'
#'  meteval(metab_obs)
#'  meteval(metab_dtd)
#' }
meteval <- function(metab_in) UseMethod('meteval')

#' @rdname meteval
#'
#' @export
#'
#' @method meteval metab
meteval.metab <- function(metab_in, ...){

  # remove NA values
  toeval <- na.omit(metab_in)

  # summarize metab
  out <- list(
    meanPg = mean(toeval$Pg),
    sdPg = sd(toeval$Pg),
    anomPg = 100 * sum(toeval$Pg <= 0)/nrow(toeval),
    meanRt = mean(toeval$Rt),
    sdRt = sd(toeval$Rt),
    anomRt = 100 * sum(toeval$Rt >= 0)/nrow(toeval)
  )

  return(unlist(out))

}
