#' Calculate oxygen mass transfer coefficient
#'
#' Calculate oxygen mass transfer coefficient using equations in Thiebault et al. 2008.  Output is used to estimate the volumetric reaeration coefficient for ecosystem metabolism.
#'
#' @param Temp numeric for water temperature (C)
#' @param Sal numeric for salinity (ppt)
#' @param ATemp numeric for air temperature (C)
#' @param WSpd numeric for wind speed (m/s)
#' @param BP numeric for barometric pressure (mb)
#' @param Height numeric for height of anemometer (meters)
#'
#' @import oce
#'
#' @export
#'
#' @details
#' This function is used within the \code{\link{ecometab}} function and should not be used explicitly.
#'
#' @references
#' Ro KS, Hunt PG. 2006. A new unified equation for wind-driven surficial oxygen transfer into stationary water bodies. Transactions of the American Society of Agricultural and Biological Engineers. 49(5):1615-1622.
#'
#' Thebault J, Schraga TS, Cloern JE, Dunlavey EG. 2008. Primary production and carrying capacity of former salt ponds after reconnection to San Francisco Bay. Wetlands. 28(3):841-851.
#'
#' @seealso
#' \code{\link{ecometab}}
f_calcKL <- function(Temp, Sal, ATemp, WSpd, BP, Height = 10){

  #celsius to kelvin conversion
  CtoK<-function(val) val+273.15
  sig.fun<-Vectorize(swSigmaT)

  to.vect<-function(Temp,Sal,ATemp,WSpd,BP,Height=10){

    Patm<-BP*100; # convert from millibars to Pascals
    zo<-1e-5; # assumed surface roughness length (m) for smooth water surface
    U10<-WSpd*log(10/zo)/log(Height/zo)
    TempK<-CtoK(Temp)
    ATempK<-CtoK(ATemp)
    sigT<-sig.fun(Sal,Temp,10) # set for 10 decibars = 1000mbar = 1 bar = 1atm
    rho_w<-1000+sigT #density of SW (kg m-3)
    Upw<-1.002e-3*10^((1.1709*(20-Temp)-(1.827*10^-3*(Temp-20)^2))/(Temp+89.93)) #dynamic viscosity of pure water (Sal=0);
    Uw<-Upw*(1+(5.185e-5*Temp+1.0675e-4)*(rho_w*Sal/1806.55)^0.5+(3.3e-5*Temp+2.591e-3)*(rho_w*Sal/1806.55))  # dynamic viscosity of SW
    Vw<-Uw/rho_w  #kinematic viscosity
    Ew<-6.112*exp(17.65*ATemp/(243.12+ATemp))  # water vapor pressure (hectoPascals)
    Pv<-Ew*100 # Water vapor pressure in Pascals
    Rd<-287.05  # gas constant for dry air ( kg-1 K-1)
    Rv<-461.495  # gas constant for water vapor ( kg-1 K-1)
    rho_a<-(Patm-Pv)/(Rd*ATempK) +Pv/(Rv*TempK)
    kB<-1.3806503e-23 # Boltzman constant (m2 kg s-2 K-1)
    Ro<-1.72e-10     #radius of the O2 molecule (m)
    Dw<-kB*TempK/(4*pi*Uw*Ro)  #diffusivity of O2 in water
    KL<-0.24*170.6*(Dw/Vw)^0.5*(rho_a/rho_w)^0.5*U10^1.81  #mass xfer coef (m d-1)

    return(KL)

    }

  out.fun<-Vectorize(to.vect)

  out.fun(Temp,Sal,ATemp,WSpd,BP,Height=10)

  }
