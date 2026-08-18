\name{nl_plot_diagnostics}
\alias{nl_plot_diagnostics}
\title{Create a publication-ready diagnostic panel}
\description{Builds four standard nonlinear-regression diagnostic ggplots from observed/fitted/residual information.}
\usage{nl_plot_diagnostics(object)}
\arguments{
  \item{object}{An `nlrfit`.}
}
\value{A patchwork object when `patchwork` is installed, otherwise a list of ggplots.}
\examples{
\dontrun{
f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_plot_diagnostics(f)
f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_plot_diagnostics(f)
f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_plot_diagnostics(f)
}
}
