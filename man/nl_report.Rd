\name{nl_report}
\alias{nl_report}
\title{Generate a reproducible Markdown analysis report}
\description{Writes a concise scientific report containing specification, coefficients, fit metrics, diagnostics, warnings, and reproducibility information.}
\usage{nl_report(object,file="nlrFlow_report.md",title="nlrFlow nonlinear regression report",include_session=TRUE)}
\arguments{
  \item{object}{An `nlrfit`.}
  \item{file}{Markdown output file.}
  \item{title}{Report title.}
  \item{include_session}{Include session information.}
}
\value{The report path invisibly.}
\examples{
\dontrun{
f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_report(f,tempfile(fileext=".md"))
f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_report(f,tempfile(fileext=".md"),"Soil fertility nonlinear report")
f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_report(f,tempfile(fileext=".md"),"Soil infiltration nonlinear report")
}
}
