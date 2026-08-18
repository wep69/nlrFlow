\name{nl_gp_discrepancy}
\alias{nl_gp_discrepancy}
\title{Diagnose mechanistic-model discrepancy with a Gaussian process}
\description{Fits a Gaussian-process emulator to residual structure after a nonlinear mechanistic fit. This is deliberately a *sequential discrepancy diagnostic*: it reveals systematic residual structure without silently letting a flexible GP redefine mechanistic parameters.}
\usage{nl_gp_discrepancy(object,predictors,newdata=NULL,covtype="matern5_2",...)}
\arguments{
  \item{object}{An `nlrfit`.}
  \item{predictors}{Character vector of columns used as GP inputs.}
  \item{newdata}{Optional prediction grid.}
  \item{covtype}{Covariance type passed to `DiceKriging::km`.}
  \item{...}{Additional arguments to `DiceKriging::km`.}
}
\value{An `nlr_gp_discrepancy` object with GP fit and corrected predictions.}
\examples{
\dontrun{
o<-nl_data("okra_growth_means"); fo<-nl_fit(data=o,model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_gp_discrepancy(fo,"day_after_flowering")
f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); ff<-nl_fit(data=f,model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_gp_discrepancy(ff,"P2O5_kg_ha")
s<-subset(nl_data("soil_water_retention"),texture=="Clayey"); fs<-nl_fit(data=s,model="van_genuchten",response="water_content_cm3_cm3",predictor="pressure_head_kPa",engine="nls"); nl_gp_discrepancy(fs,"pressure_head_kPa")
}
}
