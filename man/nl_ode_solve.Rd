\name{nl_ode_solve}
\alias{nl_ode_solve}
\title{Solve a deterministic ODE model}
\description{Routes initial-value ODE systems to `deSolve::ode`, enabling agronomic, soil-process, physiological, and environmental dynamic models that do not have a convenient closed-form nonlinear regression equation.}
\usage{nl_ode_solve(state,times,func,parms,method="lsoda",...)}
\arguments{
  \item{state}{Named initial state vector.}
  \item{times}{Numeric output times.}
  \item{func}{ODE derivative function accepted by `deSolve::ode`.}
  \item{parms}{Named parameter vector/list.}
  \item{method}{ODE solver method.}
  \item{...}{Additional arguments to `deSolve::ode`.}
}
\value{A data frame-like ODE solution returned by `deSolve`.}
\examples{
\dontrun{
# Example 1: crop biomass with first-order approach to carrying capacity.
f <- function(t,state,parms) list(c(parms["r"]*(parms["K"]-state[1])))
nl_ode_solve(c(B=1),0:30,f,c(r=.08,K=20))
# Example 2: soil nutrient mineralization pool.
g <- function(t,state,parms) list(c(-parms["k"]*state[1]))
nl_ode_solve(c(N=100),0:60,g,c(k=.03))
# Example 3: physiological recovery after stress.
h <- function(t,state,parms) list(c(parms["k"]*(parms["Amax"]-state[1])))
nl_ode_solve(c(A=5),0:24,h,c(k=.2,Amax=30))
}
}
