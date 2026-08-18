\name{nl_bayes_approx}
\alias{nl_bayes_approx}
\title{Fast approximate Bayesian inference}
\description{Provides a common front end for Laplace/MAP or ADVI through `BayesRTMB`. Approximate posterior methods are intended for screening, initialization and large models; final uncertainty should be compared with simulation-based inference when scientifically consequential.}
\usage{nl_bayes_approx(model, method = c("laplace", "advi"), ...)}
\arguments{
  \item{model}{A `BayesRTMB` model object.}
  \item{method}{`laplace` or `advi`.}
  \item{...}{Arguments passed to `model$optimize()` or `model$variational()`.}
}
\value{An `nlr_bayes_approx` object.}
\examples{
\dontrun{
# nl_bayes_approx(agronomy_rtmb_model,"laplace")
# nl_bayes_approx(soil_rtmb_model,"advi")
# nl_bayes_approx(physiology_rtmb_model,"advi")
}
}
