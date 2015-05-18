######
# get predicted, normalized values not using interp grid, tide as predictor
# 'dat_in' is raw data used to create 'grd_in' and used to get predictions
# 'DO_obs' is string indicating name of col for observed DO values from 'dat_in'
# output is data frame same as 'dat_in' but includes predicted and norm columns
wtreg <- function(dat_in, DO_obs = 'DO_obs', wins = list(4, 12, NULL),
  parallel = F, progress = F){

  # get mean tidal height from empirical data
  mean_tide <- mean(dat_in$Tide)

  #for counter
  strt <- Sys.time()

  out <- ddply(dat_in,
    .variable = 'DateTimeStamp',
    .parallel = parallel,
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
      ref_wts <- wt_fun(ref_in, dat_in, wins = wins, slice = T,
        subs_only = T, wt_vars = c('dec_time', 'hour', 'Tide'))

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
