\name{nl_surrogate}
\alias{nl_surrogate}
\title{Fit a surrogate for an expensive nonlinear simulator}
\description{Trains a Gaussian-process or polynomial-response-surface emulator from a parameter design and simulator outputs. Surrogates should be validated on held-out simulator runs before use inside bootstrap, MCMC or optimization.}
\usage{nl_surrogate(parameters,response,method=c("gp","quadratic"),...)}
\arguments{
  \item{parameters}{Matrix/data frame of simulator input parameters.}
  \item{response}{Numeric simulator output or scalar summary.}
  \item{method}{`gp` or `quadratic`.}
  \item{...}{Additional backend arguments.}
}
\value{An `nlr_surrogate` object.}
\examples{
\dontrun{
X<-expand.grid(A=seq(15,22,length=8),k=seq(.2,.7,length=8)); y<-with(X,A*k/exp(1)); nl_surrogate(X,y,"quadratic")
X2<-data.frame(qmax=runif(50,300,800),K=runif(50,.02,.5)); y2<-with(X2,qmax*K*10/(1+K*10)); nl_surrogate(X2,y2,"gp")
X3<-data.frame(Amax=runif(50,10,50),alpha=runif(50,.01,.2)); y3<-with(X3,Amax*alpha*1000/(Amax+alpha*1000)); nl_surrogate(X3,y3,"gp")
}
}
