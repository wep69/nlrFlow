# Engine registry for pluggable backends

# Internal environment for engine registry
.nl_engine_registry <- new.env(parent = emptyenv())

#' Register a custom fitting engine
#'
#' Adds a new backend engine that can be used with `nl_fit()`.
#'
#' @param name Engine name (e.g., "torch", "jax")
#' @param fit_fn Function(formula, data, start, lower, upper, weights, ...) that returns a fitted model object
#' @param predict_fn Function(object, newdata) that returns predictions
#' @param validate_fn Function(object) that returns a list with diagnostics, or NULL
#' @export
nl_register_engine <- function(name, fit_fn, predict_fn, validate_fn = NULL) {
  if (!is.character(name) || !nzchar(name)) stop("Engine name must be a non-empty string.", call. = FALSE)
  if (!is.function(fit_fn)) stop("fit_fn must be a function.", call. = FALSE)
  if (!is.function(predict_fn)) stop("predict_fn must be a function.", call. = FALSE)
  if (!is.null(validate_fn) && !is.function(validate_fn)) stop("validate_fn must be a function or NULL.", call. = FALSE)

  assign(name, list(fit = fit_fn, predict = predict_fn, validate = validate_fn),
         envir = .nl_engine_registry)
  message("Engine '", name, "' registered successfully.")
  invisible(TRUE)
}

#' List registered engines
#'
#' Returns the names of all registered custom engines.
#'
#' @return Character vector of engine names
#' @export
nl_list_engines <- function() {
  custom <- ls(.nl_engine_registry, all.names = FALSE)
  builtin <- c("nls", "nlsLM", "multistart", "gnls", "robust", "quantile")
  list(builtin = builtin, custom = custom)
}

#' Check if a custom engine is registered
#' @param name Engine name
#' @return Logical
#' @keywords internal
.nl_has_engine <- function(name) {
  exists(name, envir = .nl_engine_registry, inherits = FALSE)
}

#' Get a custom engine
#' @param name Engine name
#' @return List with fit, predict, validate functions, or NULL
#' @keywords internal
.nl_get_engine <- function(name) {
  if (.nl_has_engine(name)) {
    get(name, envir = .nl_engine_registry, inherits = FALSE)
  } else {
    NULL
  }
}
