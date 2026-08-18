\name{nl_propagate}
\alias{nl_propagate}
\title{Deterministic uncertainty propagation by cubature-like sigma points}
\description{Propagates approximately Gaussian parameter uncertainty through an arbitrary nonlinear derived quantity using a spherical-radial cubature rule with `2p` sigma points. It is a deterministic alternative to Monte Carlo for fast uncertainty propagation and is especially useful for AGR, RGR, AUC and response-at-dose calculations.}
\usage{nl_propagate(estimate, vcov, fun, level = 0.95, jitter = 1e-10)}
\arguments{
  \item{estimate}{Named parameter estimate vector.}
  \item{vcov}{Parameter covariance matrix.}
  \item{fun}{Function mapping a named parameter vector to a numeric result.}
  \item{level}{Confidence level for normal-approximation intervals.}
  \item{jitter}{Small diagonal regularization used if the covariance is nearly singular.}
}
\value{An `nlr_propagation` object with transformed center, mean, covariance,}
\examples{
ok <- nl_data("okra_growth_means"); fit <- nl_fit(data=ok,model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls")
nl_propagate(coef(fit),vcov(fit$fit),function(b) b["Asym"]*b["k"]/exp(1))
f <- subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); sf <- nl_fit(data=f,model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls")
nl_propagate(coef(sf),vcov(sf$fit),function(b) -log(.5)/b["k"])
s <- subset(nl_data("soil_infiltration"),management=="NoTill"); si <- nl_fit(data=s,model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls")
nl_propagate(coef(si),vcov(si$fit),function(b) b["Vmax"]*.5)
}
