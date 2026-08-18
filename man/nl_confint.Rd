\name{nl_confint}
\alias{nl_confint}
\title{Confidence intervals for nonlinear model parameters}
\description{Computes Wald, profile-likelihood, bootstrap, or Bayesian posterior intervals where supported.}
\usage{nl_confint(object,method=c("wald","profile","bootstrap","posterior"),level=.95,boot=NULL,bootstrap_interval=c("percentile","bca"))}
\arguments{
  \item{object}{An `nlrfit` object.}
  \item{method}{`wald`, `profile`, `bootstrap`, or `posterior`. For `brms` fits, omission defaults to `posterior`.}
  \item{level}{Confidence level.}
  \item{boot}{Optional `nlrboot` object for bootstrap intervals.}
  \item{bootstrap_interval}{Bootstrap interval type, either `percentile` or `bca`.}
}
\value{A data frame of parameter intervals.}
\examples{
f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_confint(f,"wald")
nl_confint(f,"profile")
b <- nl_boot(f,R=30,seed=1); nl_confint(f,"bootstrap",boot=b,bootstrap_interval="bca")
}
