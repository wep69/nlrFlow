test_that("candidate validation detects monotone exponential saturation", {
  d <- data.frame(x=seq(0,5,length.out=30)); d$y <- 10*(1-exp(-.5*d$x))
  f <- nl_fit(y~A*(1-exp(-k*x)),d,start=list(A=9,k=.4),engine="nlsLM")
  v <- nl_validate_candidate(f,"x",list(positive=TRUE,monotonic="increasing"),k=3,extrapolation=0)
  expect_true(v$pass)
})

test_that("knowledge discovery retains successful nonlinear candidates", {
  d <- data.frame(x=seq(0,5,length.out=30)); d$y <- 10*(1-exp(-.5*d$x)) + rnorm(30,0,.05)
  z <- nl_discover(d,"y","x",candidate_formulas=list(mono=y~A*(1-exp(-k*x))),candidate_starts=list(mono=c(A=9,k=.4)),engine="nlsLM",k=3)
  expect_true("mono" %in% names(z$fits))
})

test_that("model discrimination returns symmetric disagreement", {
  d <- data.frame(x=seq(0,5,length.out=30)); d$y <- 10*(1-exp(-.5*d$x)) + rnorm(30,0,.05)
  f1 <- nl_fit(y~A*(1-exp(-k*x)),d,start=list(A=9,k=.4),engine="nlsLM")
  f2 <- nl_fit(y~A*x/(K+x),d,start=list(A=11,K=1),engine="nlsLM")
  z <- nl_discriminate(list(exp=f1,mm=f2),"x",k=3)
  expect_equal(z$disagreement,t(z$disagreement),tolerance=1e-8)
})

test_that("sequential discovery selects a candidate", {
  d <- data.frame(x=seq(0,5,length.out=30)); d$y <- 10*(1-exp(-.5*d$x)) + rnorm(30,0,.05)
  f1 <- nl_fit(y~A*(1-exp(-k*x)),d,start=list(A=9,k=.4),engine="nlsLM")
  f2 <- nl_fit(y~A*x/(K+x),d,start=list(A=11,K=1),engine="nlsLM")
  z <- nl_sequential_discovery(list(exp=f1,mm=f2),d[1,,drop=FALSE],"x",seq(0,8,.1),existing=d$x,min_distance=.05)
  expect_length(z$selected,1)
})
