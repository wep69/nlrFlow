\name{nl_start}
\alias{nl_start}
\title{Generate starting values}
\description{Creates data-informed starting values for a registered nonlinear model. The values are intended as initialization, not scientific estimates.}
\usage{nl_start(data, response, predictor, model)}
\arguments{
  \item{data}{Data frame.}
  \item{response}{Response column.}
  \item{predictor}{Predictor column.}
  \item{model}{Registered model name.}
}
\value{A named list of starting values.}
\examples{
okra <- nl_data("okra_growth_means")
nl_start(okra,"fruit_length","day_after_flowering","richards")
fert <- nl_data("soil_fertility_p"); nl_start(fert,"grain_yield_Mg_ha","P2O5_kg_ha","mitscherlich")
phys <- nl_data("plant_physiology_light"); nl_start(phys,"A_umol_CO2_m2_s","PAR_umol_m2_s","nonrectangular_hyperbola")
}
