#' Linear contrasts of nonlinear parameters
#'
#' Computes user-specified linear contrasts. Frequentist fits use the estimated variance-covariance matrix; `brms` fits use posterior draws and posterior probabilities.
#' @param object An `nlrfit`.
#' @param L Numeric contrast vector or matrix with columns matching coefficient names.
#' @param level Confidence level.
#' @return A data frame of frequentist contrast estimates/SEs/Wald intervals and p-values, or posterior contrast summaries for `brms` fits.
#' @examples
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_contrast(f,c(Asym=1,k=0,xmid=0))
#' f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_contrast(f,c(Asym=1,delta=-1,k=0))
#' f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_contrast(f,c(Vmax=1,Km=0))
#' @export
nl_contrast <- function(object,L,level=.95) {
  vector_names <- if(is.null(dim(L))) names(L) else NULL
  if(is.null(dim(L))) {
    L <- matrix(L,nrow=1)
    if(length(vector_names)) colnames(L) <- vector_names
  }
  if(inherits(object,"nlrfit") && identical(object$engine,"brms")) {
    .nl_require("brms","Bayesian nonlinear contrasts")
    D <- as.matrix(object$fit)
    if(is.null(colnames(L))) stop("For brms fits, L must have column names matching posterior draw columns (for example b_Asym_Intercept).",call.=FALSE)
    miss <- setdiff(colnames(L),colnames(D)); if(length(miss)) stop("Contrast columns absent from posterior draws: ",paste(miss,collapse=", "),call.=FALSE)
    C <- D[,colnames(L),drop=FALSE] %*% t(L)
    alpha <- 1-level
    return(data.frame(contrast=seq_len(nrow(L)),estimate=apply(C,2,stats::median),lower=apply(C,2,stats::quantile,probs=alpha/2),upper=apply(C,2,stats::quantile,probs=1-alpha/2),posterior_probability_gt0=colMeans(C>0),method="posterior"))
  }
  cf <- .nl_coef(object); V <- .nl_extract_vcov(object)
  if(is.null(V)) stop("vcov unavailable",call.=FALSE)
  if(!is.null(colnames(L))) {
    miss <- setdiff(colnames(L),names(cf)); if(length(miss)) stop("Contrast columns absent from coefficients: ",paste(miss,collapse=", "),call.=FALSE)
    full <- matrix(0,nrow=nrow(L),ncol=length(cf),dimnames=list(NULL,names(cf)))
    full[,colnames(L)] <- L; L <- full
  } else {
    if(ncol(L)!=length(cf)) stop("L columns must match coefficients, or provide coefficient names.",call.=FALSE)
    colnames(L) <- names(cf)
  }
  est <- drop(L %*% cf); se <- sqrt(diag(L %*% V %*% t(L))); z <- stats::qnorm(1-(1-level)/2)
  data.frame(contrast=seq_along(est),estimate=est,se=se,lower=est-z*se,upper=est+z*se,z=est/se,p_value=2*stats::pnorm(-abs(est/se)))
}

#' Compare nested curve specifications
#'
#' Compares a reduced and full curve model and can perform an LRT only when nesting is explicitly confirmed.
#' @param reduced Reduced `nlrfit`.
#' @param full Full `nlrfit`.
#' @param nested Logical confirmation of mathematical nesting.
#' @return A list with fit-comparison table and optional LRT.
#' @examples
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_curve_test(f,f,nested=FALSE)
#' f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_curve_test(f,f,nested=FALSE)
#' f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_curve_test(f,f,nested=FALSE)
#' @export
nl_curve_test <- function(reduced,full,nested=FALSE) {
  bayes <- all(vapply(list(reduced,full),function(z) inherits(z,"nlrfit") && identical(z$engine,"brms"),logical(1)))
  if(bayes) return(list(comparison=nl_bayes_compare(list(reduced=reduced,full=full)),lrt=NULL,note="Bayesian curve comparison uses PSIS-LOO; no likelihood-ratio test is performed."))
  list(comparison=nl_compare(list(reduced=reduced,full=full)),lrt=if(isTRUE(nested))nl_lrt(reduced,full,TRUE) else NULL,note=if(!nested)"No LRT performed because nesting was not explicitly confirmed." else NULL)
}
#' Derive biological quantities from a fitted curve
#'
#' Computes numerically stable first and second derivatives, absolute and relative growth rates, inflection location, maximum absolute growth rate, t50, and area under the fitted curve. Bootstrap uncertainty can be propagated for frequentist fits; `brms` fits propagate posterior expected-response draws.
#' @param object An `nlrfit`.
#' @param predictor Predictor name; inferred when possible.
#' @param grid Optional numeric grid.
#' @param quantities Requested quantities.
#' @param boot Optional `nlrboot` for uncertainty propagation.
#' @param level Confidence/credible level used for propagated uncertainty.
#' @param nsim Number of posterior expected-response draws for a `brms` fit.
#' @param ... Additional arguments passed to `brms::posterior_epred()` for Bayesian fits, such as `re_formula`.
#' @return An `nlrderived` object with curve-level and summary quantities.
#' @examples
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="richards",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_derive(f)
#' f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_derive(f)
#' f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_derive(f)
#' @export
nl_derive <- function(object,predictor=NULL,grid=NULL,quantities=c("AGR","RGR","inflection","AGRmax","t50","AUC"),boot=NULL,level=.95,nsim=1000,...) {
  allowed <- c("AGR","RGR","inflection","AGRmax","t50","AUC")
  bad <- setdiff(quantities,allowed); if(length(bad)) stop("Unknown derived quantities: ",paste(bad,collapse=", "),call.=FALSE)
  is_bayes <- inherits(object,"nlrfit") && identical(object$engine,"brms")
  if(is_bayes && !is.null(boot)) stop("Bayesian derived uncertainty uses posterior draws; do not supply boot=.",call.=FALSE)
  if(is.null(predictor)) {
    if(is_bayes) stop("Specify predictor= explicitly for a brms-backed nonlinear model.",call.=FALSE)
    vars <- .nl_predictor_names(object$formula)
    vars <- vars[vars %in% names(object$data)]
    num <- vars[vapply(object$data[vars],is.numeric,logical(1))]
    predictor <- if(length(num)) num[1] else NULL
  }
  if(is.na(predictor) || is.null(predictor) || !predictor %in% names(object$data)) stop("Specify a valid numeric predictor.",call.=FALSE)
  x0 <- object$data[[predictor]]; if(!is.numeric(x0)) stop("predictor must be numeric.",call.=FALSE)
  if(is.null(grid)) grid <- seq(min(x0,na.rm=TRUE),max(x0,na.rm=TRUE),length.out=300)
  grid <- sort(unique(as.numeric(grid))); if(length(grid)<5L || any(!is.finite(grid))) stop("grid must contain at least five finite unique values.",call.=FALSE)
  nd <- object$data[rep(1,length(grid)),,drop=FALSE]; nd[[predictor]] <- grid

  grad <- function(y,x) {
    n <- length(y); g <- numeric(n)
    g[1] <- (y[2]-y[1])/(x[2]-x[1]); g[n] <- (y[n]-y[n-1])/(x[n]-x[n-1])
    if(n>2) g[2:(n-1)] <- (y[3:n]-y[1:(n-2)])/(x[3:n]-x[1:(n-2)])
    g
  }
  calc_one <- function(y) {
    d1 <- grad(y,grid); d2 <- grad(d1,grid); rgr <- d1/pmax(abs(y),1e-12)
    interior <- if(length(grid)>2) 2:(length(grid)-1) else seq_along(grid)
    iin <- interior[which.min(abs(d2[interior]))]; imax <- which.max(d1)
    target <- min(y)+(max(y)-min(y))/2; it50 <- which.min(abs(y-target))
    auc <- sum(diff(grid)*(head(y,-1)+tail(y,-1))/2)
    list(curve=data.frame(x=grid,fitted=y,AGR=d1,RGR=rgr,second_derivative=d2),
         summary=c(inflection=grid[iin],AGRmax=d1[imax],t_AGRmax=grid[imax],t50=grid[it50],AUC=auc))
  }
  select_summary <- function(tab) {
    keep <- character()
    if("inflection" %in% quantities) keep <- c(keep,"inflection")
    if("AGRmax" %in% quantities) keep <- c(keep,"AGRmax","t_AGRmax")
    if("t50" %in% quantities) keep <- c(keep,"t50")
    if("AUC" %in% quantities) keep <- c(keep,"AUC")
    tab[tab$quantity %in% keep,,drop=FALSE]
  }

  alpha <- 1-level
  if(is_bayes) {
    .nl_require("brms","Bayesian derived quantities")
    set.seed(20260817)
    draws <- brms::posterior_epred(object$fit,newdata=nd,ndraws=nsim,...)
    if(length(dim(draws))!=2L) stop("Only univariate posterior expected-response draws are supported by nl_derive().",call.=FALSE)
    central_y <- apply(draws,2,stats::median,na.rm=TRUE); z <- calc_one(central_y)
    M <- t(vapply(seq_len(nrow(draws)),function(i) calc_one(draws[i,])$summary,numeric(5)))
    colnames(M) <- names(z$summary)
    summary <- data.frame(quantity=colnames(M),estimate=apply(M,2,stats::median,na.rm=TRUE),lower=apply(M,2,stats::quantile,probs=alpha/2,na.rm=TRUE),upper=apply(M,2,stats::quantile,probs=1-alpha/2,na.rm=TRUE),method="posterior",row.names=NULL)
    z$curve$.lower <- apply(draws,2,stats::quantile,probs=alpha/2,na.rm=TRUE)
    z$curve$.upper <- apply(draws,2,stats::quantile,probs=1-alpha/2,na.rm=TRUE)
    summary <- select_summary(summary)
    return(structure(list(curve=z$curve,summary=summary,predictor=predictor,quantities=quantities,boot=NULL,posterior_draws=nrow(draws)),class="nlrderived"))
  }

  y <- as.numeric(predict(object,newdata=nd)); z <- calc_one(y)
  summary <- data.frame(quantity=names(z$summary),estimate=unname(z$summary),row.names=NULL)
  if(!is.null(boot)) {
    B <- boot$coefficients[boot$converged,,drop=FALSE]
    if(nrow(B)>1) {
      M <- t(vapply(seq_len(nrow(B)),function(i){yy<-.nl_rhs_eval(object$formula,nd,B[i,]);calc_one(yy)$summary},numeric(5)))
      colnames(M) <- names(z$summary)
      summary$lower <- apply(M,2,stats::quantile,probs=alpha/2,na.rm=TRUE)
      summary$upper <- apply(M,2,stats::quantile,probs=1-alpha/2,na.rm=TRUE)
      summary$method <- paste0("bootstrap-",boot$type)
    }
  }
  summary <- select_summary(summary)
  curve <- z$curve
  if(!"AGR" %in% quantities) curve$AGR <- NULL
  if(!"RGR" %in% quantities) curve$RGR <- NULL
  structure(list(curve=curve,summary=summary,predictor=predictor,quantities=quantities,boot=boot),class="nlrderived")
}
