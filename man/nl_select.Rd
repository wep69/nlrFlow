\name{nl_select}
\alias{nl_select}
\title{Select the preferred candidate model}
\description{Ranks a fitted candidate set by AICc, AIC, BIC, RMSE, or cross-validated RMSE. Selection is a ranking aid and does not replace scientific diagnostics.}
\usage{nl_select(fits, criterion=c("AICc","AIC","BIC","RMSE","CV_RMSE"), k=5)}
\arguments{
  \item{fits}{An `nlrfit_list` or named list of `nlrfit` objects.}
  \item{criterion}{Ranking criterion.}
  \item{k}{Folds when `criterion = "CV_RMSE"`.}
}
\value{The selected `nlrfit`, with ranking table in an attribute.}
\examples{
okra <- nl_fit_many(nl_data("okra_growth_means"),"fruit_length","day_after_flowering",c("logistic","gompertz"),engine="nls"); nl_select(okra,"AICc")
soil <- nl_fit_many(subset(nl_data("soil_infiltration"),management=="NoTill"),"cumulative_infiltration_mm","time_min",c("michaelis_menten","monomolecular"),engine="nls"); nl_select(soil,"RMSE")
fert <- nl_fit_many(subset(nl_data("soil_fertility_p"),soil_class=="Sandy"),"grain_yield_Mg_ha","P2O5_kg_ha",c("mitscherlich","michaelis_menten"),engine="nls"); nl_select(fert,"BIC")
}
