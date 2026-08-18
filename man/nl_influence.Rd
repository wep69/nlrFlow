\name{nl_influence}
\alias{nl_influence}
\title{Leave-one-out influence analysis}
\description{Refits the model after deleting each observation and reports relative coefficient shifts and fit failures.}
\usage{nl_influence(object,max_cases=Inf)}
\arguments{
  \item{object}{An `nlrfit`.}
  \item{max_cases}{Optional maximum number of cases for a quick diagnostic.}
}
\value{A data frame of case influence summaries.}
\examples{
f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_influence(f)
f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Sandy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_influence(f,max_cases=12)
f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_influence(f,max_cases=15)
}
