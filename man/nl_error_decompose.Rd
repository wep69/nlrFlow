\name{nl_error_decompose}
\alias{nl_error_decompose}
\title{Decompose process and observation uncertainty in a state-space fit}
\description{Summarizes latent-state uncertainty, normalized innovations, and available parameter estimates corresponding to process- and measurement-noise terms. The function does not force identifiability: when both noise sources are weakly identified it flags the issue for sensitivity analysis or external calibration.}
\usage{nl_error_decompose(object,process_parameters=NULL,observation_parameters=NULL)}
\arguments{
  \item{object}{An `nlr_state_space` object.}
  \item{process_parameters}{Optional names of process-noise parameters.}
  \item{observation_parameters}{Optional names of observation-noise parameters.}
}
\value{An `nlr_error_decomposition` object.}
\examples{
\dontrun{
# nl_error_decompose(soil_state_fit,"sigma_x","sigma_y")
# nl_error_decompose(physiology_state_fit,c("sigma_growth","sigma_env"),"sigma_sensor")
# nl_error_decompose(agronomy_state_fit,"sigma_process","sigma_obs")
}
}
