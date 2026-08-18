\name{nl_model_info}
\alias{nl_model_info}
\title{Inspect one nonlinear model}
\description{Provides equation, parameter names, category, starting-value suggestions, and teaching notes for a registered model.}
\usage{nl_model_info(model)}
\arguments{
  \item{model}{Registered model name.}
}
\value{A structured list of model information.}
\examples{
# Example 1: growth curve
nl_model_info("richards")
# Example 2: fertility response
nl_model_info("mitscherlich")
# Example 3: physiology response
nl_model_info("nonrectangular_hyperbola")
}
