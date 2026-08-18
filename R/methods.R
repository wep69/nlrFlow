print.nlrfit <- function(x, ...) { cat("nlrFlow fit\n  engine:",x$engine,"\n  formula:"); print(x$formula); cat("  coefficients:\n"); print(stats::coef(x$fit)); invisible(x) }
summary.nlrfit <- function(object, ...) summary(object$fit,...)
coef.nlrfit <- function(object, ...) stats::coef(object$fit,...)
predict.nlrfit <- function(object, newdata=NULL, ...) stats::predict(object$fit,newdata=newdata,...)
fitted.nlrfit <- function(object, ...) stats::fitted(object$fit,...)
residuals.nlrfit <- function(object, ...) stats::residuals(object$fit,...)
