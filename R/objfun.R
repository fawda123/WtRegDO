#' An objective function to minimize for finding optimal window widths
#'
#' @param metab_obs A metab object estimated the observed dissolved oxygen time series
#' @param metab_dtd A metab object estimated the detided dissolved oxygen time series
#' @param vls chr vector of summary evaluation object to optimize, see details
#'
#' @return A single numeric value indicating the estimate from the objective function
#' @export
#'
#' @details
#' This function is an attempt to quantify a relative measure of comparison to evaluate metabolism estimates from observed and detided dissolved oxygen time series. It is the sole function that is optimized when identifying window widths that produce "best" detided metabolism estimates. The summary is based on an assumption that a detided estimate provides an improved measure of metabolism following several rules of thumb.  Specifically, improved estimates are assumed to have lower anomalies (less negative production and positive respiration values), lower standard deviation, and similar mean values for gross production and respiration between the observed and detided estimates.
#'
#' The quantification of improved fit is based on a sum of percent differences for the six paired measures for percent anomalous production, percent anomalous respiration, mean production, mean respiration, standard deviation of production, and standard deviation of respiration for the estimates from the observed and detided metabolism.  The comparisons of the means are taken as the inverse (1 / mean) such that optimization should attempt to keep the values as similar as possible. The final sum is multiplied by negative one such that the value is to be optimized by minimization, i.e., a lower value indicates improved detiding across all measures.
#'
#' The function can also quantify a comparison based on different measures supplied by the user. By default, all six measures are used.  However, selecting specific measures, such as only optimizing by reducing anomalous values, may be preferred.  Changing the argument for \code{vls} changes which comparisons are used for the summary value.
#'
#' @importFrom dplyr %>%
#'
#' @seealso \code{\link{wtobjfun}}, \code{\link{winopt}}
#'
#' @examples
#' # estimate a summary value for all six measures
#' objfun(metab_obs, metab_dtd)
#'
#' # estimate a summary value for only anomalies
#' objfun(metab_obs, metab_dtd, vls = c('anomPg', 'anomRt'))
objfun <- function(metab_obs, metab_dtd, vls = c('meanPg', 'sdPg', 'anomPg', 'meanRt', 'sdRt', 'anomRt')){

  eval <- list(
    obseval = meteval(metab_obs, all = F),
    dtdeval = meteval(metab_dtd, all = F)
  ) %>%
    tibble::enframe('metdat', 'fitdat') %>%
    tidyr::unnest('fitdat') %>%
    tidyr::gather('name', 'value', -metdat) %>%
    dplyr::filter(name %in% vls) %>%
    tidyr::unnest('value') %>%
    tidyr::spread(metdat, value)

  # Improved percent difference calculation with numerical stability
  eval <- eval %>%
    dplyr::mutate(
      # Add small epsilon to prevent division by zero
      eps = 1e-10,

      # More stable percent difference calculation
      perdif = dplyr::case_when(
        # For means: use log ratio which is more stable
        name %in% c('meanPg', 'meanRt') ~ {
          abs_obs <- abs(obseval) + eps
          abs_dtd <- abs(dtdeval) + eps
          -abs(log(abs_obs / abs_dtd))  # Negative because we want similar means
        },

        # For anomalies: we want dtd to have fewer anomalies (lower values)
        name %in% c('anomPg', 'anomRt') ~ dtdeval - obseval,

        # For standard deviations: we want dtd to have lower variability
        name %in% c('sdPg', 'sdRt') ~ dtdeval - obseval,

        TRUE ~ 0
      ),

      # Apply weights if desired (can be adjusted based on importance)
      weight = dplyr::case_when(
        name %in% c('anomPg', 'anomRt') ~ 1.0,  # Weight anomalies more heavily
        name %in% c('meanPg', 'meanRt') ~ 1.0,  # Moderate weight for means
        name %in% c('sdPg', 'sdRt') ~ 1.0,      # Standard weight for SDs
        TRUE ~ 1.0
      ),

      weighted_perdif = perdif * weight
    )

  # Return weighted sum (no need for -1 multiplication if directions are correct)
  est <- sum(eval$weighted_perdif, na.rm = TRUE)

  # Add penalty for extreme parameter values to encourage reasonable solutions
  return(est)

}
