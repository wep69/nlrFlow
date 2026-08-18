\name{nl_sciml_setup}
\alias{nl_sciml_setup}
\title{Prepare or install the optional Julia SciML environment}
\description{By default this function only returns a reproducible setup specification. With `install = TRUE`, it invokes the bundled Julia setup script. It never installs Julia itself.}
\usage{nl_sciml_setup(install = FALSE, julia = NULL, env_dir = path.expand("~/.nlrFlow/julia"))}
\arguments{
  \item{install}{Logical; actually run Julia package installation.}
  \item{julia}{Optional Julia executable.}
  \item{env_dir}{Directory for the dedicated Julia environment.}
}
\value{A setup report.}
\examples{
nl_sciml_setup(install = FALSE)
nl_sciml_setup(FALSE)$packages
nl_sciml_setup(FALSE)$environment
}
