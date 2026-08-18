\name{nl_curve_test}
\alias{nl_curve_test}
\title{Compare nested curve specifications}
\description{Compares a reduced and full curve model and can perform an LRT only when nesting is explicitly confirmed.}
\usage{nl_curve_test(reduced,full,nested=FALSE)}
\arguments{
  \item{reduced}{Reduced `nlrfit`.}
  \item{full}{Full `nlrfit`.}
  \item{nested}{Logical confirmation of mathematical nesting.}
}
\value{A list with fit-comparison table and optional LRT.}
\examples{
f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_curve_test(f,f,nested=FALSE)
f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_curve_test(f,f,nested=FALSE)
f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_curve_test(f,f,nested=FALSE)
}
