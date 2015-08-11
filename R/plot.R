#' @param x input object to plot
#' @param by chr string describing aggregation period, passed to \code{\link{aggregate}}. See details for accepted values.
#' @param alpha numeric indicating alpha level for confidence intervals in aggregated data. Use \code{NULL} to remove from the plot.
#' @param width numeric indicating width of top and bottom segments on error bars
#' @param pretty logical indicating use of predefined plot aesthetics
#' @param ... arguments passed to or from other methods
#'
#' @import ggplot2
#'
#' @export
#'
#' @rdname ecometab
#'
#' @method plot metab
plot.metab <- function(x, by = 'months', metab_units = 'mmol', alpha = 0.05, width = 10, pretty = TRUE, ...){

  # stop if units not mmol or grams
  if(any(!(grepl('mmol|grams', metab_units))))
    stop('Units must be mmol or grams')

  # aggregate metab results by time period
  if(!is.null(alpha)){
    to_plo <- aggregate(x, by = by, alpha = alpha)
  } else {
    to_plo <- aggregate(x, by = by, alpha = 0.05)
  }

  ## base plot
  p <- ggplot(to_plo, aes_string(x = 'Date', y = 'means', group = 'Estimate')) +
    geom_line()

  # add bars if not days and alpha not null
  if(by != 'days' & !is.null(alpha))
    p <- p +
      geom_errorbar(
        aes_string(ymin = 'lower', ymax = 'upper', group = 'Estimate'),
      width = width)

  # return blank
  if(!pretty)
    return(p)

  # ylabs
  ylabs <- expression(paste('mmol ', O [2], ' ', m^-2, d^-1))
  if(metab_units == 'grams')
    ylabs <- expression(paste('g ', O [2], ' ', m^-2, d^-1))

  p <- p +
    geom_line(aes_string(colour = 'Estimate')) +
    geom_point(aes_string(colour = 'Estimate')) +
    theme_bw() +
    theme(axis.title.x = element_blank()) +
    scale_y_continuous(ylabs)

  if(by != 'days' & !is.null(alpha))
    p <- p +
      geom_errorbar(aes_string(ymin = 'lower', ymax = 'upper',
        colour = 'Estimate', group = 'Estimate'), width = width)

  return(p)

}
