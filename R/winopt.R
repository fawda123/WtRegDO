#' Find the optimal half-window width combination
#'
#' Find the optimal half-window width combination to use for weighted regression.
#'
#' @param dat_in input data frame
#' @param tz chr string specifying timezone of location, e.g., 'America/Jamaica' for EST, no daylight savings, must match the time zone in \code{dat_in$DateTimeStamp}
#' @param lat numeric for latitude of location
#' @param long numeric for longitude of location (negative west of prime meridian)
#' @param wins list of half-window widths to use in the order specified by \code{\link{wtfun}} (i.e., days, hours, tide height).
#' @param vls chr vector of summary evaluation object to optimize, see details for \code{\link{objfun}}
#' @param parallel logical if regression is run in parallel to reduce processing time, requires a parallel backend outside of the function
#' @param progress logical if progress saved to a txt file names 'log.txt' in the working directory,
#' @param control A list of control parameters passed to \code{\link[stats]{optim}} (see details in \code{\link[stats]{optim}} help file).  The value passed to \code{factr} controls the convergence behavior of the \code{"L-BFGS-B"} method.  Values larger than the default will generally speed up the optimization with a potential loss of precision. \code{parscale} describes the scaling values of the parameters.
#' @param lower vector of minimum half-window widths to evaluate
#' @param upper vector of maximum half-window widths to evaluate
#'
#' @details
#' This is a super sketchy function based on many assumptions, see details in \code{\link{objfun}}
#'
#' @seealso \code{\link{objfun}}, \code{\link{wtobjfun}}
#'
#' @return
#' @export
#'
#' @examples
#' \dontrun{
#'
#' library(foreach)
#' library(doParallel)
#'
#' data(SAPDC)
#'
#' tz <- 'America/Jamaica'
#' lat <- 31.39
#' long <- -81.28
#'
#' ncores <- detectCores()
#' cl <- makeCluster(ncores)
#' registerDoParallel(cl)
#'
#' winopt(SAPDC, tz = tz, lat = lat, long = long, wins = list(6, 6, 0.5), parallel = T)
#'
#' stopCluster(cl)
#' }
winopt <- function(dat_in, tz, lat, long, wins, vls = c('meanPg', 'sdPg', 'anomPg', 'meanRt', 'sdRt', 'anomRt'), parallel = F, progress = T,
                    control = list(factr = 1e7, parscale = c(50, 100, 50)), lower = c(0.1, 0.1, 0.1), upper = c(12, 12, 1)){

  # estimate ecosystem metabolism using observed DO time series
  metobs <- ecometab(dat_in, DO_var = 'DO_obs', tz = tz,
                        lat = lat, long = long)

  strt <- Sys.time()

  out <- optim(
    wins,
    wtobjfun,
    gr = NULL,
    dat_in = dat_in,
    tz = tz,
    lat = lat,
    long = long,
    metab_obs = metobs,
    strt = strt,
    vls = vls,
    parallel = parallel,
    progress = progress,
    method = 'L-BFGS-B',
    lower = lower,
    upper = upper,
    control = control
  )

  return(out)

}
