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
