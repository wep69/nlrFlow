
.nl_parameter_glossary <- function() c(
  Asym="Upper asymptote of the response", xmid="Location parameter controlling curve timing", scal="Positive horizontal scale parameter",
  k="Positive rate/curvature parameter", nu="Richards shape/asymmetry parameter", m="Growth-shape exponent",
  delta="Difference between asymptote and low-x response", Vmax="Maximum/saturating response scale", Km="Half-saturation scale",
  bottom="Lower response asymptote", top="Upper response asymptote", EC50="Predictor level associated with the central/half response",
  h="Hill steepness coefficient", y0="Response at the reference/zero predictor", a="Multiplicative scale", b="Power exponent",
  intercept="Intercept of the rising linear segment", slope="Slope/steepness parameter", breakpoint="Predictor value at which the linear plateau begins",
  b0="Quadratic intercept", b1="Quadratic linear coefficient", b2="Quadratic curvature coefficient",
  Amax="Light-saturated assimilation/response scale", alpha="Initial light-use efficiency or scale parameter", theta="Convexity of the non-rectangular hyperbola",
  Rd="Dark respiration/subtractive baseline", baseline="Baseline response", amplitude="Peak amplitude", mu="Peak location", sigma="Peak-width parameter",
  shape="Weibull shape parameter", E0="Baseline response", Emax="Maximum incremental effect", plateau="Long-run plateau",
  qmax="Maximum sorption capacity", K="Langmuir affinity coefficient", Kf="Freundlich sorption coefficient", n="Freundlich/van Genuchten shape parameter as defined by the selected model",
  theta_r="Residual volumetric water content", theta_s="Saturated volumetric water content", Ki="Inhibition constant", f="Hormesis parameter"
)

.nl_tutor_ranges <- function(param) {
  tab <- list(
    Asym=c(1,50,20),xmid=c(-10,60,10),scal=c(.1,30,5),k=c(.001,2,.2),nu=c(.1,6,1),m=c(.2,5,1.5),
    delta=c(.01,30,5),Vmax=c(.1,100,30),Km=c(.01,100,10),bottom=c(-10,30,0),top=c(-5,100,30),EC50=c(.01,100,20),h=c(.1,8,2),
    y0=c(-10,30,1),a=c(.01,20,1),b=c(-3,5,.5),intercept=c(-10,30,1),slope=c(-5,5,.5),breakpoint=c(0,100,40),
    b0=c(-10,30,1),b1=c(-5,5,.5),b2=c(-1,1,-.01),Amax=c(.1,80,30),alpha=c(.001,.5,.06),theta=c(.05,.99,.85),Rd=c(0,10,1.5),
    baseline=c(-10,30,0),amplitude=c(.1,100,20),mu=c(-20,100,30),sigma=c(.1,50,10),shape=c(.1,6,1.5),E0=c(-10,30,0),Emax=c(-30,100,20),
    plateau=c(-10,50,1),qmax=c(1,1500,500),K=c(.0001,2,.1),Kf=c(.01,300,30),n=c(1.01,8,2),theta_r=c(0,.5,.08),theta_s=c(.1,.8,.45),
    Ki=c(.1,500,100),f=c(-2,2,.02)
  )
  tab[[param]] %||% c(-10,10,1)
}

#' Audit data for nonlinear regression
#'
#' Inspects missingness, replication, predictor coverage, response support, grouping variables, and potential scale/outlier flags before model fitting.
#' @param data A data frame.
#' @param response Response column name.
#' @param predictor Primary numeric predictor column name.
#' @param group Optional grouping variable or variables.
#' @return An object of class `nlr_audit` containing summaries, warnings, and an audit trail.
#' @examples
#' # Example 1: okra fruit growth
#' okra <- nl_data("okra_growth_means")
#' # Example 2: soil fertility
#' fert <- nl_data("soil_fertility_p")
#' # Example 3: plant physiology
#' phys <- nl_data("plant_physiology_light")
#' nl_audit(okra, "fruit_length", "day_after_flowering")
#' nl_audit(fert, "grain_yield_Mg_ha", "P2O5_kg_ha", "soil_class")
#' nl_audit(phys, "A_umol_CO2_m2_s", "PAR_umol_m2_s", "water_regime")
#' @export
nl_audit <- function(data, response, predictor, group = NULL) {
  stopifnot(is.data.frame(data), response %in% names(data), predictor %in% names(data))
  y <- data[[response]]; x <- data[[predictor]]
  grp <- if (is.null(group)) NULL else interaction(data[group], drop = TRUE)
  tabx <- table(x)
  warnings <- character()
  if (anyNA(y) || anyNA(x)) warnings <- c(warnings, "Missing values detected in response or predictor.")
  if (length(unique(x[is.finite(x)])) < 5L) warnings <- c(warnings, "Fewer than five distinct predictor values; complex nonlinear models may be weakly identified.")
  if (max(tabx) == 1L) warnings <- c(warnings, "No exact predictor replication detected; pure-error lack-of-fit decomposition is unavailable.")
  q <- stats::quantile(y, c(.25,.5,.75), na.rm=TRUE); iqr <- q[3]-q[1]
  outlier_n <- if (is.finite(iqr) && iqr > 0) sum(y < q[1]-3*iqr | y > q[3]+3*iqr, na.rm=TRUE) else 0L
  structure(list(n=nrow(data), response=response, predictor=predictor, groups=if(is.null(grp)) 0L else nlevels(grp),
                 distinct_x=length(unique(x)), replicated_x=sum(tabx>1), missing=sum(!stats::complete.cases(y,x)),
                 response_range=range(y,na.rm=TRUE), predictor_range=range(x,na.rm=TRUE), extreme_outlier_flags=outlier_n,
                 warnings=warnings,
                 audit=c("Input columns validated","Predictor support inspected","Replication inspected","Scale/outlier screen completed")),
            class="nlr_audit")
}
#' List registered nonlinear models
#'
#' Returns the built-in model registry used by model-based fitting and teaching functions.
#' @return A data frame describing model names, categories, parameters, and equations.
#' @examples
#' # Example 1: okra fruit growth
#' okra <- nl_data("okra_growth_means")
#' # Example 2: soil fertility
#' fert <- nl_data("soil_fertility_p")
#' # Example 3: plant physiology
#' phys <- nl_data("plant_physiology_light")
#' head(nl_models())
#' subset(nl_models(), category == "fertility")
#' subset(nl_models(), category == "physiology")
#' @export
nl_models <- function() {
  reg <- .nl_registry()
  data.frame(model=names(reg), category=vapply(reg, `[[`, "", "category"),
             parameters=vapply(reg, function(z) paste(z$parameters, collapse=", "), ""),
             equation=vapply(reg, `[[`, "", "equation"), row.names=NULL, check.names=FALSE)
}
#' Inspect one nonlinear model
#'
#' Provides equation, parameter names, category, starting-value suggestions, and teaching notes for a registered model.
#' @param model Registered model name.
#' @return A structured list of model information.
#' @examples
#' # Example 1: growth curve
#' nl_model_info("richards")
#' # Example 2: fertility response
#' nl_model_info("mitscherlich")
#' # Example 3: physiology response
#' nl_model_info("nonrectangular_hyperbola")
#' @export
nl_model_info <- function(model) {
  reg <- .nl_registry(); if(!model %in% names(reg)) stop("Unknown model: ",model,call.=FALSE)
  z <- reg[[model]]; gl <- .nl_parameter_glossary()
  z$parameter_table <- data.frame(parameter=z$parameters,meaning=unname(gl[z$parameters]),row.names=NULL,check.names=FALSE)
  z$notes <- switch(z$category,
    sigmoidal="Use data spanning acceleration, inflection and plateau regions whenever possible; shape parameters can be weakly identified when one region is absent.",
    growth="Interpret asymptote, timing and rate only over scientifically supported predictor ranges; avoid extrapolating a plateau from early growth alone.",
    fertility="Interpret response plateaus and breakpoints in the context of agronomic sufficiency, tested dose range and, when relevant, economic information.",
    physiology="Check physical parameter bounds, measurement-scale compatibility and whether low- and high-intensity regions are both observed.",
    soil_sorption="Check concentration units, sorption convention and parameter constraints; compare non-nested isotherms with fit/predictive criteria rather than an LRT.",
    soil_hydraulic="Use physically defensible water-content and shape bounds and preserve repeated measurements within cores when present.",
    dose_response="Check response direction, predictor support around the central effective range and whether hormesis/inhibition is scientifically plausible before adding shape flexibility.",
    "Check parameter identifiability, scientific interpretation and the observed predictor range before extrapolation.")
  z$starting_value_guidance <- "Use nl_start() for a data-informed first attempt, then nl_multistart() or nl_global_start() with scientifically plausible bounds when convergence is sensitive to initialization."
  z
}
#' Inspect backend capabilities
#'
#' Shows which scientific capabilities are implemented and which optional package provides each engine.
#' @return A data frame with capability, engine, optional package, and availability.
#' @examples
#' nl_capabilities()
#' subset(nl_capabilities(), capability == "mixed")
#' subset(nl_capabilities(), available)
#' @export
nl_capabilities <- function() {
  x <- data.frame(
    capability=c(
      "classical","bounded_LM","multistart","global_start","heteroscedastic_correlated",
      "resistant","quantile","mixed","SAEM","Bayesian","Bayesian_LOO","joint_confidence_region",
      "ODE_solve","dynamic_NLME","agricultural_selfstarts","nonlinear_curvature","dose_response",
      "publication_graphics","publication_tables","automatic_differentiation","BayesRTMB_Laplace_NUTS",
      "quantile_mixed","quantile_mixed_sensitivity","conformal","cluster_conformal","measurement_error",
      "joint_mean_variance","censoring_truncation","structural_identifiability_screen","global_sensitivity",
      "optimal_design","stochastic_state_space","process_observation_error","GP_discrepancy","surrogate",
      "cubature_propagation","ABC","symbolic_regression","knowledge_guided_discovery",
      "model_discrimination","sequential_discovery"),
    engine=c(
      "stats::nls","minpack.lm::nlsLM","nls.multstart::nls_multstart","GA::ga","nlme::gnls",
      "robustbase::nlrob","quantreg::nlrq","nlme::nlme","saemix","brms","loo","nlstools::nlsConfRegions",
      "deSolve::ode","nlmixr2::nlmixr2","nlraa","IPEC::curvIPEC","drc","ggplot2","gt",
      "RTMB::MakeADFun","BayesRTMB","qrNLMM::QRNLMM","nlrFlow penalized sensitivity estimator",
      "nlrFlow split conformal","nlrFlow cluster/Mondrian conformal","nlrFlow Gaussian EIV MLE",
      "nlrFlow joint Gaussian mean-logSD","nlrFlow censored/truncated likelihood",
      "nlrFlow local structural sensitivity screen","nlrFlow Morris/Sobol/local","nlrFlow local Fisher design",
      "ctsmTMB","nlrFlow decomposition","DiceKriging::km","DiceKriging/quadratic response surface",
      "nlrFlow sigma-point cubature","nlrFlow rejection ABC","PySR via reticulate",
      "nlrFlow candidate validation","nlrFlow AICc/CV/disagreement","nlrFlow sequential discrimination"),
    package=c(
      "stats","minpack.lm","nls.multstart","GA","nlme","robustbase","quantreg","nlme","saemix","brms","loo",
      "nlstools","deSolve","nlmixr2","nlraa","IPEC","drc","ggplot2","gt","RTMB","BayesRTMB","qrNLMM",
      "internal","internal","internal","internal","internal","internal","internal","internal","internal",
      "ctsmTMB","internal","DiceKriging","DiceKriging","internal","internal","reticulate","internal","internal","internal"),
    stringsAsFactors=FALSE)
  extra <- data.frame(capability=c("neural_ODE","universal_differential_equation","PINN","missing_physics_discovery","UDE_symbolic_discovery","SciML_diagnostics","dynamic_optimal_design","dynamic_control"),
    engine=c("Julia SciML: OrdinaryDiffEq + Lux","Julia SciML: OrdinaryDiffEq + SciMLSensitivity + Lux","Julia NeuralPDE","nlrFlow UDE decomposition","Julia SymbolicRegression.jl","nlrFlow + SciMLSensitivity outputs","nlrFlow dynamic design","Julia Optimization + differentiable model"),
    package=rep("internal",8),stringsAsFactors=FALSE)
  x <- rbind(x,extra)
  x$available <- vapply(x$package,function(pkg) if(pkg=="internal") TRUE else requireNamespace(pkg,quietly=TRUE),logical(1))
  sc <- x$capability %in% c("neural_ODE","universal_differential_equation","PINN","UDE_symbolic_discovery","dynamic_control")
  x$available[sc] <- isTRUE(nl_sciml_available(check_packages=FALSE))
  # Reticulate availability alone does not guarantee that the Python PySR environment is configured.
  x$availability_note <- ifelse(x$capability=="symbolic_regression",
    "TRUE means reticulate is installed; nl_symbolic() also checks for Python package pysr at runtime.","")
  x
}
#' Load a packaged teaching dataset
#'
#' Loads one of the frozen CSV teaching datasets distributed with nlrFlow.
#' @param name Dataset name. Includes the original nonlinear-regression teaching data plus Scientific Machine Learning datasets prefixed with `sciml_`.
#' @return A data frame.
#' @examples
#' # Example 1: raw okra observations
#' head(nl_data("okra_growth_raw"))
#' # Example 2: soil infiltration
#' head(nl_data("soil_infiltration"))
#' # Example 3: agronomy growth
#' head(nl_data("agronomy_growth"))
#' @export
nl_data <- function(name) {
  allowed <- c("okra_growth_raw","okra_growth_means","agronomy_growth","soil_infiltration","soil_fertility_p","soil_water_retention","soil_p_sorption","plant_physiology_light","sciml_crop_growth","sciml_fruit_growth","sciml_soil_water","sciml_fertility_dynamic","sciml_physiology_dynamic","sciml_irrigation_horizon")
  name <- match.arg(name, allowed)
  p <- system.file("extdata", paste0(name,".csv"), package="nlrFlow")
  if (!nzchar(p)) {
    p2 <- file.path("inst","extdata",paste0(name,".csv"))
    if (file.exists(p2)) p <- p2 else stop("Dataset file not found.", call.=FALSE)
  }
  utils::read.csv(p, check.names=FALSE)
}
