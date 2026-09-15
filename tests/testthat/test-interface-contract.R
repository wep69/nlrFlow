## Interface-contract regressions from the external audit (RELATORIO-AO-AUTOR.md,
## items 1, 12.1-12.11). Each test pins one behaviour that used to fail silently.

test_that("seeded functions never reprogramme the global generator (item 1)", {
  okra <- nl_data("okra_growth_means")
  f <- nl_fit(data = okra, model = "gompertz", response = "fruit_length",
              predictor = "day_after_flowering", engine = "nls")
  lo <- c(Asym = 10, k = 0.01, xmid = -2); up <- c(Asym = 30, k = 3, xmid = 15)
  expect_no_rng_change <- function(call) {
    set.seed(11); runif(1); before <- runif(3)
    set.seed(11); runif(1); try(call, silent = TRUE); after <- runif(3)
    expect_identical(before, after)
  }
  expect_no_rng_change(nl_cv(f, k = 3))
  expect_no_rng_change(nl_conformal(f, alpha = .1))
  expect_no_rng_change(nl_boot(f, R = 3))
  expect_no_rng_change(nl_multistart(fruit_length ~ Asym * exp(-exp(-k * (day_after_flowering - xmid))),
                                     okra, lo, up, iter = 1, ncores = 1))
  expect_no_rng_change(nl_predict(f, interval = "prediction", nsim = 10))
})

test_that("nlrfit exposes the standard accessor methods (item 12.2)", {
  okra <- nl_data("okra_growth_means")
  f <- nl_fit(data = okra, model = "gompertz", response = "fruit_length",
              predictor = "day_after_flowering", engine = "nls")
  expect_s3_class(f, "nlrfit")
  expect_true(is.matrix(stats::vcov(f)))
  expect_s3_class(stats::logLik(f), "logLik")
  expect_true(is.finite(stats::AIC(f)))
  expect_true(is.finite(stats::BIC(f)))
  expect_identical(stats::nobs(f), nrow(okra))
  expect_true(is.finite(stats::deviance(f)))
  expect_identical(stats::df.residual(f), stats::df.residual(f$fit))
  expect_true(is.matrix(stats::confint(f)))
  expect_s3_class(stats::anova(f), "anova")
})

test_that("predict and model.frame dispatch on nlrfit instead of returning junk", {
  okra <- nl_data("okra_growth_means")
  f <- nl_fit(data = okra, model = "gompertz", response = "fruit_length",
              predictor = "day_after_flowering", engine = "nls")
  expect_length(stats::predict(f), nrow(okra))
  expect_true(is.data.frame(stats::model.frame(f)))
  expect_gt(nrow(stats::model.frame(f)), 0L)
  expect_error(stats::predict(f, interval = "confidence"), "nl_predict")
  expect_error(stats::predict(f, se.fit = TRUE), "nl_predict")
})

test_that("nl_table writes every file-rendering mode it advertises", {
  skip_if_not_installed("gt")
  okra <- nl_data("okra_growth_means")
  f <- nl_fit(data = okra, model = "gompertz", response = "fruit_length",
              predictor = "day_after_flowering", engine = "nls")
  for (r in c("csv", "latex")) {
    path <- tempfile(fileext = paste0(".", if (r == "csv") "csv" else "tex"))
    out <- nl_table(f, "parameters", render = r, file = path)
    expect_true(file.exists(path), info = r)
    expect_gt(file.info(path)$size, 0)
    expect_true(nzchar(out))
  }
  expect_true(is.data.frame(nl_table(f, "parameters")))
})

test_that("nl_table diagnostics and nl_report work for a plain nls fit (item 3)", {
  okra <- nl_data("okra_growth_means")
  f <- nl_fit(data = okra, model = "gompertz", response = "fruit_length",
              predictor = "day_after_flowering", engine = "nls")
  d <- nl_table(f, "diagnostics")
  expect_true(is.data.frame(d))
  expect_identical(nrow(d), length(d$value))
  path <- tempfile(fileext = ".md")
  nl_report(f, path)
  expect_true(file.exists(path))
})

test_that("nl_plot relabels axes with xlab/ylab without changing the variables (item 12.8)", {
  skip_if_not_installed("ggplot2")
  okra <- nl_data("okra_growth_means")
  f <- nl_fit(data = okra, model = "gompertz", response = "fruit_length",
              predictor = "day_after_flowering", engine = "nls")
  p <- nl_plot(f, xlab = "Days", ylab = "Fruit length (cm)")
  expect_identical(p$labels$x, "Days")
  expect_identical(p$labels$y, "Fruit length (cm)")
  expect_error(nl_plot(f, x = "Days"), "Numeric variables available")
})

test_that("nl_audit refuses a non-numeric predictor with an actionable message (item 12.9)", {
  fert <- nl_data("soil_fertility_p")
  expect_error(nl_audit(fert, "grain_yield_Mg_ha", "soil_class"), "must be numeric")
  expect_error(nl_audit(fert, "grain_yield_Mg_ha", "soil_class"), "P2O5_kg_ha")
  expect_error(nl_audit(fert, "grain_yield_Mg_ha", "absent_column"), "not found in `data`")
  expect_s3_class(nl_audit(fert, "grain_yield_Mg_ha", "P2O5_kg_ha", "soil_class"), "nlr_audit")
})

test_that("nl_robust names and validates bounds, and never warns on defaults (items 12.1, 12.6)", {
  skip_if_not_installed("robustbase")
  s <- subset(nl_data("soil_fertility_p"), soil_class == "Loamy")
  s <- s[order(s$P2O5_kg_ha), c("P2O5_kg_ha", "grain_yield_Mg_ha")]
  fo <- grain_yield_Mg_ha ~ a * (1 - exp(-k * P2O5_kg_ha))
  expect_silent(nl_robust(fo, s, c(a = 4, k = 0.02), method = "M"))
  expect_silent(nl_robust(fo, s, c(a = 4, k = 0.02), method = "M", lower = 0, upper = 10))
  expect_error(nl_robust(fo, s, c(4, 0.02)), "fully named")
  expect_error(nl_robust(fo, s, c(a = 4, k = 0.02), method = "MM"), "requires finite")
  fit_mm <- nl_robust(fo, s, c(a = 4, k = 0.02), method = "MM",
                      lower = c(a = 0, k = 0), upper = c(a = 20, k = 1))
  expect_true(all(is.finite(stats::coef(fit_mm))))
})

test_that("discovery grids stay inside the physically meaningful predictor range (item 12.10)", {
  sp <- subset(nl_data("soil_p_sorption"), soil_class == "Clayey")
  fs <- nl_fit(data = sp, model = "langmuir", response = "sorbed_P_mg_kg",
               predictor = "solution_P_mg_L", engine = "nls")
  v <- nl_validate_candidate(fs, "solution_P_mg_L", list(positive = TRUE))
  expect_gte(min(v$grid$solution_P_mg_L), 0)
  d <- nl_discover(sp, "sorbed_P_mg_kg", "solution_P_mg_L",
                   candidate_formulas = list(power = sorbed_P_mg_kg ~ a * solution_P_mg_L^b),
                   candidate_starts = list(power = c(a = 50, b = 0.5)),
                   constraints = list(positive = TRUE), engine = "nls", k = NULL)
  expect_true(d$table$valid[1])
  d2 <- nl_discover(sp, "sorbed_P_mg_kg", "solution_P_mg_L",
                    candidate_formulas = list(power = sorbed_P_mg_kg ~ a * solution_P_mg_L^b),
                    candidate_starts = list(power = c(a = 50, b = 0.5)),
                    constraints = list(monotonic = "decreasing"), engine = "nls", k = NULL)
  expect_match(d2$table$error[1], "failed checks")
})

test_that("nl_ode_solve returns an nlr_ode envelope that stays matrix-compatible (item 12.11)", {
  skip_if_not_installed("deSolve")
  fun <- function(t, state, parms) list(c(parms["r"] * (parms["K"] - state[1])))
  sol <- nl_ode_solve(c(B = 1), seq(0, 30, 5), fun, c(r = 0.08, K = 20))
  expect_s3_class(sol, "nlr_ode")
  expect_true(is.matrix(sol$solution))
  expect_identical(sol$states, "B")
  expect_identical(sol$method, "lsoda")
  expect_length(sol$times, 7L)
  expect_length(sol[, "B"], 7L)
  expect_true(is.data.frame(as.data.frame(sol)))
  expect_output(print(sol), "nlr_ode")
})
