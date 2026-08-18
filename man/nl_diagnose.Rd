\name{nl_diagnose}
\alias{nl_diagnose}
\title{Diagnose a nonlinear fit}
\description{Computes residual summaries, residual-fit correlation, normal-score correlation, heteroscedasticity indicators, and optional autocorrelation diagnostics without reducing model adequacy to a single test.}
\usage{nl_diagnose(object,lag=5)}
\arguments{
  \item{object}{An `nlrfit`.}
  \item{lag}{Maximum residual autocorrelation lag.}
}
\value{An `nlrdiag` object with data and warnings.}
\examples{
f <- nl_fit(data=nl_data("okra_growth_means"),model="richards",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_diagnose(f)
f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Clayey"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_diagnose(f)
f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="CoverCrop"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_diagnose(f)
}
