\name{nl_bayes_rtmb}
\alias{nl_bayes_rtmb}
\title{Run inference for a BayesRTMB model}
\description{Routes a pre-built `BayesRTMB` model to MAP/Laplace optimization, NUTS, automatic-differentiation variational inference, or the package's classical route. Model construction remains explicit so priors, constraints and latent variables are visible and reproducible.}
\usage{nl_bayes_rtmb(model, method = c("optimize", "sample", "variational", "classic"), ...)}
\arguments{
  \item{model}{A `BayesRTMB` model object, usually returned by `rtmb_model()`.}
  \item{method}{One of `optimize`, `sample`, `variational`, or `classic`.}
  \item{...}{Arguments passed to the selected model method.}
}
\value{An `nlr_bayesrtmb_fit` object.}
\examples{
\dontrun{
# Agronomy: mdl <- BayesRTMB::rtmb_model(code, data=list(...)); nl_bayes_rtmb(mdl,"optimize")
# Soil: the same RTMB model definition can be checked rapidly with MAP/Laplace.
# nl_bayes_rtmb(soil_mdl,"optimize",laplace=TRUE)
# Physiology: use ADVI as a fast sensitivity analysis before NUTS.
# nl_bayes_rtmb(phys_mdl,"variational")
}
}
