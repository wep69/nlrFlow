\name{nl_tutor}
\alias{nl_tutor}
\title{Launch or return the nonlinear-regression tutor}
\description{Returns all teaching cards, or launches an interactive Shiny tutor with model selection, parameter sliders, a predictor-range control, live curve visualization, equations and parameter interpretation when `interactive = TRUE`.}
\usage{nl_tutor(interactive=FALSE)}
\arguments{
  \item{interactive}{Logical; request an interactive tutor when possible.}
}
\value{A list of teaching cards, or a running Shiny application.}
\examples{
cards <- nl_tutor(FALSE); names(cards)
nl_tutor(FALSE)$richards
nl_tutor(FALSE)$nonrectangular_hyperbola
}
