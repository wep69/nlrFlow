\name{nl_contrast}
\alias{nl_contrast}
\title{Linear contrasts of nonlinear parameters}
\description{Computes user-specified linear contrasts. Frequentist fits use the estimated variance-covariance matrix; `brms` fits use posterior draws and posterior probabilities.}
\usage{nl_contrast(object,L,level=.95)}
\arguments{
  \item{object}{An `nlrfit`.}
  \item{L}{Numeric contrast vector or matrix with columns matching coefficient names.}
  \item{level}{Confidence level.}
}
\value{A data frame of frequentist contrast estimates/SEs/Wald intervals and p-values, or posterior contrast summaries for `brms` fits.}
\examples{
f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_contrast(f,c(Asym=1,k=0,xmid=0))
f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_contrast(f,c(Asym=1,delta=-1,k=0))
f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_contrast(f,c(Vmax=1,Km=0))
}
