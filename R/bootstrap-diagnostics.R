#' Bootstrap nonlinear regression
#'
#' Implements case, residual, parametric, wild, and cluster bootstrap while preserving the original model specification and recording failed refits.
#' @param object An `nlrfit`.
#' @param R Number of bootstrap replicates.
#' @param type Bootstrap type.
#' @param cluster Cluster column for cluster bootstrap.
#' @param seed Random seed.
#' @return An `nlrboot` object with coefficient draws, convergence status, and metadata.
#' @examples
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_boot(f,R=20,type="case",seed=1)
#' f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_boot(f,R=20,type="residual",seed=2)
#' f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_boot(f,R=20,type="parametric",seed=3)
#' @export
nl_boot <- function(object,R=999,type=c("case","residual","parametric","cluster","wild"),cluster=NULL,seed=20260817) {
  stopifnot(inherits(object,"nlrfit")); if(identical(object$engine,"brms")) stop("Use posterior draws rather than frequentist bootstrap for a brms-backed fit.",call.=FALSE); type<-match.arg(type); dat<-object$data; resp<-.nl_response_name(object$formula); n<-nrow(dat); cf<-.nl_coef(object); out<-matrix(NA_real_,R,length(cf),dimnames=list(NULL,names(cf))); ok<-logical(R); set.seed(seed)
  fitv<-as.numeric(fitted(object)); res<-as.numeric(residuals(object)); sig<-sqrt(sum(res^2)/max(1,n-length(cf)))
  for(b in seq_len(R)){
    d<-switch(type,
      case=dat[sample.int(n,n,replace=TRUE),,drop=FALSE],
      residual={z<-dat;z[[resp]]<-fitv+sample(res,n,replace=TRUE);z},
      parametric={z<-dat;z[[resp]]<-fitv+stats::rnorm(n,0,sig);z},
      wild={z<-dat; mult<-sample(c(-1,1),n,replace=TRUE); z[[resp]]<-fitv+res*mult; z},
      cluster={if(is.null(cluster)||!cluster%in%names(dat)) stop("cluster column required",call.=FALSE); ids<-unique(dat[[cluster]]); draw<-sample(ids,length(ids),replace=TRUE); do.call(rbind,lapply(seq_along(draw),function(j){z<-dat[dat[[cluster]]==draw[j],,drop=FALSE];z[[cluster]]<-paste0(draw[j],"_boot",j);z}))})
    z<-try(.nl_refit(object,d),silent=TRUE); if(!inherits(z,"try-error")){cc<-try(coef(z),silent=TRUE);if(!inherits(cc,"try-error")){out[b,names(cc)]<-cc;ok[b]<-TRUE}}
  }
  structure(list(coefficients=out,converged=ok,R=R,type=type,seed=seed,object=object,failure_rate=mean(!ok)),class="nlrboot")
}
#' Predict from nonlinear models with uncertainty
#'
#' Produces point predictions and approximate confidence or prediction intervals using parameter simulation, or bootstrap intervals when a bootstrap object is supplied.
#' @param object An `nlrfit`.
#' @param newdata Prediction data.
#' @param interval `none`, `confidence`, or `prediction`.
#' @param level Interval level.
#' @param nsim Number of parameter simulations.
#' @param boot Optional `nlrboot` for bootstrap prediction intervals.
#' @param seed Simulation seed.
#' @param ... Additional prediction arguments passed to `brms::posterior_epred()` or `brms::posterior_predict()` for Bayesian fits, such as `re_formula`.
#' @return A data frame with fitted values and interval bounds.
#' @examples
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_predict(f,interval="confidence",nsim=100)
#' f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_predict(f,interval="prediction",nsim=100)
#' f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_predict(f,interval="confidence",nsim=100)
#' @export
nl_predict <- function(object,newdata=NULL,interval=c("none","confidence","prediction"),level=.95,nsim=1000,boot=NULL,seed=20260817,...) {
  interval<-match.arg(interval); dat<-newdata %||% object$data; alpha<-1-level
  if(inherits(object,"nlrfit") && identical(object$engine,"brms")) {
    .nl_require("brms","Bayesian posterior prediction")
    set.seed(seed)
    draws <- if(interval=="prediction") brms::posterior_predict(object$fit,newdata=dat,ndraws=nsim,...) else brms::posterior_epred(object$fit,newdata=dat,ndraws=nsim,...)
    if(length(dim(draws))!=2L) stop("Only univariate brms predictions are currently supported by nl_predict().",call.=FALSE)
    ans <- data.frame(dat,.fitted=apply(draws,2,stats::median,na.rm=TRUE),check.names=FALSE)
    if(interval=="none") return(ans)
    ans$.lower <- apply(draws,2,stats::quantile,probs=alpha/2,na.rm=TRUE)
    ans$.upper <- apply(draws,2,stats::quantile,probs=1-alpha/2,na.rm=TRUE)
    return(ans)
  }
  pred<-as.numeric(predict(object,newdata=dat)); ans<-data.frame(dat,.fitted=pred,check.names=FALSE)
  if(interval=="none") return(ans)
  draws<-NULL
  if(!is.null(boot)) { B<-boot$coefficients[boot$converged,,drop=FALSE]; draws<-vapply(seq_len(nrow(B)),function(i).nl_rhs_eval(object$formula,dat,B[i,]),numeric(nrow(dat))) }
  else {V<-.nl_extract_vcov(object); if(is.null(V)) stop("vcov unavailable; provide boot=.",call.=FALSE); set.seed(seed); P<-.nl_mvrnorm(nsim,.nl_coef(object),V); draws<-vapply(seq_len(nsim),function(i).nl_rhs_eval(object$formula,dat,P[i,]),numeric(nrow(dat)))}
  if(interval=="prediction"){res<-as.numeric(residuals(object));sig<-sqrt(mean(res^2));set.seed(seed+1);draws<-draws+matrix(stats::rnorm(length(draws),0,sig),nrow(draws),ncol(draws))}
  ans$.lower<-apply(draws,1,stats::quantile,probs=alpha/2,na.rm=TRUE);ans$.upper<-apply(draws,1,stats::quantile,probs=1-alpha/2,na.rm=TRUE);ans
}
#' Diagnose a nonlinear fit
#'
#' Computes residual summaries, residual-fit correlation, normal-score correlation, heteroscedasticity indicators, and optional autocorrelation diagnostics without reducing model adequacy to a single test.
#' @param object An `nlrfit`.
#' @param lag Maximum residual autocorrelation lag.
#' @return An `nlrdiag` object with data and warnings.
#' @examples
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="richards",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_diagnose(f)
#' f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Clayey"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_diagnose(f)
#' f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="CoverCrop"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_diagnose(f)
#' @export
nl_diagnose <- function(object,lag=5) {
  if(inherits(object,"nlrfit") && identical(object$engine,"brms")) stop("Use nl_bayes_diagnose() and nl_ppcheck() for brms-backed models.",call.=FALSE)
  r<-as.numeric(residuals(object));f<-as.numeric(fitted(object));n<-length(r);sr<-r/sqrt(mean(r^2)); ord<-sort(sr); theo<-stats::qnorm((seq_len(n)-.375)/(n+.25));
  ac<-if(n>3) as.numeric(stats::acf(r,plot=FALSE,lag.max=min(lag,n-1))$acf[-1]) else numeric()
  slope<-tryCatch(coef(stats::lm(log(pmax(r^2,1e-12))~log(pmax(abs(f),1e-12))))[2],error=function(e) NA_real_)
  warnings<-character();if(is.finite(slope)&&abs(slope)>.5) warnings<-c(warnings,"Residual scale changes materially with fitted magnitude; consider a variance function or transformation/distributional model.");if(length(ac)&&any(abs(ac)>2/sqrt(n)))warnings<-c(warnings,"Residual autocorrelation exceeds an approximate sampling band; consider correlated errors if supported by design.")
  structure(list(residuals=r,fitted=f,standardized=sr,rmse=sqrt(mean(r^2)),mean_residual=mean(r),normal_score_correlation=stats::cor(ord,theo),residual_fitted_correlation=stats::cor(r,f),variance_log_slope=slope,acf=ac,warnings=warnings),class="nlrdiag")
}
#' Leave-one-out influence analysis
#'
#' Refits the model after deleting each observation and reports relative coefficient shifts and fit failures.
#' @param object An `nlrfit`.
#' @param max_cases Optional maximum number of cases for a quick diagnostic.
#' @return A data frame of case influence summaries.
#' @examples
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_influence(f)
#' f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Sandy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_influence(f,max_cases=12)
#' f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_influence(f,max_cases=15)
#' @export
nl_influence <- function(object,max_cases=Inf) {
  if(inherits(object,"nlrfit") && identical(object$engine,"brms")) stop("Case-deletion influence is not implemented for brms-backed fits; use posterior predictive and PSIS-LOO diagnostics.",call.=FALSE)
  dat<-object$data;n<-min(nrow(dat),max_cases);base<-.nl_coef(object);rows<-vector("list",n)
  for(i in seq_len(n)){z<-try(.nl_refit(object,dat[-i,,drop=FALSE]),silent=TRUE);if(inherits(z,"try-error")){rows[[i]]<-data.frame(case=i,converged=FALSE,max_relative_shift=NA);next};cc<-coef(z); rel<-abs((cc-base[names(cc)])/pmax(abs(base[names(cc)]),1e-8));rows[[i]]<-data.frame(case=i,converged=TRUE,max_relative_shift=max(rel,na.rm=TRUE))};do.call(rbind,rows)
}
#' Assess local parameter identifiability
#'
#' Builds a finite-difference prediction Jacobian, singular values, condition index, and parameter-correlation matrix to flag weak local identifiability.
#' @param object An `nlrfit`.
#' @param eps Relative finite-difference step.
#' @return An `nlr_identifiability` object.
#' @examples
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="richards",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_identify(f)
#' f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_identify(f)
#' f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_identify(f)
#' @export
nl_identify <- function(object,eps=1e-6) {
  if(inherits(object,"nlrfit") && identical(object$engine,"brms")) stop("Local Jacobian identifiability is not defined through the brms wrapper; inspect priors, posterior correlations, sampling diagnostics and sensitivity instead.",call.=FALSE)
  cf<-.nl_coef(object);dat<-object$data;base<-.nl_rhs_eval(object$formula,dat,cf);J<-matrix(NA_real_,length(base),length(cf),dimnames=list(NULL,names(cf)))
  for(j in seq_along(cf)){h<-eps*max(1,abs(cf[j]));p<-cf;p[j]<-p[j]+h;J[,j]<-(.nl_rhs_eval(object$formula,dat,p)-base)/h}
  sv<-svd(J,nu=0,nv=0)$d; cond<-if(min(sv)>0) max(sv)/min(sv) else Inf;V<-.nl_extract_vcov(object);corpar<-if(is.null(V))NULL else stats::cov2cor(V)
  structure(list(jacobian=J,singular_values=sv,condition_number=cond,parameter_correlation=corpar,warning=if(cond>1e4)"Weak local identifiability likely; inspect profiles/reparameterization." else NULL),class="nlr_identifiability")
}

#' Bates-Watts-style nonlinear curvature diagnostics
#'
#' Computes root-mean-square intrinsic and parameter-effects curvature through
#' `IPEC::curvIPEC`. This diagnostic assesses how strongly first-order linear
#' approximations may be distorted by the model-data geometry.
#' @param object An `nlrfit` object with one primary numeric predictor.
#' @param predictor Predictor name; inferred when there is exactly one numeric predictor in the nonlinear formula.
#' @param level Reference confidence level used by the curvature critical value.
#' @param ... Additional arguments passed to `IPEC::curvIPEC`.
#' @return An `nlr_curvature` object containing RMS intrinsic curvature, RMS parameter-effects curvature, the critical curvature, and the backend result.
#' @examples
#' \dontrun{
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="richards",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_curvature(f)
#' f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_curvature(f)
#' f <- nl_fit(data=subset(nl_data("plant_physiology_light"),water_regime=="WellWatered"),model="rectangular_hyperbola",response="A_umol_CO2_m2_s",predictor="PAR_umol_m2_s",engine="nls"); nl_curvature(f)
#' }
#' @export
nl_curvature <- function(object,predictor=NULL,level=.95,...) {
  .nl_require("IPEC","intrinsic and parameter-effects curvature diagnostics")
  if(!inherits(object,"nlrfit")) stop("object must be an nlrfit.",call.=FALSE)
  resp <- .nl_response_name(object$formula)
  vars <- .nl_predictor_names(object$formula)
  if(is.null(predictor)) {
    available <- vars[vars %in% names(object$data)]
    candidates <- available[vapply(object$data[available],is.numeric,logical(1))]
    if(length(candidates)!=1L) stop("Specify predictor explicitly when the model contains more than one numeric predictor.",call.=FALSE)
    predictor <- candidates
  }
  if(!predictor %in% names(object$data) || !is.numeric(object$data[[predictor]])) stop("predictor must name a numeric column in the fitted data.",call.=FALSE)
  cf <- .nl_coef(object); pnames <- names(cf); dat0 <- object$data
  fun <- function(theta,x) {
    d <- dat0[rep(1,length(x)),,drop=FALSE]
    d[[predictor]] <- as.numeric(x)
    .nl_rhs_eval(object$formula,d,stats::setNames(as.numeric(theta),pnames))
  }
  z <- IPEC::curvIPEC(fun,theta=as.numeric(cf),x=object$data[[predictor]],y=object$data[[resp]],alpha=1-level,...)
  structure(list(rms_intrinsic=z$rms.ic,rms_parameter_effects=z$rms.pec,critical_curvature=z$critical.c,
                 level=level,predictor=predictor,backend=z),class="nlr_curvature")
}
