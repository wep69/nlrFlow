\name{nl_teach}
\alias{nl_teach}
\title{Teach a registered nonlinear model}
\description{Returns a pedagogical model card covering equation, parameters, interpretation, identifiability cautions, starting values, diagnostics, and suitable scientific domains.}
\usage{nl_teach(model)}
\arguments{
  \item{model}{Registered model name.}
}
\value{An `nlr_teaching_card` list.}
\examples{
nl_teach("richards")
nl_teach("mitscherlich")
nl_teach("nonrectangular_hyperbola")
}
