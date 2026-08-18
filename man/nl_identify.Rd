\name{nl_identify}
\alias{nl_identify}
\title{Assess local parameter identifiability}
\description{Builds a finite-difference prediction Jacobian, singular values, condition index, and parameter-correlation matrix to flag weak local identifiability.}
\usage{nl_identify(object,eps=1e-6)}
\arguments{
  \item{object}{An `nlrfit`.}
  \item{eps}{Relative finite-difference step.}
}
\value{An `nlr_identifiability` object.}
\examples{
f <- nl_fit(data=nl_data("okra_growth_means"),model="richards",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_identify(f)
f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_identify(f)
f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_identify(f)
}
