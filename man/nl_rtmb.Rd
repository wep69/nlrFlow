\name{nl_rtmb}
\alias{nl_rtmb}
\title{Fit an RTMB automatic-differentiation objective}
\description{Builds an `RTMB::MakeADFun` objective from an R negative log-likelihood and, optionally, optimizes it with `stats::nlminb`. This is the low-level high- performance route for nonlinear likelihoods, latent variables, and random effects that are not covered by a dedicated nlrFlow backend.}
\usage{nl_rtmb(objective, parameters, random = NULL, optimize = TRUE, control = list(), silent = TRUE, ...)}
\arguments{
  \item{objective}{Function receiving the parameter list/vector and returning a}
  \item{parameters}{Named list or vector of starting parameter values.}
  \item{random}{Optional parameter names integrated by Laplace approximation.}
  \item{optimize}{Logical; optimize the objective after constructing the AD tape.}
  \item{control}{Control list passed to `stats::nlminb`.}
  \item{silent}{Logical passed to `RTMB::MakeADFun`.}
  \item{...}{Additional arguments passed to `RTMB::MakeADFun`.}
}
\value{An `nlr_rtmb_fit` object containing the AD function, optimizer output,}
\examples{
\dontrun{
# Agronomy: Gaussian nonlinear growth likelihood.
d <- subset(nl_data("agronomy_growth"), cultivar == "C1")
obj <- function(p) { mu <- p$A/(1+exp(-p$k*(d$day-p$tm))); -sum(dnorm(d$biomass_Mg_ha,mu,exp(p$ls),log=TRUE)) }
nl_rtmb(obj, list(A=18,k=.08,tm=50,ls=log(1)))
# Soil fertility: nonlinear Mitscherlich likelihood.
f <- subset(nl_data("soil_fertility_p"), soil_class == "Loamy")
obj2 <- function(p) { mu <- p$A-p$d*exp(-p$k*f$P2O5_kg_ha); -sum(dnorm(f$grain_yield_Mg_ha,mu,exp(p$ls),log=TRUE)) }
nl_rtmb(obj2, list(A=8,d=5,k=.02,ls=0))
# Plant physiology: arbitrary constrained parameterization in the objective.
p <- subset(nl_data("plant_physiology_light"), water_regime == "WellWatered")
obj3 <- function(z) { a<-exp(z$la); A<-exp(z$lA); mu<-A*a*p$PAR_umol_m2_s/(A+a*p$PAR_umol_m2_s)-exp(z$lRd); -sum(dnorm(p$A_umol_CO2_m2_s,mu,exp(z$ls),log=TRUE)) }
nl_rtmb(obj3, list(la=log(.05),lA=log(30),lRd=log(1),ls=0))
}
}
