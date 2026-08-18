\name{nl_discover}
\alias{nl_discover}
\title{Knowledge-guided nonlinear equation discovery}
\description{Fits a user-defined set of mechanistically plausible registered models and/or additional nonlinear formulas, then applies the same explicit scientific validation constraints to every successful fit. Symbolic-regression output can therefore be reparameterized into interpretable candidate formulas before entering the inferential comparison.}
\usage{nl_discover(data,response,predictor,models=character(),candidate_formulas=list(), candidate_starts=list(),constraints=list(),engine="nlsLM",k=5,...)}
\arguments{
  \item{data}{Data frame.}
  \item{response}{Response column name.}
  \item{predictor}{Main predictor column name.}
  \item{models}{Registered nlrFlow model names.}
  \item{candidate_formulas}{Optional named list of additional formulas.}
  \item{candidate_starts}{Named list of starts corresponding to `candidate_formulas`.}
  \item{constraints}{Scientific constraint list passed to `nl_validate_candidate`.}
  \item{engine}{Fitting engine.}
  \item{k}{Cross-validation folds.}
  \item{...}{Additional arguments to `nl_fit` for registered models.}
}
\value{An `nlr_discovery` object with successful fits, failures and validation table.}
\examples{
o<-nl_data("okra_growth_means");nl_discover(o,"fruit_length","day_after_flowering",c("gompertz","logistic","richards"),constraints=list(positive=TRUE,monotonic="increasing"),engine="nls")
f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy");nl_discover(f,"grain_yield_Mg_ha","P2O5_kg_ha",c("mitscherlich","michaelis_menten","linear_plateau"),constraints=list(positive=TRUE),engine="nls")
s<-subset(nl_data("soil_p_sorption"),soil_class=="Clayey");nl_discover(s,"sorbed_P_mg_kg","solution_P_mg_L",c("langmuir","freundlich"),constraints=list(positive=TRUE,monotonic="increasing"),engine="nls")
}
