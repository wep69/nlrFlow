#' Generate starting values
#'
#' Creates data-informed starting values for a registered nonlinear model. The values are intended as initialization, not scientific estimates.
#' @param data Data frame.
#' @param response Response column.
#' @param predictor Predictor column.
#' @param model Registered model name.
#' @return A named list of starting values.
#' @examples
#' okra <- nl_data("okra_growth_means")
#' nl_start(okra,"fruit_length","day_after_flowering","richards")
#' fert <- nl_data("soil_fertility_p"); nl_start(fert,"grain_yield_Mg_ha","P2O5_kg_ha","mitscherlich")
#' phys <- nl_data("plant_physiology_light"); nl_start(phys,"A_umol_CO2_m2_s","PAR_umol_m2_s","nonrectangular_hyperbola")
#' @export
nl_start <- function(data, response, predictor, model) {
  info <- nl_model_info(model)
  if(!all(c(response,predictor) %in% names(data))) stop("response and predictor must be columns in data.",call.=FALSE)
  x <- data[[predictor]]; y <- data[[response]]
  ok <- is.finite(x) & is.finite(y); x <- x[ok]; y <- y[ok]
  if(length(x) < 3L) stop("At least three finite observations are required to generate starting values.",call.=FALSE)
  xr <- diff(range(x)); if(!is.finite(xr) || xr <= 0) stop("Predictor must span more than one finite value.",call.=FALSE)
  yr <- diff(range(y)); if(!is.finite(yr)) yr <- 0
  posx <- x[x > 0]; xmedpos <- if(length(posx)) stats::median(posx) else max(xr/2,1e-3)
  xmin_i <- which.min(x); xmax_i <- which.max(x); ymax_i <- which.max(y)
  Asym <- max(y); ymin <- min(y); ymax <- max(y)
  half <- ymin + yr/2
  xmid <- x[which.min(abs(y-half))[1]]
  k0 <- max(1/xr,1e-4)
  slope0 <- (y[xmax_i]-y[xmin_i])/xr
  direction <- suppressWarnings(stats::cor(x,y,use="complete.obs"))
  if(!is.finite(direction)) direction <- sign(slope0)
  loglog_slope <- if(direction >= 0) -1 else 1
  rd0 <- max(0,-ymin)
  amax0 <- max(ymax + rd0, max(abs(y),na.rm=TRUE), 0.1)
  alpha_light <- max(abs(slope0), 0.01)

  out <- switch(model,
    logistic = list(Asym=Asym,xmid=xmid,scal=max(xr/5,1e-3)),
    gompertz = {
      k_start <- max(min(10/xr, 1), 0.1)
      list(Asym=max(Asym * 1.05, Asym + 1e-3), k=k_start, xmid=as.numeric(xmid))
    },
    richards = list(Asym=Asym,xmid=xmid,scal=max(xr/5,1e-3),nu=1),
    chapman_richards = list(Asym=Asym,k=k0,m=1.5),
    mitscherlich = list(Asym=max(Asym,y[xmax_i]),delta=max(Asym-ymin,0.1),k=max(10/xr,0.01)),
    michaelis_menten = list(Vmax=max(1.05*ymax,0.1),Km=max(xmedpos,1e-3)),
    hill = list(bottom=ymin,top=ymax,EC50=max(xmedpos,1e-3),h=2),
    monomolecular = list(Asym=Asym,y0=y[xmin_i],k=k0),
    power = list(a=max(stats::median(abs(y)/pmax(abs(x)^0.5,1e-6)),1e-3),b=0.5),
    linear_plateau = list(intercept=y[xmin_i],slope=slope0,breakpoint=stats::median(x)),
    quadratic_plateau = list(b0=y[xmin_i],b1=max(abs(slope0),0.01)*sign(ifelse(slope0==0,1,slope0)),b2=-max(abs(yr)/(xr^2),1e-4)),
    rectangular_hyperbola = list(Amax=amax0,alpha=alpha_light,Rd=rd0),
    nonrectangular_hyperbola = list(Amax=amax0,alpha=alpha_light,theta=0.85,Rd=rd0),
    gaussian_peak = list(baseline=ymin,amplitude=max(yr,0.1),mu=x[ymax_i],sigma=max(xr/5,1e-3)),
    weibull_growth = list(Asym=Asym,scal=max(xmedpos,1e-3),shape=1.5),
    von_bertalanffy = list(Asym=Asym,b=0.8,k=k0),
    emax = list(E0=ymin,Emax=max(yr,0.1),EC50=max(xmedpos,1e-3)),
    exponential_decay = list(plateau=ymin,amplitude=max(yr,0.1),k=k0),
    langmuir = list(qmax=max(1.1*ymax,0.1),K=max(1/max(xmedpos,1e-3),1e-4)),
    freundlich = list(Kf=max(stats::median(abs(y)/pmax(pmax(x,1e-6)^0.5,1e-6)),1e-3),n=2),
    van_genuchten = list(theta_r=max(ymin,0),theta_s=max(ymax,max(ymin,0)+1e-3),alpha=max(1/max(xmedpos,1e-3),1e-5),n=1.5),
    log_logistic4 = list(bottom=ymin,top=ymax,EC50=max(xmedpos,1e-3),slope=loglog_slope),
    substrate_inhibition = list(Vmax=max(1.1*ymax,0.1),Km=max(xmedpos/3,1e-3),Ki=max(max(x,na.rm=TRUE)*2,1e-3)),
    brain_cousens = list(bottom=ymin,top=ymax,EC50=max(xmedpos,1e-3),slope=loglog_slope,f=max(0.01*max(yr,0.1)/max(xr,1e-3),1e-6)),
    stop("Starting-value strategy has not been implemented for model: ",model,call.=FALSE)
  )
  out[info$parameters]
}

#' Multistart nonlinear least-squares search
#'
#' Fits the same nonlinear formula from many starting-value combinations through
#' `nls.multstart`. A scalar `iter` performs shotgun or Latin-hypercube sampling;
#' a vector `iter` requests a parameter grid. The winning fit is selected by the
#' backend's AIC rule and is returned in the common `nlrfit` class.
#' @param formula Nonlinear model formula.
#' @param data Data frame.
#' @param start_lower Named lower bounds for starting values.
#' @param start_upper Named upper bounds for starting values.
#' @param iter Scalar number of sampled starts, or a vector defining a start grid.
#' @param lhstype Latin-hypercube strategy: `shotgun`, `random`, `improved`, `maximin`, or `genetic`.
#' @param convergence_count Number of consecutive undefeated fits before early stopping in scalar-iteration searches; use `FALSE` to evaluate all starts.
#' @param seed Random seed controlling sampled starting values.
#' @param ... Additional arguments passed to `nls.multstart::nls_multstart` and ultimately `nlsLM`.
#' @return An `nlrfit` with engine `multistart`.
#' @examples
#' \dontrun{
#' d <- nl_data("okra_growth_means"); nl_multistart(fruit_length~Asym*exp(-exp(-k*(day_after_flowering-xmid))),d,c(Asym=12,k=.05,xmid=0),c(Asym=25,k=2,xmid=12),iter=100,lhstype="maximin")
#' d <- subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); nl_multistart(grain_yield_Mg_ha~Asym-delta*exp(-k*P2O5_kg_ha),d,c(Asym=4,delta=.1,k=.001),c(Asym=12,delta=10,k=.2),iter=100,lhstype="improved")
#' d <- subset(nl_data("plant_physiology_light"),water_regime=="WellWatered"); nl_multistart(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,d,c(Amax=5,alpha=.005,Rd=0),c(Amax=60,alpha=.3,Rd=6),iter=c(4,4,4))
#' }
#' @export
nl_multistart <- function(formula,data,start_lower,start_upper,iter=250,lhstype=c("shotgun","random","improved","maximin","genetic"),convergence_count=100,seed=20260817,...) {
  .nl_require("nls.multstart","multistart nonlinear fitting")
  lhstype <- match.arg(lhstype)
  if(is.null(names(start_lower)) || is.null(names(start_upper)) || !identical(names(start_lower),names(start_upper))) stop("start_lower and start_upper must be named vectors with identical names.",call.=FALSE)
  if(any(start_lower >= start_upper)) stop("Each start_lower value must be smaller than start_upper.",call.=FALSE)
  lhs <- if(lhstype=="shotgun") NULL else lhstype
  args <- list(formula=formula,data=data,iter=iter,start_lower=start_lower,start_upper=start_upper,supp_errors="Y",convergence_count=convergence_count)
  if(!is.null(lhs) && length(iter)==1L) args$lhstype <- lhs
  set.seed(seed)
  fit <- do.call(nls.multstart::nls_multstart,c(args,list(...)))
  .nl_wrap(fit,"multistart",formula,data,start=(start_lower+start_upper)/2,metadata=list(start_lower=start_lower,start_upper=start_upper,iter=iter,lhstype=lhstype,convergence_count=convergence_count,seed=seed))
}
#' Global genetic-algorithm search for nonlinear starting values
#'
#' Uses a bounded real-valued genetic algorithm to minimize residual sum of
#' squares before a local nonlinear fit. It is intended as a fallback when
#' biological heuristics and multistart searches are insufficient, not as the
#' default first step.
#' @param formula Nonlinear model formula.
#' @param data Data frame.
#' @param lower Named lower bounds for all nonlinear parameters.
#' @param upper Named upper bounds for all nonlinear parameters.
#' @param pop_size Genetic-algorithm population size.
#' @param maxiter Maximum number of generations.
#' @param run Stop after this many generations without improvement.
#' @param seed Random seed.
#' @param local_search Allow the GA backend to use its optional local optimization step.
#' @param ... Additional arguments passed to `GA::ga`.
#' @return An `nlr_global_start` list containing the recommended named start vector, objective RSS, and the backend GA object.
#' @examples
#' \dontrun{
#' d <- nl_data("okra_growth_means"); nl_global_start(fruit_length~Asym*exp(-exp(-k*(day_after_flowering-xmid))),d,c(Asym=10,k=.01,xmid=-2),c(Asym=30,k=3,xmid=15),pop_size=60,maxiter=300,run=50)
#' d <- subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); nl_global_start(grain_yield_Mg_ha~Asym-delta*exp(-k*P2O5_kg_ha),d,c(Asym=3,delta=.01,k=.0001),c(Asym=15,delta=12,k=.5),pop_size=60,maxiter=300,run=50)
#' d <- subset(nl_data("plant_physiology_light"),water_regime=="WellWatered"); nl_global_start(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,d,c(Amax=1,alpha=.001,Rd=0),c(Amax=80,alpha=.5,Rd=10),pop_size=60,maxiter=300,run=50)
#' }
#' @export
nl_global_start <- function(formula,data,lower,upper,pop_size=100,maxiter=1000,run=100,seed=20260817,local_search=TRUE,...) {
  .nl_require("GA","global starting-value search")
  if(is.null(names(lower)) || is.null(names(upper)) || !identical(names(lower),names(upper))) stop("lower and upper must be named vectors with identical parameter names.",call.=FALSE)
  if(any(!is.finite(lower)) || any(!is.finite(upper)) || any(lower>=upper)) stop("Global-search bounds must be finite and satisfy lower < upper.",call.=FALSE)
  resp <- .nl_response_name(formula); if(!resp %in% names(data)) stop("Response column is absent from data.",call.=FALSE); y <- data[[resp]]; pnames <- names(lower)
  fitness <- function(theta) {
    names(theta) <- pnames
    pred <- try(.nl_rhs_eval(formula,data,theta),silent=TRUE)
    if(inherits(pred,"try-error") || length(pred)!=length(y) || any(!is.finite(pred))) return(-.Machine$double.xmax)
    rss <- sum((y-pred)^2,na.rm=TRUE); if(!is.finite(rss)) return(-.Machine$double.xmax); -rss
  }
  set.seed(seed)
  ga <- GA::ga(type="real-valued",fitness=fitness,lower=as.numeric(lower),upper=as.numeric(upper),names=pnames,popSize=pop_size,maxiter=maxiter,run=run,optim=local_search,monitor=FALSE,...)
  sol <- ga@solution; if(is.matrix(sol)) sol <- sol[1,,drop=TRUE]; sol <- stats::setNames(as.numeric(sol),pnames)
  structure(list(start=sol,RSS=-as.numeric(ga@fitnessValue),seed=seed,bounds=list(lower=lower,upper=upper),backend=ga),class="nlr_global_start")
}
#' Fit a nonlinear regression model
#'
#' Unified front end for base NLS, Levenberg-Marquardt, multistart NLS, generalized nonlinear least squares, robust regression, and nonlinear quantile regression.
#' @param formula Nonlinear model formula. May be omitted when `model`, `response`, and `predictor` are supplied.
#' @param data Data frame.
#' @param start Named starting values; generated automatically for registered models when omitted.
#' @param engine One of `nls`, `nlsLM`, `multistart`, `gnls`, `robust`, or `quantile`.
#' @param model Optional registered model name.
#' @param response Response name when `model` is supplied.
#' @param predictor Predictor name when `model` is supplied.
#' @param lower Lower parameter bounds.
#' @param upper Upper parameter bounds.
#' @param weights Optional weights or variance structure, depending on engine.
#' @param correlation Optional `nlme` correlation structure for `gnls`.
#' @param params Optional `gnls` parameter model formulas, including qualitative-factor effects.
#' @param tau Quantile for `quantile` engine.
#' @param ... Additional backend arguments.
#' @return An `nlrfit` object containing the fitted backend and reproducibility metadata.
#' @examples
#' okra <- nl_data("okra_growth_means")
#' f1 <- nl_fit(data=okra, model="gompertz", response="fruit_length", predictor="day_after_flowering", engine="nls")
#' fert <- subset(nl_data("soil_fertility_p"), soil_class=="Loamy"); f2 <- nl_fit(data=fert, model="mitscherlich", response="grain_yield_Mg_ha", predictor="P2O5_kg_ha", engine="nls")
#' soil <- subset(nl_data("soil_infiltration"), management=="NoTill"); f3 <- nl_fit(data=soil, model="michaelis_menten", response="cumulative_infiltration_mm", predictor="time_min", engine="nls")
#' @export
nl_fit <- function(formula = NULL, data, start = NULL, engine = c("nlsLM","nls","multistart","gnls","robust","quantile"),
                   model = NULL, response = NULL, predictor = NULL, lower = -Inf, upper = Inf,
                   weights = NULL, correlation = NULL, params = NULL, tau = 0.5, ...) {
  engine <- match.arg(engine)
  if (is.null(formula)) {
    if (is.null(model)||is.null(response)||is.null(predictor)) stop("Supply formula or model + response + predictor.",call.=FALSE)
    formula <- .nl_model_formula(model,response,predictor)
  }
  if (is.null(start) && !is.null(model)) start <- nl_start(data,response,predictor,model)
  if (is.null(start) && engine %in% c("nls","nlsLM","gnls","robust","quantile")) stop("Starting values are required for an arbitrary formula.",call.=FALSE)
  if (!is.null(start)) {
    pnames <- names(start)
    if (length(lower) == 1L) lower <- rep(lower, length(pnames))
    if (length(upper) == 1L) upper <- rep(upper, length(pnames))
    names(lower) <- names(upper) <- pnames
  }
  fit <- switch(engine,
    nls = {
      args <- list(formula=formula, data=data, start=start,
                   algorithm=if(any(is.finite(c(lower,upper)))) "port" else "default",
                   lower=lower, upper=upper,
                   control=stats::nls.control(maxiter=500))
      if (!is.null(weights)) args$weights <- weights
      args <- c(args, list(...))
      do.call(stats::nls, args)
    },
    nlsLM = {
      .nl_require("minpack.lm","Levenberg-Marquardt fitting")
      args <- list(formula=formula, data=data, start=start,
                   lower=lower, upper=upper)
      if (!is.null(weights)) args$weights <- weights
      args <- c(args, list(...))
      do.call(minpack.lm::nlsLM, args)
    },
    multistart = {
      if (is.null(names(start))) stop("multistart requires named starting values",call.=FALSE)
      span <- pmax(abs(unlist(start))*0.75, 1)
      return(nl_multistart(formula,data,start_lower=unlist(start)-span,start_upper=unlist(start)+span,iter=250,lhstype="maximin",...))
    },
    gnls = { .nl_require("nlme","generalized nonlinear least squares"); nlme::gnls(formula,data=data,params=params,start=unlist(start),weights=weights,correlation=correlation,...) },
    robust = return(nl_robust(formula,data,start=start,lower=lower,upper=upper,...)),
    quantile = return(nl_quantile(formula,data,start=start,tau=tau,...))
  )
  .nl_wrap(fit,engine,formula,data,start,model,match.call(),list(lower=lower,upper=upper,params=params,tau=tau))
}
#' Fit multiple candidate nonlinear models
#'
#' Fits a common response-predictor relationship using several registered models, retaining failures in an auditable result.
#' @param data Data frame.
#' @param response Response name.
#' @param predictor Predictor name.
#' @param models Character vector of registered models.
#' @param engine Fitting engine passed to `nl_fit`.
#' @param ... Additional arguments passed to `nl_fit`.
#' @return An `nlrfit_list` containing successful fits, failures, and an audit trail.
#' @examples
#' okra <- nl_data("okra_growth_means"); nl_fit_many(okra,"fruit_length","day_after_flowering",c("logistic","gompertz","richards"),engine="nls")
#' fert <- subset(nl_data("soil_fertility_p"),soil_class=="Clayey"); nl_fit_many(fert,"grain_yield_Mg_ha","P2O5_kg_ha",c("mitscherlich","michaelis_menten"),engine="nls")
#' soil <- subset(nl_data("soil_infiltration"),management=="CoverCrop"); nl_fit_many(soil,"cumulative_infiltration_mm","time_min",c("michaelis_menten","monomolecular"),engine="nls")
#' @export
nl_fit_many <- function(data, response, predictor, models, engine="nlsLM", ...) {
  fits <- list(); failures <- list()
  for (m in models) {
    z <- try(nl_fit(data=data,model=m,response=response,predictor=predictor,engine=engine,...),silent=TRUE)
    if (inherits(z,"try-error")) failures[[m]] <- as.character(z) else fits[[m]] <- z
  }
  structure(list(fits=fits,failures=failures,response=response,predictor=predictor,
                 audit=c(sprintf("%d candidate models requested",length(models)),sprintf("%d converged fits retained",length(fits)))),class="nlrfit_list")
}
