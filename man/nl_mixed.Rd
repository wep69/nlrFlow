\name{nl_mixed}
\alias{nl_mixed}
\title{Fit nonlinear mixed-effects models}
\description{Fits nonlinear mixed-effects models through `nlme::nlme`, supporting qualitative fixed effects on nonlinear parameters, random effects, nested groups, variance functions, and residual correlation structures.}
\usage{nl_mixed(model,data,fixed,random,groups=NULL,start,correlation=NULL,weights=NULL,method="ML",...)}
\arguments{
  \item{model}{Nonlinear response formula.}
  \item{data}{Data frame.}
  \item{fixed}{Fixed-effects parameter formula or list.}
  \item{random}{Random-effects parameter formula or list.}
  \item{groups}{Optional grouping formula.}
  \item{start}{Initial fixed-effect values.}
  \item{correlation}{Optional `corStruct`.}
  \item{weights}{Optional `varFunc`.}
  \item{method}{ML or REML where supported.}
  \item{...}{Additional `nlme::nlme` arguments.}
}
\value{An `nlrfit` with engine `nlme`.}
\examples{
\dontrun{
# Agronomy: cultivar effects may be placed on Asym and k with block/plant random effects.
a <- nl_data("agronomy_growth"); nl_mixed(biomass_Mg_ha~Asym/(1+exp(-k*(day-xmid))),a,fixed=list(Asym~cultivar,k~cultivar,xmid~1),random=Asym~1|block,start=c(18,1,1,.09,.01,.01,52))
# Soil: management-specific infiltration parameters with block random effects.
s <- nl_data("soil_infiltration"); nl_mixed(cumulative_infiltration_mm~Vmax*time_min/(Km+time_min),s,fixed=list(Vmax~management,Km~management),random=Vmax~1|block,start=c(100,20,30,25,5,5))
# Physiology: water-regime effects with plant-level random Amax.
p <- nl_data("plant_physiology_light"); nl_mixed(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,p,fixed=list(Amax~water_regime,alpha~water_regime,Rd~1),random=Amax~1|plant_id,start=c(30,-6,-14,.07,-.01,-.02,1.3))
}
}
