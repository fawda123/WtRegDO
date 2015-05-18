#' Weighted regression for dissolved oxygen time series
#'
#' Use weighted regression to reduce effects of tidal advection on dissolved oxygen time series
#'
#' @param dat_in input data frame
#' @param DO_obs name of dissolved oxygen column
#' @param wins half-window widths to use
#' @param parallel logical if regression is run in parallel to reduce processing time
#'
#' @export
#'
#' @import dplyr
#'
#' @details See the supplied dataset for required input data
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
  parallel = FALSE, progress = FALSE){

  # get mean tidal height from empirical data
  mean_tide <- mean(dat_in$Tide)

  out <- ddply(dat_in,
    .variable = 'DateTimeStamp',
    .parallel = parallel,
    .fun = function(row){

      # row for prediction
      ref_in <- row
      ref_in <- ref_in[rep(1, 2),]
      ref_in$Tide <- c(unique(ref_in$Tide), mean_tide)

      # get wts
      ref_wts <- wt_fun(ref_in, dat_in, wins = wins, slice = TRUE,
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
