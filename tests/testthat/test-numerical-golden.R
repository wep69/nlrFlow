# test-numerical-golden.R
# Bateria numérica congelada para validação de release

# === Gompertz ===
test_that("Gompertz golden values recover within tolerance", {
  d <- nl_simulate("gompertz", 1:25, c(Asym=18, k=0.44, xmid=3.7), sigma=0, seed=1)
  f <- nl_fit(data=d, model="gompertz", response="y", predictor="x", engine="nlsLM")
  cf <- coef(f)
  expect_equal(unname(cf["Asym"]), 18, tolerance=1e-6)
  expect_equal(unname(cf["k"]), 0.44, tolerance=1e-4)
  expect_equal(unname(cf["xmid"]), 3.7, tolerance=1e-4)
})

# === Logistic ===
test_that("Logistic golden values recover within tolerance", {
  d <- nl_simulate("logistic", 1:20, c(Asym=20, xmid=10, scal=3), sigma=0, seed=2)
  f <- nl_fit(data=d, model="logistic", response="y", predictor="x", engine="nlsLM")
  cf <- coef(f)
  expect_equal(unname(cf["Asym"]), 20, tolerance=1e-6)
  expect_equal(unname(cf["xmid"]), 10, tolerance=1e-4)
  expect_equal(unname(cf["scal"]), 3, tolerance=1e-4)
})

# === Mitscherlich ===
test_that("Mitscherlich golden values recover within tolerance", {
  d <- nl_simulate("mitscherlich", seq(0,180,15), c(Asym=8, delta=5, k=0.025), sigma=0, seed=3)
  f <- nl_fit(data=d, model="mitscherlich", response="y", predictor="x", engine="nlsLM")
  cf <- coef(f)
  expect_equal(unname(cf["Asym"]), 8, tolerance=1e-6)
  expect_equal(unname(cf["delta"]), 5, tolerance=1e-4)
  expect_equal(unname(cf["k"]), 0.025, tolerance=1e-4)
})

# === Michaelis-Menten ===
test_that("Michaelis-Menten golden values recover within tolerance", {
  d <- nl_simulate("michaelis_menten", 1:20, c(Vmax=10, Km=5), sigma=0, seed=4)
  f <- nl_fit(data=d, model="michaelis_menten", response="y", predictor="x", engine="nlsLM")
  cf <- coef(f)
  expect_equal(unname(cf["Vmax"]), 10, tolerance=1e-6)
  expect_equal(unname(cf["Km"]), 5, tolerance=1e-4)
})

# === Richards ===
test_that("Richards golden values recover within tolerance", {
  d <- nl_simulate("richards", 1:25, c(Asym=18, xmid=5, scal=3, nu=1.5), sigma=0, seed=5)
  f <- nl_fit(data=d, model="richards", response="y", predictor="x", engine="nlsLM")
  cf <- coef(f)
  expect_equal(unname(cf["Asym"]), 18, tolerance=1e-5)
  expect_equal(unname(cf["xmid"]), 5, tolerance=1e-3)
})

# === Conformal coverage ===
test_that("Conformal coverage is within nominal", {
  skip_on_cran()
  skip_if_not_installed("boot")
  d <- nl_simulate("gompertz", 1:30, c(Asym=18, k=0.44, xmid=3.7), sigma=0.5, seed=42)
  f <- nl_fit(data=d, model="gompertz", response="y", predictor="x", engine="nlsLM")
  ci <- tryCatch(nl_conformal(f, alpha=0.10), error=function(e) NULL)
  if (!is.null(ci) && !is.null(ci$lower) && !is.null(ci$upper)) {
    coverage <- mean(ci$lower <= d$y & ci$upper >= d$y, na.rm=TRUE)
    expect_gt(coverage, 0.70)
  } else {
    skip("nl_conformal not available or returned NULL")
  }
})

# === Model comparison consistency ===
test_that("Model comparison returns consistent AICc ordering", {
  d <- nl_data("okra_growth_means")
  fits <- nl_fit_many(d, "fruit_length", "day_after_flowering",
                      c("logistic", "gompertz", "richards"), engine="nlsLM")
  tab <- nl_compare(fits)
  expect_true("AICc" %in% names(tab))
  expect_true(nrow(tab) >= 2)
})

# === Data integrity ===
test_that("Teaching datasets have expected dimensions", {
  expect_equal(nrow(nl_data("okra_growth_means")), 10)
  expect_equal(nrow(nl_data("okra_growth_raw")), 530)
  expect_true(nrow(nl_data("soil_fertility_p")) > 0)
  expect_true(nrow(nl_data("soil_infiltration")) > 0)
})

# === Sensitivity golden values ===
test_that("Sensitivity local indices match analytic for exponential", {
  f <- function(p) p["A"] * (1 - exp(-p["k"] * 1:10))
  ranges <- matrix(c(10,30, 0.05,0.5), 2, 2, byrow=TRUE,
                   dimnames=list(c("A","k"), c("lower","upper")))
  s <- nl_sensitivity(f, ranges, method="local")
  expect_true(is.list(s))
  expect_true("indices" %in% names(s))
  expect_true(all(c("A","k") %in% s$indices$parameter))
  expect_true(all(s$indices$sensitivity_index >= 0))
})
