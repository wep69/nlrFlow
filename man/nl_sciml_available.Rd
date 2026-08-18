\name{nl_sciml_available}
\alias{nl_sciml_available}
\title{Check whether the optional Julia/SciML backend is available}
\description{Checks for a Julia executable and, optionally, whether the Julia packages used by the nlrFlow SciML layer can be imported. No software is installed.}
\usage{nl_sciml_available(julia = NULL, check_packages = FALSE)}
\arguments{
  \item{julia}{Optional path or executable name.}
  \item{check_packages}{Logical; also test required Julia packages.}
}
\value{A logical value with diagnostic attributes.}
\examples{
nl_sciml_available(check_packages = FALSE)
attr(nl_sciml_available(check_packages = FALSE), "julia")
is.logical(nl_sciml_available(check_packages = FALSE))
}
