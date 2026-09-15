# Validation helpers - internal utility functions for input validation
# These eliminate the recurring "undefined columns selected" bug pattern.

#' Get safe variable names that exist in data
#' @param object An nlrfit or data frame
#' @param type "predictor" or "response"
#' @return Character vector of variable names present in data
#' @keywords internal
.nl_safe_vars <- function(object, type = c("predictor", "response")) {
  type <- match.arg(type)
  if (inherits(object, "nlrfit")) {
    v <- switch(type,
      predictor = .nl_predictor_names(object$formula),
      response = .nl_response_name(object$formula)
    )
    v[v %in% names(object$data)]
  } else {
    character(0)
  }
}

#' Validate nlrfit object
#' @param object Object to validate
#' @return TRUE invisibly
#' @keywords internal
.nl_validate_nlrfit <- function(object) {
  if (!inherits(object, "nlrfit")) stop("object must be an nlrfit.", call. = FALSE)
  invisible(TRUE)
}

#' Validate that a column exists and has correct type
#' @param data Data frame
#' @param col Column name
#' @param type Expected type: "numeric", "character", "factor", or "any"
#' @param label Human-readable label for error messages
#' @return TRUE invisibly
#' @keywords internal
.nl_validate_column <- function(data, col, type = "any", label = col) {
  if (is.null(col) || is.na(col) || !nzchar(col)) stop(label, " must be specified.", call. = FALSE)
  if (!col %in% names(data)) stop(label, " ('", col, "') is not a column in data.", call. = FALSE)
  if (type == "numeric" && !is.numeric(data[[col]])) stop(label, " ('", col, "') must be numeric.", call. = FALSE)
  if (type == "factor" && !is.factor(data[[col]])) stop(label, " ('", col, "') must be a factor.", call. = FALSE)
  invisible(TRUE)
}

#' Require that columns exist, with an actionable message
#'
#' Replaces bare `stopifnot(... %in% names(data))` calls, whose failure message is
#' the raw expression, by a message naming the missing columns and the accepted ones.
#' @param data A data frame.
#' @param cols Character vector of required column names.
#' @param label Function name used to prefix the error message.
#' @param numeric_cols Optional character vector of columns that must additionally be numeric.
#' @return TRUE invisibly
#' @keywords internal
.nl_require_columns <- function(data, cols, label = "this function", numeric_cols = NULL) {
  cols <- cols[!vapply(cols, function(z) is.null(z) || length(z) != 1L || is.na(z) || !nzchar(z), logical(1L))]
  missing <- setdiff(cols, names(data))
  if (length(missing)) {
    stop(label, ": column(s) not found in `data`: ",
         paste0("'", missing, "'", collapse = ", "),
         ". Available columns: ", paste0("'", names(data), "'", collapse = ", "), ".",
         call. = FALSE)
  }
  if (!is.null(numeric_cols) && length(numeric_cols)) {
    bad <- numeric_cols[!vapply(data[numeric_cols], is.numeric, logical(1L))]
    if (length(bad)) {
      stop(label, ": column(s) must be numeric: ",
           paste0("'", bad, "'", collapse = ", "),
           ". Numeric columns available: ",
           paste0("'", names(data)[vapply(data, is.numeric, logical(1L))], "'", collapse = ", "), ".",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' Resolve and validate predictor column
#' @param object An nlrfit
#' @param predictor Predictor name or NULL to auto-detect
#' @return Validated predictor name
#' @keywords internal
.nl_validate_predictor <- function(object, predictor = NULL) {
  if (is.null(predictor)) {
    vars <- .nl_safe_vars(object, "predictor")
    nums <- vars[vapply(object$data[vars], is.numeric, logical(1))]
    if (length(nums) == 0L) stop("No numeric predictor found. Specify predictor= explicitly.", call. = FALSE)
    predictor <- nums[1]
  }
  .nl_validate_column(object$data, predictor, "numeric", "predictor")
  predictor
}

#' Resolve and validate response column
#' @param object An nlrfit
#' @param response Response name or NULL to auto-detect
#' @return Validated response name
#' @keywords internal
.nl_validate_response <- function(object, response = NULL) {
  if (is.null(response)) {
    response <- .nl_response_name(object$formula)
  }
  .nl_validate_column(object$data, response, "numeric", "response")
  response
}

# Accepted keys for the `constraints` argument of nl_validate_candidate()
.NL_CONSTRAINT_KEYS <- c("positive", "monotonic", "response_range", "parameter_bounds")

# Deprecated synonyms mapped to their canonical key
.NL_CONSTRAINT_SYNONYMS <- c(nonnegative = "positive", monotone = "monotonic")

#' Validate constraint key names
#'
#' Rejects unknown keys in `constraints` instead of silently ignoring them.
#' Deprecated synonyms (`nonnegative`, `monotone`) are accepted with a warning
#' and renamed to their canonical form, so previously written code keeps
#' running while the caller is informed.
#'
#' @param constraints Named list of scientific constraints.
#' @return The constraints list, with synonyms renamed to canonical keys.
#' @keywords internal
.nl_check_constraint_names <- function(constraints) {
  if (!length(constraints)) return(constraints)
  nm <- names(constraints)
  if (is.null(nm) || any(!nzchar(nm)))
    stop("Every element of constraints must be named. Accepted: ",
         paste(.NL_CONSTRAINT_KEYS, collapse = ", "), ".", call. = FALSE)
  synonyms <- intersect(nm, names(.NL_CONSTRAINT_SYNONYMS))
  if (length(synonyms)) {
    for (s in synonyms) {
      canonical <- .NL_CONSTRAINT_SYNONYMS[[s]]
      warning("constraints$", s, " is deprecated; use constraints$", canonical,
              " instead.", call. = FALSE)
      if (!canonical %in% nm) constraints[[canonical]] <- constraints[[s]]
    }
    constraints[synonyms] <- NULL
    nm <- names(constraints)
  }
  unknown <- setdiff(nm, .NL_CONSTRAINT_KEYS)
  if (length(unknown))
    stop("Unknown constraint(s): ", paste(unknown, collapse = ", "),
         ". Accepted: ", paste(.NL_CONSTRAINT_KEYS, collapse = ", "), ".",
         call. = FALSE)
  constraints
}

#' Validate group column
#' @param object An nlrfit
#' @param group Group name or NULL
#' @return Validated group name or NULL
#' @keywords internal
.nl_validate_group <- function(object, group = NULL) {
  if (!is.null(group)) {
    .nl_validate_column(object$data, group, "any", "group")
  }
  group
}

#' Normalize a collection of fits to a named list of nlrfit objects
#'
#' Accepts an `nlrfit_list` (from `nl_fit_many()`), an `nlr_discovery` result,
#' a single `nlrfit`, or a plain list of `nlrfit` objects, and fails loudly on
#' anything else. Without this, passing the wrong container silently produces
#' all-NA scores instead of an error.
#'
#' @param fits Fits object in any accepted form.
#' @param min_length Minimum number of fits required.
#' @return A named list of `nlrfit` objects.
#' @keywords internal
.nl_as_fit_list <- function(fits, min_length = 2L) {
  if (inherits(fits, "nlrfit_list")) fits <- fits$fits
  else if (inherits(fits, "nlr_discovery")) fits <- fits$fits
  else if (inherits(fits, "nlrfit")) fits <- list(fits)
  if (!is.list(fits) || !length(fits))
    stop("fits must be an nlrfit_list, an nlr_discovery result, a list of nlrfit objects, or a single nlrfit.",
         call. = FALSE)
  ok <- vapply(fits, inherits, logical(1), "nlrfit")
  if (!all(ok))
    stop("All entries must be nlrfit objects; element(s) ",
         paste(which(!ok), collapse = ", "), " are not.", call. = FALSE)
  if (length(fits) < min_length)
    stop("At least ", min_length, " competing fits are required.", call. = FALSE)
  if (is.null(names(fits)) || any(!nzchar(names(fits))))
    names(fits) <- paste0("model", seq_along(fits))
  fits
}

#' Normalize lower/upper bounds to match parameter names
#' @param lower Lower bounds (scalar or named vector)
#' @param upper Upper bounds (scalar or named vector)
#' @param pnames Character vector of parameter names
#' @return List with named lower and upper vectors
#' @keywords internal
.nl_prepare_bounds <- function(lower, upper, pnames) {
  if (length(lower) == 1L) lower <- rep(lower, length(pnames))
  if (length(upper) == 1L) upper <- rep(upper, length(pnames))
  names(lower) <- names(upper) <- pnames
  list(lower = lower, upper = upper)
}

# Session-level cache for the SciML capability probe. Checking Julia packages
# costs a few seconds, so it is done once per session instead of on every call.
.nl_sciml_cap_cache <- new.env(parent = emptyenv())

#' Cached SciML availability probe including Julia packages
#' @return Logical: TRUE only when Julia and the required Julia packages load.
#' @keywords internal
.nl_sciml_capability_cached <- function() {
  if (!is.null(.nl_sciml_cap_cache$value)) return(.nl_sciml_cap_cache$value)
  ok <- tryCatch(isTRUE(as.logical(nl_sciml_available(check_packages = TRUE))),
                 error = function(e) FALSE)
  .nl_sciml_cap_cache$value <- ok
  ok
}
