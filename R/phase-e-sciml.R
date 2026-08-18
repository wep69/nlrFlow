# Phase E: Scientific machine learning for dynamic agronomic systems ---------

.nl_sciml_file <- function(...) {
  p <- system.file("julia", ..., package = "nlrFlow")
  if (!nzchar(p)) p <- file.path(getwd(), "inst", "julia", ...)
  p
}

.nl_sciml_julia <- function(julia = NULL) {
  julia <- julia %||% Sys.getenv("JULIA", unset = "julia")
  path <- Sys.which(julia)
  if (!nzchar(path)) path <- Sys.which("julia")
  unname(path)
}

.nl_sciml_project <- function() Sys.getenv("NLRFLOW_JULIA_PROJECT", unset = path.expand("~/.nlrFlow/julia"))

.nl_sciml_spec <- function(mode, config, data = NULL, julia = NULL,
                           output_dir = NULL, dry_run = FALSE) {
  out <- output_dir %||% file.path(tempdir(), paste0("nlrflow_", mode, "_", format(Sys.time(), "%Y%m%d%H%M%S")))
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  structure(list(mode = mode, config = config, data = data, julia = .nl_sciml_julia(julia),
                 output_dir = normalizePath(out, mustWork = FALSE), dry_run = dry_run,
                 julia_project = normalizePath(.nl_sciml_project(), mustWork = FALSE),
                 runner = .nl_sciml_file("nlrflow_sciml_runner.jl")),
            class = "nlr_sciml_spec")
}

.nl_sciml_execute <- function(spec) {
  if (!inherits(spec, "nlr_sciml_spec")) stop("spec must be an nlr_sciml_spec.", call. = FALSE)
  if (isTRUE(spec$dry_run)) return(spec)
  if (!nzchar(spec$julia)) stop("Julia was not found. Run nl_sciml_setup() or use dry_run = TRUE to inspect the execution specification.", call. = FALSE)
  .nl_require("jsonlite", "SciML Julia bridge")
  if (!file.exists(spec$runner)) stop("SciML Julia runner was not found in inst/julia.", call. = FALSE)
  input <- file.path(spec$output_dir, "input.csv")
  config <- file.path(spec$output_dir, "config.json")
  if (!is.null(spec$data)) utils::write.csv(spec$data, input, row.names = FALSE)
  jsonlite::write_json(spec$config, config, auto_unbox = TRUE, pretty = TRUE, null = "null", digits = NA)
  project_arg <- paste0("--project=", shQuote(spec$julia_project))
  args <- c(project_arg, shQuote(spec$runner), spec$mode, shQuote(config), if (is.null(spec$data)) "NONE" else shQuote(input), shQuote(spec$output_dir))
  logf <- file.path(spec$output_dir, "julia.log")
  status <- suppressWarnings(system2(spec$julia, args = args, stdout = logf, stderr = logf))
  if (!identical(as.integer(status), 0L)) {
    logtxt <- if (file.exists(logf)) paste(readLines(logf, warn = FALSE), collapse = "\n") else ""
    stop("Julia SciML backend failed. See ", logf, if(nzchar(logtxt)) paste0("\n", logtxt) else "", call. = FALSE)
  }
  read_if <- function(name) {f <- file.path(spec$output_dir, name); if(file.exists(f)) utils::read.csv(f, check.names = FALSE) else NULL}
  list(predictions = read_if("predictions.csv"), training = read_if("training.csv"),
       decomposition = read_if("decomposition.csv"), diagnostics = read_if("diagnostics.csv"),
       summary = read_if("summary.csv"), parameters = read_if("parameters.csv"),
       candidates = read_if("candidates.csv"), design = read_if("design.csv"),
       control = read_if("control.csv"), model_file = file.path(spec$output_dir, "model.jls"),
       log_file = logf)
}

#' Check whether the optional Julia/SciML backend is available
#'
#' Checks for a Julia executable and, optionally, whether the Julia packages used by
#' the nlrFlow SciML layer can be imported. No software is installed.
#' @param julia Optional path or executable name.
#' @param check_packages Logical; also test required Julia packages.
#' @return A logical value with diagnostic attributes.
#' @examples
#' nl_sciml_available(check_packages = FALSE)
#' attr(nl_sciml_available(check_packages = FALSE), "julia")
#' is.logical(nl_sciml_available(check_packages = FALSE))
#' @export
nl_sciml_available <- function(julia = NULL, check_packages = FALSE) {
  exe <- .nl_sciml_julia(julia); ok <- nzchar(exe)
  packages_ok <- NA
  if (ok && isTRUE(check_packages)) {
    expr <- "using OrdinaryDiffEq, SciMLSensitivity, Lux, Optimization, OptimizationOptimisers, OptimizationOptimJL, ComponentArrays, NeuralPDE, SymbolicRegression, CSV, DataFrames, JSON3, Zygote, Optim"
    status <- suppressWarnings(system2(exe, c(paste0("--project=", shQuote(.nl_sciml_project())), "-e", shQuote(expr)), stdout = FALSE, stderr = FALSE))
    packages_ok <- identical(as.integer(status), 0L); ok <- ok && packages_ok
  }
  structure(ok, julia = exe, packages_ok = packages_ok)
}

#' Inspect the SciML backend map
#'
#' Returns the Julia packages used by blocks 68--74 and their roles.
#' @return A data frame.
#' @examples
#' nl_sciml_info()
#' subset(nl_sciml_info(), block == 69)
#' subset(nl_sciml_info(), grepl("design|control", role, ignore.case = TRUE))
#' @export
nl_sciml_info <- function() {
  data.frame(
    block = c(68,68,69,69,70,70,71,72,73,74,74),
    package = c("OrdinaryDiffEq","Lux","SciMLSensitivity","Optimization","NeuralPDE","ModelingToolkit",
                "SciMLSensitivity","SymbolicRegression","SciMLSensitivity","Optimization","OptimizationOptimJL"),
    role = c("ODE integration","neural derivative","differentiable UDE solver","parameter training",
             "PINN discretization and inverse problems","symbolic ODE/PDE definitions","missing-physics sensitivities",
             "equation discovery","gradient and solver diagnostics",
             "dynamic experimental design","bounded optimal control"),
    required = c(TRUE,TRUE,TRUE,TRUE,TRUE,FALSE,TRUE,TRUE,TRUE,TRUE,TRUE),
    stringsAsFactors = FALSE)
}

#' Prepare or install the optional Julia SciML environment
#'
#' By default this function only returns a reproducible setup specification. With
#' `install = TRUE`, it invokes the bundled Julia setup script. It never installs
#' Julia itself.
#' @param install Logical; actually run Julia package installation.
#' @param julia Optional Julia executable.
#' @param env_dir Directory for the dedicated Julia environment.
#' @return A setup report.
#' @examples
#' nl_sciml_setup(install = FALSE)
#' nl_sciml_setup(FALSE)$packages
#' nl_sciml_setup(FALSE)$environment
#' @export
nl_sciml_setup <- function(install = FALSE, julia = NULL,
                           env_dir = path.expand("~/.nlrFlow/julia")) {
  pkgs <- c("OrdinaryDiffEq","SciMLSensitivity","Lux","Optimization","OptimizationOptimisers",
            "OptimizationOptimJL","ComponentArrays","NeuralPDE","ModelingToolkit","SymbolicRegression",
            "CSV","DataFrames","JSON3","StableRNGs","LineSearches","Optim","Zygote")
  exe <- .nl_sciml_julia(julia)
  out <- list(julia = exe, environment = normalizePath(env_dir, mustWork = FALSE), packages = pkgs,
              installed = FALSE, note = "Julia is optional. The core nlrFlow package remains usable without it. Set NLRFLOW_JULIA_PROJECT to use a non-default Julia environment.")
  if (!install) return(out)
  if (!nzchar(exe)) stop("Julia executable was not found; install Julia first and rerun nl_sciml_setup(install=TRUE).", call. = FALSE)
  script <- .nl_sciml_file("setup_sciml.jl"); if(!file.exists(script)) stop("Bundled setup_sciml.jl was not found.", call.=FALSE)
  dir.create(env_dir, recursive = TRUE, showWarnings = FALSE)
  status <- system2(exe, c(shQuote(script), shQuote(normalizePath(env_dir, mustWork = FALSE))))
  out$installed <- identical(as.integer(status), 0L)
  if (out$installed) Sys.setenv(NLRFLOW_JULIA_PROJECT = normalizePath(env_dir, mustWork = FALSE))
  out
}

.nl_sciml_validate_dynamic_data <- function(data, time, states, covariates = character()) {
  req <- unique(c(time, states, covariates)); if(!all(req %in% names(data))) stop("All time, state and covariate columns must be present in data.", call.=FALSE)
  if(!is.numeric(data[[time]]) || any(!vapply(data[c(states,covariates)], is.numeric, logical(1)))) stop("SciML time, states, and covariates must be numeric.", call.=FALSE)
  if(any(!is.finite(as.matrix(data[req])))) stop("SciML input columns must contain finite values.", call.=FALSE)
  if(anyDuplicated(data[[time]])) stop("Neural ODE/UDE input must represent one trajectory with one row per time; subset grouping units before fitting.", call.=FALSE)
  if(length(unique(data[[time]])) < 3L) stop("At least three distinct time points are required.", call.=FALSE)
  invisible(TRUE)
}

#' Fit a Neural ODE to an agronomic dynamic trajectory
#'
#' Fits a continuous-time neural differential equation in which a Lux neural
#' network represents the derivative of one or more observed states. Exogenous
#' covariates are linearly interpolated through time. Julia/SciML is an optional
#' backend; `dry_run=TRUE` returns the complete execution specification without
#' running Julia.
#' @param data Data frame for one dynamic trajectory.
#' @param time Time column.
#' @param states Character vector of response/state columns.
#' @param covariates Numeric time-varying covariates.
#' @param hidden Hidden-layer widths.
#' @param activation Activation function (`tanh`, `relu`, or `swish`).
#' @param maxiters Adam iterations before optional BFGS refinement.
#' @param learning_rate Adam learning rate.
#' @param weight_decay Nonnegative L2 penalty on neural-network parameters.
#' @param refine Logical; perform BFGS refinement.
#' @param seed Reproducible seed.
#' @param julia Julia executable.
#' @param output_dir Optional persistent output directory.
#' @param dry_run Return specification without execution.
#' @return An `nlr_neural_ode` object or an `nlr_sciml_spec` in dry-run mode.
#' @examples
#' d<-subset(nl_data("sciml_fruit_growth"),fruit_id==unique(nl_data("sciml_fruit_growth")$fruit_id)[1]);nl_neural_ode(d,"day_after_set","fruit_mass_g",c("temperature_C","soil_water_rel"),dry_run=TRUE)
#' d<-subset(nl_data("sciml_crop_growth"),plot_id==unique(nl_data("sciml_crop_growth")$plot_id)[1]);nl_neural_ode(d,"day","biomass_g_m2",c("temperature_C","PAR_MJ_m2_d","soil_water_rel","nitrogen_rel"),dry_run=TRUE)
#' d<-subset(nl_data("sciml_physiology_dynamic"),plant_id==unique(nl_data("sciml_physiology_dynamic")$plant_id)[1]);nl_neural_ode(d,"hour",c("A_umol_CO2_m2_s","gs_mol_H2O_m2_s"),c("PAR_umol_m2_s","VPD_kPa","leaf_temperature_C","soil_water_rel"),dry_run=TRUE)
#' @export
nl_neural_ode <- function(data,time,states,covariates=character(),hidden=c(16,16),activation="tanh",
                          maxiters=500,learning_rate=.01,weight_decay=0,refine=TRUE,seed=20260817,
                          julia=NULL,output_dir=NULL,dry_run=FALSE) {
  .nl_sciml_validate_dynamic_data(data,time,states,covariates); data<-data[order(data[[time]]),,drop=FALSE]
  activation<-match.arg(activation,c("tanh","relu","swish"))
  if(length(hidden)<1L||any(!is.finite(hidden))||any(hidden<1))stop("hidden must contain positive finite layer widths.",call.=FALSE)
  if(!is.numeric(weight_decay)||length(weight_decay)!=1L||!is.finite(weight_decay)||weight_decay<0)stop("weight_decay must be a finite nonnegative scalar.",call.=FALSE)
  cfg<-list(time=time,states=states,covariates=covariates,hidden=as.integer(hidden),activation=activation,
            maxiters=as.integer(maxiters),learning_rate=learning_rate,weight_decay=weight_decay,refine=refine,seed=as.integer(seed))
  spec<-.nl_sciml_spec("neural_ode",cfg,data,julia,output_dir,dry_run); if(dry_run)return(spec)
  res<-.nl_sciml_execute(spec)
  structure(c(list(method="neural_ode",data=data,time=time,states=states,covariates=covariates,spec=spec),res),class="nlr_neural_ode")
}

.nl_ude_template <- function(template, states, covariates, known_parameters) {
  template <- match.arg(template,c("generic","crop_growth_rue","fruit_growth","nitrogen_uptake","soil_carbon"))
  if(template=="generic") return(NULL)
  requirements <- list(
    crop_growth_rue=list(states=1L,covariates=c("PAR_MJ_m2_d","temperature_C","soil_water_rel"),parameters=c("RUE","Topt","Twidth","respiration")),
    fruit_growth=list(states=1L,covariates="soil_water_rel",parameters=c("r","K")),
    nitrogen_uptake=list(states=2L,covariates="soil_water_rel",parameters=c("vmax","Km")),
    soil_carbon=list(states=1L,covariates=c("temperature_C","soil_water_rel"),parameters=c("k","Q10")))
  rq <- requirements[[template]]
  if(length(states)!=rq$states) stop("Template '",template,"' requires ",rq$states," state(s).",call.=FALSE)
  missc <- setdiff(rq$covariates,covariates); if(length(missc)) stop("Template '",template,"' requires covariate(s): ",paste(missc,collapse=", "),call.=FALSE)
  missp <- setdiff(rq$parameters,names(known_parameters)); if(length(missp)) stop("Template '",template,"' requires known parameter(s): ",paste(missp,collapse=", "),call.=FALSE)
  if(template=="crop_growth_rue") return(c("kp[\"RUE\"]*cov[\"PAR_MJ_m2_d\"]*exp(-((cov[\"temperature_C\"]-kp[\"Topt\"])/kp[\"Twidth\"])^2)*cov[\"soil_water_rel\"]-kp[\"respiration\"]*u[1]"))
  if(template=="fruit_growth") return(c("kp[\"r\"]*u[1]*(1-u[1]/kp[\"K\"])*cov[\"soil_water_rel\"]"))
  if(template=="nitrogen_uptake") return(c("kp[\"vmax\"]*u[2]/(kp[\"Km\"]+u[2])*cov[\"soil_water_rel\"]", "-kp[\"vmax\"]*u[2]/(kp[\"Km\"]+u[2])*cov[\"soil_water_rel\"]"))
  if(template=="soil_carbon") return(c("-kp[\"k\"]*u[1]*(kp[\"Q10\"]^((cov[\"temperature_C\"]-20)/10))*cov[\"soil_water_rel\"]"))
}

#' Fit a Universal Differential Equation (UDE)
#'
#' Combines a known mechanistic derivative with a neural correction. This is the
#' preferred SciML mode when agronomic knowledge is available but incomplete.
#' Built-in templates cover radiation-use-efficiency crop growth, fruit growth,
#' N uptake, and soil-carbon turnover; advanced users may supply Julia derivative
#' expressions through `known_rhs`.
#' @param data One dynamic trajectory.
#' @param time Time column.
#' @param states State columns.
#' @param covariates Numeric covariates.
#' @param template Mechanistic template or `generic`.
#' @param known_parameters Named numeric vector/list of mechanistic parameters.
#' @param known_rhs Optional character vector of Julia expressions, one per state.
#' @param neural_scale Multiplicative scale for the learned correction.
#' @param hidden Hidden-layer widths.
#' @param maxiters Training iterations.
#' @param learning_rate Adam learning rate.
#' @param weight_decay Nonnegative L2 penalty on the neural correction; useful for protecting mechanistic interpretability.
#' @param refine Logical BFGS refinement.
#' @param seed Seed.
#' @param julia Julia executable.
#' @param output_dir Optional output directory.
#' @param dry_run Return specification only.
#' @return An `nlr_ude` object or dry-run specification.
#' @examples
#' d<-subset(nl_data("sciml_crop_growth"),plot_id==unique(nl_data("sciml_crop_growth")$plot_id)[1]);nl_ude(d,"day","biomass_g_m2",c("temperature_C","PAR_MJ_m2_d","soil_water_rel","nitrogen_rel"),template="crop_growth_rue",known_parameters=c(RUE=2.8,Topt=26,Twidth=10,respiration=.01),dry_run=TRUE)
#' d<-subset(nl_data("sciml_fruit_growth"),fruit_id==unique(nl_data("sciml_fruit_growth")$fruit_id)[1]);nl_ude(d,"day_after_set","fruit_mass_g",c("temperature_C","soil_water_rel"),template="fruit_growth",known_parameters=c(r=.2,K=200),dry_run=TRUE)
#' d<-subset(nl_data("sciml_fertility_dynamic"),plot_id==unique(nl_data("sciml_fertility_dynamic")$plot_id)[1]);nl_ude(d,"day",c("plant_N_g_m2","soil_mineral_N_mg_kg"),c("temperature_C","soil_water_rel"),template="nitrogen_uptake",known_parameters=c(vmax=.08,Km=20),dry_run=TRUE)
#' @export
nl_ude <- function(data,time,states,covariates=character(),template=c("generic","crop_growth_rue","fruit_growth","nitrogen_uptake","soil_carbon"),
                   known_parameters=numeric(),known_rhs=NULL,neural_scale=1,hidden=c(16,16),maxiters=600,
                   learning_rate=.01,weight_decay=1e-6,refine=TRUE,seed=20260817,julia=NULL,output_dir=NULL,dry_run=FALSE) {
  .nl_sciml_validate_dynamic_data(data,time,states,covariates);template<-match.arg(template);data<-data[order(data[[time]]),,drop=FALSE]
  if(length(hidden)<1L||any(!is.finite(hidden))||any(hidden<1))stop("hidden must contain positive finite layer widths.",call.=FALSE)
  if(!is.numeric(neural_scale)||length(neural_scale)!=1L||!is.finite(neural_scale)||neural_scale<0)stop("neural_scale must be a finite nonnegative scalar.",call.=FALSE)
  kp<-as.numeric(known_parameters);names(kp)<-names(known_parameters);if(any(!is.finite(kp)))stop("known_parameters must be finite.",call.=FALSE)
  rhs<-known_rhs %||% .nl_ude_template(template,states,covariates,kp);if(is.null(rhs)||length(rhs)!=length(states))stop("Provide one known_rhs expression per state or use a compatible template.",call.=FALSE)
  if(!is.numeric(weight_decay)||length(weight_decay)!=1L||!is.finite(weight_decay)||weight_decay<0)stop("weight_decay must be a finite nonnegative scalar.",call.=FALSE)
  cfg<-list(time=time,states=states,covariates=covariates,template=template,known_parameters=as.list(kp),known_rhs=as.list(rhs),
            neural_scale=neural_scale,hidden=as.integer(hidden),maxiters=as.integer(maxiters),learning_rate=learning_rate,weight_decay=weight_decay,
            refine=refine,seed=as.integer(seed))
  spec<-.nl_sciml_spec("ude",cfg,data,julia,output_dir,dry_run);if(dry_run)return(spec)
  res<-.nl_sciml_execute(spec);structure(c(list(method="ude",data=data,time=time,states=states,covariates=covariates,template=template,spec=spec),res),class="nlr_ude")
}

#' Fit a physics-informed neural network (PINN)
#'
#' Provides PINN workflows for a discretized one-dimensional Richards soil-water
#' equation and for simple ODE growth templates. The Richards mode uses soil-depth
#' states and can combine physical residuals with observed water contents through
#' NeuralPDE's ODE-specialized PINN algorithm.
#' @param data Data frame.
#' @param problem `richards_1d`, `logistic_growth`, or `first_order_nutrient`.
#' @param time Time column.
#' @param response Response/state column for one-state problems; water-content column for Richards mode.
#' @param depth Depth column for `richards_1d`.
#' @param covariates Optional numeric covariates.
#' @param parameters Named physical parameters. Richards expects `theta_r`, `theta_s`, `alpha`, `n`, and `Ks`.
#' @param estimate_parameters Logical; allow NeuralPDE inverse estimation where supported.
#' @param hidden Hidden-layer widths.
#' @param maxiters Maximum PINN optimizer iterations.
#' @param strategy Collocation strategy: `weighted_interval` (recommended for ODE-specialized PINNs) or `grid` (mainly for testing/reproducibility).
#' @param collocation_points Number of collocation samples used by `weighted_interval`.
#' @param seed Seed.
#' @param julia Julia executable.
#' @param output_dir Output directory.
#' @param dry_run Return execution specification only.
#' @return An `nlr_pinn` object or dry-run specification.
#' @examples
#' s<-nl_data("sciml_soil_water");nl_pinn(s,"richards_1d","day","theta_cm3_cm3",depth="depth_cm",covariates=c("rain_mm_d","ET0_mm_d"),parameters=c(theta_r=.06,theta_s=.46,alpha=.035,n=1.55,Ks=12),dry_run=TRUE)
#' f<-subset(nl_data("sciml_fruit_growth"),fruit_id==unique(nl_data("sciml_fruit_growth")$fruit_id)[1]);nl_pinn(f,"logistic_growth","day_after_set","fruit_mass_g",parameters=c(r=.2,K=200),dry_run=TRUE)
#' n<-subset(nl_data("sciml_fertility_dynamic"),plot_id==unique(nl_data("sciml_fertility_dynamic")$plot_id)[1]);nl_pinn(n,"first_order_nutrient","day","plant_N_g_m2",parameters=c(k=.08,K=18),dry_run=TRUE)
#' @export
nl_pinn <- function(data,problem=c("richards_1d","logistic_growth","first_order_nutrient"),time,response,depth=NULL,
                    covariates=character(),parameters=numeric(),estimate_parameters=FALSE,hidden=c(24,24),maxiters=1500,
                    strategy=c("weighted_interval","grid"),collocation_points=500,seed=20260817,julia=NULL,output_dir=NULL,dry_run=FALSE) {
  problem<-match.arg(problem);strategy<-match.arg(strategy)
  if(problem=="richards_1d"&&(is.null(depth)||length(depth)!=1L||!nzchar(depth)))stop("depth must name the soil-depth column for richards_1d.",call.=FALSE)
  req<-c(time,response,covariates);if(problem=="richards_1d")req<-c(req,depth)
  if(!all(req%in%names(data)))stop("PINN columns are missing from data.",call.=FALSE);if(any(!vapply(data[req],is.numeric,logical(1))))stop("PINN input columns must be numeric.",call.=FALSE)
  if(any(!is.finite(as.matrix(data[req]))))stop("PINN input columns must contain finite values.",call.=FALSE)
  if(problem!="richards_1d"&&anyDuplicated(data[[time]]))stop("One-state PINN input must contain one row per time; subset grouping units before fitting.",call.=FALSE)
  if(length(unique(data[[time]]))<3L)stop("At least three distinct times are required.",call.=FALSE)
  if(length(hidden)<1L||any(!is.finite(hidden))||any(hidden<1))stop("hidden must contain positive finite layer widths.",call.=FALSE)
  pars<-as.numeric(parameters);names(pars)<-names(parameters)
  required_pars<-switch(problem,richards_1d=c("theta_r","theta_s","alpha","n","Ks"),logistic_growth=c("r","K"),first_order_nutrient=c("k","K"))
  if(!all(required_pars%in%names(pars)))stop(problem," PINN requires parameter(s): ",paste(required_pars,collapse=", "),".",call.=FALSE)
  if(any(!is.finite(pars[required_pars])))stop("PINN physical parameters must be finite.",call.=FALSE)
  if(problem=="richards_1d"&&(pars["theta_s"]<=pars["theta_r"]||pars["alpha"]<=0||pars["n"]<=1||pars["Ks"]<=0))stop("Richards parameters require theta_s > theta_r, alpha > 0, n > 1, and Ks > 0.",call.=FALSE)
  if(problem=="logistic_growth"&&any(pars[c("r","K")]<=0))stop("Logistic PINN requires r > 0 and K > 0.",call.=FALSE)
  if(problem=="first_order_nutrient"&&any(pars[c("k","K")]<=0))stop("First-order nutrient PINN requires k > 0 and K > 0.",call.=FALSE)
  if(!is.numeric(collocation_points)||length(collocation_points)!=1L||!is.finite(collocation_points)||collocation_points<50)stop("collocation_points must be a finite scalar >= 50.",call.=FALSE)
  cfg<-list(problem=problem,time=time,response=response,depth=depth,covariates=covariates,parameters=as.list(pars),
            estimate_parameters=estimate_parameters,hidden=as.integer(hidden),maxiters=as.integer(maxiters),strategy=strategy,
            collocation_points=as.integer(collocation_points),seed=as.integer(seed))
  spec<-.nl_sciml_spec("pinn",cfg,data,julia,output_dir,dry_run);if(dry_run)return(spec)
  res<-.nl_sciml_execute(spec);structure(c(list(method="pinn",data=data,problem=problem,time=time,response=response,depth=depth,spec=spec),res),class="nlr_pinn")
}

#' Extract and summarize the missing mechanism learned by a UDE
#'
#' Separates known and neural derivative contributions, computes their relative
#' importance, and identifies where the learned correction is largest.
#' @param object An `nlr_ude` object.
#' @param state Optional state name; defaults to all states.
#' @param threshold Relative neural contribution used to flag important regions.
#' @return An `nlr_missing_physics` object.
#' @examples
#' fake1<-structure(list(decomposition=data.frame(time=0:2,state="biomass",known=c(2,2,1),neural=c(.2,.6,.1),total=c(2.2,2.6,1.1))),class="nlr_ude");nl_missing_physics(fake1)
#' fake2<-structure(list(decomposition=data.frame(time=0:2,state="fruit",known=c(3,2,1),neural=c(.1,-.2,.5),total=c(3.1,1.8,1.5))),class="nlr_ude");nl_missing_physics(fake2,threshold=.15)
#' fake3<-structure(list(decomposition=data.frame(time=0:2,state=c("plantN","plantN","plantN"),known=c(.5,.4,.3),neural=c(.3,.1,.05),total=c(.8,.5,.35))),class="nlr_ude");nl_missing_physics(fake3,"plantN")
#' @export
nl_missing_physics <- function(object,state=NULL,threshold=.25) {
  if(!is.numeric(threshold)||length(threshold)!=1L||!is.finite(threshold)||threshold<0||threshold>1)stop("threshold must be between 0 and 1.",call.=FALSE)
  if(!inherits(object,"nlr_ude"))stop("object must be an executed nlr_ude result; a dry-run specification has no learned mechanism.",call.=FALSE)
  d<-object$decomposition;if(is.null(d))stop("The UDE backend did not return decomposition.csv.",call.=FALSE)
  if(!is.null(state)){if(!state%in%d$state)stop("Requested state is absent.",call.=FALSE);d<-d[d$state==state,,drop=FALSE]}
  den<-pmax(abs(d$known)+abs(d$neural),.Machine$double.eps);d$neural_fraction<-abs(d$neural)/den;d$important<-d$neural_fraction>=threshold
  sm<-stats::aggregate(cbind(abs_known=abs(d$known),abs_neural=abs(d$neural),neural_fraction=d$neural_fraction),list(state=d$state),mean,na.rm=TRUE)
  structure(list(decomposition=d,summary=sm,threshold=threshold,source=object),class="nlr_missing_physics")
}

#' Discover symbolic equations from a learned UDE correction
#'
#' Applies SymbolicRegression.jl to the learned neural derivative. The returned
#' Pareto frontier is a hypothesis set, not proof of a biological law; candidates
#' should be validated and, ideally, tested in new experiments.
#' @param object Executed `nlr_ude` or `nlr_missing_physics` object.
#' @param predictors Columns of the decomposition table used to explain the neural correction.
#' @param state Optional state.
#' @param niterations Symbolic-regression iterations.
#' @param binary_operators Allowed binary operators.
#' @param unary_operators Allowed unary operators.
#' @param maxsize Maximum expression size.
#' @param seed Seed.
#' @param parallelism SymbolicRegression.jl search mode: `serial` (default, reproducibility-focused) or `multithreading`.
#' @param deterministic Logical; request deterministic birth-order bookkeeping. This requires serial search.
#' @param julia Julia executable.
#' @param output_dir Output directory.
#' @param dry_run Return specification only.
#' @return An `nlr_ude_discovery` object or dry-run specification.
#' @examples
#' d<-subset(nl_data("sciml_crop_growth"),plot_id==unique(nl_data("sciml_crop_growth")$plot_id)[1]);u<-nl_ude(d,"day","biomass_g_m2",c("temperature_C","PAR_MJ_m2_d","soil_water_rel","nitrogen_rel"),template="crop_growth_rue",known_parameters=c(RUE=2.8,Topt=26,Twidth=10,respiration=.01),dry_run=TRUE);nl_ude_discover(u,c("nitrogen_rel","soil_water_rel"),dry_run=TRUE)
#' d<-subset(nl_data("sciml_fruit_growth"),fruit_id==unique(nl_data("sciml_fruit_growth")$fruit_id)[1]);u<-nl_ude(d,"day_after_set","fruit_mass_g",c("temperature_C","soil_water_rel"),template="fruit_growth",known_parameters=c(r=.2,K=200),dry_run=TRUE);nl_ude_discover(u,c("temperature_C","soil_water_rel"),dry_run=TRUE)
#' d<-subset(nl_data("sciml_fertility_dynamic"),plot_id==unique(nl_data("sciml_fertility_dynamic")$plot_id)[1]);u<-nl_ude(d,"day",c("plant_N_g_m2","soil_mineral_N_mg_kg"),c("temperature_C","soil_water_rel"),template="nitrogen_uptake",known_parameters=c(vmax=.08,Km=20),dry_run=TRUE);nl_ude_discover(u,c("temperature_C","soil_water_rel"),state="plant_N_g_m2",dry_run=TRUE)
#' @export
nl_ude_discover <- function(object,predictors,state=NULL,niterations=200,binary_operators=c("+","-","*","/"),
                            unary_operators=c("exp","log","sqrt"),maxsize=18,seed=20260817,
                            parallelism=c("serial","multithreading"),deterministic=TRUE,
                            julia=NULL,output_dir=NULL,dry_run=FALSE) {
  parallelism<-match.arg(parallelism)
  if(isTRUE(deterministic)&&parallelism!="serial")stop("deterministic=TRUE requires parallelism='serial' in SymbolicRegression.jl.",call.=FALSE)
  base_cfg<-list(predictors=predictors,state=state,niterations=as.integer(niterations),binary_operators=binary_operators,unary_operators=unary_operators,maxsize=as.integer(maxsize),seed=as.integer(seed),parallelism=parallelism,deterministic=isTRUE(deterministic))
  if(inherits(object,"nlr_sciml_spec") && isTRUE(dry_run)) {cfg<-c(list(source_spec=object$config),base_cfg);return(.nl_sciml_spec("ude_symbolic",cfg,NULL,julia,output_dir,TRUE))}
  if(inherits(object,"nlr_missing_physics")) d<-object$decomposition else if(inherits(object,"nlr_ude")) d<-object$decomposition else if(inherits(object,"nlr_sciml_spec")) d<-object$data else stop("object must be a UDE, missing-physics result, or UDE dry-run spec.",call.=FALSE)
  if(is.null(d)){if(inherits(object,"nlr_sciml_spec")){cfg<-c(list(source_spec=object$config),base_cfg);return(.nl_sciml_spec("ude_symbolic",cfg,NULL,julia,output_dir,TRUE))};stop("No UDE decomposition is available.",call.=FALSE)}
  if(!is.null(state)&&"state"%in%names(d))d<-d[d$state==state,,drop=FALSE];if(!all(predictors%in%names(d)))stop("predictors must occur in the UDE decomposition table.",call.=FALSE)
  target<-if("neural"%in%names(d))"neural" else stop("UDE decomposition must contain a neural column.",call.=FALSE)
  cfg<-c(list(response=target),base_cfg)
  spec<-.nl_sciml_spec("symbolic",cfg,d,julia,output_dir,dry_run);if(dry_run)return(spec);res<-.nl_sciml_execute(spec)
  structure(c(list(method="ude_symbolic",source=object,predictors=predictors,state=state,spec=spec),res),class="nlr_ude_discovery")
}

#' Diagnose Neural ODE, UDE, and PINN fits
#'
#' Combines data-fit error, training stability, physics loss when available,
#' neural-correction magnitude, and seed-to-seed variability into an interpretable
#' diagnostic table.
#' @param object Executed Neural ODE, UDE, or PINN object.
#' @param thresholds Named thresholds for `rmse_ratio`, `physics_loss`, and `neural_fraction`.
#' @param seed_fits Optional list of repeated fits from different seeds.
#' @return An `nlr_sciml_diagnostics` object.
#' @examples
#' f1<-structure(list(predictions=data.frame(time=0:2,y_observed=c(1,2,3),y_predicted=c(1.1,2.1,2.9)),time="time",states="y",training=data.frame(iteration=1:3,loss=c(1,.2,.05))),class="nlr_neural_ode");nl_sciml_diagnose(f1)
#' f2<-structure(list(predictions=data.frame(time=0:2,y_observed=c(1,2,3),y_predicted=c(1,2,3)),time="time",states="y",training=data.frame(iteration=1:2,loss=c(.2,.02)),decomposition=data.frame(known=c(1,1,1),neural=c(.1,.2,.1))),class="nlr_ude");nl_sciml_diagnose(f2)
#' f3<-structure(list(predictions=data.frame(time=0:2,y_observed=c(1,2,3),y_predicted=c(1,2.2,2.8)),time="time",states="y",diagnostics=data.frame(metric="physics_loss",value=.01)),class="nlr_pinn");nl_sciml_diagnose(f3)
#' @export
nl_sciml_diagnose <- function(object,thresholds=c(rmse_ratio=.20,physics_loss=.05,neural_fraction=.50),seed_fits=NULL) {
  if(inherits(object,"nlr_sciml_spec"))stop("Diagnostics require an executed fit, not dry_run=TRUE.",call.=FALSE)
  ok<-inherits(object,c("nlr_neural_ode","nlr_ude","nlr_pinn"));if(!ok)stop("Unsupported SciML object.",call.=FALSE)
  pr<-object$predictions;if(is.null(pr))stop("No predictions were returned.",call.=FALSE)
  rows<-list()
  if(all(c("observed","predicted")%in%names(pr))){
    st<-as.character(object$response %||% "state");rmse<-.nl_rmse(pr$observed,pr$predicted);scale<-diff(range(pr$observed,na.rm=TRUE));ratio<-rmse/max(scale,.Machine$double.eps)
    rows[[length(rows)+1]]<-data.frame(metric=paste0("RMSE_ratio:",st[1]),value=ratio,threshold=thresholds["rmse_ratio"],status=if(ratio<=thresholds["rmse_ratio"])"PASS" else "CHECK")
  } else {
    state_cols<-as.character(object$states %||% object$response)
    for(st in state_cols){obsnm<-paste0(st,"_observed");prednm<-paste0(st,"_predicted");if(!all(c(obsnm,prednm)%in%names(pr)))next;rmse<-.nl_rmse(pr[[obsnm]],pr[[prednm]]);scale<-diff(range(pr[[obsnm]],na.rm=TRUE));ratio<-rmse/max(scale,.Machine$double.eps);rows[[length(rows)+1]]<-data.frame(metric=paste0("RMSE_ratio:",st),value=ratio,threshold=thresholds["rmse_ratio"],status=if(ratio<=thresholds["rmse_ratio"])"PASS" else "CHECK")}
  }
  if(!is.null(object$diagnostics)&&all(c("metric","value")%in%names(object$diagnostics))){z<-object$diagnostics;for(i in seq_len(nrow(z))){thr<-if(z$metric[i]=="physics_loss")thresholds["physics_loss"] else NA;rows[[length(rows)+1]]<-data.frame(metric=z$metric[i],value=z$value[i],threshold=thr,status=if(is.finite(thr)&&z$value[i]>thr)"CHECK" else "INFO")}}
  if(inherits(object,"nlr_ude")&&!is.null(object$decomposition)){den<-abs(object$decomposition$known)+abs(object$decomposition$neural);nf<-mean(abs(object$decomposition$neural)/pmax(den,.Machine$double.eps),na.rm=TRUE);rows[[length(rows)+1]]<-data.frame(metric="mean_neural_fraction",value=nf,threshold=thresholds["neural_fraction"],status=if(nf<=thresholds["neural_fraction"])"PASS" else "CHECK")}
  seed_sd<-NA_real_;if(!is.null(seed_fits)&&length(seed_fits)>1){lastloss<-vapply(seed_fits,function(z){tr<-z$training;if(is.null(tr)||!"loss"%in%names(tr))NA_real_ else tail(tr$loss,1)},numeric(1));seed_sd<-stats::sd(lastloss,na.rm=TRUE);rows[[length(rows)+1]]<-data.frame(metric="seed_final_loss_sd",value=seed_sd,threshold=NA,status="INFO")}
  structure(list(table=if(length(rows))do.call(rbind,rows) else data.frame(),training=object$training,seed_sd=seed_sd,object=object),class="nlr_sciml_diagnostics")
}

#' Optimize measurement times for a dynamic SciML model
#'
#' Scores candidate times using trajectory curvature, predictive disagreement, or
#' uncertainty supplied by an executed dynamic model. It can be used after a UDE
#' or Neural ODE to decide when the next destructive or sensor measurement should
#' be collected.
#' @param object Executed SciML model or a list of competing executed models.
#' @param candidates Candidate time or depth values.
#' @param dimension Design axis: `time` for all dynamic models or `depth` for long-form Richards PINN output.
#' @param n_points Number of times to select.
#' @param criterion `curvature`, `discrimination`, or `uncertainty`.
#' @param min_distance Minimum spacing between selected times.
#' @return An `nlr_dynamic_design` object.
#' @examples
#' x<-data.frame(time=seq(0,30,by=3),fruit_mass_g=seq(5,190,length.out=11));fake<-structure(list(predictions=data.frame(time=x$time,fruit_mass_g_predicted=x$fruit_mass_g),time="time",states="fruit_mass_g"),class="nlr_neural_ode");nl_dynamic_design(fake,0:30,3)
#' x<-data.frame(time=0:20,y_predicted=(0:20)^2);fake<-structure(list(predictions=x,time="time",states="y"),class="nlr_ude");nl_dynamic_design(fake,0:20,4,criterion="curvature")
#' a<-structure(list(predictions=data.frame(time=0:20,y_predicted=0:20),time="time",states="y"),class="nlr_neural_ode");b<-structure(list(predictions=data.frame(time=0:20,y_predicted=(0:20)^1.15),time="time",states="y"),class="nlr_neural_ode");nl_dynamic_design(list(a,b),0:20,3,criterion="discrimination")
#' @export
nl_dynamic_design <- function(object,candidates,n_points=3,criterion=c("curvature","discrimination","uncertainty"),min_distance=0,dimension=c("time","depth")) {
  dimension<-match.arg(dimension);criterion<-match.arg(criterion);cand<-sort(unique(as.numeric(candidates)))
  if(length(cand)<1L||any(!is.finite(cand)))stop("candidates must contain finite times.",call.=FALSE)
  if(!is.numeric(n_points)||length(n_points)!=1L||n_points<1)stop("n_points must be >= 1.",call.=FALSE)
  if(!is.numeric(min_distance)||length(min_distance)!=1L||!is.finite(min_distance)||min_distance<0)stop("min_distance must be a finite nonnegative scalar.",call.=FALSE)
  mods<-if(is.list(object)&&!inherits(object,c("nlr_neural_ode","nlr_ude","nlr_pinn")))object else list(object)
  getcurve<-function(z,cand){p<-z$predictions;if(is.null(p))stop("Each object must contain predictions.",call.=FALSE);if(all(c("time","depth","predicted")%in%names(p))){axis<-dimension;if(!axis%in%names(p))stop("Requested design dimension is absent from Richards PINN predictions.",call.=FALSE);a<-stats::aggregate(p$predicted,list(candidate=p[[axis]]),mean,na.rm=TRUE);return(stats::approx(a$candidate,a$x,xout=cand,rule=2)$y)};if(dimension=="depth")stop("dimension='depth' is currently supported for long-form Richards PINN outputs only.",call.=FALSE);time<-z$time %||% names(p)[1];state<-(z$states %||% z$response)[1];pred<-paste0(state,"_predicted");if(!pred%in%names(p))pred<-grep("_predicted$",names(p),value=TRUE)[1];if(is.na(pred)||!nzchar(pred))stop("No predicted state column was found.",call.=FALSE);stats::approx(p[[time]],p[[pred]],xout=cand,rule=2)$y}
  P<-sapply(mods,getcurve,cand=cand);if(is.null(dim(P)))P<-matrix(P,ncol=1)
  if(criterion=="discrimination"&&ncol(P)<2)stop("discrimination requires at least two competing dynamic models.",call.=FALSE)
  if(criterion=="uncertainty"&&ncol(P)<2)stop("uncertainty currently requires an ensemble/list of at least two fitted dynamic models; use curvature for a single deterministic trajectory.",call.=FALSE)
  score<-if(criterion=="discrimination")apply(P,1,stats::var) else if(criterion=="curvature"){
    m<-rowMeans(P);curv<-numeric(length(cand))
    if(length(cand)>2L){
      left<-(m[2:(length(m)-1)]-m[1:(length(m)-2)])/(cand[2:(length(cand)-1)]-cand[1:(length(cand)-2)])
      right<-(m[3:length(m)]-m[2:(length(m)-1)])/(cand[3:length(cand)]-cand[2:(length(cand)-1)])
      span<-(cand[3:length(cand)]-cand[1:(length(cand)-2)])/2
      curv[2:(length(cand)-1)]<-abs(right-left)/pmax(span,.Machine$double.eps)
    }
    curv
  } else apply(P,1,stats::sd)
  selected<-numeric();eligible<-rep(TRUE,length(cand));for(i in seq_len(min(n_points,length(cand)))){s<-score;s[!eligible]<--Inf;j<-which.max(s);if(!is.finite(s[j]))break;selected<-c(selected,cand[j]);if(min_distance>0)eligible<-eligible&abs(cand-cand[j])>=min_distance else eligible[j]<-FALSE}
  scores<-data.frame(candidate=cand,score=score,selected=cand%in%selected);names(scores)[1]<-dimension
  structure(list(scores=scores,selected=selected,criterion=criterion,dimension=dimension,predictions=P),class="nlr_dynamic_design")
}

#' Optimize a bounded dynamic control schedule
#'
#' Uses the Julia/SciML model saved by an executed Neural ODE or UDE and optimizes
#' a piecewise-constant control covariate. Agronomic use cases include irrigation
#' and fertigation schedules. The objective balances a terminal target against
#' total input cost.
#' @param object Executed `nlr_neural_ode` or `nlr_ude` with a saved Julia model.
#' @param control_covariate Covariate to manipulate, for example `irrigation_mm_d`.
#' @param control_times Times at which control values may change.
#' @param lower Lower scalar or vector bound for the control schedule.
#' @param upper Upper scalar or vector bound for the control schedule.
#' @param target_state State to maximize at the terminal time.
#' @param input_penalty Penalty per unit control input.
#' @param initial Initial control schedule.
#' @param maxiters Optimization iterations.
#' @param julia Julia executable.
#' @param output_dir Output directory.
#' @param dry_run Return specification only.
#' @return An `nlr_dynamic_control` object or dry-run specification.
#' @examples
#' d<-subset(nl_data("sciml_crop_growth"),plot_id==unique(nl_data("sciml_crop_growth")$plot_id)[1]);u<-nl_ude(d,"day","biomass_g_m2",c("temperature_C","PAR_MJ_m2_d","soil_water_rel","nitrogen_rel"),template="crop_growth_rue",known_parameters=c(RUE=2.8,Topt=26,Twidth=10,respiration=.01),dry_run=TRUE);nl_control(u,"soil_water_rel",seq(0,98,14),.4,1,"biomass_g_m2",dry_run=TRUE)
#' d<-subset(nl_data("sciml_fruit_growth"),fruit_id==unique(nl_data("sciml_fruit_growth")$fruit_id)[1]);u<-nl_ude(d,"day_after_set","fruit_mass_g",c("temperature_C","soil_water_rel"),template="fruit_growth",known_parameters=c(r=.2,K=200),dry_run=TRUE);nl_control(u,"soil_water_rel",seq(0,30,5),.45,.95,"fruit_mass_g",dry_run=TRUE)
#' d<-subset(nl_data("sciml_fertility_dynamic"),plot_id==unique(nl_data("sciml_fertility_dynamic")$plot_id)[1]);u<-nl_ude(d,"day",c("plant_N_g_m2","soil_mineral_N_mg_kg"),c("temperature_C","soil_water_rel"),template="nitrogen_uptake",known_parameters=c(vmax=.08,Km=20),dry_run=TRUE);nl_control(u,"soil_water_rel",seq(0,84,14),.4,.95,"plant_N_g_m2",dry_run=TRUE)
#' @export
nl_control <- function(object,control_covariate,control_times,lower,upper,target_state,input_penalty=.01,initial=NULL,maxiters=300,julia=NULL,output_dir=NULL,dry_run=FALSE) {
  if(!inherits(object,c("nlr_neural_ode","nlr_ude","nlr_sciml_spec")))stop("object must be a Neural ODE/UDE fit or dry-run specification.",call.=FALSE)
  times<-as.numeric(control_times);if(length(times)<1L||any(!is.finite(times))||is.unsorted(times,strictly=TRUE))stop("control_times must be finite and strictly increasing.",call.=FALSE)
  n<-length(times);lo<-rep(lower,length.out=n);up<-rep(upper,length.out=n);ini<-as.numeric(initial %||% ((lo+up)/2))
  if(any(!is.finite(lo))||any(!is.finite(up))||any(lo>up))stop("lower and upper must be finite with lower <= upper.",call.=FALSE)
  if(length(ini)!=n||any(!is.finite(ini))||any(ini<lo)||any(ini>up))stop("initial must be finite and lie within the control bounds.",call.=FALSE)
  if(!is.numeric(input_penalty)||length(input_penalty)!=1L||!is.finite(input_penalty)||input_penalty<0)stop("input_penalty must be a finite nonnegative scalar.",call.=FALSE)
  src_cfg<-object$config %||% object$spec$config
  src_dat<-object$data %||% object$spec$data
  time_name<-src_cfg$time %||% object$time
  if(!is.null(src_dat)&&!is.null(time_name)&&time_name%in%names(src_dat)){
    horizon<-range(as.numeric(src_dat[[time_name]]),na.rm=TRUE)
    tol<-sqrt(.Machine$double.eps)*max(1,max(abs(horizon)))
    if(times[1]>horizon[1]+tol)stop("control_times must begin at or before the fitted model horizon so input cost is integrated over the full controlled interval.",call.=FALSE)
    if(tail(times,1)>horizon[2]+tol)stop("control_times cannot extend beyond the fitted model horizon.",call.=FALSE)
  }
  cfg<-list(source_dir=object$spec$output_dir %||% object$output_dir,source_config=src_cfg,
            control_covariate=control_covariate,control_times=times,lower=lo,upper=up,initial=as.numeric(ini),
            target_state=target_state,input_penalty=input_penalty,maxiters=as.integer(maxiters))
  spec<-.nl_sciml_spec("control",cfg,NULL,julia,output_dir,dry_run||inherits(object,"nlr_sciml_spec"));if(spec$dry_run)return(spec)
  res<-.nl_sciml_execute(spec);structure(c(list(method="dynamic_control",source=object,spec=spec),res),class="nlr_dynamic_control")
}
