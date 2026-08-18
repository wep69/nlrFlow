#' Fit robust nonlinear regression
#'
#' Fits resistant nonlinear regression through `robustbase::nlrob`, retaining the nlrFlow metadata contract.
#' @param formula Nonlinear formula.
#' @param data Data frame.
#' @param start Named starting values.
#' @param method Robust method supported by `nlrob`.
#' @param lower Lower bounds.
#' @param upper Upper bounds.
#' @param ... Additional arguments to `robustbase::nlrob`.
#' @return An `nlrfit` with engine `robust`.
#' @examples
#' \dontrun{
#' okra <- nl_data("okra_growth_means"); nl_robust(fruit_length~Asym*exp(-exp(-k*(day_after_flowering-xmid))),okra,list(Asym=18,k=.4,xmid=4))
#' fert <- subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); nl_robust(grain_yield_Mg_ha~Asym-delta*exp(-k*P2O5_kg_ha),fert,list(Asym=8,delta=5,k=.02))
#' soil <- subset(nl_data("soil_infiltration"),management=="NoTill"); nl_robust(cumulative_infiltration_mm~Vmax*time_min/(Km+time_min),soil,list(Vmax=130,Km=30))
#' }
#' @export
nl_robust <- function(formula,data,start,method="M",lower=-Inf,upper=Inf,...) {.nl_require("robustbase","robust nonlinear regression");fit<-robustbase::nlrob(formula,data=data,start=start,method=method,lower=lower,upper=upper,...);.nl_wrap(fit,"robust",formula,data,start,metadata=list(lower=lower,upper=upper,method=method))}
#' Fit nonlinear quantile regression
#'
#' Fits nonlinear conditional quantiles through `quantreg::nlrq`, useful when nonlinear effects differ across the response distribution.
#' @param formula Nonlinear formula.
#' @param data Data frame.
#' @param start Named starting values.
#' @param tau Quantile in (0,1).
#' @param ... Additional arguments to `quantreg::nlrq`.
#' @return An `nlrfit` with engine `quantile`.
#' @examples
#' \dontrun{
#' okra <- nl_data("okra_growth_raw"); nl_quantile(fruit_length~Asym*exp(-exp(-k*(day_after_flowering-xmid))),okra,list(Asym=18,k=.4,xmid=4),tau=.5)
#' fert <- subset(nl_data("soil_fertility_p"),soil_class=="Clayey"); nl_quantile(grain_yield_Mg_ha~Asym-delta*exp(-k*P2O5_kg_ha),fert,list(Asym=9,delta=5,k=.03),tau=.9)
#' soil <- subset(nl_data("soil_infiltration"),management=="CoverCrop"); nl_quantile(cumulative_infiltration_mm~Vmax*time_min/(Km+time_min),soil,list(Vmax=145,Km=34),tau=.1)
#' }
#' @export
nl_quantile <- function(formula,data,start,tau=.5,...) {.nl_require("quantreg","nonlinear quantile regression");fit<-quantreg::nlrq(formula,data=data,start=start,tau=tau,...);.nl_wrap(fit,"quantile",formula,data,start,metadata=list(tau=tau))}
#' Fit nonlinear mixed-effects models
#'
#' Fits nonlinear mixed-effects models through `nlme::nlme`, supporting qualitative fixed effects on nonlinear parameters, random effects, nested groups, variance functions, and residual correlation structures.
#' @param model Nonlinear response formula.
#' @param data Data frame.
#' @param fixed Fixed-effects parameter formula or list.
#' @param random Random-effects parameter formula or list.
#' @param groups Optional grouping formula.
#' @param start Initial fixed-effect values.
#' @param correlation Optional `corStruct`.
#' @param weights Optional `varFunc`.
#' @param method ML or REML where supported.
#' @param ... Additional `nlme::nlme` arguments.
#' @return An `nlrfit` with engine `nlme`.
#' @examples
#' \dontrun{
#' # Agronomy: cultivar effects may be placed on Asym and k with block/plant random effects.
#' a <- nl_data("agronomy_growth"); nl_mixed(biomass_Mg_ha~Asym/(1+exp(-k*(day-xmid))),a,fixed=list(Asym~cultivar,k~cultivar,xmid~1),random=Asym~1|block,start=c(18,1,1,.09,.01,.01,52))
#' # Soil: management-specific infiltration parameters with block random effects.
#' s <- nl_data("soil_infiltration"); nl_mixed(cumulative_infiltration_mm~Vmax*time_min/(Km+time_min),s,fixed=list(Vmax~management,Km~management),random=Vmax~1|block,start=c(100,20,30,25,5,5))
#' # Physiology: water-regime effects with plant-level random Amax.
#' p <- nl_data("plant_physiology_light"); nl_mixed(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,p,fixed=list(Amax~water_regime,alpha~water_regime,Rd~1),random=Amax~1|plant_id,start=c(30,-6,-14,.07,-.01,-.02,1.3))
#' }
#' @export
nl_mixed <- function(model,data,fixed,random,groups=NULL,start,correlation=NULL,weights=NULL,method="ML",...) {.nl_require("nlme","nonlinear mixed-effects models");fit<-nlme::nlme(model=model,data=data,fixed=fixed,random=random,groups=groups,start=start,correlation=correlation,weights=weights,method=method,...);.nl_wrap(fit,"nlme",model,data,start,metadata=list(fixed=fixed,random=random,groups=groups,method=method))}
#' Fit an SAEM nonlinear mixed-effects model
#'
#' Provides a transparent adapter to `saemix` for difficult nonlinear mixed-effects models. The user supplies the model function and mapping explicitly because SAEM parameterizations are study-specific.
#' @param model_function Function in the form expected by `saemixModel`.
#' @param data Data frame.
#' @param psi0 Initial population parameter matrix.
#' @param id Subject/group identifier column.
#' @param predictor Predictor column.
#' @param response Response column.
#' @param parameter_names Parameter names.
#' @param covariate_model Optional covariate model matrix.
#' @param transform_par Parameter transformations.
#' @param ... Additional arguments passed to `saemixModel` or `saemix`.
#' @return A fitted `saemix` object wrapped in `nlrfit`.
#' @examples
#' \dontrun{
#' # Example 1: agronomy repeated growth uses a user-defined logistic function.
#' a <- nl_data("agronomy_growth"); # nl_saemix(model_fun,a,psi0,... )
#' # Example 2: soil infiltration can use subject/block-specific Vmax.
#' s <- nl_data("soil_infiltration"); # nl_saemix(model_fun,s,psi0,... )
#' # Example 3: physiology can use plant-level Amax and alpha.
#' p <- nl_data("plant_physiology_light"); # nl_saemix(model_fun,p,psi0,... )
#' }
#' @export
nl_saemix <- function(model_function,data,psi0,id,predictor,response,parameter_names,covariate_model=NULL,transform_par=rep(0,length(parameter_names)),...) {.nl_require("saemix","SAEM nonlinear mixed-effects models"); sm<-saemix::saemixModel(model=model_function,description="nlrFlow SAEM model",psi0=psi0,transform.par=transform_par,covariate.model=covariate_model,parameter.names=parameter_names);sd<-saemix::saemixData(name.data=data,name.group=id,name.predictors=predictor,name.response=response);fit<-saemix::saemix(sm,sd,...);.nl_wrap(fit,"saemix",stats::as.formula(paste(response,"~",predictor)),data,psi0,metadata=list(parameter_names=parameter_names,id=id))}
#' Fit Bayesian nonlinear models
#'
#' Fits arbitrary nonlinear, multilevel, and distributional Bayesian models through `brms`. Priors are required by default for nonlinear parameters to discourage unidentified default analyses.
#' @param formula A `brmsformula` or formula accepted by `brms::brm`.
#' @param data Data frame.
#' @param prior Explicit prior specification.
#' @param family Response family.
#' @param backend Stan backend, usually `cmdstanr` or `rstan`.
#' @param require_prior Require non-empty priors for nonlinear models.
#' @param ... Additional arguments to `brms::brm`.
#' @return An `nlrfit` with engine `brms`.
#' @examples
#' \dontrun{
#' # Example 1: Bayesian Gompertz for okra with explicit priors.
#' # nl_bayes(brms::bf(..., nl=TRUE), nl_data("okra_growth_raw"), prior=...)
#' # Example 2: cultivar-specific nonlinear growth with multilevel block effects.
#' # nl_bayes(brms::bf(..., nl=TRUE), nl_data("agronomy_growth"), prior=...)
#' # Example 3: water-regime nonlinear photosynthesis with Student-t residuals.
#' # nl_bayes(brms::bf(..., nl=TRUE), nl_data("plant_physiology_light"), prior=..., family=brms::student())
#' }
#' @export
nl_bayes <- function(formula,data,prior,family=stats::gaussian(),backend="cmdstanr",require_prior=TRUE,...) {.nl_require("brms","Bayesian nonlinear models");if(require_prior&&(missing(prior)||length(prior)==0))stop("Explicit priors are required for nonlinear Bayesian fitting.",call.=FALSE);fit<-brms::brm(formula=formula,data=data,prior=prior,family=family,backend=backend,...);.nl_wrap(fit,"brms",formula,data,prior,metadata=list(family=family,backend=backend))}
#' Posterior predictive checks
#'
#' Routes Bayesian fitted objects to `brms::pp_check` while preserving a package-level teaching interface.
#' @param object An `nlrfit` produced by `nl_bayes`.
#' @param ... Arguments to `brms::pp_check`.
#' @return A posterior predictive-check plot object.
#' @examples
#' \dontrun{
#' # nl_ppcheck(okra_bayes,type="dens_overlay")
#' # nl_ppcheck(agronomy_bayes,type="scatter_avg")
#' # nl_ppcheck(physiology_bayes,type="intervals")
#' }
#' @export
nl_ppcheck <- function(object,...) {if(!inherits(object,"nlrfit")||object$engine!="brms")stop("nl_ppcheck requires a brms-backed nlrfit",call.=FALSE);.nl_require("brms");brms::pp_check(object$fit,...)}

#' Diagnose Bayesian nonlinear sampling
#'
#' Summarizes Stan sampling diagnostics for a `brms`-backed nonlinear fit,
#' including R-hat, relative effective sample size, NUTS divergences, and the
#' largest observed tree depth.
#' @param object An `nlrfit` produced by `nl_bayes`.
#' @param rhat_threshold Threshold used to flag potentially problematic R-hat values.
#' @return An `nlr_bayes_diagnostic` list with parameter-level vectors, sampler summaries, and warnings.
#' @examples
#' \dontrun{
#' # Example 1: diagnose an okra Bayesian nonlinear model.
#' # nl_bayes_diagnose(okra_bayes)
#' # Example 2: diagnose a cultivar multilevel nonlinear model.
#' # nl_bayes_diagnose(agronomy_bayes)
#' # Example 3: diagnose a Student-t photosynthesis model.
#' # nl_bayes_diagnose(physiology_bayes)
#' }
#' @export
nl_bayes_diagnose <- function(object,rhat_threshold=1.01) {
  if(!inherits(object,"nlrfit") || object$engine!="brms") stop("nl_bayes_diagnose requires a brms-backed nlrfit.",call.=FALSE)
  .nl_require("brms","Bayesian sampling diagnostics")
  fit <- object$fit
  rh <- brms::rhat(fit); ne <- brms::neff_ratio(fit); np <- brms::nuts_params(fit)
  div <- if(any(np$Parameter=="divergent__")) sum(np$Value[np$Parameter=="divergent__"],na.rm=TRUE) else NA_real_
  td <- if(any(np$Parameter=="treedepth__")) max(np$Value[np$Parameter=="treedepth__"],na.rm=TRUE) else NA_real_
  maxrh <- if(length(rh)) max(rh,na.rm=TRUE) else NA_real_; minne <- if(length(ne)) min(ne,na.rm=TRUE) else NA_real_
  warn <- character()
  if(is.finite(maxrh) && maxrh > rhat_threshold) warn <- c(warn,sprintf("Maximum R-hat %.4f exceeds the configured threshold %.3f.",maxrh,rhat_threshold))
  if(is.finite(div) && div > 0) warn <- c(warn,sprintf("%d divergent NUTS transitions detected; inspect geometry, priors and sampler controls.",as.integer(div)))
  structure(list(max_rhat=maxrh,min_neff_ratio=minne,divergences=div,max_treedepth_observed=td,rhat=rh,neff_ratio=ne,nuts_params=np,warnings=warn),class="nlr_bayes_diagnostic")
}

#' Compare Bayesian nonlinear models with PSIS-LOO
#'
#' Computes PSIS-LOO for Bayesian nonlinear models fitted to the same outcome
#' observations, compares expected log predictive density, reports Pareto-k
#' diagnostics through the retained LOO objects, and computes stacking or
#' pseudo-BMA+ predictive weights.
#' @param fits Named list of `brms`-backed `nlrfit` objects.
#' @param method Predictive weighting method: `stacking` or `pseudobma`.
#' @param moment_match Passed to `brms::loo` for optional moment matching.
#' @param reloo Passed to `brms::loo` for optional exact refits of problematic observations.
#' @param ... Additional arguments passed to `brms::loo`.
#' @return An `nlr_bayes_comparison` containing LOO objects, comparison matrix, and model weights.
#' @examples
#' \dontrun{
#' # Example 1: compare two Bayesian okra growth equations.
#' # nl_bayes_compare(list(Gompertz=okra_gomp_bayes, Richards=okra_rich_bayes))
#' # Example 2: compare agronomic residual/distributional specifications.
#' # nl_bayes_compare(list(Gaussian=agri_gauss, StudentT=agri_student), method="stacking")
#' # Example 3: compare physiology models and request moment matching when needed.
#' # nl_bayes_compare(list(Rect=phys_rect, Nonrect=phys_nonrect), moment_match=TRUE)
#' }
#' @export
nl_bayes_compare <- function(fits,method=c("stacking","pseudobma"),moment_match=FALSE,reloo=FALSE,...) {
  method <- match.arg(method); .nl_require("brms","Bayesian LOO comparison"); .nl_require("loo","Bayesian LOO comparison")
  if(!is.list(fits) || length(fits)<2) stop("fits must be a list containing at least two Bayesian nlrfit objects.",call.=FALSE)
  if(is.null(names(fits)) || any(names(fits)=="")) names(fits) <- paste0("model",seq_along(fits))
  ok <- vapply(fits,function(z) inherits(z,"nlrfit") && identical(z$engine,"brms"),logical(1))
  if(!all(ok)) stop("All fits must be brms-backed nlrfit objects.",call.=FALSE)
  nobs <- vapply(fits,function(z)nrow(z$data),integer(1)); if(length(unique(nobs))!=1L) stop("PSIS-LOO comparison requires models fitted to the same number of observations.",call.=FALSE)
  loos <- lapply(fits,function(z) brms::loo(z$fit,moment_match=moment_match,reloo=reloo,...)); names(loos) <- names(fits)
  comp <- do.call(loo::loo_compare,loos)
  w <- loo::loo_model_weights(loos,method=method)
  structure(list(loo=loos,comparison=comp,weights=w,method=method),class="nlr_bayes_comparison")
}
