\name{nl_fit}
\alias{nl_fit}
\title{Fit a nonlinear regression model}
\description{Unified front end for base NLS, Levenberg-Marquardt, multistart NLS, generalized nonlinear least squares, robust regression, and nonlinear quantile regression.}
\usage{nl_fit(formula = NULL, data, start = NULL, engine = c("nlsLM","nls","multistart","gnls","robust","quantile"), model = NULL, response = NULL, predictor = NULL, lower = -Inf, upper = Inf, weights = NULL, correlation = NULL, params = NULL, tau = 0.5, ...)}
\arguments{
  \item{formula}{Nonlinear model formula. May be omitted when `model`, `response`, and `predictor` are supplied.}
  \item{data}{Data frame.}
  \item{start}{Named starting values; generated automatically for registered models when omitted.}
  \item{engine}{One of `nls`, `nlsLM`, `multistart`, `gnls`, `robust`, or `quantile`.}
  \item{model}{Optional registered model name.}
  \item{response}{Response name when `model` is supplied.}
  \item{predictor}{Predictor name when `model` is supplied.}
  \item{lower}{Lower parameter bounds.}
  \item{upper}{Upper parameter bounds.}
  \item{weights}{Optional weights or variance structure, depending on engine.}
  \item{correlation}{Optional `nlme` correlation structure for `gnls`.}
  \item{params}{Optional `gnls` parameter model formulas, including qualitative-factor effects.}
  \item{tau}{Quantile for `quantile` engine.}
  \item{...}{Additional backend arguments.}
}
\value{An `nlrfit` object containing the fitted backend and reproducibility metadata.}
\examples{
okra <- nl_data("okra_growth_means")
f1 <- nl_fit(data=okra, model="gompertz", response="fruit_length", predictor="day_after_flowering", engine="nls")
fert <- subset(nl_data("soil_fertility_p"), soil_class=="Loamy"); f2 <- nl_fit(data=fert, model="mitscherlich", response="grain_yield_Mg_ha", predictor="P2O5_kg_ha", engine="nls")
soil <- subset(nl_data("soil_infiltration"), management=="NoTill"); f3 <- nl_fit(data=soil, model="michaelis_menten", response="cumulative_infiltration_mm", predictor="time_min", engine="nls")
}
