#' @param na.action function for treating missing data, default \code{na.pass}
#'
#' @import data.table
#'
#' @export
#'
#' @importFrom stats na.omit na.pass qt sd
#'
#' @details The aggregate method summarizes metabolism data by averaging across set periods of observation. Confidence intervals are also returned based on the specified alpha level.  It is used within the \code{\link{plot}} function to view summarized metabolism results.  Data can be aggregated by \code{'years'}, \code{'quarters'}, \code{'months'}, or \code{'weeks'} for the supplied function, which defaults to the \code{\link[base]{mean}}.
#'
#' @return Returns an aggregated metabolism \code{\link[base]{data.frame}}.
#'
#' @seealso \code{\link[stats]{aggregate}}, \code{\link{ecometab}}
#'
#' @rdname ecometab
#'
#' @method aggregate metab
#'
#' @examples
#' \dontrun{
#' ## import sample data
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
#' ## change aggregation period and alpha
#' aggregate(metab, by = 'months', alpha = 0.1)
#' }
aggregate.metab <- function(x, by = 'weeks', na.action = na.pass, alpha = 0.05, ...){

  # sanity checks
  if(!by %in% c('years', 'quarters', 'months', 'weeks', 'days'))
    stop('Unknown value for by, see help documentation')

  # data
  to_agg <- x
  to_agg <- to_agg[, names(to_agg) %in% c('Date', 'Pg', 'Rt', 'NEM')]

  # create agg values from Date
  if(by != 'days'){
    to_agg$Date <- round(
      data.table::as.IDate(to_agg$Date),
      digits = by
    )
    to_agg$Date <- base::as.Date(to_agg$Date)
  }

  # long-form
  to_agg <- reshape2::melt(to_agg, measure.vars = c('Pg', 'Rt', 'NEM'))
  names(to_agg) <- c('Date', 'Estimate', 'Value')
  to_agg$Estimate <- as.character(to_agg$Estimate)

  # aggregate
  sum_fun <- function(x, alpha_in = alpha){
      x <- na.omit(x)
      means <- mean(x)
      margs <- suppressWarnings(
        qt(1 - alpha_in/2, length(x) - 1) * sd(x)/sqrt(length(x))
      )
      upper <- means + margs
      lower <- means - margs

      return(c(means, upper, lower))
    }
  aggs <- stats::aggregate(Value ~ Date + Estimate, to_agg,
    FUN = function(x) sum_fun(x, alpha_in = alpha))
  aggs_vals <- data.frame(aggs[, 'Value'])
  names(aggs_vals) <- c('means', 'lower', 'upper')
  aggs <- data.frame(aggs[, c('Date', 'Estimate')], aggs_vals)

  # return output
  return(aggs)

}
