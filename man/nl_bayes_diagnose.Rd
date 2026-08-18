\name{nl_bayes_diagnose}
\alias{nl_bayes_diagnose}
\title{Diagnose Bayesian nonlinear sampling}
\description{Summarizes Stan sampling diagnostics for a `brms`-backed nonlinear fit, including R-hat, relative effective sample size, NUTS divergences, and the largest observed tree depth.}
\usage{nl_bayes_diagnose(object,rhat_threshold=1.01)}
\arguments{
  \item{object}{An `nlrfit` produced by `nl_bayes`.}
  \item{rhat_threshold}{Threshold used to flag potentially problematic R-hat values.}
}
\value{An `nlr_bayes_diagnostic` list with parameter-level vectors, sampler summaries, and warnings.}
\examples{
\dontrun{
# Example 1: diagnose an okra Bayesian nonlinear model.
# nl_bayes_diagnose(okra_bayes)
# Example 2: diagnose a cultivar multilevel nonlinear model.
# nl_bayes_diagnose(agronomy_bayes)
# Example 3: diagnose a Student-t photosynthesis model.
# nl_bayes_diagnose(physiology_bayes)
}
}
