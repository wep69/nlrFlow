# Internal utilities --------------------------------------------------------
.nl_stop_missing <- function(pkg, feature = pkg) {
  stop(sprintf("%s requires optional package '%s'. Install it before using this backend.", feature, pkg), call. = FALSE)
}
.nl_require <- function(pkg, feature = pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) .nl_stop_missing(pkg, feature)
  invisible(TRUE)
}
.nl_response_name <- function(formula) all.vars(formula[[2L]])[1L]
.nl_predictor_names <- function(formula) setdiff(all.vars(formula), .nl_response_name(formula))
.nl_n <- function(object) {
  if (inherits(object, "nlrfit")) return(nrow(object$data))
  nobs(object)
}
.nl_aicc <- function(object) {
  fit <- .nl_unwrap(object)
  a <- tryCatch(stats::AIC(fit), error = function(e) NA_real_)
  k <- tryCatch(as.integer(attr(stats::logLik(fit),"df")), error = function(e) NA_integer_)
  if(is.na(k) || !length(k)) k <- tryCatch(length(stats::coef(fit)) + 1L, error = function(e) NA_integer_)
  n <- tryCatch(.nl_n(object), error = function(e) NA_integer_)
  if (!is.finite(a) || is.na(k) || is.na(n) || n <= k + 1L) return(NA_real_)
  a + (2 * k * (k + 1))/(n - k - 1)
}
.nl_rmse <- function(obs, pred) sqrt(mean((obs - pred)^2, na.rm = TRUE))
.nl_mae <- function(obs, pred) mean(abs(obs - pred), na.rm = TRUE)
.nl_rhs_eval <- function(formula, data, par) {
  rhs <- formula[[3L]]
  env <- list2env(c(as.list(data), as.list(par)), parent = environment(formula) %||% parent.frame())
  eval(rhs, envir = env)
}
`%||%` <- function(x, y) if (is.null(x)) y else x
.nl_mvrnorm <- function(n, mu, Sigma) {
  p <- length(mu)
  if (p == 1L) return(matrix(stats::rnorm(n, mu, sqrt(Sigma)), ncol = 1L, dimnames = list(NULL, names(mu))))
  ev <- eigen((Sigma + t(Sigma))/2, symmetric = TRUE)
  val <- pmax(ev$values, 0)
  A <- ev$vectors %*% diag(sqrt(val), p)
  z <- matrix(stats::rnorm(n * p), n, p)
  out <- sweep(z %*% t(A), 2, mu, `+`)
  colnames(out) <- names(mu)
  out
}
.nl_unwrap <- function(x) if (inherits(x, "nlrfit")) x$fit else x
.nl_wrap <- function(fit, engine, formula, data, start = NULL, model = NULL, call = NULL, metadata = list()) {
  structure(list(fit = fit, engine = engine, formula = formula, data = data, start = start,
                 model = model, call = call, metadata = metadata), class = "nlrfit")
}
.nl_refit <- function(object, data) {
  stopifnot(inherits(object, "nlrfit"))
  eng <- object$engine
  if (eng %in% c("nls", "nlsLM", "multistart")) {
    return(nl_fit(object$formula, data = data, start = as.list(stats::coef(object$fit)), engine = if(eng=="multistart") "nlsLM" else eng,
                  model = object$model, lower = object$metadata$lower %||% -Inf,
                  upper = object$metadata$upper %||% Inf))
  }
  if (eng == "robust") return(nl_robust(object$formula, data, start = as.list(stats::coef(object$fit))))
  if (eng == "quantile") return(nl_quantile(object$formula, data, start = as.list(stats::coef(object$fit)), tau = object$metadata$tau %||% 0.5))
  if (eng %in% c("gnls", "nlme")) {
    fit2 <- stats::update(object$fit, data = data)
    return(.nl_wrap(fit2, eng, object$formula, data, object$start, object$model, metadata = object$metadata))
  }
  stop("Refitting is not implemented for engine: ", eng, call. = FALSE)
}
.nl_extract_vcov <- function(object) {
  fit <- .nl_unwrap(object)
  tryCatch(stats::vcov(fit), error = function(e) NULL)
}
.nl_coef <- function(object) stats::coef(.nl_unwrap(object))
.nl_obs_pred <- function(object, newdata = NULL) {
  if (!inherits(object, "nlrfit")) stop("object must be an nlrfit object", call. = FALSE)
  dat <- newdata %||% object$data
  pred <- as.numeric(stats::predict(object$fit, newdata = dat))
  list(data = dat, pred = pred)
}
