\name{nl_state_space}
\alias{nl_state_space}
\title{Fit a continuous-time stochastic state-space model through ctsmTMB}
\description{Accepts either a preconfigured `ctsmTMB` model or a builder function that receives a fresh model created by the current `ctsmTMB` constructor (`newModel()` when available, otherwise the exported R6 generator). This keeps process equations, observation equations, process diffusion and measurement variance explicit.}
\usage{nl_state_space(model,data,method="ekf",...)}
\arguments{
  \item{model}{A configured ctsmTMB R6 model, or a function that configures and returns one.}
  \item{data}{Time-ordered data frame with a `t` column and required observations/inputs.}
  \item{method}{Filtering/estimation method passed to `model$estimate` when supported.}
  \item{...}{Additional arguments to `model$estimate`.}
}
\value{An `nlr_state_space` object.}
\examples{
\dontrun{
builder <- function(m){m$addSystem(dx~theta*(mu-x)*dt+sigma_x*dw);m$addObs(y~x);m$setVariance(y~sigma_y^2);m$setParameter(theta=c(initial=1,lower=.001,upper=20),mu=c(initial=1,lower=-10,upper=10),sigma_x=c(initial=.1,lower=1e-5,upper=5),sigma_y=.1);m$setInitialState(list(mean=1,cov=.01));m}
# nl_state_space(builder, agronomy_sensor_series)
# nl_state_space(builder, soil_moisture_series)
# nl_state_space(builder, physiology_time_series)
}
}
