\name{nl_bayes_compare}
\alias{nl_bayes_compare}
\title{Compare Bayesian nonlinear models with PSIS-LOO}
\description{Computes PSIS-LOO for Bayesian nonlinear models fitted to the same outcome observations, compares expected log predictive density, reports Pareto-k diagnostics through the retained LOO objects, and computes stacking or pseudo-BMA+ predictive weights.}
\usage{nl_bayes_compare(fits,method=c("stacking","pseudobma"),moment_match=FALSE,reloo=FALSE,...)}
\arguments{
  \item{fits}{Named list of `brms`-backed `nlrfit` objects.}
  \item{method}{Predictive weighting method: `stacking` or `pseudobma`.}
  \item{moment_match}{Passed to `brms::loo` for optional moment matching.}
  \item{reloo}{Passed to `brms::loo` for optional exact refits of problematic observations.}
  \item{...}{Additional arguments passed to `brms::loo`.}
}
\value{An `nlr_bayes_comparison` containing LOO objects, comparison matrix, and model weights.}
\examples{
\dontrun{
# Example 1: compare two Bayesian okra growth equations.
# nl_bayes_compare(list(Gompertz=okra_gomp_bayes, Richards=okra_rich_bayes))
# Example 2: compare agronomic residual/distributional specifications.
# nl_bayes_compare(list(Gaussian=agri_gauss, StudentT=agri_student), method="stacking")
# Example 3: compare physiology models and request moment matching when needed.
# nl_bayes_compare(list(Rect=phys_rect, Nonrect=phys_nonrect), moment_match=TRUE)
}
}
