#' An objective function to minimize plus weighted regression for finding optimal window widths
#'
#' @param wins list of half-window widths to use in the order specified by \code{\link{wtfun}} (i.e., days, hours, tide height).
#' @param dat_in input data frame
#' @param tz chr string specifying timezone of location, e.g., 'America/Jamaica' for EST, no daylight savings, must match the time zone in \code{dat_in$DateTimeStamp}
#' @param lat numeric for latitude of location
#' @param long numeric for longitude of location (negative west of prime meridian)
#' @param metab_obs A \code{metab} object returned by \code{\link{ecometab}} based on the observed DO time series in \code{dat_in}, used as comparison for the objective function
#' @param strt a \code{\link{POSIXct}} object returned by \code{\link{Sys.time}}
#' @param vls chr vector of summary evaluation object to optimize, see details for \code{\link{objfun}}
#' @param parallel logical if regression is run in parallel to reduce processing time, requires a parallel backend outside of the function
#'
#' @seealso \code{\link{objfun}}, \code{\link{winopt}}
#'
#' @return A single numeric value to minimize, as output from \code{\link{objfun}}
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
#' metobs <- ecometab(SAPDC, DO_var = 'DO_obs', tz = tz, lat = lat, long = long)
#'
#' ncores <- detectCores()
#' cl <- makeCluster(ncores)
#' registerDoParallel(cl)
#'
#' wtobjfun(SAPDC, tz = tz, lat = lat, long = long, metab_obs = metobs, strt = Sys.time(),
#'    wins = list(6, 6, 0.5), parallel = T)
#'
#' stopCluster(cl)
#' }
wtobjfun <- function(wins, dat_in, tz, lat, long, metab_obs, strt = NULL, vls = c('meanPg', 'sdPg', 'anomPg', 'meanRt', 'sdRt', 'anomRt'),
                      parallel = F){

  if(is.null(strt))
    strt <- Sys.time()

  txt <- unlist(wins)
  print(Sys.time() - strt)
  cat(txt, '\n')

  wtreg_res <- wtreg(dat_in, parallel = parallel, wins = wins, progress = F,
                     tz = tz, lat = lat, long = long)

  metab_dtd <- ecometab(wtreg_res, DO_var = 'DO_nrm', tz = tz,
                        lat = lat, long = long)

  out <- objfun(metab_obs, metab_dtd, vls = vls)

  cat(out, '\n\n')

  return(out)

}
