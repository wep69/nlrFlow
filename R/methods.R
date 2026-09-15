#' @exportS3Method print nlrfit
print.nlrfit <- function(x, ...) {
  cat("nlrFlow fit\n  engine:", x$engine, "\n  formula:")
  print(x$formula)
  cat("  coefficients:\n")
  print(stats::coef(x$fit))
  invisible(x)
}

#' @exportS3Method summary nlrfit
summary.nlrfit <- function(object, ...) summary(object$fit, ...)

#' @exportS3Method coef nlrfit
coef.nlrfit <- function(object, ...) stats::coef(object$fit, ...)

#' @exportS3Method predict nlrfit
predict.nlrfit <- function(object, newdata = NULL, interval = NULL, se.fit = NULL, ...) {
  # Delegates to the wrapped backend. The `interval` and `se.fit` arguments are
  # not supported here: they are accepted for compatibility with the
  # `stats::predict` generic, but the backend may not honour them, so they are
  # refused explicitly instead of being silently dropped. Use nl_predict() for
  # confidence and prediction intervals with uncertainty propagation.
  if (!is.null(interval) && !identical(interval, "none"))
    stop("predict.nlrfit() does not compute intervals. Use nl_predict(object, interval = \"",
         interval, "\") instead.", call. = FALSE)
  if (isTRUE(se.fit))
    stop("predict.nlrfit() does not return standard errors. Use nl_predict() for intervals with uncertainty.",
         call. = FALSE)
  stats::predict(object$fit, newdata = newdata, ...)
}

#' @exportS3Method fitted nlrfit
fitted.nlrfit <- function(object, ...) stats::fitted(object$fit, ...)

#' @exportS3Method residuals nlrfit
residuals.nlrfit <- function(object, ...) stats::residuals(object$fit, ...)

#' @exportS3Method vcov nlrfit
vcov.nlrfit <- function(object, ...) stats::vcov(object$fit, ...)

#' @exportS3Method logLik nlrfit
logLik.nlrfit <- function(object, ...) stats::logLik(object$fit, ...)

#' @exportS3Method AIC nlrfit
AIC.nlrfit <- function(object, ..., k = 2) stats::AIC(object$fit, ..., k = k)

#' @exportS3Method BIC nlrfit
BIC.nlrfit <- function(object, ...) stats::BIC(object$fit, ...)

#' @exportS3Method nobs nlrfit
nobs.nlrfit <- function(object, ...) stats::nobs(object$fit, ...)

#' @exportS3Method deviance nlrfit
deviance.nlrfit <- function(object, ...) stats::deviance(object$fit, ...)

#' @exportS3Method df.residual nlrfit
df.residual.nlrfit <- function(object, ...) stats::df.residual(object$fit, ...)

#' @exportS3Method confint nlrfit
confint.nlrfit <- function(object, parm = NULL, level = 0.95, ...) {
  stats::confint(object$fit, parm = parm, level = level, ...)
}

#' @exportS3Method anova nlrfit
anova.nlrfit <- function(object, ...) {
  others <- lapply(list(...), function(z) if (inherits(z, "nlrfit")) z$fit else z)
  if (length(others)) return(do.call(stats::anova, c(list(object$fit), others)))
  # `anova.nls()` only accepts a *sequence* of nested fits, so a single object
  # would error. Where the backend can summarise one model, use it; otherwise
  # report the residual line of the analysis-of-variance table.
  out <- tryCatch(stats::anova(object$fit), error = function(e) NULL)
  if (!is.null(out)) return(out)
  df <- stats::df.residual(object$fit)
  rss <- stats::deviance(object$fit)
  if (!is.finite(rss) || !is.finite(df) || df <= 0)
    stop("anova() needs at least two nested nlrfit objects for this backend; a single fit provides no residual degrees of freedom.",
         call. = FALSE)
  ans <- data.frame(Df = df, `Sum Sq` = rss, `Mean Sq` = rss / df,
                    `F value` = NA_real_, `Pr(>F)` = NA_real_,
                    row.names = "Residuals", check.names = FALSE)
  class(ans) <- c("anova", "data.frame")
  ans
}

#' @exportS3Method model.frame nlrfit
model.frame.nlrfit <- function(formula, ...) {
  # Returns a real model frame. Without this method, `model.frame.default` finds
  # the `$model` component of the `nlrfit` envelope, which holds the registered
  # model **name**, and returns that string instead of a data frame.
  fit <- formula$fit
  mf <- tryCatch(suppressWarnings(stats::model.frame(fit, ...)), error = function(e) NULL)
  if (is.data.frame(mf) && nrow(mf)) return(mf)
  if (is.data.frame(fit$model) && nrow(fit$model)) return(fit$model)
  d <- formula$data
  if (is.data.frame(d) && nrow(d)) {
    # Several backends (nls, nlsLM, nlrob) keep no usable model frame, so the
    # data stored on the envelope is used with the fitted formula's terms.
    tt <- tryCatch(stats::terms(formula$formula, data = d), error = function(e) NULL)
    if (!is.null(tt)) {
      mf2 <- tryCatch(stats::model.frame(tt, data = d), error = function(e) NULL)
      if (is.data.frame(mf2) && nrow(mf2)) return(mf2)
    }
    return(d)
  }
  stop("model.frame() is unavailable for this nlrfit: the backend exposes no model frame and the object stores no data.",
       call. = FALSE)
}
