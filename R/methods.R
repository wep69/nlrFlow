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
predict.nlrfit <- function(object, newdata = NULL, ...) stats::predict(object$fit, newdata = newdata, ...)

#' @exportS3Method fitted nlrfit
fitted.nlrfit <- function(object, ...) stats::fitted(object$fit, ...)

#' @exportS3Method residuals nlrfit
residuals.nlrfit <- function(object, ...) stats::residuals(object$fit, ...)
