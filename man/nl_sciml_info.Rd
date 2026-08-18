\name{nl_sciml_info}
\alias{nl_sciml_info}
\title{Inspect the SciML backend map}
\description{Returns the Julia packages used by blocks 68--74 and their roles.}
\usage{nl_sciml_info()}
\value{A data frame.}
\examples{
nl_sciml_info()
subset(nl_sciml_info(), block == 69)
subset(nl_sciml_info(), grepl("design|control", role, ignore.case = TRUE))
}
