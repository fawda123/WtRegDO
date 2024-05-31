#' Calculate climate means for relevant weather variables
#'
#' Calculate climate means for relevant weather variables
#'
#' @param dat_in Input data frame as a similar format required for \code{\link{ecometab}}
#' @param gasex chr indicating if gas exchange is estimated using equations in Thiebault et al. 2008 or Wanninkhof 2014 (see \code{\link{f_calcKL}} or \code{\link{f_calcWanninkhof}})
#'
#' @details Function is used internally within \code{\link{ecometab}}.  Missing values for weather variables are replaced by the monthly/hourly average calculated from the available data in \code{dat_in}.  If \code{gasex = 'Thiebault'}, this applies to air temperature, wind speed, and barometric pressure.  If \code{gasex = 'Wanninkhof'}, this applies only to wind speed.
#'
#' @return The same data frame as in \code{dat_in}, except missing values for the relevant weather variables are replaced with estimated means.
#'
#' @export
#'
#' @examples
#' climmeans(SAPDC)
climmeans <- function(dat_in, gasex = c('Thiebault', 'Wanninkhof')){

  gasex <- match.arg(gasex)

  if(gasex == 'Thiebault'){

    # monthly and hourly averages
    months <- format(dat_in$DateTimeStamp, '%m')
    hours <- format(dat_in$DateTimeStamp, '%H')
    clim_means <- ddply(data.frame(dat_in, months, hours),
                        .variables=c('months', 'hours'),
                        .fun = function(x){
                          data.frame(
                            ATemp = mean(x$ATemp, na.rm = TRUE),
                            WSpd = mean(x$WSpd, na.rm = TRUE),
                            BP = mean(x$BP, na.rm = TRUE)
                          )
                        }
    )
    clim_means <- merge(
      data.frame(DateTimeStamp = dat_in$DateTimeStamp, months,hours),
      clim_means, by = c('months','hours'),
      all.x = TRUE
    )
    clim_means <- clim_means[order(clim_means$DateTimeStamp),]

    # reassign empty values to means, objects are removed later
    ATemp_mix <- dat_in$ATemp
    WSpd_mix <- dat_in$WSpd
    BP_mix <- dat_in$BP
    ATemp_mix[is.na(ATemp_mix)] <- clim_means$ATemp[is.na(ATemp_mix)]
    WSpd_mix[is.na(WSpd_mix)] <- clim_means$WSpd[is.na(WSpd_mix)]
    BP_mix[is.na(BP_mix)] <- clim_means$BP[is.na(BP_mix)]

    # assign climate mean values to input data
    dat_in$BP <- BP_mix
    dat_in$ATemp <- ATemp_mix
    dat_in$WSpd <- WSpd_mix

  }

  if(gasex == 'Wanninkhof'){

    # monthly and hourly averages
    months <- format(dat_in$DateTimeStamp, '%m')
    hours <- format(dat_in$DateTimeStamp, '%H')
    clim_means <- ddply(data.frame(dat_in, months, hours),
                        .variables=c('months', 'hours'),
                        .fun = function(x){
                          data.frame(
                            WSpd = mean(x$WSpd, na.rm = TRUE),
                            BP = mean(x$BP, na.rm = TRUE) # not used by wanninkhof but required for oxysol
                          )
                        }
    )
    clim_means <- merge(
      data.frame(DateTimeStamp = dat_in$DateTimeStamp, months,hours),
      clim_means, by = c('months','hours'),
      all.x = TRUE
    )
    clim_means <- clim_means[order(clim_means$DateTimeStamp),]

    # reassign empty values to means, objects are removed later
    WSpd_mix <- dat_in$WSpd
    BP_mix <- dat_in$BP
    WSpd_mix[is.na(WSpd_mix)] <- clim_means$WSpd[is.na(WSpd_mix)]
    BP_mix[is.na(BP_mix)] <- clim_means$BP[is.na(BP_mix)]


    # assign climate mean values to input data
    dat_in$BP <- BP_mix
    dat_in$WSpd <- WSpd_mix

  }

  out <- dat_in

  return(out)

}
