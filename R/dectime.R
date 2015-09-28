#' Create decimal time using day on a 24 hour scale
#'
#' Create decimal time using day on a 24 hour scale in prep for weighted regression
#'
#' @param dat_in data frame input with time vector as posix, must be preprocessed with \code{\link{met_day_fun}}
#' @import plyr
#'
dectime <- function(dat_in){

  # get decimal value by metabolic date for hour/min
  by_met <- dlply(dat_in,
    .variables = 'met.date',
    .fun = function(x){

      strt <- (48 - nrow(x))/48
      out <- seq(strt, 1, length = 1 + nrow(x))
      out <- out[1:(length(out) - 1)]

      out

      }
    )

  # get continuous day value
  days <- as.character(seq(1:(length(by_met))) - 1)
  names(by_met) <- days
  by_met <- reshape2::melt(by_met)
  by_met$L1 <- as.numeric(by_met$L1)

  # add continuous day value to decimal value
  out <- rowSums(by_met)

  # add to dat_in
  dat_in$dec_time <- out

  return(dat_in)

  }
