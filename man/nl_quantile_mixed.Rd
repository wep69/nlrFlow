\name{nl_quantile_mixed}
\alias{nl_quantile_mixed}
\title{Nonlinear quantile mixed-effects regression through qrNLMM}
\description{Fits one or several conditional quantiles in a nonlinear mixed-effects model using the SAEM/asymmetric-Laplace implementation in `qrNLMM`. The model expression and initial parameter structure are kept explicit because they are study-specific.}
\usage{nl_quantile_mixed(y, x, groups, initial, exprNL, covar = NA, tau = 0.5, ...)}
\arguments{
  \item{y}{Response vector.}
  \item{x}{Predictor vector or matrix accepted by `qrNLMM::QRNLMM`.}
  \item{groups}{Group/subject identifier.}
  \item{initial}{Initial values accepted by `QRNLMM`.}
  \item{exprNL}{Nonlinear expression expected by `QRNLMM`.}
  \item{covar}{Optional covariates.}
  \item{tau}{One or more quantiles in (0,1).}
  \item{...}{Additional arguments to `qrNLMM::QRNLMM`.}
}
\value{An `nlr_quantile_mixed` object retaining the backend fit and quantiles.}
\examples{
\dontrun{
a <- nl_data("agronomy_growth"); # nl_quantile_mixed(a$biomass_Mg_ha,a$day,interaction(a$cultivar,a$block,drop=TRUE),initial,exprNL,tau=c(.1,.5,.9))
p <- nl_data("plant_physiology_light"); # nl_quantile_mixed(p$A_umol_CO2_m2_s,p$PAR_umol_m2_s,p$plant_id,initial,exprNL,tau=.5)
s <- nl_data("soil_infiltration"); # nl_quantile_mixed(s$cumulative_infiltration_mm,s$time_min,interaction(s$management,s$block,drop=TRUE),initial,exprNL,tau=.9)
}
}
