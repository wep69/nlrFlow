test_that("registry is coherent", {
  x <- nl_models(); expect_true(nrow(x) >= 24); expect_true(all(c("richards","mitscherlich","nonrectangular_hyperbola","langmuir","van_genuchten","brain_cousens") %in% x$model))
})
test_that("teaching datasets load", { expect_equal(nrow(nl_data("okra_growth_raw")),530); expect_equal(length(unique(nl_data("okra_growth_raw")$day_after_flowering)),10) })
