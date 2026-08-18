\name{nl_symbolic}
\alias{nl_symbolic}
\title{Symbolic regression through PySR}
\description{Runs high-performance symbolic regression through the optional Python `pysr` package (whose search engine is SymbolicRegression.jl). The function returns the Pareto-style equation table rather than silently selecting a biological law. Candidate equations should subsequently be screened with `nl_validate_candidate()` or entered into `nl_discover()` with explicit parameterization and domain constraints.}
\usage{nl_symbolic(data,response,predictors,niterations=200, binary_operators=c("+","-","*","/"), unary_operators=c("exp","log","sqrt"),maxsize=20, model_selection=c("best","accuracy","score"), python_env=NULL,seed=20260817,...)}
\arguments{
  \item{data}{Data frame.}
  \item{response}{Numeric response column name.}
  \item{predictors}{Character vector of numeric predictor columns.}
  \item{niterations}{PySR evolutionary iterations.}
  \item{binary_operators}{Allowed binary operators.}
  \item{unary_operators}{Allowed unary operators.}
  \item{maxsize}{Maximum expression complexity/size.}
  \item{model_selection}{PySR model-selection rule.}
  \item{python_env}{Optional reticulate Python environment name/path.}
  \item{seed}{Random seed forwarded when supported by PySR.}
  \item{...}{Additional named arguments passed to `pysr.PySRRegressor`.}
}
\value{An `nlr_symbolic` object containing the Python model and equation table.}
\examples{
\dontrun{
o <- nl_data("okra_growth_means"); nl_symbolic(o,"fruit_length","day_after_flowering",niterations=100)
f <- nl_data("soil_fertility_p"); nl_symbolic(f,"grain_yield_Mg_ha","P2O5_kg_ha",niterations=100)
p <- nl_data("plant_physiology_light"); nl_symbolic(p,"A_umol_CO2_m2_s","PAR_umol_m2_s",niterations=100)
}
}
