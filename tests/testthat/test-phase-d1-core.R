test_that("local structural screen finds full rank in a simple exponential model", {
  d <- data.frame(x=seq(0,5,length.out=20), y=NA_real_)
  z <- nl_structural_identify(y ~ A*(1-exp(-k*x)), d, c(A=10,k=.5))
  expect_equal(z$rank, 2L)
})

test_that("sensitivity methods return named parameter results", {
  R <- matrix(c(5,15,.1,1),2,2,byrow=TRUE,dimnames=list(c("A","k"),c("lower","upper")))
  z <- nl_sensitivity(function(p) p["A"]*(1-exp(-p["k"]*(1:5))),R,"local")
  expect_equal(z$indices$parameter,c("A","k"))
})

test_that("local optimal design selects requested unique points", {
  d <- data.frame(x=0,y=0)
  z <- nl_design(y~A*(1-exp(-k*x)),d,c(A=10,k=.5),"x",seq(0,5,.25),3)
  expect_length(z$selected,3)
  expect_equal(length(unique(z$selected)),3)
})

test_that("cubature propagation returns finite uncertainty", {
  z <- nl_propagate(c(A=10,k=.5),diag(c(.4,.01)),function(b)b["A"]*b["k"])
  expect_true(all(is.finite(z$se)))
})

test_that("ABC preserves parameter names and acceptance fraction", {
  prior <- function(n)cbind(A=runif(n,5,15),k=runif(n,.1,1))
  sim <- function(p)p["A"]*(1-exp(-p["k"]*(1:4)))
  z <- nl_abc(c(1,3,5,7),sim,prior,function(x)c(mean(x),max(x)),n_sim=200,tolerance=.05,seed=1)
  expect_equal(colnames(z$accepted),c("A","k"))
  expect_equal(nrow(z$accepted),10)
})
