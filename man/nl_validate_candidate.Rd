\name{nl_validate_candidate}
\alias{nl_validate_candidate}
\title{Validate a candidate nonlinear equation against scientific constraints}
\description{Combines predictive diagnostics with shape/domain checks. It can test finite extrapolation, positivity, monotonicity, response bounds, parameter bounds, and k-fold predictive error. Constraints are supplied explicitly so they are scientific assumptions rather than hidden package defaults.}
\usage{nl_validate_candidate(object,predictor,constraints=list(),grid_n=200, extrapolation=.1,k=5,template=NULL,tolerance=1e-8)}
\arguments{
  \item{object}{A refit-capable `nlrfit`.}
  \item{predictor}{Main predictor used to build a dense validation grid.}
  \item{constraints}{Named list. Supported entries are `positive`, `monotonic`}
  \item{grid_n}{Number of grid points.}
  \item{extrapolation}{Fraction of observed predictor range added on each side.}
  \item{k}{Number of CV folds; set `NULL` to skip cross-validation.}
  \item{template}{Optional one-row covariate template for the prediction grid.}
  \item{tolerance}{Numerical tolerance for shape violations.}
}
\value{An `nlr_candidate_validation` object with checks and metrics.}
\examples{
o<-nl_data("okra_growth_means");fo<-nl_fit(data=o,model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls");nl_validate_candidate(fo,"day_after_flowering",list(positive=TRUE,monotonic="increasing",response_range=c(0,30)))
f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy");ff<-nl_fit(data=f,model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls");nl_validate_candidate(ff,"P2O5_kg_ha",list(positive=TRUE,monotonic="increasing"))
s<-subset(nl_data("soil_p_sorption"),soil_class=="Clayey");fs<-nl_fit(data=s,model="langmuir",response="sorbed_P_mg_kg",predictor="solution_P_mg_L",engine="nls");nl_validate_candidate(fs,"solution_P_mg_L",list(positive=TRUE,monotonic="increasing"))
}
