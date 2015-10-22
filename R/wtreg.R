#' Weighted regression for dissolved oxygen time series
#'
#' Use weighted regression to reduce effects of tidal advection on dissolved oxygen time series
#'
#' @param dat_in input data frame
#' @param DO_obs name of dissolved oxygen column
#' @param wins list of half-window widths to use in the order specified by \code{\link{wtfun}} (i.e., days, hours, tide height).
#' @param progress logical if progress saved to a txt file names 'log.txt' in the working directory
#' @param parallel logical if regression is run in parallel to reduce processing time, requires a parallel backend outside of the function
#' @param ... additional arguments passed to \code{\link{met_day_fun}}, particularly timezone, lat, and long information.
#'
#' @export
#'
#' @import plyr
#'
#' @details See the supplied dataset for required input data
#'
#' @return The original data frame with additional columns describing the metabolic day, decimal time, predicted DO from weighted regression (\code{DO_prd}) and detided (normalized) DO from weighted regression (\code{DO_nrm}).
#'
#' @examples
#' \dontrun{
#' ## import data
#' data(SAPDC)
#'
#' res <- wtreg(SAPDC)
#'
#' }
wtreg <- function(dat_in, DO_obs = 'DO_obs', wins = list(4, 12, NULL),
  progress = FALSE, parallel = FALSE, ...){

  # get mean tidal height from empirical data
  mean_tide <- mean(dat_in$Tide)

  # get decimal time based on metabolic days
  dat_in <- met_day_fun(dat_in,  ...)
  dat_in <- dectime(dat_in)

  # add hour column
  dat_in$hour <- as.numeric(format(dat_in$DateTimeStamp, '%H')) +
    as.numeric(format(dat_in$DateTimeStamp, '%M'))/60

  #for counter
  strt <- Sys.time()

  out <- ddply(dat_in,
    .variables = 'DateTimeStamp',
    .parallel = parallel,
    .paropts = list(.export = 'wtfun', .packages = 'WtRegDO'),
    .fun = function(row){

      # row for prediction
      ref_in <- row
      ref_in <- ref_in[rep(1, 2),]
      ref_in$Tide <- c(unique(ref_in$Tide), mean_tide)

      # progress
      if(progress){
        prog <- which(row$DateTimeStamp == dat_in$DateTimeStamp)
        sink('log.txt')
        cat('Log entry time', as.character(Sys.time()), '\n')
        cat(prog, ' of ', nrow(dat_in), '\n')
        print(Sys.time() - strt)
        sink()
        }

      # get wts
      ref_wts <- wtfun(ref_in, dat_in, wins = wins, slice = TRUE,
        subs_only = TRUE, wt_vars = c('dec_time', 'hour', 'Tide'))

      #OLS wtd model
      out <- lapply(1:length(ref_wts),
        function(x){

          # subset data for weights > 0
          dat_proc <- dat_in[as.numeric(names(ref_wts[[x]])),]

          # if no DO values after subset, return NA
          # or if observed DO for the row is NA, return NA
          if(sum(is.na(dat_proc$DO_obs)) == nrow(dat_proc)|
              any(is.na((ref_in$DO_obs)))){

            DO_pred <- NA
            beta <- NA
            Tide <- ref_in$Tide[x]

            } else {

              # subset weigths > 0, rescale weights average
              ref_wts <- ref_wts[[x]]/mean(ref_wts[[x]])

              # get model
              mod_md <- lm(
                DO_obs ~ dec_time + Tide, # + sin(2*pi*dec_time) + cos(2*pi*dec_time),
                weights = ref_wts,
                data = dat_proc
                )

              # get prediction from model
              Tide <- ref_in$Tide[x]
              DO_pred <- predict(
                mod_md,
                newdata = data.frame(dec_time = ref_in$dec_time[x], Tide = Tide)
                )

              # get beta from model
              beta <- mod_md$coefficients['Tide']

            }

          # output
          DO_pred

          }

        )

      out <- unlist(out)
      names(out) <- c('DO_prd', 'DO_nrm')
      out

      })

  out$DateTimeStamp <- NULL
  out <- cbind(dat_in, out)

  return(out)

  }