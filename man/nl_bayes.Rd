\name{nl_bayes}
\alias{nl_bayes}
\title{Fit Bayesian nonlinear models}
\description{Fits arbitrary nonlinear, multilevel, and distributional Bayesian models through `brms`. Priors are required by default for nonlinear parameters to discourage unidentified default analyses.}
\usage{nl_bayes(formula,data,prior,family=stats::gaussian(),backend="cmdstanr",require_prior=TRUE,...)}
\arguments{
  \item{formula}{A `brmsformula` or formula accepted by `brms::brm`.}
  \item{data}{Data frame.}
  \item{prior}{Explicit prior specification.}
  \item{family}{Response family.}
  \item{backend}{Stan backend, usually `cmdstanr` or `rstan`.}
  \item{require_prior}{Require non-empty priors for nonlinear models.}
  \item{...}{Additional arguments to `brms::brm`.}
}
\value{An `nlrfit` with engine `brms`.}
\examples{
\dontrun{
# Example 1: Bayesian Gompertz for okra with explicit priors.
# nl_bayes(brms::bf(..., nl=TRUE), nl_data("okra_growth_raw"), prior=...)
# Example 2: cultivar-specific nonlinear growth with multilevel block effects.
# nl_bayes(brms::bf(..., nl=TRUE), nl_data("agronomy_growth"), prior=...)
# Example 3: water-regime nonlinear photosynthesis with Student-t residuals.
# nl_bayes(brms::bf(..., nl=TRUE), nl_data("plant_physiology_light"), prior=..., family=brms::student())
}
}
