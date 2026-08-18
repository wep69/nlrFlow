\name{nl_quantile_mixed_robust}
\alias{nl_quantile_mixed_robust}
\title{Robust penalized nonlinear quantile mixed-effects sensitivity fit}
\description{Fits a transparent penalized nonlinear quantile model with group-specific random deviations on selected nonlinear parameters. It uses a smooth pinball loss and Gaussian ridge penalty on random effects. This is an experimental sensitivity estimator, not an implementation of the contaminated-GAL model; use it to assess whether conclusions depend strongly on mean-based NLMEMs or extreme observations.}
\usage{nl_quantile_mixed_robust(formula, data, start, group, random_params = names(start), tau = 0.5, lambda = 1, smooth = 0.05, method = "BFGS", control = list())}
\arguments{
  \item{formula}{Nonlinear formula.}
  \item{data}{Data frame.}
  \item{start}{Named fixed-effect starting values.}
  \item{group}{Grouping column name.}
  \item{random_params}{Parameter names receiving group-specific deviations.}
  \item{tau}{Target quantile.}
  \item{lambda}{Positive random-effect penalty strength.}
  \item{smooth}{Positive smoothing width for the pinball loss.}
  \item{method}{Optimization method passed to `stats::optim`.}
  \item{control}{Optimizer control list.}
}
\value{An `nlr_quantile_mixed_robust` object.}
\examples{
\dontrun{
a <- nl_data("agronomy_growth"); a$unit<-interaction(a$cultivar,a$block,drop=TRUE); nl_quantile_mixed_robust(biomass_Mg_ha~Asym/(1+exp(-k*(day-xmid))),a,c(Asym=18,k=.08,xmid=50),"unit",c("Asym","k"))
p <- nl_data("plant_physiology_light"); nl_quantile_mixed_robust(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,p,c(Amax=30,alpha=.06,Rd=1),"plant_id",c("Amax"),tau=.5)
s <- nl_data("soil_infiltration"); s$unit<-interaction(s$management,s$block,drop=TRUE); nl_quantile_mixed_robust(cumulative_infiltration_mm~Vmax*time_min/(Km+time_min),s,c(Vmax=140,Km=30),"unit",c("Vmax"),tau=.9)
}
}
