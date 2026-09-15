# Seed helper - preserves .Random.seed state across function calls

#' Capture the global random-number-generator state
#'
#' Records whether \code{.Random.seed} exists in the global environment and, if
#' so, its value, so that it can be put back untouched by
#' \code{\link{.nl_rng_restore}}.
#'
#' @return A list with elements \code{present} and \code{seed}.
#' @keywords internal
.nl_rng_state <- function() {
  present <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  list(present = present,
       seed = if (present) get(".Random.seed", envir = .GlobalEnv, inherits = FALSE) else NULL)
}

#' Restore a random-number-generator state
#'
#' @param state A value returned by \code{\link{.nl_rng_state}}.
#' @return \code{NULL}, invisibly.
#' @keywords internal
.nl_rng_restore <- function(state) {
  if (isTRUE(state$present)) {
    assign(".Random.seed", state$seed, envir = .GlobalEnv)
  } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    rm(".Random.seed", envir = .GlobalEnv)
  }
  invisible(NULL)
}

#' Set seed temporarily without contaminating the global RNG state
#'
#' Saves the current global \code{.Random.seed}, applies \code{set.seed(seed)},
#' evaluates \code{expr}, then restores the previous state on exit. This keeps
#' the caller's random stream untouched, so a simulation loop that passes a
#' fixed \code{seed} to a package function still draws new data per iteration.
#'
#' Functions that draw random numbers inline instead of inside one expression use
#' the same machinery directly: \code{sav <- .nl_rng_state(); on.exit(.nl_rng_restore(sav), add = TRUE)}
#' registers the restoration on the exit of the \emph{calling} function.
#'
#' @param seed A numeric seed, or \code{NULL} to evaluate without touching the RNG.
#' @param expr Expression to evaluate.
#' @return The value of \code{expr}.
#' @keywords internal
.nl_with_seed <- function(seed, expr) {
  if (is.null(seed)) return(force(expr))
  state <- .nl_rng_state()
  on.exit(.nl_rng_restore(state), add = TRUE)
  set.seed(seed)
  force(expr)
}
