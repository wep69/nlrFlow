\name{nl_discriminate}
\alias{nl_discriminate}
\title{Discriminate among competing nonlinear models}
\description{Compares fitted models using AICc weights, predictive error, constraint status, and pairwise prediction disagreement over a common grid. Non-nested models are not subjected to an invalid likelihood-ratio test.}
\usage{nl_discriminate(fits,predictor,constraints=list(),grid_n=200,extrapolation=.1,k=5)}
\arguments{
  \item{fits}{Named list of `nlrfit` objects or an `nlr_discovery` object.}
  \item{predictor}{Main predictor.}
  \item{constraints}{Optional constraint list for candidate validation.}
  \item{grid_n}{Number of common-grid points.}
  \item{extrapolation}{Prediction-grid extension beyond observed range.}
  \item{k}{Cross-validation folds.}
}
\value{An `nlr_discrimination` object with ranking and disagreement matrix.}
\examples{
o<-nl_data("okra_growth_means");d1<-nl_discover(o,"fruit_length","day_after_flowering",c("gompertz","logistic","richards"),engine="nls");nl_discriminate(d1,"day_after_flowering")
f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy");d2<-nl_discover(f,"grain_yield_Mg_ha","P2O5_kg_ha",c("mitscherlich","michaelis_menten"),engine="nls");nl_discriminate(d2,"P2O5_kg_ha")
s<-subset(nl_data("soil_p_sorption"),soil_class=="Clayey");d3<-nl_discover(s,"sorbed_P_mg_kg","solution_P_mg_L",c("langmuir","freundlich"),engine="nls");nl_discriminate(d3,"solution_P_mg_L")
}
