\name{nl_doctor}
\alias{nl_doctor}
\title{Check the local nlrFlow scientific environment}
\description{Checks optional engines, R version, package source version, and capability availability without installing anything.}
\usage{nl_doctor()}
\value{A structured environment report.}
\examples{
nl_doctor()
subset(nl_doctor()$capabilities, !available)
nl_doctor()$r_version
}
