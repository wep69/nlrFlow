\name{nl_plot}
\alias{nl_plot}
\title{Create publication-ready fitted-curve graphics}
\description{Creates a ggplot with observed data, fitted curve, and optional uncertainty ribbon. Raw observations are shown by default and an alternative raw-data table can be overlaid when a model was fitted to summaries.}
\usage{nl_plot(object,newdata=NULL,interval="confidence",level=.95,x=NULL,y=NULL,group=NULL,boot=NULL,raw_data=NULL,point_alpha=.65,point_size=1.8,...)}
\arguments{
  \item{object}{An `nlrfit` or a supported Phase D result such as conformal, sensitivity, design, validation, discrimination, sequential-discovery, GP-discrepancy, or surrogate-validation output.}
  \item{newdata}{Optional prediction grid.}
  \item{interval}{Prediction interval type.}
  \item{level}{Interval level.}
  \item{x}{X variable name.}
  \item{y}{Y variable name.}
  \item{group}{Optional grouping aesthetic for observed points.}
  \item{boot}{Optional bootstrap object.}
  \item{raw_data}{Optional data frame used only for plotting observed points, for example individual observations when the fitted object used time-specific means.}
  \item{point_alpha}{Point transparency.}
  \item{point_size}{Point size.}
  \item{...}{Additional arguments reserved for future themes.}
}
\value{A `ggplot` object.}
\examples{
\dontrun{
f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_plot(f,raw_data=nl_data("okra_growth_raw"))
f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_plot(f)
f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_plot(f)
}
}
