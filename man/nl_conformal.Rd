\name{nl_conformal}
\alias{nl_conformal}
\title{Split conformal prediction for nonlinear regression}
\description{Creates finite-sample split-conformal prediction intervals by refitting an `nlrfit` on a proper training subset and calibrating absolute residual scores on held-out observations. The returned interval concerns future observations, not uncertainty of the conditional mean curve.}
\usage{nl_conformal(object, newdata = NULL, alpha = 0.05, calibration_fraction = 0.25, seed = 20260817, indices = NULL)}
\arguments{
  \item{object}{Refit-capable `nlrfit` object.}
  \item{newdata}{Data frame for prediction; defaults to the original data.}
  \item{alpha}{Miscoverage probability.}
  \item{calibration_fraction}{Fraction allocated to calibration.}
  \item{seed}{Random seed controlling the split.}
  \item{indices}{Optional explicit calibration-row indices.}
}
\value{An `nlr_conformal` object containing predictions and intervals.}
\examples{
ok <- nl_data("okra_growth_means"); fo <- nl_fit(data=ok,model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_conformal(fo,alpha=.1)
sf <- subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); ff <- nl_fit(data=sf,model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_conformal(ff)
si <- subset(nl_data("soil_infiltration"),management=="NoTill"); fi <- nl_fit(data=si,model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_conformal(fi)
}
