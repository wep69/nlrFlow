# Phase D: automatic differentiation, approximate Bayes and uncertainty --------

#' Fit an RTMB automatic-differentiation objective
#'
#' Builds an `RTMB::MakeADFun` objective from an R negative log-likelihood and,
#' optionally, optimizes it with `stats::nlminb`. This is the low-level high-
#' performance route for nonlinear likelihoods, latent variables, and random
#' effects that are not covered by a dedicated nlrFlow backend.
#'
#' @param objective Function receiving the parameter list/vector and returning a
#'   scalar negative log-likelihood. It must use RTMB-compatible operations.
#' @param parameters Named list or vector of starting parameter values.
#' @param random Optional parameter names integrated by Laplace approximation.
#' @param optimize Logical; optimize the objective after constructing the AD tape.
#' @param control Control list passed to `stats::nlminb`.
#' @param silent Logical passed to `RTMB::MakeADFun`.
#' @param ... Additional arguments passed to `RTMB::MakeADFun`.
#' @return An `nlr_rtmb_fit` object containing the AD function, optimizer output,
#'   and `sdreport` when available.
#' @examples
#' \dontrun{
#' # Agronomy: Gaussian nonlinear growth likelihood.
#' d <- subset(nl_data("agronomy_growth"), cultivar == "C1")
#' obj <- function(p) { mu <- p$A/(1+exp(-p$k*(d$day-p$tm))); -sum(dnorm(d$biomass_Mg_ha,mu,exp(p$ls),log=TRUE)) }
#' nl_rtmb(obj, list(A=18,k=.08,tm=50,ls=log(1)))
#' # Soil fertility: nonlinear Mitscherlich likelihood.
#' f <- subset(nl_data("soil_fertility_p"), soil_class == "Loamy")
#' obj2 <- function(p) { mu <- p$A-p$d*exp(-p$k*f$P2O5_kg_ha); -sum(dnorm(f$grain_yield_Mg_ha,mu,exp(p$ls),log=TRUE)) }
#' nl_rtmb(obj2, list(A=8,d=5,k=.02,ls=0))
#' # Plant physiology: arbitrary constrained parameterization in the objective.
#' p <- subset(nl_data("plant_physiology_light"), water_regime == "WellWatered")
#' obj3 <- function(z) { a<-exp(z$la); A<-exp(z$lA); mu<-A*a*p$PAR_umol_m2_s/(A+a*p$PAR_umol_m2_s)-exp(z$lRd); -sum(dnorm(p$A_umol_CO2_m2_s,mu,exp(z$ls),log=TRUE)) }
#' nl_rtmb(obj3, list(la=log(.05),lA=log(30),lRd=log(1),ls=0))
#' }
#' @export
nl_rtmb <- function(objective, parameters, random = NULL, optimize = TRUE,
                    control = list(), silent = TRUE, ...) {
  .nl_require("RTMB", "automatic-differentiation nonlinear models")
  if (!is.function(objective)) stop("objective must be a function.", call. = FALSE)
  obj <- RTMB::MakeADFun(objective, parameters, random = random, silent = silent, ...)
  opt <- NULL
  sdr <- NULL
  if (isTRUE(optimize)) {
    opt <- stats::nlminb(start = obj$par, objective = obj$fn, gradient = obj$gr,
                        control = control)
    sdr <- tryCatch(RTMB::sdreport(obj), error = function(e) e)
  }
  structure(list(adfun = obj, optimization = opt, sdreport = sdr,
                 parameters = parameters, random = random,
                 optimized = isTRUE(optimize), call = match.call()),
            class = "nlr_rtmb_fit")
}

#' Evaluate an RTMB objective and its automatic gradient
#'
#' Provides an auditable derivative interface for nonlinear objectives. The
#' first derivative is obtained from RTMB automatic differentiation. A Hessian
#' can optionally be formed by `optimHess` from the AD gradient, which is useful
#' for local curvature checks but should not be confused with a symbolic Hessian.
#'
#' @param objective RTMB-compatible scalar objective function.
#' @param parameters Parameter list/vector used to construct the AD function.
#' @param at Optional numeric vector at which derivatives are evaluated.
#' @param hessian Logical; also calculate a local Hessian from the AD gradient.
#' @param ... Additional arguments to `RTMB::MakeADFun`.
#' @return A list with value, gradient, optional Hessian, and AD object.
#' @examples
#' \dontrun{
#' nl_ad(function(p) (p$a-2)^2 + (p$b+1)^2, list(a=0,b=0))
#' nl_ad(function(p) (log(p$A)-log(20))^2 + (p$k-.1)^2, list(A=10,k=.05))
#' nl_ad(function(p) sum((c(1,2,3)-p$a*c(1,2,3)^p$b)^2), list(a=1,b=1))
#' }
#' @export
nl_ad <- function(objective, parameters, at = NULL, hessian = TRUE, ...) {
  .nl_require("RTMB", "automatic differentiation")
  obj <- RTMB::MakeADFun(objective, parameters, silent = TRUE, ...)
  x <- if (is.null(at)) obj$par else as.numeric(at)
  if (length(x) != length(obj$par)) stop("at must have the same length as the AD parameter vector.", call. = FALSE)
  names(x) <- names(obj$par)
  val <- obj$fn(x)
  grad <- obj$gr(x)
  H <- if (isTRUE(hessian)) tryCatch(stats::optimHess(x, obj$fn, obj$gr), error = function(e) NULL) else NULL
  structure(list(value = val, gradient = grad, hessian = H, at = x, adfun = obj),
            class = "nlr_ad_result")
}

#' Run inference for a BayesRTMB model
#'
#' Routes a pre-built `BayesRTMB` model to MAP/Laplace optimization, NUTS,
#' automatic-differentiation variational inference, or the package's classical
#' route. Model construction remains explicit so priors, constraints and latent
#' variables are visible and reproducible.
#'
#' @param model A `BayesRTMB` model object, usually returned by `rtmb_model()`.
#' @param method One of `optimize`, `sample`, `variational`, or `classic`.
#' @param ... Arguments passed to the selected model method.
#' @return An `nlr_bayesrtmb_fit` object.
#' @examples
#' \dontrun{
#' # Agronomy: mdl <- BayesRTMB::rtmb_model(code, data=list(...)); nl_bayes_rtmb(mdl,"optimize")
#' # Soil: the same RTMB model definition can be checked rapidly with MAP/Laplace.
#' # nl_bayes_rtmb(soil_mdl,"optimize",laplace=TRUE)
#' # Physiology: use ADVI as a fast sensitivity analysis before NUTS.
#' # nl_bayes_rtmb(phys_mdl,"variational")
#' }
#' @export
nl_bayes_rtmb <- function(model, method = c("optimize", "sample", "variational", "classic"), ...) {
  .nl_require("BayesRTMB", "BayesRTMB nonlinear inference")
  method <- match.arg(method)
  fun <- tryCatch(model[[method]], error = function(e) NULL)
  if (!is.function(fun)) stop("model does not expose the requested BayesRTMB inference method.", call. = FALSE)
  fit <- fun(...)
  structure(list(fit = fit, model = model, method = method, call = match.call()),
            class = "nlr_bayesrtmb_fit")
}

#' Fast approximate Bayesian inference
#'
#' Provides a common front end for Laplace/MAP or ADVI through `BayesRTMB`.
#' Approximate posterior methods are intended for screening, initialization and
#' large models; final uncertainty should be compared with simulation-based
#' inference when scientifically consequential.
#'
#' @param model A `BayesRTMB` model object.
#' @param method `laplace` or `advi`.
#' @param ... Arguments passed to `model$optimize()` or `model$variational()`.
#' @return An `nlr_bayes_approx` object.
#' @examples
#' \dontrun{
#' # nl_bayes_approx(agronomy_rtmb_model,"laplace")
#' # nl_bayes_approx(soil_rtmb_model,"advi")
#' # nl_bayes_approx(physiology_rtmb_model,"advi")
#' }
#' @export
nl_bayes_approx <- function(model, method = c("laplace", "advi"), ...) {
  method <- match.arg(method)
  if (method == "laplace") {
    z <- nl_bayes_rtmb(model, method = "optimize", laplace = TRUE, ...)
  } else {
    z <- nl_bayes_rtmb(model, method = "variational", ...)
  }
  structure(list(fit = z$fit, model = model, method = method, call = match.call()),
            class = "nlr_bayes_approx")
}

#' Deterministic uncertainty propagation by cubature-like sigma points
#'
#' Propagates approximately Gaussian parameter uncertainty through an arbitrary
#' nonlinear derived quantity using a spherical-radial cubature rule with
#' `2p` sigma points. It is a deterministic alternative to Monte Carlo for fast
#' uncertainty propagation and is especially useful for AGR, RGR, AUC and
#' response-at-dose calculations.
#'
#' @param estimate Named parameter estimate vector.
#' @param vcov Parameter covariance matrix.
#' @param fun Function mapping a named parameter vector to a numeric result.
#' @param level Confidence level for normal-approximation intervals.
#' @param jitter Small diagonal regularization used if the covariance is nearly singular.
#' @return An `nlr_propagation` object with transformed center, mean, covariance,
#'   standard errors and approximate intervals.
#' @examples
#' ok <- nl_data("okra_growth_means"); fit <- nl_fit(data=ok,model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls")
#' nl_propagate(coef(fit),vcov(fit$fit),function(b) b["Asym"]*b["k"]/exp(1))
#' f <- subset(nl_data("soil_fertility_p"),soil_class=="Loamy"); sf <- nl_fit(data=f,model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls")
#' nl_propagate(coef(sf),vcov(sf$fit),function(b) -log(.5)/b["k"])
#' s <- subset(nl_data("soil_infiltration"),management=="NoTill"); si <- nl_fit(data=s,model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls")
#' nl_propagate(coef(si),vcov(si$fit),function(b) b["Vmax"]*.5)
#' @export
nl_propagate <- function(estimate, vcov, fun, level = 0.95, jitter = 1e-10) {
  mu <- as.numeric(estimate); names(mu) <- names(estimate)
  V <- as.matrix(vcov)
  if (length(mu) != nrow(V) || nrow(V) != ncol(V)) stop("estimate and vcov dimensions are incompatible.", call. = FALSE)
  V <- (V + t(V))/2
  ev <- eigen(V, symmetric = TRUE)
  if (min(ev$values) < 0) V <- V + diag(abs(min(ev$values)) + jitter, nrow(V))
  L <- tryCatch(chol(V), error = function(e) chol(V + diag(jitter, nrow(V))))
  p <- length(mu)
  pts <- matrix(rep(mu, each = 2*p), nrow = 2*p, byrow = FALSE)
  for (j in seq_len(p)) {
    step <- sqrt(p) * L[j, ]
    pts[2*j-1, ] <- mu + step
    pts[2*j, ] <- mu - step
  }
  colnames(pts) <- names(mu)
  vals <- lapply(seq_len(nrow(pts)), function(i) as.numeric(fun(stats::setNames(pts[i, ], names(mu)))))
  lens <- vapply(vals, length, integer(1))
  if (length(unique(lens)) != 1L) stop("fun must return a fixed-length numeric result.", call. = FALSE)
  Y <- do.call(rbind, vals)
  y0 <- as.numeric(fun(stats::setNames(mu, names(mu))))
  mn <- colMeans(Y)
  CY <- if (nrow(Y) > 1L) stats::cov(Y) else matrix(0, ncol(Y), ncol(Y))
  se <- sqrt(pmax(diag(CY), 0))
  z <- stats::qnorm(1 - (1-level)/2)
  interval <- cbind(lower = mn - z*se, upper = mn + z*se)
  structure(list(center = y0, mean = mn, covariance = CY, se = se,
                 interval = interval, level = level, sigma_points = pts,
                 transformed_points = Y, method = "spherical-radial cubature"),
            class = "nlr_propagation")
}

#' Approximate Bayesian computation for nonlinear simulators
#'
#' Implements a transparent rejection-ABC workflow for simulator-based models
#' whose likelihood is unavailable or intentionally avoided. Priors are sampled,
#' simulations are summarized, distances are calculated on standardized summary
#' statistics, and the best fraction is retained.
#'
#' @param observed Observed data object passed to `summary_fun`.
#' @param simulator Function of one named parameter vector returning simulated data.
#' @param prior_sampler Function taking integer `n` and returning an `n x p` matrix/data frame.
#' @param summary_fun Function returning a numeric summary vector.
#' @param n_sim Number of prior predictive simulations.
#' @param tolerance Fraction of simulations retained, in (0,1).
#' @param seed Random seed.
#' @param scale Optional positive scale vector for summary statistics. If `NULL`,
#'   robust scales are estimated from simulated summaries.
#' @return An `nlr_abc` object with accepted parameters, summaries and distances.
#' @examples
#' \dontrun{
#' obs <- nl_data("okra_growth_means")$fruit_length
#' prior <- function(n) cbind(Asym=runif(n,15,25),k=runif(n,.1,1),xmid=runif(n,1,8))
#' sim <- function(p) p["Asym"]*exp(-exp(-p["k"]*((1:10)-p["xmid"]))) + rnorm(10,0,.5)
#' nl_abc(obs,sim,prior,function(z)c(mean=mean(z),sd=sd(z),max=max(z)),n_sim=2000)
#' nl_abc(c(1,2,4,7),function(p)p[1]*(1-exp(-p[2]*(1:4))),function(n)cbind(A=runif(n,5,10),k=runif(n,.1,1)),function(z)c(z),n_sim=1000)
#' nl_abc(c(.4,.3,.2),function(p)exp(-p[1]*(1:3))+rnorm(3,0,p[2]),function(n)cbind(k=runif(n,.01,2),sd=runif(n,.01,.3)),function(z)c(mean(z),diff(range(z))),n_sim=1000)
#' }
#' @export
nl_abc <- function(observed, simulator, prior_sampler, summary_fun,
                   n_sim = 10000, tolerance = 0.01, seed = 20260817,
                   scale = NULL) {
  if (!is.function(simulator) || !is.function(prior_sampler) || !is.function(summary_fun)) stop("simulator, prior_sampler and summary_fun must be functions.", call. = FALSE)
  if (n_sim < 100L) stop("n_sim should be at least 100 for a meaningful ABC screen.", call. = FALSE)
  if (!is.finite(tolerance) || tolerance <= 0 || tolerance >= 1) stop("tolerance must lie in (0,1).", call. = FALSE)
  set.seed(seed)
  pars <- as.matrix(prior_sampler(n_sim))
  if (nrow(pars) != n_sim) stop("prior_sampler(n_sim) must return n_sim rows.", call. = FALSE)
  if (is.null(colnames(pars))) colnames(pars) <- paste0("par", seq_len(ncol(pars)))
  obs_s <- as.numeric(summary_fun(observed))
  sims <- vector("list", n_sim)
  S <- matrix(NA_real_, n_sim, length(obs_s))
  for (i in seq_len(n_sim)) {
    p <- stats::setNames(as.numeric(pars[i, ]), colnames(pars))
    sims[[i]] <- simulator(p)
    ss <- as.numeric(summary_fun(sims[[i]]))
    if (length(ss) != length(obs_s)) stop("summary_fun must return the same number of statistics for observed and simulated data.", call. = FALSE)
    S[i, ] <- ss
  }
  if (is.null(scale)) {
    scale <- apply(S, 2, stats::mad, na.rm = TRUE)
    bad <- !is.finite(scale) | scale <= .Machine$double.eps
    if (any(bad)) scale[bad] <- apply(S[, bad, drop=FALSE], 2, stats::sd, na.rm=TRUE)
    scale[!is.finite(scale) | scale <= .Machine$double.eps] <- 1
  }
  if (length(scale) != length(obs_s) || any(scale <= 0)) stop("scale must be positive and match the summary dimension.", call. = FALSE)
  Z <- sweep(S, 2, obs_s, "-")
  Z <- sweep(Z, 2, scale, "/")
  dist <- sqrt(rowSums(Z^2))
  n_keep <- max(1L, ceiling(tolerance*n_sim))
  keep <- order(dist)[seq_len(n_keep)]
  structure(list(accepted = pars[keep,,drop=FALSE], distances = dist[keep],
                 all_distances = dist, observed_summary = obs_s,
                 simulated_summaries = S, scale = scale, tolerance = tolerance,
                 n_sim = n_sim, seed = seed, acceptance_rate = n_keep/n_sim),
            class = "nlr_abc")
}
