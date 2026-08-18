\name{nl_capabilities}
\alias{nl_capabilities}
\title{Inspect backend capabilities}
\description{Shows which scientific capabilities are implemented and which optional package provides each engine.}
\usage{nl_capabilities()}
\value{A data frame with capability, engine, optional package, and availability.}
\examples{
nl_capabilities()
subset(nl_capabilities(), capability == "mixed")
subset(nl_capabilities(), available)
}
