\name{nl_save_plot}
\alias{nl_save_plot}
\title{Save publication graphics}
\description{Exports a plot to SVG, PDF, PNG, or TIFF with explicit physical dimensions and resolution.}
\usage{nl_save_plot(plot,file,width=180,height=120,units="mm",dpi=600)}
\arguments{
  \item{plot}{A ggplot or compatible grid plot.}
  \item{file}{Output filename.}
  \item{width}{Width.}
  \item{height}{Height.}
  \item{units}{Dimension units.}
  \item{dpi}{Raster resolution.}
}
\value{The normalized output path invisibly.}
\examples{
\dontrun{
p <- nl_plot(nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls")); nl_save_plot(p,"okra.svg")
nl_save_plot(p,"okra.tiff",width=180,height=120,units="mm",dpi=600)
nl_save_plot(p,"okra.pdf",width=180,height=120,units="mm")
}
}
