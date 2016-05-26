#' Get weights used during weighted regression
#'
#' Get weights used during weighted regression for a single observation in the dissolved oxygen time series
#'
#' @param ref_in one row of the data frame of \code{dat_in} that is teh center of the window
#' @param dat_in data frame for estimating weights
#' @param wt_vars chr string indicating names of weighting variables
#' @param wins numeric vecotr for windows for the three wt variables, values represent halves.  A \code{NULL} value for Tide specifies the half-window width is set automatically to one half the tidal range.
#' @param all logical to return all weights, rather than the product of all three
#' @param slice logical for subsetting \code{dat_in} for faster wt selection
#' @param subs_only logical for returning only wt vectors that are non-zero
#'
#' @export
#'
#' @details The default behavior is to subset the data frame for faster wt selection by limiting the input the maximum window size.  Subsetted weights are recombined to equal a vector of length equal to the original data.
#'
#' @seealso \code{\link{wtreg}}
wtfun <- function(ref_in, dat_in,
  wt_vars = c('dec_time', 'hour', 'Tide'),
  wins = list(4, 12, NULL),
  all = FALSE,
  slice = TRUE,
  subs_only = FALSE){

  # sanity check
  if(sum(wt_vars %in% names(dat_in)) != length(wt_vars))
    stop('Weighting variables must be named in "dat_in"')

  # windows for each of three variables
  wins_1<-wins[[1]]
  wins_2<-wins[[2]]
  wins_3<-wins[[3]]

  # default window width for third variable is half its range
  if(is.null(wins[[3]])) wins_3 <- diff(range(dat_in[, wt_vars[3]]))/2

  # weighting tri-cube function
  # mirror extends weighting function if vector repeats, e.g. monthly
  # 'dat_cal' is observation for weight assignment
  # 'ref' is reference observation for fitting the model
  # 'win' is window width from above (divided by two)
  # 'mirr' is logical indicating if distance accounts for repeating variables (e.g., month)
  # 'scl_val' is range for the ref vector of obs, used to get correct distance for mirrored obs
  wt_fun_sub <- function(dat_cal, ref, win, mirr = FALSE, scl_val = 1){

    # dist_val is distance of value from the ref
    dist_val <- sapply(ref, function(x) abs(dat_cal - x))

    # repeat if distance is checked on non-continuous number line
    if(mirr){

        dist_val <- pmin(
          sapply(ref, function(x)
            abs(x + scl_val - dat_cal)),
          sapply(ref, function(x) abs(dat_cal + scl_val - x)),
          dist_val
          )

      }

    # get wts within window, otherwise zero
    win_out <- dist_val > win
    dist_val <- (1 - (dist_val/win)^3)^3
    dist_val[win_out] <- 0

    return(dist_val)

    }

  #reference (starting) data
  ref_1 <- as.numeric(ref_in[, wt_vars[1]])
  ref_2 <- as.numeric(ref_in[, wt_vars[2]])
  ref_3 <- as.numeric(ref_in[, wt_vars[3]])

  ##
  # subset 'dat_in' by max window size for faster calc
  # this is repeated if min number of wts > 0 is not met
  # subset vector is all TRUE if not using subset
  dec_rng <- range(dat_in$dec_time)
  ref_time <- unique(ref_in$dec_time)
  dec_sub <- with(dat_in,
    dec_time >
      ref_time - wins_1 * 5 & dec_time < ref_time + wins_1 * 5
    )
  if(!slice) dec_sub <- rep(TRUE, length = nrow(dat_in))
  dat_sub <- dat_in[dec_sub, ]

  ##
  # weights for each observation in relation to reference
  # see comments for 'wt_fun_sub' for 'scl_val' argument

  # jday
  wts_1 <- wt_fun_sub(as.numeric(dat_sub[, wt_vars[1]]),
    ref = ref_1, win = wins_1, mirr = FALSE)
  # hour
  wts_2 <- wt_fun_sub(as.numeric(dat_sub[, wt_vars[2]]),
    ref = ref_2, win = wins_2, mirr = TRUE, scl_val = 24)
  # tide
  wts_3 <- wt_fun_sub(as.numeric(dat_sub[, wt_vars[3]]),
    ref = ref_3, win = wins_3, mirr = FALSE)
  # all as product
  out <- sapply(1:nrow(ref_in), function(x) wts_1[, x] * wts_2[, x] * wts_3[, x])

  gr_zero <- colSums(out > 0, na.rm = TRUE)
  #cat('   Number of weights greater than zero =',gr.zero,'\n')

  # extend window widths of weight vector is less than 100
  while(any(gr_zero < 100)){

    # increase window size by 10%
    wins_1 <- 1.1 * wins_1
    wins_2 <- 1.1 * wins_2
    wins_3 <- 1.1 * wins_3

    # subset again
    dec_sub <- with(dat_in,
      dec_time > ref_time - wins_1 * 5 & dec_time < ref_time + wins_1 * 5
      )
    if(!slice) dec_sub <- rep(TRUE, length = nrow(dat_in))
    dat_sub <- dat_in[dec_sub, ]

    #weights for each observation in relation to reference
    wts_1 <- wt_fun_sub(as.numeric(dat_sub[, wt_vars[1]]),
      ref = ref_1, win = wins_1, mirr = FALSE)
    wts_2 <- wt_fun_sub(as.numeric(dat_sub[, wt_vars[2]]),
      ref = ref_2, win = wins_2, mirr = TRUE, scl_val = 24)
    wts_3 <- wt_fun_sub(as.numeric(dat_sub[, wt_vars[3]]),
      ref = ref_3, win = wins_3, mirr = FALSE)

    out <- sapply(1:nrow(ref_in),
      function(x) wts_1[, x] * wts_2[, x] * wts_3[, x])

    gr_zero <- colSums(out > 0)

    }

  if(subs_only){

    nms <- which(dec_sub)
    out <- alply(out, 2, function(x) {

      to_sel <- x > 0
      tmp <- x[to_sel]
      names(tmp) <- which(dec_sub)[to_sel]
      tmp

      })

    return(out)

    }

  # extend weight vectors to length of dat_in
  empty_mat <- matrix(0, ncol = nrow(ref_in), nrow = nrow(dat_in))
  empty_fill <- function(wts_in) {
    out <- empty_mat
    out[dec_sub,] <- wts_in
    out
    }
  wts_1 <- empty_fill(wts_1)
  wts_2 <- empty_fill(wts_2)
  wts_3 <- empty_fill(wts_3)
  out <- empty_fill(out)

  #return all weights if TRUE
  if(all){
    out <- data.frame(dat_in$DateTimeStamp,
      wts_1, wts_2, wts_3, out)
    names(out) <- c('DateTimeStamp', wt_vars, 'final')
    return(out)
    }

  #final weights are product of all three
  out

  }
