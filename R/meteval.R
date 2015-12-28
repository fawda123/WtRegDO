#' Evaluate metabolism results
#'
#' Evaluate metabolism results before and after weighted regression
#'
#' @param metab_in input \code{metab} object as returned from \code{\link{ecometab}}
#' @param ... additional arguments passed to other methods
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

  browser()
  # remove NA values
  toeval <- na.omit(metab_in)
  rawdat <- attr(metab_in, 'rawdat')
  tidecol <- attr(metab_in, 'tidecol')

  # summarize metab data
  out <- list(
    meanPg = mean(toeval$Pg),
    sdPg = sd(toeval$Pg),
    anomPg = 100 * sum(toeval$Pg <= 0)/nrow(toeval),
    meanRt = mean(toeval$Rt),
    sdRt = sd(toeval$Rt),
    anomRt = 100 * sum(toeval$Rt >= 0)/nrow(toeval)
  )

  # exit if no tidal vector column
  if(is.null(tidecol)) return(out)



}
