#' Plot ecosystem metabolism results
#'
#' Plot gross production, total respiration, and net ecosystem metabolism for different time period aggregations.
#'
#' @param x input object to plot
#' @param by chr string describing aggregation period, passed to \code{\link{aggregate}}. See details for accepted values.
#' @param alpha numeric indicating alpha level for confidence intervals in aggregated data. Use \code{NULL} to remove from the plot.
#' @param width numeric indicating width of top and bottom segments on error bars
#' @param pretty logical indicating use of predefined plot aesthetics
#'
#' @import ggplot2
#'
#' @export
#'
#' @details
#' Daily metabolism estimates are aggregated into weekly averages by default.  Accepted aggregation periods are \code{'years'}, \code{'quarters'}, \code{'months'}, \code{'weeks'}, and \code{'days'} (if no aggregation is preferred).
#'
#' By default, \code{pretty = TRUE} will return a \code{\link[ggplot2]{ggplot}} object with predefined aesthetics.  Setting \code{pretty = FALSE} will return the plot with minimal modifications to the \code{\link[ggplot2]{ggplot}} object.  Use the latter approach for easier customization of the plot.
#'
#' @return
#' A \code{\link[ggplot2]{ggplot}} object which can be further modified.
#'
#' @seealso
#' \code{\link{ecometab}}
#'
#' @rdname ecometab
#'
#' @method plot metab
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
#' ## plot
#' plot(metab)
#'
#' ## change alpha, aggregation period, widths
#' plot(metab, by = 'quarters', alpha = 0.1, widths = 0)
#'
#' ## plot daily raw, no aesthetics
#' plot(metab, by = 'days', pretty = FALSE)
#' }
plot.metab <- function(x, by = 'months', metab_units = 'mmol', alpha = 0.05, width = 10, pretty = TRUE, ...){

  # stop if units not mmol or grams
  if(any(!(grepl('mmol|grams', metab_units))))
    stop('Units must be mmol or grams')

  # aggregate metab results by time period
  to_plo <- aggregate(x, by = by, alpha = alpha)

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
