# Cache system for expensive computations (Neural ODE, UDE, etc.)

#' Generate cache key from inputs
#' @param ... Named arguments to hash
#' @return SHA-256 cache key
#' @keywords internal
.nl_cache_key <- function(...) {
  args <- list(...)
  txt <- paste(names(args), vapply(args, function(x) {
    if (is.null(x)) "NULL"
    else if (is.data.frame(x)) paste("df:", nrow(x), ncol(x), digest::digest(x, algo="md5"))
    else if (is.numeric(x)) paste("num:", paste(x, collapse=","))
    else paste("str:", as.character(x))
  }, character(1)), sep="=", collapse=";")
  digest::digest(txt, algo="sha256")
}

#' Get cached result
#' @param key Cache key from .nl_cache_key()
#' @return Cached value or NULL
#' @keywords internal
.nl_cache_get <- function(key) {
  cache_dir <- file.path(path.expand("~"), ".nlrFlow", "cache")
  f <- file.path(cache_dir, paste0(key, ".rds"))
  if (file.exists(f)) {
    tryCatch(readRDS(f), error = function(e) NULL)
  } else {
    NULL
  }
}

#' Set cached result
#' @param key Cache key from .nl_cache_key()
#' @param value Value to cache
#' @keywords internal
.nl_cache_set <- function(key, value) {
  cache_dir <- file.path(path.expand("~"), ".nlrFlow", "cache")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  tryCatch(saveRDS(value, file.path(cache_dir, paste0(key, ".rds"))),
           error = function(e) invisible(NULL))
}

#' Clear all cached results
#' @export
nl_cache_clear <- function() {
  cache_dir <- file.path(path.expand("~"), ".nlrFlow", "cache")
  if (dir.exists(cache_dir)) {
    n <- length(list.files(cache_dir, pattern = "\\.rds$"))
    unlink(list.files(cache_dir, pattern = "\\.rds$", full.names = TRUE))
    message("Cleared ", n, " cached results from ", cache_dir)
  } else {
    message("No cache directory found.")
  }
  invisible(NULL)
}

#' Show cache size
#' @export
nl_cache_info <- function() {
  cache_dir <- file.path(path.expand("~"), ".nlrFlow", "cache")
  if (dir.exists(cache_dir)) {
    files <- list.files(cache_dir, pattern = "\\.rds$", full.names = TRUE)
    total_size <- sum(file.info(files)$size, na.rm = TRUE)
    cat("Cache directory:", cache_dir, "\n")
    cat("Cached entries:", length(files), "\n")
    cat("Total size:", round(total_size / 1024 / 1024, 2), "MB\n")
  } else {
    cat("No cache directory found.\n")
  }
  invisible(NULL)
}
