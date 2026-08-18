\name{nl_fit_many}
\alias{nl_fit_many}
\title{Fit multiple candidate nonlinear models}
\description{Fits a common response-predictor relationship using several registered models, retaining failures in an auditable result.}
\usage{nl_fit_many(data, response, predictor, models, engine="nlsLM", ...)}
\arguments{
  \item{data}{Data frame.}
  \item{response}{Response name.}
  \item{predictor}{Predictor name.}
  \item{models}{Character vector of registered models.}
  \item{engine}{Fitting engine passed to `nl_fit`.}
  \item{...}{Additional arguments passed to `nl_fit`.}
}
\value{An `nlrfit_list` containing successful fits, failures, and an audit trail.}
\examples{
okra <- nl_data("okra_growth_means"); nl_fit_many(okra,"fruit_length","day_after_flowering",c("logistic","gompertz","richards"),engine="nls")
fert <- subset(nl_data("soil_fertility_p"),soil_class=="Clayey"); nl_fit_many(fert,"grain_yield_Mg_ha","P2O5_kg_ha",c("mitscherlich","michaelis_menten"),engine="nls")
soil <- subset(nl_data("soil_infiltration"),management=="CoverCrop"); nl_fit_many(soil,"cumulative_infiltration_mm","time_min",c("michaelis_menten","monomolecular"),engine="nls")
}
