\name{nl_confregion}
\alias{nl_confregion}
\title{Joint nonlinear parameter confidence region}
\description{Samples Beale's unlinearized joint parameter confidence region through `nlstools::nlsConfRegions`. This complements marginal Wald/profile/bootstrap intervals by visualizing joint parameter uncertainty and non-elliptical geometry.}
\usage{nl_confregion(object,n=1000,expansion=1.5)}
\arguments{
  \item{object}{An `nlrfit` backed by an `nls`-compatible fit.}
  \item{n}{Number of accepted/candidate points requested from the backend confidence-region sampler.}
  \item{expansion}{Expansion factor of the parameter hypercube used by `nlstools`.}
}
\value{An `nlsConfRegions` object from `nlstools`.}
\examples{
\dontrun{
f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_confregion(f,n=500)
f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_confregion(f,n=500)
f <- nl_fit(data=subset(nl_data("plant_physiology_light"),water_regime=="WellWatered"),model="rectangular_hyperbola",response="A_umol_CO2_m2_s",predictor="PAR_umol_m2_s",engine="nls"); nl_confregion(f,n=500)
}
}
