\name{nl_derive}
\alias{nl_derive}
\title{Derive biological quantities from a fitted curve}
\description{Computes numerically stable first and second derivatives, absolute and relative growth rates, inflection location, maximum absolute growth rate, t50, and area under the fitted curve. Bootstrap uncertainty can be propagated for frequentist fits; `brms` fits propagate posterior expected-response draws.}
\usage{nl_derive(object,predictor=NULL,grid=NULL,quantities=c("AGR","RGR","inflection","AGRmax","t50","AUC"),boot=NULL,level=.95,nsim=1000,...)}
\arguments{
  \item{object}{An `nlrfit`.}
  \item{predictor}{Predictor name; inferred when possible.}
  \item{grid}{Optional numeric grid.}
  \item{quantities}{Requested quantities.}
  \item{boot}{Optional `nlrboot` for uncertainty propagation.}
  \item{level}{Confidence/credible level used for propagated uncertainty.}
  \item{nsim}{Number of posterior expected-response draws for a `brms` fit.}
  \item{...}{Additional arguments passed to `brms::posterior_epred()` for Bayesian fits, such as `re_formula`.}
}
\value{An `nlrderived` object with curve-level and summary quantities.}
\examples{
f <- nl_fit(data=nl_data("okra_growth_means"),model="richards",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_derive(f)
f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_derive(f)
f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_derive(f)
}
