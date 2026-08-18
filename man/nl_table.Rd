\name{nl_table}
\alias{nl_table}
\title{Create scientific result tables}
\description{Returns parameter, fit, diagnostic, or derived-quantity tables in data-frame form, with optional `gt` rendering.}
\usage{nl_table(object,type=c("parameters","fit","diagnostics","derived"),render=c("data.frame","gt","csv","xlsx","html","pdf","png","latex","rtf","docx"),file=NULL,...)}
\arguments{
  \item{object}{An `nlrfit`, `nlrfit_list`, `nlrdiag`, or `nlrderived`.}
  \item{type}{Requested table type.}
  \item{render}{Output mode: `data.frame`, `gt`, `csv`, `xlsx`, `html`, `pdf`, `png`, `latex`, `rtf`, or `docx`.}
  \item{file}{Output path for file-rendering modes.}
  \item{...}{Additional arguments passed to `gt::gtsave()` for gt-based file exports.}
}
\value{A data frame or `gt` table for in-memory modes, otherwise the normalized output path invisibly.}
\examples{
f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_table(f,"parameters")
x <- nl_fit_many(subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),"grain_yield_Mg_ha","P2O5_kg_ha",c("mitscherlich","michaelis_menten"),engine="nls"); nl_table(x,"fit")
nl_table(nl_derive(f),"derived")
}
