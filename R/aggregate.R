#' Aggregete metabolism data
#'
#' Aggregate metabolism data for a metab object
#'
#' @param x input data object as returned by \code{\link{ecometab}}
#' @param by character string indicating aggregation period or numeric value indicating moving window width for daily averages
#' @param alpha level for estimating confidence intervals in aggregated data
#' @param na.action function for treating missing data, default \code{na.pass}
#' @param ... arguments passed to or from other methods
#'
#' @import data.table
#'
#' @importFrom stats na.omit na.pass qt sd
#'
#' @method aggregate metab
aggregate.metab <- function(x, by = 'weeks', na.action = 'na.pass', alpha = 0.05, ...){

  # data
  to_agg <- x
  to_agg <- to_agg[, names(to_agg) %in% c('Date', 'Pg', 'Rt', 'NEM')]

  if(inherits(by, 'character')){

    # sanity checks
    if(!by %in% c('years', 'quarters', 'months', 'weeks', 'days'))
      stop('Unknown value for by, see help documentation')

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
      FUN = function(x) sum_fun(x, alpha_in = alpha), na.action = na.action)
    aggs_vals <- data.frame(aggs[, 'Value'])
    names(aggs_vals) <- c('val', 'lower', 'upper')
    aggs <- data.frame(aggs[, c('Date', 'Estimate')], aggs_vals)

  # use moving window average if by argument is numeric
  } else {

    # stop if not numeric
    if(!inherits(by, c('numeric', 'integer')))
      stop('By argument must be character string of aggregation period or numeric indicating number of days')

    # use smoother default method
    aggs <- smoother(to_agg[, c('Pg', 'Rt', 'NEM')], window = by, ...)
    aggs <- data.frame(Date = to_agg$Date, aggs)

    # long format
    aggs <- reshape2::melt(aggs, measure.vars = c('Pg', 'Rt', 'NEM'))
    names(aggs) <- c('Date', 'Estimate', 'val')

  }

  # return output
  return(aggs)

}
