test_that("group-specific simulation changes nonlinear truth", {
  x <- rep(seq(1, 15, length.out = 12), 2)
  g <- rep(c("Control", "Stress"), each = 12)
  d <- nl_simulate(
    model = "gompertz", x = x,
    parameters = c(Asym = 20, k = 0.4, xmid = 5), sigma = 0,
    group = g,
    group_effects = list(Stress = c(Asym = -4)), seed = 11
  )
  expect_gt(mean(d$truth[d$group == "Control"]), mean(d$truth[d$group == "Stress"]))
})

test_that("soil teaching datasets cover retention and sorption", {
  wr <- nl_data("soil_water_retention")
  ps <- nl_data("soil_p_sorption")
  expect_equal(nrow(wr), 135)
  expect_equal(nrow(ps), 108)
  expect_true(all(c("pressure_head_kPa", "water_content_cm3_cm3") %in% names(wr)))
  expect_true(all(c("solution_P_mg_L", "sorbed_P_mg_kg") %in% names(ps)))
})

test_that("advanced soil and physiology model cards are registered", {
  m <- nl_models()$model
  expect_true(all(c("van_genuchten", "langmuir", "freundlich",
                    "nonrectangular_hyperbola", "substrate_inhibition") %in% m))
})

test_that("multistart adapter returns an nlrfit when available", {
  skip_if_not_installed("nls.multstart")
  d <- nl_data("okra_growth_means")
  z <- nl_multistart(
    fruit_length ~ Asym * exp(-exp(-k * (day_after_flowering - xmid))),
    data = d,
    start_lower = c(Asym = 12, k = 0.05, xmid = 0),
    start_upper = c(Asym = 25, k = 1.5, xmid = 10),
    iter = 20, lhstype = "shotgun", seed = 101
  )
  expect_s3_class(z, "nlrfit")
})

test_that("curvature and confidence-region adapters fail informatively or return", {
  d <- nl_data("okra_growth_means")
  f <- nl_fit(data=d, model="gompertz", response="fruit_length",
              predictor="day_after_flowering", engine="nls")
  if (requireNamespace("IPEC", quietly = TRUE)) {
    expect_s3_class(nl_curvature(f), "nlr_curvature")
  } else {
    expect_error(nl_curvature(f), "IPEC")
  }
  if (requireNamespace("nlstools", quietly = TRUE)) {
    expect_s3_class(nl_confregion(f, n=25), "nlr_confregion")
  } else {
    expect_error(nl_confregion(f), "nlstools")
  }
})
