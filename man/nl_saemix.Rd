\name{nl_saemix}
\alias{nl_saemix}
\title{Fit an SAEM nonlinear mixed-effects model}
\description{Provides a transparent adapter to `saemix` for difficult nonlinear mixed-effects models. The user supplies the model function and mapping explicitly because SAEM parameterizations are study-specific.}
\usage{nl_saemix(model_function,data,psi0,id,predictor,response,parameter_names,covariate_model=NULL,transform_par=rep(0,length(parameter_names)),...)}
\arguments{
  \item{model_function}{Function in the form expected by `saemixModel`.}
  \item{data}{Data frame.}
  \item{psi0}{Initial population parameter matrix.}
  \item{id}{Subject/group identifier column.}
  \item{predictor}{Predictor column.}
  \item{response}{Response column.}
  \item{parameter_names}{Parameter names.}
  \item{covariate_model}{Optional covariate model matrix.}
  \item{transform_par}{Parameter transformations.}
  \item{...}{Additional arguments passed to `saemixModel` or `saemix`.}
}
\value{A fitted `saemix` object wrapped in `nlrfit`.}
\examples{
\dontrun{
# Example 1: agronomy repeated growth uses a user-defined logistic function.
a <- nl_data("agronomy_growth"); # nl_saemix(model_fun,a,psi0,... )
# Example 2: soil infiltration can use subject/block-specific Vmax.
s <- nl_data("soil_infiltration"); # nl_saemix(model_fun,s,psi0,... )
# Example 3: physiology can use plant-level Amax and alpha.
p <- nl_data("plant_physiology_light"); # nl_saemix(model_fun,p,psi0,... )
}
}
