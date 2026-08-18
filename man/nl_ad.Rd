\name{nl_ad}
\alias{nl_ad}
\title{Evaluate an RTMB objective and its automatic gradient}
\description{Provides an auditable derivative interface for nonlinear objectives. The first derivative is obtained from RTMB automatic differentiation. A Hessian can optionally be formed by `optimHess` from the AD gradient, which is useful for local curvature checks but should not be confused with a symbolic Hessian.}
\usage{nl_ad(objective, parameters, at = NULL, hessian = TRUE, ...)}
\arguments{
  \item{objective}{RTMB-compatible scalar objective function.}
  \item{parameters}{Parameter list/vector used to construct the AD function.}
  \item{at}{Optional numeric vector at which derivatives are evaluated.}
  \item{hessian}{Logical; also calculate a local Hessian from the AD gradient.}
  \item{...}{Additional arguments to `RTMB::MakeADFun`.}
}
\value{A list with value, gradient, optional Hessian, and AD object.}
\examples{
\dontrun{
nl_ad(function(p) (p$a-2)^2 + (p$b+1)^2, list(a=0,b=0))
nl_ad(function(p) (log(p$A)-log(20))^2 + (p$k-.1)^2, list(A=10,k=.05))
nl_ad(function(p) sum((c(1,2,3)-p$a*c(1,2,3)^p$b)^2), list(a=1,b=1))
}
}
