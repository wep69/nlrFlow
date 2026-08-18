\name{nl_sensitivity}
\alias{nl_sensitivity}
\title{Global sensitivity analysis for nonlinear model outputs}
\description{Calculates local finite-difference sensitivities, Morris elementary effects, or Monte Carlo Sobol first-order and total-effect indices for an arbitrary scalar model summary.}
\usage{nl_sensitivity(model_fun,ranges,method=c("local","morris","sobol"),summary_fun=mean,n=500,delta=.05,seed=20260817)}
\arguments{
  \item{model_fun}{Function mapping a named parameter vector to a numeric model output.}
  \item{ranges}{Named two-column matrix/data frame of lower and upper bounds.}
  \item{method}{`local`, `morris`, or `sobol`.}
  \item{summary_fun}{Function reducing model output to one scalar.}
  \item{n}{Monte Carlo sample size/number of Morris trajectories.}
  \item{delta}{Relative step for local/Morris calculations.}
  \item{seed}{Random seed.}
}
\value{An `nlr_sensitivity` object with method-specific indices.}
\examples{
nl_sensitivity(function(p)p["A"]*(1-exp(-p["k"]*(1:10))),matrix(c(10,30,.05,.5),2,2,byrow=TRUE,dimnames=list(c("A","k"),c("lower","upper"))),"local")
nl_sensitivity(function(p)p["qmax"]*p["K"]*(1:20)/(1+p["K"]*(1:20)),matrix(c(300,800,.02,.5),2,2,byrow=TRUE,dimnames=list(c("qmax","K"),c("lower","upper"))),"morris",n=30)
nl_sensitivity(function(p)p["Amax"]*p["alpha"]*(1:50)/(p["Amax"]+p["alpha"]*(1:50)),matrix(c(10,50,.01,.2),2,2,byrow=TRUE,dimnames=list(c("Amax","alpha"),c("lower","upper"))),"sobol",n=300)
}
