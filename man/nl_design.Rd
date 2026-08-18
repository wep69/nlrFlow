\name{nl_design}
\alias{nl_design}
\title{Locally optimal nonlinear experimental design}
\description{Selects candidate predictor values greedily using the Fisher information of the nonlinear mean at nominal parameter values. D-, A-, E- and c-optimal criteria are available. This is a local design and should be repeated across plausible parameter scenarios when prior uncertainty is substantial.}
\usage{nl_design(formula,data_template,parameters,predictor,candidates,n_points, criterion=c("D","A","E","c"),sigma=1,c_vector=NULL,existing=NULL)}
\arguments{
  \item{formula}{Nonlinear response formula.}
  \item{data_template}{One-row data frame containing non-predictor covariates.}
  \item{parameters}{Named nominal nonlinear parameter vector.}
  \item{predictor}{Predictor column to vary.}
  \item{candidates}{Numeric candidate predictor values.}
  \item{n_points}{Number of distinct points selected.}
  \item{criterion}{`D`, `A`, `E`, or `c`.}
  \item{sigma}{Residual SD used to scale information.}
  \item{c_vector}{Contrast vector for c-optimality.}
  \item{existing}{Optional existing predictor values whose information is included.}
}
\value{An `nlr_design` object with selected points and information trajectory.}
\examples{
o<-nl_data("okra_growth_means"); nl_design(fruit_length~Asym*exp(-exp(-k*(day_after_flowering-xmid))),o[1,,drop=FALSE],c(Asym=18,k=.4,xmid=4),"day_after_flowering",1:25,6)
f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); nl_design(grain_yield_Mg_ha~Asym-delta*exp(-k*P2O5_kg_ha),f[1,,drop=FALSE],c(Asym=8,delta=5,k=.02),"P2O5_kg_ha",seq(0,300,10),7)
p<-subset(nl_data("plant_physiology_light"),water_regime=="WellWatered"); nl_design(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,p[1,,drop=FALSE],c(Amax=30,alpha=.06,Rd=1),"PAR_umol_m2_s",seq(0,2000,100),7)
}
