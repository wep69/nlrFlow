\name{nl_ppcheck}
\alias{nl_ppcheck}
\title{Posterior predictive checks}
\description{Routes Bayesian fitted objects to `brms::pp_check` while preserving a package-level teaching interface.}
\usage{nl_ppcheck(object,...)}
\arguments{
  \item{object}{An `nlrfit` produced by `nl_bayes`.}
  \item{...}{Arguments to `brms::pp_check`.}
}
\value{A posterior predictive-check plot object.}
\examples{
\dontrun{
# nl_ppcheck(okra_bayes,type="dens_overlay")
# nl_ppcheck(agronomy_bayes,type="scatter_avg")
# nl_ppcheck(physiology_bayes,type="intervals")
}
}
