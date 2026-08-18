test_that("optional backends fail informatively when absent", {
 if(!requireNamespace("robustbase",quietly=TRUE)) expect_error(nl_robust(y~a*x,data.frame(x=1:3,y=1:3),list(a=1)),"robustbase")
 if(!requireNamespace("brms",quietly=TRUE)) expect_error(nl_bayes(y~x,data.frame(x=1:3,y=1:3),prior=1),"brms")
})
