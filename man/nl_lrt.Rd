\name{nl_lrt}
\alias{nl_lrt}
\title{Likelihood-ratio test for explicitly nested models}
\description{Performs a likelihood-ratio comparison only after the user explicitly declares that the reduced model is mathematically nested within the full model.}
\usage{nl_lrt(reduced, full, nested=FALSE)}
\arguments{
  \item{reduced}{Reduced `nlrfit`.}
  \item{full}{Full `nlrfit`.}
  \item{nested}{Must be explicitly set to `TRUE`; otherwise the test is blocked.}
}
\value{Backend ANOVA/LRT result.}
\examples{
okra <- nl_data("okra_growth_means"); f0 <- nl_fit(data=okra,model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); try(nl_lrt(f0,f0))
# A nested test must be scientifically established by the analyst.
try(nl_lrt(f0,f0,nested=FALSE))
# Explicit self-comparison is shown only as API demonstration.
nl_lrt(f0,f0,nested=TRUE)
}
