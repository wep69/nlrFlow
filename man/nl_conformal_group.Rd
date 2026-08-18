\name{nl_conformal_group}
\alias{nl_conformal_group}
\title{Cluster-aware and Mondrian conformal prediction}
\description{Splits entire clusters between training and calibration to preserve the independence unit in repeated-measures experiments. Optional `strata` creates Mondrian score distributions for qualitative groups such as cultivar, soil class or water regime.}
\usage{nl_conformal_group(object, cluster, newdata = NULL, strata = NULL, alpha = 0.05, calibration_fraction = 0.25, min_scores = 5L, seed = 20260817)}
\arguments{
  \item{object}{Refit-capable `nlrfit`.}
  \item{cluster}{Cluster/unit identifier column.}
  \item{newdata}{Prediction data; defaults to original data.}
  \item{strata}{Optional qualitative column defining Mondrian calibration groups.}
  \item{alpha}{Miscoverage probability.}
  \item{calibration_fraction}{Fraction of clusters held out for calibration.}
  \item{min_scores}{Minimum score count required for a stratum; otherwise the}
  \item{seed}{Random seed.}
}
\value{An `nlr_conformal_group` object.}
\examples{
\dontrun{
a <- nl_data("agronomy_growth"); a$unit<-interaction(a$cultivar,a$block,drop=TRUE); fa <- nl_fit(biomass_Mg_ha~Asym/(1+exp(-k*(day-xmid))),a,start=list(Asym=18,k=.08,xmid=50),engine="nls"); nl_conformal_group(fa,"unit",strata="cultivar")
p <- nl_data("plant_physiology_light"); fp <- nl_fit(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,p,start=list(Amax=30,alpha=.06,Rd=1),engine="nls"); nl_conformal_group(fp,"plant_id",strata="water_regime")
s <- nl_data("soil_infiltration"); s$unit<-interaction(s$management,s$block,drop=TRUE); fs <- nl_fit(cumulative_infiltration_mm~Vmax*time_min/(Km+time_min),s,start=list(Vmax=140,Km=30),engine="nls"); nl_conformal_group(fs,"unit",strata="management")
}
}
