\name{nl_boot}
\alias{nl_boot}
\title{Bootstrap nonlinear regression}
\description{Implements case, residual, parametric, wild, and cluster bootstrap while preserving the original model specification and recording failed refits.}
\usage{nl_boot(object,R=999,type=c("case","residual","parametric","cluster","wild"),cluster=NULL,seed=20260817)}
\arguments{
  \item{object}{An `nlrfit`.}
  \item{R}{Number of bootstrap replicates.}
  \item{type}{Bootstrap type.}
  \item{cluster}{Cluster column for cluster bootstrap.}
  \item{seed}{Random seed.}
}
\value{An `nlrboot` object with coefficient draws, convergence status, and metadata.}
\examples{
f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_boot(f,R=20,type="case",seed=1)
f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_boot(f,R=20,type="residual",seed=2)
f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_boot(f,R=20,type="parametric",seed=3)
}
