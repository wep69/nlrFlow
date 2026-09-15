# Package-level setup

#' nlrFlow: integrated scientific workflows for nonlinear regression
#'
#' The generics that nlrFlow registers S3 methods for live in \pkg{stats}, so
#' they are imported explicitly; otherwise `loadNamespace()` would fail while
#' registering, for example, `S3method(BIC, nlrfit)` when only the base
#' namespace is loaded.
#'
#' @keywords internal
#' @name nlrFlow-package
#' @aliases nlrFlow nlrFlow-package
#' @importFrom stats AIC BIC anova coef confint deviance df.residual fitted
#'   logLik model.frame nobs predict residuals vcov runif setNames weighted.mean
#' @importFrom utils capture.output combn head tail
"_PACKAGE"

# `.data` is the ggplot2/rlang pronoun used inside ggplot2::aes(); declaring it
# here keeps R CMD check from reporting it as an undefined global variable
# without making rlang a hard dependency.
utils::globalVariables(".data")

#' Pipe operator
#'
#' See \code{magrittr::\link[magrittr:pipe]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom magrittr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
"%>%" <- magrittr::"%>%"
