#' Evaluate metabolism results
#'
#' Evaluate metabolism results before and after weighted regression
#'
#' @param metab_in input \code{metab} object as returned from \code{\link{ecometab}}
#' @param all logical indicating if all evaluation summaries are returned or just mean, sd, and percent anomalies
#' @param ... additional arguments passed to other methods
#'
#' @details
#' This function provides summary statistics of metabolism results to evaluate the effectiveness of weighted regression.  These estimates are mean production, standard deviation of production, percent of production estimates that were anomalous, mean respiration, standard deviation of respiration, percent of respiration estimates that were anomalous, correlation of dissolved oxygen with tidal height changes, correlation of production with tidal height changes, and the correlation of respiration with tidal height changes.  The correlation estimates are based on an average of the correlations by each month in the time series from the raw data for dissolved oxygen and the daily results for the metabolic estimates.  Dissolved oxygen is correlated directly with tidal height at each time step.  The metabolic estimates are correlated with the tidal height ranges during the day for production and during the night for respiration.  Tidal height ranges are estimated from the raw data during each diurnal period for each metabolic day.
#'
#' In general, useful results for weighted regression are those that remove the correlation of dissolved oxygen, production, and respiration with tidal changes.  Similarly, the mean estimates of metabolism should not change if a long time series is evaluated, whereas the standard deviation and percent anomalous estimates should decrease.
#'
#' Tables 2 and 3 in Beck et al. 2015 were created using these methods.
#'
#' @return A two-element list of summary statistics for the complete period of record (\code{cmp}) and by month (\code{mos}).  The complete record summary has columns named \code{meanPg}, \code{sdPg}, \code{anomPg}, \code{meanRt}, \code{sdRt}, \code{anomRt}.  The monthly summary has \code{DOcor}, \code{Pgcor}, \code{Rtcor} for the correlations of each with the tidal cycle for the given month and \code{anomPg} and \code{anomRt} for the anomalous tallies of the metabolism estimates in each month.  See the details above for a meaning of each.
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
meteval <- function(metab_in, ...) UseMethod('meteval')

#' @rdname meteval
#'
#' @export
#'
#' @method meteval metab
meteval.metab <- function(metab_in, all = TRUE, ...){

  # get attributes
  toeval <- na.omit(metab_in)
  rawdat <- attr(metab_in, 'rawdat')
  depth_val <- attr(metab_in, 'depth_val')
  DO_var <- attr(metab_in, 'DO_var')

  # summarize metab data - means, sd, perc anoms
  out <- data.frame(
    meanPg = mean(toeval$Pg),
    sdPg = sd(toeval$Pg),
    anomPg = 100 * sum(toeval$Pg <= 0)/nrow(toeval),
    meanRt = mean(toeval$Rt),
    sdRt = sd(toeval$Rt),
    anomRt = 100 * sum(toeval$Rt >= 0)/nrow(toeval)
  )

  if(all){

    # exit if no tidal vector column
    if(is.null(depth_val)){
      warning('No tidal height column in raw data')
      return(out)
    }

    # DO obs v tide
    # correlations by month, then averaged
    # add month column
    rawdat$month <- strftime(rawdat$Date, '%m')
    DOcor<- plyr::ddply(
      rawdat,
      .variable = c('month'),
      .fun = function(x) cor.test(x[, DO_var], x[, depth_val])$estimate
    )
    names(DOcor)[2] <- 'DOcor'
    # DOcor <- mean(DOcor[, 'cor'], na.rm = TRUE)

    # get tidal range for metabolic day/night periods
    # for correlation with daily integrated metab
    tide_rngs <- plyr::ddply(rawdat,
      .variables = c('metab_date'),
      .fun = function(x){

        # mean tidal derivative for day hours
        sunrise <- mean(diff(x[x$solar_period %in% 'sunrise', 'Tide'],
          na.rm = T))

        # mean tidal derivative for night hours
        sunset <- mean(diff(x[x$solar_period %in% 'sunset', 'Tide'],
          na.rm = T))
        if(sunrise == 'Inf') sunrise <- NA
        if(sunset == 'Inf') sunset <- NA

        # mean tidal derivative for metabolic day
        daytot <- mean(diff(x$Tide, na.rm = T))

        c(daytot, sunrise, sunset)

        }
      )
    names(tide_rngs) <- c('Date','daytot', 'sunrise', 'sunset')

    # get metab data from list
    toeval <- merge(toeval, tide_rngs, by = 'Date', all.x = T)
    toeval$month <- strftime(toeval$Date, '%m')

    # Pg values correlated with tidal range during sunlight hours
    # Rt values correlated with tidal range during night hours
    # done separately for each month, then averaged
    metcor <- plyr::ddply(
        toeval,
        .variable = c('month'),
        .fun = function(x){

          with(x, c(
            Pgcor = try({cor.test(Pg, sunrise)$estimate}),
            Rtcor = try({cor.test(Rt, sunset)$estimate})
          ))

        }
      )
    names(metcor) <- gsub('\\.cor$', '', names(metcor))
    # metcor <- colMeans(metcor[, !names(metcor) %in% 'month'], na.rm = TRUE)

    # Pg, Rt anomalies by month
    anomPgRtmon <- plyr::ddply(
      toeval,
      .variable = c('month'),
      .fun = function(x){

        with(x, c(
          anomPgmon = 100 * sum(x$Pg <= 0)/nrow(x),
          anomRtmon = 100 * sum(x$Rt >= 0)/nrow(x)
        ))

      }
    )

    # combine monthly evals
    mos <- plyr::join(DOcor, metcor, by = 'month')
    mos <- plyr::join(mos, anomPgRtmon, by = 'month')

    # combine complete and monthly data
    out <- list(
      cmp = out,
      mos = mos
    )

  }

  return(out)

}
