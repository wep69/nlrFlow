\name{nl_structural_identify}
\alias{nl_structural_identify}
\title{Screen local structural identifiability of a nonlinear mean function}
\description{Evaluates the noise-free sensitivity/Jacobian matrix of the nonlinear mean on a supplied design and uses singular values to detect locally aliased parameter directions. This is a *local structural screen*, not a proof of global structural identifiability. ODE models requiring formal differential-algebraic identifiability should be checked with specialized symbolic software.}
\usage{nl_structural_identify(formula,data,parameters,rel_step=sqrt(.Machine$double.eps),tol=1e-8)}
\arguments{
  \item{formula}{Nonlinear formula.}
  \item{data}{Design data used to evaluate the mean function.}
  \item{parameters}{Named parameter vector.}
  \item{rel_step}{Relative finite-difference step.}
  \item{tol}{Relative singular-value rank tolerance.}
}
\value{An `nlr_structural_identifiability` object.}
\examples{
o<-nl_data("okra_growth_means"); nl_structural_identify(fruit_length~Asym*exp(-exp(-k*(day_after_flowering-xmid))),o,c(Asym=18,k=.4,xmid=4))
s<-subset(nl_data("soil_p_sorption"),soil_class=="Clayey"); nl_structural_identify(sorbed_P_mg_kg~qmax*K*solution_P_mg_L/(1+K*solution_P_mg_L),s,c(qmax=600,K=.2))
f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); nl_structural_identify(grain_yield_Mg_ha~Asym-delta*exp(-k*P2O5_kg_ha),f,c(Asym=8,delta=5,k=.02))
}
