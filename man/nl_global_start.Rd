\name{nl_global_start}
\alias{nl_global_start}
\title{Global genetic-algorithm search for nonlinear starting values}
\description{Uses a bounded real-valued genetic algorithm to minimize residual sum of squares before a local nonlinear fit. It is intended as a fallback when biological heuristics and multistart searches are insufficient, not as the default first step.}
\usage{nl_global_start(formula,data,lower,upper,pop_size=100,maxiter=1000,run=100,seed=20260817,local_search=TRUE,...)}
\arguments{
  \item{formula}{Nonlinear model formula.}
  \item{data}{Data frame.}
  \item{lower}{Named lower bounds for all nonlinear parameters.}
  \item{upper}{Named upper bounds for all nonlinear parameters.}
  \item{pop_size}{Genetic-algorithm population size.}
  \item{maxiter}{Maximum number of generations.}
  \item{run}{Stop after this many generations without improvement.}
  \item{seed}{Random seed.}
  \item{local_search}{Allow the GA backend to use its optional local optimization step.}
  \item{...}{Additional arguments passed to `GA::ga`.}
}
\value{An `nlr_global_start` list containing the recommended named start vector, objective RSS, and the backend GA object.}
\examples{
\dontrun{
d <- nl_data("okra_growth_means"); nl_global_start(fruit_length~Asym*exp(-exp(-k*(day_after_flowering-xmid))),d,c(Asym=10,k=.01,xmid=-2),c(Asym=30,k=3,xmid=15),pop_size=60,maxiter=300,run=50)
d <- subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); nl_global_start(grain_yield_Mg_ha~Asym-delta*exp(-k*P2O5_kg_ha),d,c(Asym=3,delta=.01,k=.0001),c(Asym=15,delta=12,k=.5),pop_size=60,maxiter=300,run=50)
d <- subset(nl_data("plant_physiology_light"),water_regime=="WellWatered"); nl_global_start(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,d,c(Amax=1,alpha=.001,Rd=0),c(Amax=80,alpha=.5,Rd=10),pop_size=60,maxiter=300,run=50)
}
}
