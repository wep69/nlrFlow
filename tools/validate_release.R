#!/usr/bin/env Rscript
# nlrFlow Release Validation Pipeline
# Uso: Rscript tools/validate_release.R [package_dir]
# Exemplo: Rscript tools/validate_release.R D:/Walter/R/Pacotes_criados/nlrFlow/validation-work/nlrFlow_0.3.0.9000

cat("=== nlrFlow Release Validation Pipeline ===\n")
cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# --- Configuração ---
pkg_dir <- if (commandArgs(TRUE)[1] != "") commandArgs(TRUE)[1] else getwd()
pkg_dir <- normalizePath(pkg_dir, mustWork = TRUE)
log_dir <- file.path(dirname(pkg_dir), "logs")
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
log_file <- file.path(log_dir, paste0("validate_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".log"))
sink(log_file, split = TRUE)

cat("Package:", pkg_dir, "\n")
cat("Log:", log_file, "\n\n")

# --- Funções auxiliares ---
section <- function(n, title) {
  cat(sprintf("\n=== [%d/7] %s ===\n", n, title))
  cat(format(Sys.time(), "%H:%M:%S"), "\n")
}

check_ok <- function(desc, expr) {
  cat(desc, "... ")
  t0 <- proc.time()
  result <- tryCatch(expr, error = function(e) {
    cat("ERROR:", conditionMessage(e), "\n")
    FALSE
  }, warning = function(w) {
    cat("WARNING:", conditionMessage(w), "\n")
    TRUE
  })
  dt <- (proc.time() - t0)[["elapsed"]]
  if (isTRUE(result)) cat(sprintf("OK (%.1fs)\n", dt))
  invisible(result)
}

# --- Fase 1: Documentação ---
section(1, "Regenerando documentação")
check_ok("devtools::document()", {
  devtools::document(pkg_dir)
  TRUE
})

# --- Fase 2: Testes ---
section(2, "Executando testes testthat")
test_results <- check_ok("devtools::test()", {
  devtools::test(pkg_dir, reporter = "summary")
})
n_failed <- sum(test_results$failed)
n_warnings <- sum(test_results$warning)
cat(sprintf("Result: %d failed, %d warnings, %d passed\n",
            n_failed, n_warnings, sum(test_results$passed)))

# --- Fase 3: Vinhetas (code check apenas) ---
section(3, "Verificando código das vinhetas")
check_ok("run vignette R code", {
  # Verifica se o código das vinhetas executa sem erro
  vignettes <- list.files(file.path(pkg_dir, "vignettes"), pattern = "\\.Rmd$", full.names = TRUE)
  errors <- character(0)
  for (v in vignettes) {
    tryCatch({
      # Extrai e executa chunks R
      lines <- readLines(v)
      r_chunks <- regmatches(lines, gregexpr("```\\{r[^}]*\\}.*?```", lines, perl = TRUE))[[1]]
      if (length(r_chunks) > 0) {
        for (chunk in r_chunks) {
          code <- gsub("```\\{r[^}]*\\}", "", chunk)
          code <- gsub("```", "", code)
          if (grepl("eval\\s*=\\s*FALSE", chunk)) next
          tryCatch(parse(text = code), error = function(e) {
            errors <<- c(errors, paste(basename(v), ":", conditionMessage(e)))
          })
        }
      }
    }, error = function(e) {
      errors <<- c(errors, paste(basename(v), ":", conditionMessage(e)))
    })
  }
  if (length(errors) > 0) {
    cat("Errors found:\n")
    cat(paste("  ", errors, collapse = "\n"), "\n")
    FALSE
  } else TRUE
})

# --- Fase 4: Bateria numérica congelada ---
section(4, "Bateria numérica congelada")
check_ok("golden tests", {
  source(file.path(pkg_dir, "tests", "testthat", "test-numerical-golden.R"), local = TRUE)
  TRUE
})

# --- Fase 5: Exemplos ---
section(5, "Verificando exemplos documentados")
check_ok("devtools::run_examples()", {
  devtools::run_examples(pkg_dir, run_donttest = FALSE)
  TRUE
})

# --- Fase 6: Build ---
section(6, "Construindo tarball")
tarball <- check_ok("devtools::build()", {
  devtools::build(pkg_dir, path = dirname(pkg_dir), args = "--no-build-vignettes")
})
cat("Tarball:", tarball, "\n")

# --- Fase 7: R CMD check ---
section(7, "R CMD check --as-cran")
check_result <- check_ok("rcmdcheck::rcmdcheck()", {
  rcmdcheck::rcmdcheck(tarball, args = c("--no-manual", "--no-build-vignettes", "--as-cran"),
                        error_on = "never")
})

# --- Resumo ---
cat("\n\n========================================\n")
cat("RESUMO DA VALIDAÇÃO\n")
cat("========================================\n")
cat("Package:", pkg_dir, "\n")
cat("Tarball:", tarball, "\n")
cat("Log:", log_file, "\n")
if (inherits(check_result, "rcmdcheck_results")) {
  cat("Errors:", length(check_result$errors), "\n")
  cat("Warnings:", length(check_result$warnings), "\n")
  cat("Notes:", length(check_result$notes), "\n")
  if (length(check_result$errors) > 0) {
    cat("\nERRORS:\n")
    cat(paste("  ", check_result$errors), sep = "\n")
  }
  if (length(check_result$warnings) > 0) {
    cat("\nWARNINGS:\n")
    cat(paste("  ", check_result$warnings), sep = "\n")
  }
  if (length(check_result$notes) > 0) {
    cat("\nNOTES:\n")
    cat(paste("  ", check_result$notes), sep = "\n")
  }
}
cat("\n========================================\n")
cat("Validação concluída:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
sink()
