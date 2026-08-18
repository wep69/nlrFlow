\name{nl_predict}
\alias{nl_predict}
\title{Predict from nonlinear models with uncertainty}
\description{Produces point predictions and approximate confidence or prediction intervals using parameter simulation, or bootstrap intervals when a bootstrap object is supplied.}
\usage{nl_predict(object,newdata=NULL,interval=c("none","confidence","prediction"),level=.95,nsim=1000,boot=NULL,seed=20260817,...)}
\arguments{
  \item{object}{An `nlrfit`.}
  \item{newdata}{Prediction data.}
  \item{interval}{`none`, `confidence`, or `prediction`.}
  \item{level}{Interval level.}
  \item{nsim}{Number of parameter simulations.}
  \item{boot}{Optional `nlrboot` for bootstrap prediction intervals.}
  \item{seed}{Simulation seed.}
  \item{...}{Additional prediction arguments passed to `brms::posterior_epred()` or `brms::posterior_predict()` for Bayesian fits, such as `re_formula`.}
}
\value{A data frame with fitted values and interval bounds.}
\examples{
f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_predict(f,interval="confidence",nsim=100)
f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_predict(f,interval="prediction",nsim=100)
f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_predict(f,interval="confidence",nsim=100)
}
