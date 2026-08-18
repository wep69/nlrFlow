# Suppress R CMD check NOTEs for non-standard evaluation in ggplot2/dplyr
utils::globalVariables(c(
  ".lower", ".upper", ".prediction", "AIC", "AICc", "BIC",
  "candidate", "complexity", "control", "corrected", "depth",
  "eligible", "fitted", "known", "loss", "lower", "mechanistic",
  "metric", "model", "neural", "observed", "point", "predicted",
  "residual", "reorder", "score", "selected", "std", "total",
  "upper", "valid", "value", "iteration"
))
