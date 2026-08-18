\name{nl_models}
\alias{nl_models}
\title{List registered nonlinear models}
\description{Returns the built-in model registry used by model-based fitting and teaching functions.}
\usage{nl_models()}
\value{A data frame describing model names, categories, parameters, and equations.}
\examples{
# Example 1: okra fruit growth
okra <- nl_data("okra_growth_means")
# Example 2: soil fertility
fert <- nl_data("soil_fertility_p")
# Example 3: plant physiology
phys <- nl_data("plant_physiology_light")
head(nl_models())
subset(nl_models(), category == "fertility")
subset(nl_models(), category == "physiology")
}
