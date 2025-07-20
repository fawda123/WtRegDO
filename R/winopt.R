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
#' @return Printed text to the console showing progress.  Output from \code{\link[stats]{optim}} will also be returned if convergence is achieved.
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
# Improved optimization wrapper with better error handling
winopt <- function(dat_in, tz, lat, long, wins,
                            vls = c('meanPg', 'sdPg', 'anomPg', 'meanRt', 'sdRt', 'anomRt'),
                            parallel = FALSE, progress = TRUE,
                            control = list(factr = 1e7, parscale = c(1, 1, 1)),
                            lower = c(0.1, 0.1, 0.1),
                            upper = c(12, 12, 1)) {

  # Estimate ecosystem metabolism using observed DO time series
  metobs <- ecometab(dat_in, DO_var = 'DO_obs', tz = tz, lat = lat, long = long)

  strt <- Sys.time()

  # Wrapper function with error handling and bounds checking
  safe_objfun <- function(pars) {
    tryCatch({
      # Ensure parameters are within bounds
      pars <- pmax(pars, lower)
      pars <- pmin(pars, upper)

      result <- wtobjfun(pars, dat_in = dat_in, tz = tz, lat = lat, long = long,
                         metab_obs = metobs, strt = strt, vls = vls,
                         parallel = parallel)

      # Check for invalid results
      if (is.na(result) || is.infinite(result)) {
        return(1e6)  # Large penalty for invalid results
      }

      return(result)

    }, error = function(e) {
      if (progress) {
        cat("Error in objective function:", e$message, "\n")
      }
      return(1e6)  # Large penalty for errors
    })
  }

  # Try multiple optimization methods in sequence
  methods_to_try <- c('L-BFGS-B', 'Nelder-Mead', 'BFGS')

  best_result <- NULL
  best_value <- Inf

  if(progress)
    sink('log.txt', append = T)
  for (opt_method in methods_to_try) {
    cat("Trying optimization method:", opt_method, "\n")

    # Adjust control parameters based on method
    current_control <- control
    if (opt_method == 'Nelder-Mead') {
      # Nelder-Mead doesn't use gradients, may be more robust
      current_control <- list(maxit = 500, reltol = 1e-8)
    }
    try_result <- tryCatch({
      if (opt_method %in% c('L-BFGS-B')) {
        print(Sys.time() - strt)
        optim(wins, safe_objfun, method = opt_method,
              lower = lower, upper = upper, control = current_control)
      } else {
        print(Sys.time() - strt)
        optim(wins, safe_objfun, method = opt_method, control = current_control)
      }
    }, error = function(e) {
      cat("Method", opt_method, "failed:", e$message, "\n")
      return(NULL)
    })

    if (!is.null(try_result) && try_result$value < best_value) {
      best_result <- try_result
      best_value <- try_result$value
      cat("New best result with", opt_method, "- value:", best_value, "\n")
    }

    # If we found a good solution, we can stop
    if (!is.null(best_result) && best_result$convergence == 0) {
      cat("Convergence achieved with", opt_method, "\n")
      break
    }
  }
  if(progress)
    sink()

  return(best_result)
}
