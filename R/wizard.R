#' Interactive analysis wizard
#'
#' Guides the user through a complete nlrFlow analysis interactively.
#' When called without arguments, presents a menu-driven interface.
#'
#' @param data Optional data frame to start with
#' @param response Optional response column name
#' @param predictor Optional predictor column name
#' @return Invisibly returns the last fitted model object
#' @export
nl_wizard <- function(data = NULL, response = NULL, predictor = NULL) {
  cat("╔══════════════════════════════════════╗\n")
  cat("║       nlrFlow Analysis Wizard        ║\n")
  cat("╚══════════════════════════════════════╝\n\n")

  # Step 1: Data
  if (is.null(data)) {
    cat("Available teaching datasets:\n")
    datasets <- c("okra_growth_means", "okra_growth_raw", "soil_fertility_p",
                  "soil_infiltration", "plant_physiology_light", "agronomy_growth")
    for (i in seq_along(datasets)) cat(sprintf("  %d. %s\n", i, datasets[i]))
    choice <- readline("Select dataset (number or name): ")
    if (grepl("^[0-9]+$", choice)) choice <- datasets[as.integer(choice)]
    data <- nl_data(choice)
    cat("\nData loaded:", nrow(data), "rows,", ncol(data), "columns\n")
    print(head(data))
  }

  # Step 2: Audit
  if (is.null(response) || is.null(predictor)) {
    cat("\nColumns:", paste(names(data), collapse=", "), "\n")
    if (is.null(response)) response <- readline("Response column: ")
    if (is.null(predictor)) predictor <- readline("Predictor column: ")
  }
  cat("\n--- Data Audit ---\n")
  nl_audit(data, response, predictor)

  # Step 3: Fit
  cat("\nAvailable models:\n")
  models <- nl_models()$model
  for (i in seq_along(models)) cat(sprintf("  %d. %s\n", i, models[i]))
  model_choice <- readline("Select model (number or name): ")
  if (grepl("^[0-9]+$", model_choice)) model_choice <- models[as.integer(model_choice)]

  cat("\nFitting", model_choice, "...\n")
  f <- nl_fit(data=data, model=model_choice, response=response, predictor=predictor, engine="nlsLM")
  cat("Converged:", !is.null(f$fit), "\n")

  # Step 4: Diagnose
  cat("\n--- Diagnostics ---\n")
  print(nl_diagnose(f))

  # Step 5: Predict
  cat("\n--- Predictions (first 5 rows) ---\n")
  pred <- nl_predict(f, interval="confidence")
  print(head(pred, 5))

  # Step 6: Plot
  cat("\n--- Plot ---\n")
  print(nl_plot(f))

  invisible(f)
}
