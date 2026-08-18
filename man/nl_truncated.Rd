\name{nl_truncated}
\alias{nl_truncated}
\title{Truncated nonlinear Gaussian regression}
\description{Conditions the Gaussian nonlinear likelihood on observations being inside known truncation bounds. Unlike censoring, truncated observations outside the admissible region are not present in the sample.}
\usage{nl_truncated(formula,data,start,lower=-Inf,upper=Inf,sigma_start=1,control=list(maxit=5000))}
\arguments{
  \item{formula}{Nonlinear mean formula.}
  \item{data}{Data frame containing observed responses inside the truncation range.}
  \item{start}{Named nonlinear parameter starts.}
  \item{lower}{Lower truncation bound, scalar/vector/column name.}
  \item{upper}{Upper truncation bound, scalar/vector/column name.}
  \item{sigma_start}{Positive initial residual SD.}
  \item{control}{Optimizer control list.}
}
\value{An `nlr_truncated_fit` object.}
\examples{
\dontrun{
o<-nl_data("okra_growth_means"); nl_truncated(fruit_length~Asym*exp(-exp(-k*(day_after_flowering-xmid))),o,c(Asym=18,k=.4,xmid=4),0,Inf,.5)
f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); nl_truncated(grain_yield_Mg_ha~Asym-delta*exp(-k*P2O5_kg_ha),f,c(Asym=8,delta=5,k=.02),0,Inf,.3)
p<-subset(nl_data("plant_physiology_light"),water_regime=="WellWatered"); nl_truncated(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,p,c(Amax=30,alpha=.06,Rd=1),-5,Inf,1)
}
}
