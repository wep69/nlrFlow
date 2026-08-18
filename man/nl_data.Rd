\name{nl_data}
\alias{nl_data}
\title{Load a packaged teaching dataset}
\description{Loads one of the frozen CSV teaching datasets distributed with nlrFlow.}
\usage{nl_data(name)}
\arguments{
  \item{name}{Dataset name. Includes the original nonlinear-regression teaching data plus Scientific Machine Learning datasets prefixed with `sciml_`.}
}
\value{A data frame.}
\examples{
# Example 1: raw okra observations
head(nl_data("okra_growth_raw"))
# Example 2: soil infiltration
head(nl_data("soil_infiltration"))
# Example 3: agronomy growth
head(nl_data("agronomy_growth"))
}
