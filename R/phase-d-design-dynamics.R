# Phase D: optimal design, stochastic dynamics, GP discrepancy and surrogates --

.nl_prediction_gradient <- function(formula, data_row, parameters, rel_step=sqrt(.Machine$double.eps)) {
  b<-unlist(parameters);g<-numeric(length(b));names(g)<-names(b)
  for(j in seq_along(b)){h<-rel_step*max(abs(b[j]),1);bp<-bm<-b;bp[j]<-bp[j]+h;bm[j]<-bm[j]-h;g[j]<-(as.numeric(.nl_rhs_eval(formula,data_row,bp))[1]-as.numeric(.nl_rhs_eval(formula,data_row,bm))[1])/(2*h)}
  g
}
.nl_design_score <- function(M,criterion,c_vector=NULL,ridge=1e-10) {
  M<-(M+t(M))/2+diag(ridge,nrow(M));ev<-eigen(M,symmetric=TRUE,only.values=TRUE)$values
  if(criterion=="D") return(sum(log(pmax(ev,ridge))))
  if(criterion=="A") { iv<-tryCatch(solve(M),error=function(e)NULL); if(is.null(iv)) return(-Inf); return(-sum(diag(iv))) }
  if(criterion=="E") return(min(ev))
  if(criterion=="c") {if(is.null(c_vector))stop("c_vector is required for c-optimality.",call.=FALSE);iv<-tryCatch(solve(M),error=function(e)NULL);if(is.null(iv))return(-Inf);return(-as.numeric(t(c_vector)%*%iv%*%c_vector))}
  stop("Unknown criterion.",call.=FALSE)
}

#' Locally optimal nonlinear experimental design
#'
#' Selects candidate predictor values greedily using the Fisher information of
#' the nonlinear mean at nominal parameter values. D-, A-, E- and c-optimal
#' criteria are available. This is a local design and should be repeated across
#' plausible parameter scenarios when prior uncertainty is substantial.
#'
#' @param formula Nonlinear response formula.
#' @param data_template One-row data frame containing non-predictor covariates.
#' @param parameters Named nominal nonlinear parameter vector.
#' @param predictor Predictor column to vary.
#' @param candidates Numeric candidate predictor values.
#' @param n_points Number of distinct points selected.
#' @param criterion `D`, `A`, `E`, or `c`.
#' @param sigma Residual SD used to scale information.
#' @param c_vector Contrast vector for c-optimality.
#' @param existing Optional existing predictor values whose information is included.
#' @return An `nlr_design` object with selected points and information trajectory.
#' @examples
#' o<-nl_data("okra_growth_means"); nl_design(fruit_length~Asym*exp(-exp(-k*(day_after_flowering-xmid))),o[1,,drop=FALSE],c(Asym=18,k=.4,xmid=4),"day_after_flowering",1:25,6)
#' f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); nl_design(grain_yield_Mg_ha~Asym-delta*exp(-k*P2O5_kg_ha),f[1,,drop=FALSE],c(Asym=8,delta=5,k=.02),"P2O5_kg_ha",seq(0,300,10),7)
#' p<-subset(nl_data("plant_physiology_light"),water_regime=="WellWatered"); nl_design(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,p[1,,drop=FALSE],c(Amax=30,alpha=.06,Rd=1),"PAR_umol_m2_s",seq(0,2000,100),7)
#' @export
nl_design <- function(formula,data_template,parameters,predictor,candidates,n_points,
                      criterion=c("D","A","E","c"),sigma=1,c_vector=NULL,existing=NULL) {
  criterion<-match.arg(criterion);b<-unlist(parameters);if(is.null(names(b)))stop("parameters must be named.",call.=FALSE);if(!predictor%in%names(data_template))stop("predictor must be present in data_template.",call.=FALSE);cand<-sort(unique(as.numeric(candidates)));if(n_points<1||n_points>length(cand))stop("n_points must be between 1 and the number of unique candidates.",call.=FALSE);p<-length(b);M<-matrix(0,p,p);rownames(M)<-colnames(M)<-names(b)
  info_at<-function(x){d<-data_template[rep(1,1),,drop=FALSE];d[[predictor]]<-x;g<-.nl_prediction_gradient(formula,d,b);tcrossprod(g)/sigma^2}
  if(!is.null(existing))for(x in existing)M<-M+info_at(x)
  remaining<-cand;sel<-numeric(0);traj<-data.frame(step=integer(),point=numeric(),score=numeric())
  for(k in seq_len(n_points)){scores<-vapply(remaining,function(x).nl_design_score(M+info_at(x),criterion,c_vector),numeric(1));j<-which.max(scores);x<-remaining[j];M<-M+info_at(x);sel<-c(sel,x);traj<-rbind(traj,data.frame(step=k,point=x,score=scores[j]));remaining<-remaining[-j]}
  structure(list(selected=sel,information=M,trajectory=traj,criterion=criterion,parameters=b,predictor=predictor,candidates=cand,existing=existing,sigma=sigma),class="nlr_design")
}

#' Select the next informative nonlinear measurement
#'
#' Chooses one new predictor value by adding candidate Fisher information to an
#' existing local design. It is intended for sequential sampling after an
#' interim fit has updated the nominal parameters.
#'
#' @param formula Nonlinear response formula.
#' @param data_template One-row covariate template.
#' @param parameters Current named parameter estimates.
#' @param predictor Predictor column.
#' @param candidates Candidate new predictor values.
#' @param existing Existing predictor values.
#' @param criterion Optimality criterion.
#' @param sigma Residual SD.
#' @param c_vector Contrast for c-optimality.
#' @return The one-point `nlr_design` result.
#' @examples
#' o<-nl_data("okra_growth_means"); nl_next_measurement(fruit_length~Asym*exp(-exp(-k*(day_after_flowering-xmid))),o[1,,drop=FALSE],c(Asym=18,k=.4,xmid=4),"day_after_flowering",1:25,o$day_after_flowering)
#' f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); nl_next_measurement(grain_yield_Mg_ha~Asym-delta*exp(-k*P2O5_kg_ha),f[1,,drop=FALSE],c(Asym=8,delta=5,k=.02),"P2O5_kg_ha",seq(0,300,10),f$P2O5_kg_ha)
#' p<-subset(nl_data("plant_physiology_light"),water_regime=="WellWatered"); nl_next_measurement(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,p[1,,drop=FALSE],c(Amax=30,alpha=.06,Rd=1),"PAR_umol_m2_s",seq(0,2000,100),p$PAR_umol_m2_s)
#' @export
nl_next_measurement <- function(formula,data_template,parameters,predictor,candidates,existing,
                                criterion=c("D","A","E","c"),sigma=1,c_vector=NULL) {
  nl_design(formula,data_template,parameters,predictor,candidates,n_points=1,
            criterion=match.arg(criterion),sigma=sigma,c_vector=c_vector,existing=existing)
}

#' Fit a continuous-time stochastic state-space model through ctsmTMB
#'
#' Accepts either a preconfigured `ctsmTMB` model or a builder function that
#' receives a fresh model created by the current `ctsmTMB` constructor (`newModel()` when available, otherwise the exported R6 generator). This keeps process equations,
#' observation equations, process diffusion and measurement variance explicit.
#'
#' @param model A configured ctsmTMB R6 model, or a function that configures and returns one.
#' @param data Time-ordered data frame with a `t` column and required observations/inputs.
#' @param method Filtering/estimation method passed to `model$estimate` when supported.
#' @param ... Additional arguments to `model$estimate`.
#' @return An `nlr_state_space` object.
#' @examples
#' \dontrun{
#' builder <- function(m){m$addSystem(dx~theta*(mu-x)*dt+sigma_x*dw);m$addObs(y~x);m$setVariance(y~sigma_y^2);m$setParameter(theta=c(initial=1,lower=.001,upper=20),mu=c(initial=1,lower=-10,upper=10),sigma_x=c(initial=.1,lower=1e-5,upper=5),sigma_y=.1);m$setInitialState(list(mean=1,cov=.01));m}
#' # nl_state_space(builder, agronomy_sensor_series)
#' # nl_state_space(builder, soil_moisture_series)
#' # nl_state_space(builder, physiology_time_series)
#' }
#' @export
nl_state_space <- function(model,data,method="ekf",...) {
  .nl_require("ctsmTMB","continuous-time stochastic state-space models")
  m<-model
  if(is.function(model)){
    ns <- asNamespace("ctsmTMB")
    ctor <- if(exists("newModel", envir=ns, inherits=FALSE)) get("newModel", envir=ns, inherits=FALSE) else NULL
    m <- if(is.function(ctor)) ctor() else get("ctsmTMB", envir=ns, inherits=FALSE)$new()
    m<-model(m);if(is.null(m))stop("Builder function must return the configured ctsmTMB model.",call.=FALSE)
  }
  if(is.null(m$estimate)||!is.function(m$estimate))stop("model must be a configured ctsmTMB object or builder function.",call.=FALSE)
  fit<-m$estimate(data,method=method,...)
  structure(list(fit=fit,model=m,data=data,method=method,call=match.call()),class="nlr_state_space")
}

#' Decompose process and observation uncertainty in a state-space fit
#'
#' Summarizes latent-state uncertainty, normalized innovations, and available
#' parameter estimates corresponding to process- and measurement-noise terms.
#' The function does not force identifiability: when both noise sources are weakly
#' identified it flags the issue for sensitivity analysis or external calibration.
#'
#' @param object An `nlr_state_space` object.
#' @param process_parameters Optional names of process-noise parameters.
#' @param observation_parameters Optional names of observation-noise parameters.
#' @return An `nlr_error_decomposition` object.
#' @examples
#' \dontrun{
#' # nl_error_decompose(soil_state_fit,"sigma_x","sigma_y")
#' # nl_error_decompose(physiology_state_fit,c("sigma_growth","sigma_env"),"sigma_sensor")
#' # nl_error_decompose(agronomy_state_fit,"sigma_process","sigma_obs")
#' }
#' @export
nl_error_decompose <- function(object,process_parameters=NULL,observation_parameters=NULL) {
  if(!inherits(object,"nlr_state_space"))stop("object must be returned by nl_state_space.",call.=FALSE);f<-object$fit;pars<-f$par.fixed%||%numeric();proc<-pars[intersect(process_parameters%||%character(),names(pars))];obs<-pars[intersect(observation_parameters%||%character(),names(pars))];nr<-tryCatch(f$residuals$normalized,error=function(e)NULL);state<-tryCatch(f$states,error=function(e)NULL);warn<-character();if(length(proc)>0&&length(obs)>0&&any(!is.finite(c(proc,obs))))warn<-c(warn,"Non-finite noise parameter estimate detected.");if(length(proc)==0&&length(obs)==0)warn<-c(warn,"No process/observation parameter names supplied; decomposition is descriptive only.");structure(list(process_parameters=proc,observation_parameters=obs,normalized_innovations=nr,states=state,warnings=warn,fit=f),class="nlr_error_decomposition")
}

#' Diagnose mechanistic-model discrepancy with a Gaussian process
#'
#' Fits a Gaussian-process emulator to residual structure after a nonlinear
#' mechanistic fit. This is deliberately a *sequential discrepancy diagnostic*:
#' it reveals systematic residual structure without silently letting a flexible
#' GP redefine mechanistic parameters.
#'
#' @param object An `nlrfit`.
#' @param predictors Character vector of columns used as GP inputs.
#' @param newdata Optional prediction grid.
#' @param covtype Covariance type passed to `DiceKriging::km`.
#' @param ... Additional arguments to `DiceKriging::km`.
#' @return An `nlr_gp_discrepancy` object with GP fit and corrected predictions.
#' @examples
#' \dontrun{
#' o<-nl_data("okra_growth_means"); fo<-nl_fit(data=o,model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_gp_discrepancy(fo,"day_after_flowering")
#' f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); ff<-nl_fit(data=f,model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_gp_discrepancy(ff,"P2O5_kg_ha")
#' s<-subset(nl_data("soil_water_retention"),texture=="Clayey"); fs<-nl_fit(data=s,model="van_genuchten",response="water_content_cm3_cm3",predictor="pressure_head_kPa",engine="nls"); nl_gp_discrepancy(fs,"pressure_head_kPa")
#' }
#' @export
nl_gp_discrepancy <- function(object,predictors,newdata=NULL,covtype="matern5_2",...) {
  .nl_require("DiceKriging","Gaussian-process discrepancy diagnostics");if(!inherits(object,"nlrfit"))stop("object must be an nlrfit.",call.=FALSE);if(!all(predictors%in%names(object$data)))stop("All predictors must be columns in fitted data.",call.=FALSE);r<-as.numeric(stats::residuals(object$fit));X<-as.data.frame(object$data[,predictors,drop=FALSE]);gp<-DiceKriging::km(design=X,response=r,covtype=covtype,nugget.estim=TRUE,control=list(trace=FALSE),...);nd<-newdata%||%object$data;mech<-as.numeric(stats::predict(object$fit,newdata=nd));pg<-stats::predict(gp,newdata=as.data.frame(nd[,predictors,drop=FALSE]),type="UK",se.compute=TRUE,cov.compute=FALSE);structure(list(gp=gp,mechanistic=mech,discrepancy=as.numeric(pg$mean),discrepancy_se=as.numeric(pg$sd),corrected=mech+as.numeric(pg$mean),predictors=predictors,newdata=nd,method="sequential mechanistic + GP discrepancy diagnostic"),class="nlr_gp_discrepancy")
}

#' Fit a surrogate for an expensive nonlinear simulator
#'
#' Trains a Gaussian-process or polynomial-response-surface emulator from a
#' parameter design and simulator outputs. Surrogates should be validated on
#' held-out simulator runs before use inside bootstrap, MCMC or optimization.
#'
#' @param parameters Matrix/data frame of simulator input parameters.
#' @param response Numeric simulator output or scalar summary.
#' @param method `gp` or `quadratic`.
#' @param ... Additional backend arguments.
#' @return An `nlr_surrogate` object.
#' @examples
#' \dontrun{
#' X<-expand.grid(A=seq(15,22,length=8),k=seq(.2,.7,length=8)); y<-with(X,A*k/exp(1)); nl_surrogate(X,y,"quadratic")
#' X2<-data.frame(qmax=runif(50,300,800),K=runif(50,.02,.5)); y2<-with(X2,qmax*K*10/(1+K*10)); nl_surrogate(X2,y2,"gp")
#' X3<-data.frame(Amax=runif(50,10,50),alpha=runif(50,.01,.2)); y3<-with(X3,Amax*alpha*1000/(Amax+alpha*1000)); nl_surrogate(X3,y3,"gp")
#' }
#' @export
nl_surrogate <- function(parameters,response,method=c("gp","quadratic"),...) {
  method<-match.arg(method);X<-as.data.frame(parameters);y<-as.numeric(response);if(nrow(X)!=length(y))stop("parameters rows and response length differ.",call.=FALSE);if(any(!vapply(X,is.numeric,logical(1))))stop("All surrogate inputs must be numeric.",call.=FALSE)
  if(method=="gp"){.nl_require("DiceKriging","Gaussian-process surrogates");fit<-DiceKriging::km(design=X,response=y,covtype="matern5_2",nugget.estim=TRUE,control=list(trace=FALSE),...);predfun<-function(newdata){z<-stats::predict(fit,newdata=as.data.frame(newdata),type="UK",se.compute=TRUE,cov.compute=FALSE);data.frame(.prediction=as.numeric(z$mean),.se=as.numeric(z$sd))}}
  else {nm<-names(X);terms<-c(nm,paste0("I(",nm,"^2)"));if(length(nm)>1)terms<-c(terms,combn(nm,2,FUN=function(z)paste(z,collapse="*")));frm<-stats::as.formula(paste(".y ~",paste(terms,collapse=" + ")));dd<-X;dd$.y<-y;fit<-stats::lm(frm,data=dd);predfun<-function(newdata){p<-stats::predict(fit,newdata=as.data.frame(newdata),se.fit=TRUE);data.frame(.prediction=as.numeric(p$fit),.se=as.numeric(p$se.fit))}}
  structure(list(fit=fit,method=method,parameters=X,response=y,predict=predfun,call=match.call()),class="nlr_surrogate")
}

#' Validate a nonlinear surrogate on independent simulator runs
#'
#' Computes prediction error and empirical interval coverage where surrogate
#' standard errors are available.
#'
#' @param object An `nlr_surrogate`.
#' @param parameters Validation parameter matrix/data frame.
#' @param response True simulator outputs.
#' @param level Nominal normal-approximation prediction level.
#' @return A data frame of validation metrics and predictions.
#' @examples
#' \dontrun{
#' X<-expand.grid(A=seq(15,22,length=8),k=seq(.2,.7,length=8));y<-with(X,A*k/exp(1));s<-nl_surrogate(X,y,"quadratic");nl_surrogate_validate(s,X,y)
#' X2<-data.frame(qmax=runif(50,300,800),K=runif(50,.02,.5));y2<-with(X2,qmax*K*10/(1+K*10));s2<-nl_surrogate(X2,y2,"gp");nl_surrogate_validate(s2,X2,y2)
#' X3<-data.frame(Amax=runif(50,10,50),alpha=runif(50,.01,.2));y3<-with(X3,Amax*alpha*1000/(Amax+alpha*1000));s3<-nl_surrogate(X3,y3,"gp");nl_surrogate_validate(s3,X3,y3)
#' }
#' @export
nl_surrogate_validate <- function(object,parameters,response,level=.95) {
  if(!inherits(object,"nlr_surrogate"))stop("object must be returned by nl_surrogate.",call.=FALSE);pr<-object$predict(parameters);y<-as.numeric(response);if(length(y)!=nrow(pr))stop("response length is incompatible with predictions.",call.=FALSE);z<-stats::qnorm(1-(1-level)/2);lo<-pr$.prediction-z*pr$.se;up<-pr$.prediction+z*pr$.se;metrics<-data.frame(RMSE=.nl_rmse(y,pr$.prediction),MAE=.nl_mae(y,pr$.prediction),Bias=mean(pr$.prediction-y),Coverage=mean(y>=lo&y<=up,na.rm=TRUE),Level=level);structure(list(metrics=metrics,predictions=data.frame(observed=y,pr,lower=lo,upper=up)),class="nlr_surrogate_validation")
}
