# Seed helper - preserves .Random.seed state across function calls

#' Set seed temporarily without contaminating the global RNG state
#'
#' Saves the current global \code{.Random.seed}, applies \code{set.seed(seed)},
#' evaluates \code{expr}, then restores the previous state on exit. This keeps
#' the caller's random stream untouched, so a simulation loop that passes a
#' fixed \code{seed} to a package function still draws new data per iteration.
#'
#' @param seed A numeric seed, or \code{NULL} to evaluate without touching the RNG.
#' @param expr Expression to evaluate.
#' @return The value of \code{expr}.
#' @keywords internal
.nl_with_seed <- function(seed, expr) {
  if (is.null(seed)) return(force(expr))
  tinha <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  antes <- if (tinha) get(".Random.seed", envir = .GlobalEnv, inherits = FALSE) else NULL
  on.exit({
    if (tinha) {
      assign(".Random.seed", antes, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  set.seed(seed)
  force(expr)
}
