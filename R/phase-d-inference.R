# Phase D: distributional, quantile, conformal and identifiability inference ----

#' Nonlinear quantile mixed-effects regression through qrNLMM
#'
#' Fits one or several conditional quantiles in a nonlinear mixed-effects model
#' using the SAEM/asymmetric-Laplace implementation in `qrNLMM`. The model
#' expression and initial parameter structure are kept explicit because they are
#' study-specific.
#'
#' @param y Response vector.
#' @param x Predictor vector or matrix accepted by `qrNLMM::QRNLMM`.
#' @param groups Group/subject identifier.
#' @param initial Initial values accepted by `QRNLMM`.
#' @param exprNL Nonlinear expression expected by `QRNLMM`.
#' @param covar Optional covariates.
#' @param tau One or more quantiles in (0,1).
#' @param ... Additional arguments to `qrNLMM::QRNLMM`.
#' @return An `nlr_quantile_mixed` object retaining the backend fit and quantiles.
#' @examples
#' \dontrun{
#' a <- nl_data("agronomy_growth"); # nl_quantile_mixed(a$biomass_Mg_ha,a$day,interaction(a$cultivar,a$block,drop=TRUE),initial,exprNL,tau=c(.1,.5,.9))
#' p <- nl_data("plant_physiology_light"); # nl_quantile_mixed(p$A_umol_CO2_m2_s,p$PAR_umol_m2_s,p$plant_id,initial,exprNL,tau=.5)
#' s <- nl_data("soil_infiltration"); # nl_quantile_mixed(s$cumulative_infiltration_mm,s$time_min,interaction(s$management,s$block,drop=TRUE),initial,exprNL,tau=.9)
#' }
#' @export
nl_quantile_mixed <- function(y, x, groups, initial, exprNL, covar = NA, tau = 0.5, ...) {
  .nl_require("qrNLMM", "nonlinear quantile mixed-effects regression")
  if (any(!is.finite(tau)) || any(tau <= 0 | tau >= 1)) stop("tau values must lie strictly between 0 and 1.", call. = FALSE)
  fit <- qrNLMM::QRNLMM(y = y, x = x, groups = groups, initial = initial,
                        exprNL = exprNL, covar = covar, p = tau, ...)
  structure(list(fit = fit, tau = tau, groups = groups, call = match.call()),
            class = "nlr_quantile_mixed")
}

# Internal smooth pinball loss. Linear tails preserve bounded influence in y.
.nl_softplus <- function(z) log1p(exp(-abs(z))) + pmax(z, 0)
.nl_smooth_pinball <- function(u, tau, delta) {
  delta * (tau * .nl_softplus(u/delta) + (1-tau) * .nl_softplus(-u/delta))
}

#' Robust penalized nonlinear quantile mixed-effects sensitivity fit
#'
#' Fits a transparent penalized nonlinear quantile model with group-specific
#' random deviations on selected nonlinear parameters. It uses a smooth pinball
#' loss and Gaussian ridge penalty on random effects. This is an experimental
#' sensitivity estimator, not an implementation of the contaminated-GAL model;
#' use it to assess whether conclusions depend strongly on mean-based NLMEMs or
#' extreme observations.
#'
#' @param formula Nonlinear formula.
#' @param data Data frame.
#' @param start Named fixed-effect starting values.
#' @param group Grouping column name.
#' @param random_params Parameter names receiving group-specific deviations.
#' @param tau Target quantile.
#' @param lambda Positive random-effect penalty strength.
#' @param smooth Positive smoothing width for the pinball loss.
#' @param method Optimization method passed to `stats::optim`.
#' @param control Optimizer control list.
#' @return An `nlr_quantile_mixed_robust` object.
#' @examples
#' \dontrun{
#' a <- nl_data("agronomy_growth"); a$unit<-interaction(a$cultivar,a$block,drop=TRUE); nl_quantile_mixed_robust(biomass_Mg_ha~Asym/(1+exp(-k*(day-xmid))),a,c(Asym=18,k=.08,xmid=50),"unit",c("Asym","k"))
#' p <- nl_data("plant_physiology_light"); nl_quantile_mixed_robust(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,p,c(Amax=30,alpha=.06,Rd=1),"plant_id",c("Amax"),tau=.5)
#' s <- nl_data("soil_infiltration"); s$unit<-interaction(s$management,s$block,drop=TRUE); nl_quantile_mixed_robust(cumulative_infiltration_mm~Vmax*time_min/(Km+time_min),s,c(Vmax=140,Km=30),"unit",c("Vmax"),tau=.9)
#' }
#' @export
nl_quantile_mixed_robust <- function(formula, data, start, group, random_params = names(start),
                                     tau = 0.5, lambda = 1, smooth = 0.05,
                                     method = "BFGS", control = list()) {
  if (!is.data.frame(data)) stop("data must be a data frame.", call. = FALSE)
  if (!group %in% names(data)) stop("group column is absent from data.", call. = FALSE)
  if (is.null(names(start)) || any(names(start)=="")) stop("start must be a named numeric vector/list.", call. = FALSE)
  start <- unlist(start)
  if (!all(random_params %in% names(start))) stop("random_params must be names in start.", call. = FALSE)
  if (!is.finite(tau) || tau <= 0 || tau >= 1) stop("tau must lie in (0,1).", call. = FALSE)
  if (!is.finite(lambda) || lambda <= 0 || !is.finite(smooth) || smooth <= 0) stop("lambda and smooth must be positive.", call. = FALSE)
  g <- factor(data[[group]]); gi <- as.integer(g); ng <- nlevels(g); q <- length(random_params); p <- length(start)
  response <- .nl_response_name(formula); y <- data[[response]]
  if (is.null(y)) stop("Response column could not be located.", call. = FALSE)
  objective <- function(theta) {
    fixed <- theta[seq_len(p)]; names(fixed) <- names(start)
    b <- matrix(theta[p + seq_len(ng*q)], nrow = ng, ncol = q, byrow = TRUE)
    pred <- numeric(nrow(data))
    for (k in seq_len(ng)) {
      idx <- which(gi == k); par <- fixed; par[random_params] <- par[random_params] + b[k, ]
      pred[idx] <- .nl_rhs_eval(formula, data[idx,,drop=FALSE], par)
    }
    u <- y - pred
    sum(.nl_smooth_pinball(u, tau, smooth), na.rm=TRUE) + 0.5*lambda*sum(b^2)
  }
  theta0 <- c(start, rep(0, ng*q))
  opt <- stats::optim(theta0, objective, method = method, control = control, hessian = TRUE)
  fixed <- opt$par[seq_len(p)]; names(fixed) <- names(start)
  b <- matrix(opt$par[p + seq_len(ng*q)], nrow=ng, ncol=q, byrow=TRUE,
              dimnames=list(levels(g), random_params))
  pred <- numeric(nrow(data))
  for (k in seq_len(ng)) {
    idx <- which(gi == k); par <- fixed; par[random_params] <- par[random_params] + b[k,]
    pred[idx] <- .nl_rhs_eval(formula,data[idx,,drop=FALSE],par)
  }
  H <- opt$hessian; V <- tryCatch(solve(H), error=function(e) NULL)
  structure(list(coefficients=fixed, random_effects=b, fitted=pred, residuals=y-pred,
                 tau=tau, lambda=lambda, smooth=smooth, group=group, formula=formula,
                 data=data, optimization=opt, vcov=if(is.null(V)) NULL else V[seq_len(p),seq_len(p),drop=FALSE],
                 method="penalized smooth pinball sensitivity estimator", call=match.call()),
            class="nlr_quantile_mixed_robust")
}

#' Split conformal prediction for nonlinear regression
#'
#' Creates finite-sample split-conformal prediction intervals by refitting an
#' `nlrfit` on a proper training subset and calibrating absolute residual scores
#' on held-out observations. The returned interval concerns future observations,
#' not uncertainty of the conditional mean curve.
#'
#' @param object Refit-capable `nlrfit` object.
#' @param newdata Data frame for prediction; defaults to the original data.
#' @param alpha Miscoverage probability.
#' @param calibration_fraction Fraction allocated to calibration.
#' @param seed Random seed controlling the split.
#' @param indices Optional explicit calibration-row indices.
#' @return An `nlr_conformal` object containing predictions and intervals.
#' @examples
#' ok <- nl_data("okra_growth_means"); fo <- nl_fit(data=ok,model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_conformal(fo,alpha=.1)
#' sf <- subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); ff <- nl_fit(data=sf,model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_conformal(ff)
#' si <- subset(nl_data("soil_infiltration"),management=="NoTill"); fi <- nl_fit(data=si,model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_conformal(fi)
#' @export
nl_conformal <- function(object, newdata = NULL, alpha = 0.05,
                         calibration_fraction = 0.25, seed = 20260817,
                         indices = NULL) {
  if (!inherits(object,"nlrfit")) stop("object must be an nlrfit.", call.=FALSE)
  if (!is.finite(alpha) || alpha <= 0 || alpha >= 1) stop("alpha must lie in (0,1).",call.=FALSE)
  d <- object$data; n <- nrow(d)
  if (n < 8L) stop("At least eight observations are recommended for split conformal prediction.",call.=FALSE)
  if (is.null(indices)) {
    if (!is.finite(calibration_fraction) || calibration_fraction <= 0 || calibration_fraction >= .8) stop("calibration_fraction must lie in (0,.8).",call.=FALSE)
    set.seed(seed); ncal <- max(2L, floor(n*calibration_fraction)); cal <- sort(sample.int(n,ncal))
  } else {
    cal <- sort(unique(as.integer(indices))); if(any(cal<1|cal>n)) stop("indices contain invalid rows.",call.=FALSE)
  }
  train <- setdiff(seq_len(n),cal)
  if(length(train)<length(coef(object))+2L) stop("Training split is too small for the fitted nonlinear model.",call.=FALSE)
  fit_train <- .nl_refit(object,d[train,,drop=FALSE])
  resp <- .nl_response_name(object$formula)
  pcal <- as.numeric(stats::predict(fit_train$fit,newdata=d[cal,,drop=FALSE]))
  scores <- abs(d[[resp]][cal]-pcal)
  m <- length(scores); prob <- min(1, ceiling((m+1)*(1-alpha))/m)
  q <- as.numeric(stats::quantile(scores,probs=prob,type=1,na.rm=TRUE,names=FALSE))
  nd <- newdata %||% d
  pred <- as.numeric(stats::predict(fit_train$fit,newdata=nd))
  out <- data.frame(.prediction=pred,.lower=pred-q,.upper=pred+q)
  structure(list(interval=out,score_quantile=q,scores=scores,alpha=alpha,
                 calibration=cal,training=train,fit=fit_train,seed=seed,
                 method="split conformal absolute residual",newdata=nd),class="nlr_conformal")
}

#' Cluster-aware and Mondrian conformal prediction
#'
#' Splits entire clusters between training and calibration to preserve the
#' independence unit in repeated-measures experiments. Optional `strata` creates
#' Mondrian score distributions for qualitative groups such as cultivar, soil
#' class or water regime.
#'
#' @param object Refit-capable `nlrfit`.
#' @param cluster Cluster/unit identifier column.
#' @param newdata Prediction data; defaults to original data.
#' @param strata Optional qualitative column defining Mondrian calibration groups.
#' @param alpha Miscoverage probability.
#' @param calibration_fraction Fraction of clusters held out for calibration.
#' @param min_scores Minimum score count required for a stratum; otherwise the
#'   global cluster-calibrated quantile is used.
#' @param seed Random seed.
#' @return An `nlr_conformal_group` object.
#' @examples
#' \dontrun{
#' a <- nl_data("agronomy_growth"); a$unit<-interaction(a$cultivar,a$block,drop=TRUE); fa <- nl_fit(biomass_Mg_ha~Asym/(1+exp(-k*(day-xmid))),a,start=list(Asym=18,k=.08,xmid=50),engine="nls"); nl_conformal_group(fa,"unit",strata="cultivar")
#' p <- nl_data("plant_physiology_light"); fp <- nl_fit(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,p,start=list(Amax=30,alpha=.06,Rd=1),engine="nls"); nl_conformal_group(fp,"plant_id",strata="water_regime")
#' s <- nl_data("soil_infiltration"); s$unit<-interaction(s$management,s$block,drop=TRUE); fs <- nl_fit(cumulative_infiltration_mm~Vmax*time_min/(Km+time_min),s,start=list(Vmax=140,Km=30),engine="nls"); nl_conformal_group(fs,"unit",strata="management")
#' }
#' @export
nl_conformal_group <- function(object, cluster, newdata = NULL, strata = NULL,
                               alpha = 0.05, calibration_fraction = 0.25,
                               min_scores = 5L, seed = 20260817) {
  if(!inherits(object,"nlrfit")) stop("object must be an nlrfit.",call.=FALSE)
  d <- object$data
  if(!cluster %in% names(d)) stop("cluster column is absent from fitted data.",call.=FALSE)
  if(!is.null(strata) && !strata %in% names(d)) stop("strata column is absent from fitted data.",call.=FALSE)
  ids <- unique(d[[cluster]]); G <- length(ids)
  if(G < 4L) stop("At least four independent clusters are required.",call.=FALSE)
  set.seed(seed); ncal <- max(1L,floor(G*calibration_fraction)); cal_ids <- sample(ids,ncal)
  cal <- which(d[[cluster]] %in% cal_ids); train <- setdiff(seq_len(nrow(d)),cal)
  fit_train <- .nl_refit(object,d[train,,drop=FALSE]); resp <- .nl_response_name(object$formula)
  pcal <- as.numeric(stats::predict(fit_train$fit,newdata=d[cal,,drop=FALSE])); scores <- abs(d[[resp]][cal]-pcal)
  qfun <- function(s) { m<-sum(is.finite(s)); if(m<1L)return(NA_real_); pr<-min(1,ceiling((m+1)*(1-alpha))/m); as.numeric(stats::quantile(s,pr,type=1,na.rm=TRUE,names=FALSE)) }
  q_global <- qfun(scores)
  nd <- newdata %||% d; pred <- as.numeric(stats::predict(fit_train$fit,newdata=nd)); q <- rep(q_global,nrow(nd)); q_by <- NULL
  if(!is.null(strata)) {
    lev <- unique(as.character(d[[strata]][cal])); q_by <- stats::setNames(rep(q_global,length(lev)),lev)
    for(z in lev) { sc<-scores[as.character(d[[strata]][cal])==z]; if(sum(is.finite(sc))>=min_scores) q_by[z]<-qfun(sc) }
    zz <- as.character(nd[[strata]]); hit <- zz %in% names(q_by); q[hit] <- q_by[zz[hit]]
  }
  out <- data.frame(.prediction=pred,.lower=pred-q,.upper=pred+q,.score_quantile=q)
  structure(list(interval=out,global_quantile=q_global,quantile_by_stratum=q_by,
                 scores=scores,calibration_clusters=cal_ids,training_rows=train,
                 alpha=alpha,cluster=cluster,strata=strata,fit=fit_train,seed=seed,
                 method="cluster split / Mondrian conformal",newdata=nd),class="nlr_conformal_group")
}

.nl_sd_vector <- function(x, data, n, name) {
  if (length(x)==1L && is.character(x) && x %in% names(data)) x <- data[[x]]
  if (length(x)==1L) x <- rep(as.numeric(x),n)
  x <- as.numeric(x)
  if(length(x)!=n || any(!is.finite(x)) || any(x<=0)) stop(name," must be positive, finite, and length 1 or n (or a valid column name).",call.=FALSE)
  x
}

#' Nonlinear errors-in-variables regression
#'
#' Fits a Gaussian nonlinear measurement-error model in which each observed
#' predictor is a noisy measurement of a latent true predictor. Both x and y
#' measurement standard deviations may be observation-specific. This avoids the
#' attenuation and parameter bias that can occur when the predictor is treated
#' as exact.
#'
#' @param formula Nonlinear mean formula using `predictor`.
#' @param data Data frame.
#' @param start Named nonlinear parameter starts.
#' @param predictor Predictor column subject to measurement error.
#' @param sd_x Predictor measurement SD: scalar, vector or column name.
#' @param sd_y Response measurement/residual SD: scalar, vector or column name.
#' @param lower Lower bounds for nonlinear parameters.
#' @param upper Upper bounds for nonlinear parameters.
#' @param control Optimizer control list.
#' @return An `nlr_eiv_fit` with parameter estimates and estimated latent x values.
#' @examples
#' \dontrun{
#' s <- subset(nl_data("soil_p_sorption"),soil_class=="Clayey"); nl_measurement_error(sorbed_P_mg_kg~qmax*K*solution_P_mg_L/(1+K*solution_P_mg_L),s,c(qmax=600,K=.2),"solution_P_mg_L",sd_x=.05,sd_y=10)
#' p <- subset(nl_data("plant_physiology_light"),water_regime=="WellWatered"); nl_measurement_error(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,p,c(Amax=30,alpha=.06,Rd=1),"PAR_umol_m2_s",sd_x=10,sd_y=1)
#' f <- subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); nl_measurement_error(grain_yield_Mg_ha~Asym-delta*exp(-k*P2O5_kg_ha),f,c(Asym=8,delta=5,k=.02),"P2O5_kg_ha",sd_x=2,sd_y=.25)
#' }
#' @export
nl_measurement_error <- function(formula, data, start, predictor, sd_x, sd_y,
                                 lower = -Inf, upper = Inf, control = list(maxit=5000)) {
  if(!predictor %in% names(data)) stop("predictor column is absent from data.",call.=FALSE)
  start <- unlist(start); if(is.null(names(start))) stop("start must be named.",call.=FALSE)
  resp <- .nl_response_name(formula); y <- data[[resp]]; xobs <- as.numeric(data[[predictor]]); n <- nrow(data)
  sx <- .nl_sd_vector(sd_x,data,n,"sd_x"); sy <- .nl_sd_vector(sd_y,data,n,"sd_y")
  p <- length(start); lo <- rep(lower,length.out=p); hi <- rep(upper,length.out=p)
  obj <- function(z) {
    b <- z[seq_len(p)]; names(b)<-names(start); xt <- z[p+seq_len(n)]; dd<-data; dd[[predictor]]<-xt
    mu <- .nl_rhs_eval(formula,dd,b)
    if(any(!is.finite(mu))) return(.Machine$double.xmax/100)
    -sum(stats::dnorm(y,mu,sy,log=TRUE)+stats::dnorm(xobs,xt,sx,log=TRUE))
  }
  z0 <- c(start,xobs); low <- c(lo,rep(-Inf,n)); upp <- c(hi,rep(Inf,n))
  opt <- stats::optim(z0,obj,method="L-BFGS-B",lower=low,upper=upp,control=control,hessian=TRUE)
  b <- opt$par[seq_len(p)]; names(b)<-names(start); xt <- opt$par[p+seq_len(n)]; dd<-data; dd[[predictor]]<-xt; mu<-.nl_rhs_eval(formula,dd,b)
  V <- tryCatch(solve(opt$hessian),error=function(e)NULL)
  structure(list(coefficients=b,latent_predictor=xt,predictor=predictor,fitted=mu,
                 residuals=y-mu,sd_x=sx,sd_y=sy,optimization=opt,
                 vcov=if(is.null(V))NULL else V[seq_len(p),seq_len(p),drop=FALSE],
                 formula=formula,data=data,call=match.call()),class="nlr_eiv_fit")
}

.nl_eval_one_sided <- function(formula, data, par) {
  rhs <- if(length(formula)==2L) formula[[2L]] else formula[[3L]]
  env <- list2env(c(as.list(data),as.list(par)),parent=environment(formula)%||%parent.frame())
  eval(rhs,envir=env)
}

#' Joint nonlinear mean-variance regression
#'
#' Fits a Gaussian nonlinear model in which the conditional mean and log standard
#' deviation have separate parameterized formulas. The variance formula may use
#' `.mu`, the current fitted mean, enabling explicit mean-dependent dispersion.
#'
#' @param mean_formula Nonlinear response formula.
#' @param variance_formula One-sided formula for log SD, e.g. `~ g0 + g1*log(.mu)`.
#' @param data Data frame.
#' @param start_mean Named starting values for the nonlinear mean.
#' @param start_variance Named starting values for the log-SD model.
#' @param method Optimizer method.
#' @param control Optimizer control list.
#' @return An `nlr_mean_variance_fit` object.
#' @examples
#' \dontrun{
#' o <- nl_data("okra_growth_raw"); nl_mean_variance(fruit_length~Asym*exp(-exp(-k*(day_after_flowering-xmid))),~g0+g1*log(pmax(.mu,1e-4)),o,c(Asym=18,k=.4,xmid=4),c(g0=-1,g1=.3))
#' s <- subset(nl_data("soil_p_sorption"),soil_class=="Clayey"); nl_mean_variance(sorbed_P_mg_kg~qmax*K*solution_P_mg_L/(1+K*solution_P_mg_L),~g0+g1*log1p(.mu),s,c(qmax=600,K=.2),c(g0=1,g1=.1))
#' p <- nl_data("plant_physiology_light"); nl_mean_variance(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,~g0+g1*sqrt(abs(.mu)),p,c(Amax=30,alpha=.06,Rd=1),c(g0=-.2,g1=.03))
#' }
#' @export
nl_mean_variance <- function(mean_formula, variance_formula, data, start_mean,
                             start_variance, method="BFGS", control=list(maxit=5000)) {
  bm <- unlist(start_mean); bv <- unlist(start_variance)
  if(is.null(names(bm))||is.null(names(bv))) stop("Both starting-value vectors must be named.",call.=FALSE)
  y <- data[[.nl_response_name(mean_formula)]]; pm<-length(bm); pv<-length(bv)
  obj <- function(z) {
    m<-z[seq_len(pm)]; names(m)<-names(bm); v<-z[pm+seq_len(pv)]; names(v)<-names(bv)
    mu<-.nl_rhs_eval(mean_formula,data,m); dd<-data; dd$.mu<-mu; ls<-.nl_eval_one_sided(variance_formula,dd,v); sd<-exp(ls)
    if(any(!is.finite(mu))||any(!is.finite(sd))||any(sd<=0))return(.Machine$double.xmax/100)
    -sum(stats::dnorm(y,mu,sd,log=TRUE))
  }
  opt<-stats::optim(c(bm,bv),obj,method=method,control=control,hessian=TRUE)
  m<-opt$par[seq_len(pm)];names(m)<-names(bm);v<-opt$par[pm+seq_len(pv)];names(v)<-names(bv)
  mu<-.nl_rhs_eval(mean_formula,data,m);dd<-data;dd$.mu<-mu;sd<-exp(.nl_eval_one_sided(variance_formula,dd,v))
  V<-tryCatch(solve(opt$hessian),error=function(e)NULL)
  structure(list(mean_coefficients=m,variance_coefficients=v,fitted=mu,sigma=sd,residuals=y-mu,
                 standardized_residuals=(y-mu)/sd,vcov=V,optimization=opt,
                 mean_formula=mean_formula,variance_formula=variance_formula,data=data,call=match.call()),
            class="nlr_mean_variance_fit")
}

.nl_logdiffexp <- function(a,b) { # log(exp(a)-exp(b)), requires a >= b
  out <- a + log1p(-exp(pmin(b-a,0)))
  out[!is.finite(out)] <- log(.Machine$double.xmin)
  out
}

#' Censored nonlinear Gaussian regression
#'
#' Fits nonlinear regression without substituting arbitrary values for left-,
#' right- or interval-censored observations. Censoring contributions are entered
#' through the appropriate Gaussian CDF probabilities.
#'
#' @param formula Nonlinear mean formula.
#' @param data Data frame.
#' @param start Named nonlinear parameter starts.
#' @param status Character vector/column with `none`, `left`, `right`, or `interval`.
#' @param lower Numeric lower censoring bound or column name.
#' @param upper Numeric upper censoring bound or column name.
#' @param sigma_start Positive initial residual SD.
#' @param control Optimizer control list.
#' @return An `nlr_censored_fit` object.
#' @examples
#' \dontrun{
#' d <- subset(nl_data("soil_p_sorption"),soil_class=="Clayey"); d$status<-"none"; d$lo<-d$sorbed_P_mg_kg; d$up<-d$sorbed_P_mg_kg; nl_censored(sorbed_P_mg_kg~qmax*K*solution_P_mg_L/(1+K*solution_P_mg_L),d,c(qmax=600,K=.2),"status","lo","up",10)
#' f <- subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); f$status<-"none"; nl_censored(grain_yield_Mg_ha~Asym-delta*exp(-k*P2O5_kg_ha),f,c(Asym=8,delta=5,k=.02),f$status,-Inf,Inf,.3)
#' p <- subset(nl_data("plant_physiology_light"),water_regime=="WellWatered"); p$status<-"none"; nl_censored(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,p,c(Amax=30,alpha=.06,Rd=1),p$status,-Inf,Inf,1)
#' }
#' @export
nl_censored <- function(formula,data,start,status,lower=-Inf,upper=Inf,sigma_start=1,
                        control=list(maxit=5000)) {
  b0<-unlist(start);if(is.null(names(b0)))stop("start must be named.",call.=FALSE);n<-nrow(data);p<-length(b0);resp<-.nl_response_name(formula);y<-data[[resp]]
  st<-if(length(status)==1L&&is.character(status)&&status%in%names(data))as.character(data[[status]]) else as.character(status);if(length(st)==1L)st<-rep(st,n);if(length(st)!=n||any(!st%in%c("none","left","right","interval")))stop("status must contain none/left/right/interval.",call.=FALSE)
  bound<-function(z,default){if(length(z)==1L&&is.character(z)&&z%in%names(data))z<-data[[z]];if(length(z)==1L)z<-rep(as.numeric(z),n);if(length(z)!=n)stop("Censoring bounds must have length 1/n or name a column.",call.=FALSE);as.numeric(z)}
  lo<-bound(lower,-Inf);up<-bound(upper,Inf)
  obj<-function(z){b<-z[seq_len(p)];names(b)<-names(b0);sd<-exp(z[p+1L]);mu<-.nl_rhs_eval(formula,data,b);ll<-numeric(n);i<-st=="none";ll[i]<-stats::dnorm(y[i],mu[i],sd,log=TRUE);i<-st=="left";ll[i]<-stats::pnorm(up[i],mu[i],sd,log.p=TRUE);i<-st=="right";ll[i]<-stats::pnorm(lo[i],mu[i],sd,lower.tail=FALSE,log.p=TRUE);i<-st=="interval";if(any(i)){a<-stats::pnorm(up[i],mu[i],sd,log.p=TRUE);bb<-stats::pnorm(lo[i],mu[i],sd,log.p=TRUE);ll[i]<-.nl_logdiffexp(a,bb)};if(any(!is.finite(ll)))return(.Machine$double.xmax/100);-sum(ll)}
  opt<-stats::optim(c(b0,log(sigma_start)),obj,method="BFGS",control=control,hessian=TRUE);b<-opt$par[seq_len(p)];names(b)<-names(b0);sd<-exp(opt$par[p+1L]);mu<-.nl_rhs_eval(formula,data,b);V<-tryCatch(solve(opt$hessian),error=function(e)NULL)
  structure(list(coefficients=b,sigma=sd,fitted=mu,status=st,lower=lo,upper=up,optimization=opt,vcov=V,formula=formula,data=data,call=match.call()),class="nlr_censored_fit")
}

#' Truncated nonlinear Gaussian regression
#'
#' Conditions the Gaussian nonlinear likelihood on observations being inside
#' known truncation bounds. Unlike censoring, truncated observations outside the
#' admissible region are not present in the sample.
#'
#' @param formula Nonlinear mean formula.
#' @param data Data frame containing observed responses inside the truncation range.
#' @param start Named nonlinear parameter starts.
#' @param lower Lower truncation bound, scalar/vector/column name.
#' @param upper Upper truncation bound, scalar/vector/column name.
#' @param sigma_start Positive initial residual SD.
#' @param control Optimizer control list.
#' @return An `nlr_truncated_fit` object.
#' @examples
#' \dontrun{
#' o<-nl_data("okra_growth_means"); nl_truncated(fruit_length~Asym*exp(-exp(-k*(day_after_flowering-xmid))),o,c(Asym=18,k=.4,xmid=4),0,Inf,.5)
#' f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); nl_truncated(grain_yield_Mg_ha~Asym-delta*exp(-k*P2O5_kg_ha),f,c(Asym=8,delta=5,k=.02),0,Inf,.3)
#' p<-subset(nl_data("plant_physiology_light"),water_regime=="WellWatered"); nl_truncated(A_umol_CO2_m2_s~Amax*alpha*PAR_umol_m2_s/(Amax+alpha*PAR_umol_m2_s)-Rd,p,c(Amax=30,alpha=.06,Rd=1),-5,Inf,1)
#' }
#' @export
nl_truncated <- function(formula,data,start,lower=-Inf,upper=Inf,sigma_start=1,control=list(maxit=5000)) {
  b0<-unlist(start);if(is.null(names(b0)))stop("start must be named.",call.=FALSE);n<-nrow(data);p<-length(b0);y<-data[[.nl_response_name(formula)]]
  bound<-function(z){if(length(z)==1L&&is.character(z)&&z%in%names(data))z<-data[[z]];if(length(z)==1L)z<-rep(as.numeric(z),n);if(length(z)!=n)stop("Bounds must have length 1/n or name a column.",call.=FALSE);as.numeric(z)};lo<-bound(lower);up<-bound(upper);if(any(y<=lo|y>=up,na.rm=TRUE))warning("Some observations lie on/outside truncation bounds; verify the specification.",call.=FALSE)
  obj<-function(z){b<-z[seq_len(p)];names(b)<-names(b0);sd<-exp(z[p+1L]);mu<-.nl_rhs_eval(formula,data,b);lp<-stats::dnorm(y,mu,sd,log=TRUE);au<-stats::pnorm(up,mu,sd,log.p=TRUE);al<-stats::pnorm(lo,mu,sd,log.p=TRUE);norm<-.nl_logdiffexp(au,al);ll<-lp-norm;if(any(!is.finite(ll)))return(.Machine$double.xmax/100);-sum(ll)}
  opt<-stats::optim(c(b0,log(sigma_start)),obj,method="BFGS",control=control,hessian=TRUE);b<-opt$par[seq_len(p)];names(b)<-names(b0);sd<-exp(opt$par[p+1L]);mu<-.nl_rhs_eval(formula,data,b);V<-tryCatch(solve(opt$hessian),error=function(e)NULL)
  structure(list(coefficients=b,sigma=sd,fitted=mu,lower=lo,upper=up,optimization=opt,vcov=V,formula=formula,data=data,call=match.call()),class="nlr_truncated_fit")
}

#' Screen local structural identifiability of a nonlinear mean function
#'
#' Evaluates the noise-free sensitivity/Jacobian matrix of the nonlinear mean on
#' a supplied design and uses singular values to detect locally aliased parameter
#' directions. This is a *local structural screen*, not a proof of global
#' structural identifiability. ODE models requiring formal differential-algebraic
#' identifiability should be checked with specialized symbolic software.
#'
#' @param formula Nonlinear formula.
#' @param data Design data used to evaluate the mean function.
#' @param parameters Named parameter vector.
#' @param rel_step Relative finite-difference step.
#' @param tol Relative singular-value rank tolerance.
#' @return An `nlr_structural_identifiability` object.
#' @examples
#' o<-nl_data("okra_growth_means"); nl_structural_identify(fruit_length~Asym*exp(-exp(-k*(day_after_flowering-xmid))),o,c(Asym=18,k=.4,xmid=4))
#' s<-subset(nl_data("soil_p_sorption"),soil_class=="Clayey"); nl_structural_identify(sorbed_P_mg_kg~qmax*K*solution_P_mg_L/(1+K*solution_P_mg_L),s,c(qmax=600,K=.2))
#' f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); nl_structural_identify(grain_yield_Mg_ha~Asym-delta*exp(-k*P2O5_kg_ha),f,c(Asym=8,delta=5,k=.02))
#' @export
nl_structural_identify <- function(formula,data,parameters,rel_step=sqrt(.Machine$double.eps),tol=1e-8) {
  b<-unlist(parameters);if(is.null(names(b)))stop("parameters must be named.",call.=FALSE);p<-length(b);base<-.nl_rhs_eval(formula,data,b);J<-matrix(NA_real_,length(base),p,dimnames=list(NULL,names(b)))
  for(j in seq_len(p)){h<-rel_step*max(abs(b[j]),1);bp<-bm<-b;bp[j]<-bp[j]+h;bm[j]<-bm[j]-h;J[,j]<-(.nl_rhs_eval(formula,data,bp)-.nl_rhs_eval(formula,data,bm))/(2*h)}
  sv<-svd(J);thr<-max(sv$d,na.rm=TRUE)*tol;rank<-sum(sv$d>thr);cond<-if(length(sv$d)&&min(sv$d)>0)max(sv$d)/min(sv$d) else Inf;null<-if(rank<p)sv$v[,(rank+1L):p,drop=FALSE] else matrix(numeric(0),p,0,dimnames=list(names(b),NULL));rownames(null)<-names(b)
  status<-if(rank==p)"locally identifiable on supplied design" else "potential local parameter aliasing"
  structure(list(status=status,rank=rank,n_parameters=p,singular_values=sv$d,condition_number=cond,jacobian=J,null_directions=null,tolerance=tol,scope="local structural screen; not global proof"),class="nlr_structural_identifiability")
}

#' Global sensitivity analysis for nonlinear model outputs
#'
#' Calculates local finite-difference sensitivities, Morris elementary effects,
#' or Monte Carlo Sobol first-order and total-effect indices for an arbitrary
#' scalar model summary.
#'
#' @param model_fun Function mapping a named parameter vector to a numeric model output.
#' @param ranges Named two-column matrix/data frame of lower and upper bounds.
#' @param method `local`, `morris`, or `sobol`.
#' @param summary_fun Function reducing model output to one scalar.
#' @param n Monte Carlo sample size/number of Morris trajectories.
#' @param delta Relative step for local/Morris calculations.
#' @param seed Random seed.
#' @return An `nlr_sensitivity` object with method-specific indices.
#' @examples
#' nl_sensitivity(function(p)p["A"]*(1-exp(-p["k"]*(1:10))),matrix(c(10,30,.05,.5),2,2,byrow=TRUE,dimnames=list(c("A","k"),c("lower","upper"))),"local")
#' nl_sensitivity(function(p)p["qmax"]*p["K"]*(1:20)/(1+p["K"]*(1:20)),matrix(c(300,800,.02,.5),2,2,byrow=TRUE,dimnames=list(c("qmax","K"),c("lower","upper"))),"morris",n=30)
#' nl_sensitivity(function(p)p["Amax"]*p["alpha"]*(1:50)/(p["Amax"]+p["alpha"]*(1:50)),matrix(c(10,50,.01,.2),2,2,byrow=TRUE,dimnames=list(c("Amax","alpha"),c("lower","upper"))),"sobol",n=300)
#' @export
nl_sensitivity <- function(model_fun,ranges,method=c("local","morris","sobol"),summary_fun=mean,n=500,delta=.05,seed=20260817) {
  method<-match.arg(method);R<-as.matrix(ranges);if(ncol(R)!=2L)stop("ranges must have exactly two columns: lower and upper.",call.=FALSE);if(is.null(rownames(R)))stop("ranges must have parameter names as row names.",call.=FALSE);if(any(R[,1]>=R[,2]))stop("Each lower bound must be smaller than its upper bound.",call.=FALSE);p<-nrow(R);names0<-rownames(R);eval1<-function(v)as.numeric(summary_fun(model_fun(stats::setNames(v,names0))))[1]
  set.seed(seed)
  if(method=="local"){x<-rowMeans(R);base<-eval1(x);out<-data.frame(parameter=names0,sensitivity=NA_real_,elasticity=NA_real_);for(j in seq_len(p)){h<-delta*(R[j,2]-R[j,1]);xp<-xm<-x;xp[j]<-min(R[j,2],x[j]+h);xm[j]<-max(R[j,1],x[j]-h);s<-(eval1(xp)-eval1(xm))/(xp[j]-xm[j]);out$sensitivity[j]<-s;out$elasticity[j]<-if(is.finite(base)&&abs(base)>.Machine$double.eps)s*x[j]/base else NA_real_};res<-out}
  if(method=="morris"){EE<-matrix(NA_real_,n,p,dimnames=list(NULL,names0));for(i in seq_len(n)){x<-runif(p,R[,1],R[,2]);for(j in seq_len(p)){h<-delta*(R[j,2]-R[j,1]);xp<-x;xp[j]<-min(R[j,2],x[j]+h);if(xp[j]==x[j])xp[j]<-max(R[j,1],x[j]-h);EE[i,j]<-(eval1(xp)-eval1(x))/(xp[j]-x[j])}};res<-data.frame(parameter=names0,mu=colMeans(EE,na.rm=TRUE),mu_star=colMeans(abs(EE),na.rm=TRUE),sigma=apply(EE,2,stats::sd,na.rm=TRUE));attr(res,"elementary_effects")<-EE}
  if(method=="sobol"){A<-matrix(runif(n*p),n,p);B<-matrix(runif(n*p),n,p);A<-sweep(A,2,R[,2]-R[,1],"*");A<-sweep(A,2,R[,1],"+");B<-sweep(B,2,R[,2]-R[,1],"*");B<-sweep(B,2,R[,1],"+");YA<-apply(A,1,eval1);YB<-apply(B,1,eval1);V<-stats::var(c(YA,YB));S<-ST<-numeric(p);for(j in seq_len(p)){AB<-A;AB[,j]<-B[,j];YAB<-apply(AB,1,eval1);S[j]<-mean(YB*(YAB-YA))/V;ST[j]<-.5*mean((YA-YAB)^2)/V};res<-data.frame(parameter=names0,S1=S,ST=ST)}
  structure(list(indices=res,method=method,ranges=R,n=n,delta=delta,seed=seed),class="nlr_sensitivity")
}
