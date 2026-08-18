#' Select the preferred candidate model
#'
#' Ranks a fitted candidate set by AICc, AIC, BIC, RMSE, or cross-validated RMSE. Selection is a ranking aid and does not replace scientific diagnostics.
#' @param fits An `nlrfit_list` or named list of `nlrfit` objects.
#' @param criterion Ranking criterion.
#' @param k Folds when `criterion = "CV_RMSE"`.
#' @return The selected `nlrfit`, with ranking table in an attribute.
#' @examples
#' okra <- nl_fit_many(nl_data("okra_growth_means"),"fruit_length","day_after_flowering",c("logistic","gompertz"),engine="nls"); nl_select(okra,"AICc")
#' soil <- nl_fit_many(subset(nl_data("soil_infiltration"),management=="NoTill"),"cumulative_infiltration_mm","time_min",c("michaelis_menten","monomolecular"),engine="nls"); nl_select(soil,"RMSE")
#' fert <- nl_fit_many(subset(nl_data("soil_fertility_p"),soil_class=="Sandy"),"grain_yield_Mg_ha","P2O5_kg_ha",c("mitscherlich","michaelis_menten"),engine="nls"); nl_select(fert,"BIC")
#' @export
nl_select <- function(fits, criterion=c("AICc","AIC","BIC","RMSE","CV_RMSE"), k=5) {
  criterion<-match.arg(criterion); tab<-nl_compare(fits,cv=(criterion=="CV_RMSE"),k=k)
  if (!criterion %in% names(tab)) stop("Criterion unavailable.",call.=FALSE)
  ok<-which(is.finite(tab[[criterion]])); if(!length(ok)) stop("No finite criterion values.",call.=FALSE)
  i<-ok[which.min(tab[[criterion]][ok])]; fs<-if(inherits(fits,"nlrfit_list")) fits$fits else fits
  out<-fs[[tab$model[i]]]; attr(out,"selection_table")<-tab; out
}
#' Compare fitted nonlinear models
#'
#' Produces a model-comparison table using information criteria, residual metrics, and optionally cross-validation. It does not perform invalid likelihood-ratio tests for non-nested curves.
#' @param fits An `nlrfit_list`, named list of `nlrfit`, or individual fits.
#' @param ... Additional fits when the first argument is a single fit.
#' @param cv Logical; compute K-fold cross-validation.
#' @param k Number of folds.
#' @return A data frame with fit statistics and ranking quantities.
#' @examples
#' x <- nl_fit_many(nl_data("okra_growth_means"),"fruit_length","day_after_flowering",c("logistic","gompertz"),engine="nls"); nl_compare(x)
#' y <- nl_fit_many(subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),"grain_yield_Mg_ha","P2O5_kg_ha",c("mitscherlich","michaelis_menten"),engine="nls"); nl_compare(y)
#' z <- nl_fit_many(subset(nl_data("soil_infiltration"),management=="Conventional"),"cumulative_infiltration_mm","time_min",c("michaelis_menten","monomolecular"),engine="nls"); nl_compare(z,cv=TRUE,k=3)
#' @export
nl_compare <- function(fits, ..., cv=FALSE, k=5) {
  dots<-list(...); if(inherits(fits,"nlrfit_list")) fs<-fits$fits else if(inherits(fits,"nlrfit")) fs<-c(list(model1=fits),dots) else fs<-fits
  if(is.null(names(fs))||any(names(fs)=="")) names(fs)<-paste0("model",seq_along(fs))
  if(any(vapply(fs,function(z) inherits(z,"nlrfit") && identical(z$engine,"brms"),logical(1)))) stop("Bayesian brms fits must be compared with nl_bayes_compare(), which uses PSIS-LOO rather than the classical fit table.",call.=FALSE)
  likelihood_engines <- c("nls","nlsLM","multistart","gnls","nlme")
  rows<-lapply(names(fs),function(nm){o<-fs[[nm]]; fit<-.nl_unwrap(o); dat<-o$data; resp<-.nl_response_name(o$formula); pred<-as.numeric(stats::predict(fit)); obs<-dat[[resp]]
    likelihood_ok <- o$engine %in% likelihood_engines
    a<-if(likelihood_ok) tryCatch(AIC(fit),error=function(e) NA_real_) else NA_real_
    b<-if(likelihood_ok) tryCatch(BIC(fit),error=function(e) NA_real_) else NA_real_
    ac<-if(likelihood_ok) tryCatch(.nl_aicc(o),error=function(e) NA_real_) else NA_real_
    cvv<-if(cv) tryCatch(nl_cv(o,k=k)$RMSE,error=function(e) NA_real_) else NA_real_
    data.frame(model=nm,engine=o$engine,likelihood_based=likelihood_ok,k=length(tryCatch(coef(fit),error=function(e) numeric())),AIC=a,AICc=ac,BIC=b,RMSE=.nl_rmse(obs,pred),MAE=.nl_mae(obs,pred),CV_RMSE=cvv)
  })
  tab<-do.call(rbind,rows); if(any(is.finite(tab$AICc))){d<-tab$AICc-min(tab$AICc,na.rm=TRUE); w<-exp(-.5*d);tab$delta_AICc<-d;tab$Akaike_weight<-w/sum(w,na.rm=TRUE)} else {tab$delta_AICc<-NA;tab$Akaike_weight<-NA}
  if(any(!tab$likelihood_based)) attr(tab,"note") <- "AIC/AICc/BIC are omitted for resistant or quantile-regression engines; compare those fits with predictive error, parameter stability and scientific diagnostics."
  tab[order(tab$AICc,tab$RMSE,na.last=TRUE),]
}
#' Likelihood-ratio test for explicitly nested models
#'
#' Performs a likelihood-ratio comparison only after the user explicitly declares that the reduced model is mathematically nested within the full model.
#' @param reduced Reduced `nlrfit`.
#' @param full Full `nlrfit`.
#' @param nested Must be explicitly set to `TRUE`; otherwise the test is blocked.
#' @return Backend ANOVA/LRT result.
#' @examples
#' okra <- nl_data("okra_growth_means"); f0 <- nl_fit(data=okra,model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); try(nl_lrt(f0,f0))
#' # A nested test must be scientifically established by the analyst.
#' try(nl_lrt(f0,f0,nested=FALSE))
#' # Explicit self-comparison is shown only as API demonstration.
#' nl_lrt(f0,f0,nested=TRUE)
#' @export
nl_lrt <- function(reduced, full, nested=FALSE) {
  if(any(vapply(list(reduced,full),function(z) inherits(z,"nlrfit") && identical(z$engine,"brms"),logical(1)))) stop("Likelihood-ratio tests are not used for brms-backed Bayesian fits; use nl_bayes_compare().",call.=FALSE)
  if(!isTRUE(nested)) stop("LRT blocked: set nested=TRUE only after establishing mathematical nesting and compatible likelihoods.",call.=FALSE)
  stats::anova(.nl_unwrap(reduced),.nl_unwrap(full))
}
#' K-fold predictive cross-validation
#'
#' Refits a nonlinear model across deterministic K-fold splits and returns prediction errors.
#' @param object An `nlrfit` object.
#' @param k Number of folds.
#' @param seed Random seed for fold allocation.
#' @return A list with fold metrics and aggregate RMSE/MAE.
#' @examples
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_cv(f,k=3)
#' f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_cv(f,k=4)
#' f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_cv(f,k=5)
#' @export
nl_cv <- function(object,k=5,seed=20260817) {
  stopifnot(inherits(object,"nlrfit")); if(identical(object$engine,"brms")) stop("Use PSIS-LOO via nl_bayes_compare() for brms-backed models.",call.=FALSE); n<-nrow(object$data); if(k<2||k>n) stop("Invalid k",call.=FALSE)
  set.seed(seed); fold<-sample(rep(seq_len(k),length.out=n)); resp<-.nl_response_name(object$formula); res<-vector("list",k)
  for(i in seq_len(k)){tr<-object$data[fold!=i,,drop=FALSE];te<-object$data[fold==i,,drop=FALSE]; z<-try(.nl_refit(object,tr),silent=TRUE)
    if(inherits(z,"try-error")){res[[i]]<-data.frame(fold=i,n=nrow(te),RMSE=NA,MAE=NA);next}; pr<-as.numeric(predict(z,newdata=te)); ob<-te[[resp]];res[[i]]<-data.frame(fold=i,n=nrow(te),RMSE=.nl_rmse(ob,pr),MAE=.nl_mae(ob,pr))}
  tab<-do.call(rbind,res); list(folds=tab,RMSE=weighted.mean(tab$RMSE,tab$n,na.rm=TRUE),MAE=weighted.mean(tab$MAE,tab$n,na.rm=TRUE),seed=seed)
}
#' Confidence intervals for nonlinear model parameters
#'
#' Computes Wald, profile-likelihood, bootstrap, or Bayesian posterior intervals where supported.
#' @param object An `nlrfit` object.
#' @param method `wald`, `profile`, `bootstrap`, or `posterior`. For `brms` fits, omission defaults to `posterior`.
#' @param level Confidence level.
#' @param boot Optional `nlrboot` object for bootstrap intervals.
#' @param bootstrap_interval Bootstrap interval type, either `percentile` or `bca`.
#' @return A data frame of parameter intervals.
#' @examples
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_confint(f,"wald")
#' nl_confint(f,"profile")
#' b <- nl_boot(f,R=30,seed=1); nl_confint(f,"bootstrap",boot=b,bootstrap_interval="bca")
#' @export
nl_confint <- function(object,method=c("wald","profile","bootstrap","posterior"),level=.95,boot=NULL,bootstrap_interval=c("percentile","bca")) {
  if(missing(method) && inherits(object,"nlrfit") && identical(object$engine,"brms")) method <- "posterior"
  method<-match.arg(method); bootstrap_interval<-match.arg(bootstrap_interval); alpha<-1-level
  if(method=="posterior") {
    if(!inherits(object,"nlrfit") || !identical(object$engine,"brms")) stop("posterior intervals require an nlrFlow brms fit.",call.=FALSE)
    .nl_require("brms","Bayesian posterior intervals")
    ps <- brms::posterior_summary(object$fit, probs=c(alpha/2,1-alpha/2), robust=TRUE)
    keep <- grepl("^b_",rownames(ps))
    if(!any(keep)) keep <- rep(TRUE,nrow(ps))
    ps <- ps[keep,,drop=FALSE]
    return(data.frame(parameter=rownames(ps),estimate=ps[,1],uncertainty=ps[,2],lower=ps[,3],upper=ps[,4],method="posterior-median",row.names=NULL,check.names=FALSE))
  }
  cf<-.nl_coef(object)
  if(method=="bootstrap") {
    if(is.null(boot)) stop("Supply boot= from nl_boot().",call.=FALSE)
    B<-boot$coefficients[boot$converged,,drop=FALSE]
    if(nrow(B)<10) warning("Very few converged bootstrap replicates; interval estimates are unstable.",call.=FALSE)
    if(bootstrap_interval=="percentile") {
      q<-apply(B,2,stats::quantile,probs=c(alpha/2,1-alpha/2),na.rm=TRUE)
      return(data.frame(parameter=colnames(q),estimate=cf[colnames(q)],lower=q[1,],upper=q[2,],method="bootstrap-percentile"))
    }
    # BCa: bias correction from bootstrap draws and acceleration from delete-one jackknife.
    dat<-object$data; pnames<-names(cf); J<-matrix(NA_real_,nrow(dat),length(cf),dimnames=list(NULL,pnames))
    for(i in seq_len(nrow(dat))) {
      z<-try(.nl_refit(object,dat[-i,,drop=FALSE]),silent=TRUE)
      if(!inherits(z,"try-error")) {cc<-try(coef(z),silent=TRUE); if(!inherits(cc,"try-error")) J[i,names(cc)]<-cc}
    }
    lo<-hi<-rep(NA_real_,length(cf)); names(lo)<-names(hi)<-pnames
    za<-stats::qnorm(c(alpha/2,1-alpha/2))
    for(j in seq_along(cf)) {
      bj<-B[,pnames[j]]; bj<-bj[is.finite(bj)]; jj<-J[,pnames[j]]; jj<-jj[is.finite(jj)]
      if(length(bj)<10 || length(jj)<5) next
      prop<-min(max(mean(bj < cf[j]),1/(2*length(bj))),1-1/(2*length(bj)))
      z0<-stats::qnorm(prop); jm<-mean(jj); u<-jm-jj
      acc<-sum(u^3)/(6*(sum(u^2)^(3/2))); if(!is.finite(acc)) acc<-0
      probs<-stats::pnorm(z0 + (z0+za)/(1-acc*(z0+za))); probs<-pmin(pmax(probs,0),1)
      qq<-stats::quantile(bj,probs=probs,na.rm=TRUE,names=FALSE);lo[j]<-qq[1];hi[j]<-qq[2]
    }
    return(data.frame(parameter=pnames,estimate=cf,lower=lo,upper=hi,method="bootstrap-BCa"))
  }
  if(method=="profile") { ci<-tryCatch(stats::confint(.nl_unwrap(object),level=level),error=function(e) NULL); if(!is.null(ci)) return(data.frame(parameter=rownames(ci),estimate=cf[rownames(ci)],lower=ci[,1],upper=ci[,2],method="profile")) }
  V<-.nl_extract_vcov(object); if(is.null(V)) stop("Variance-covariance matrix unavailable.",call.=FALSE); se<-sqrt(diag(V)); z<-stats::qnorm(1-alpha/2); data.frame(parameter=names(cf),estimate=cf,se=se,lower=cf-z*se,upper=cf+z*se,method="wald")
}

#' Joint nonlinear parameter confidence region
#'
#' Samples Beale's unlinearized joint parameter confidence region through
#' `nlstools::nlsConfRegions`. This complements marginal Wald/profile/bootstrap
#' intervals by visualizing joint parameter uncertainty and non-elliptical geometry.
#' @param object An `nlrfit` backed by an `nls`-compatible fit.
#' @param n Number of accepted/candidate points requested from the backend confidence-region sampler.
#' @param expansion Expansion factor of the parameter hypercube used by `nlstools`.
#' @return An `nlsConfRegions` object from `nlstools`.
#' @examples
#' \dontrun{
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_confregion(f,n=500)
#' f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_confregion(f,n=500)
#' f <- nl_fit(data=subset(nl_data("plant_physiology_light"),water_regime=="WellWatered"),model="rectangular_hyperbola",response="A_umol_CO2_m2_s",predictor="PAR_umol_m2_s",engine="nls"); nl_confregion(f,n=500)
#' }
#' @export
nl_confregion <- function(object,n=1000,expansion=1.5) {
  .nl_require("nlstools","joint nonlinear confidence regions")
  if(!inherits(object,"nlrfit")) stop("object must be an nlrfit.",call.=FALSE)
  fit <- .nl_unwrap(object)
  if(!inherits(fit,"nls")) stop("nl_confregion currently requires an nls-compatible backend fit.",call.=FALSE)
  z <- nlstools::nlsConfRegions(fit,length=n,exp=expansion)
  class(z) <- unique(c("nlr_confregion",class(z)))
  z
}
