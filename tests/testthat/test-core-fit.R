test_that("base nls workflow fits known simulated Gompertz", {
  d <- nl_simulate("gompertz",1:25,c(Asym=18,k=.44,xmid=3.7),sigma=.05,seed=9)
  f <- nl_fit(data=d,model="gompertz",response="y",predictor="x",engine="nls")
  expect_s3_class(f,"nlrfit"); expect_lt(abs(coef(f)["Asym"]-18),1)
})
test_that("non-nested LRT is blocked", { d<-nl_data("okra_growth_means");f<-nl_fit(data=d,model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls");expect_error(nl_lrt(f,f),"blocked") })
