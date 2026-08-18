test_that("diagnostics and derivatives return expected structures", {
 d<-nl_simulate("mitscherlich",seq(0,180,15),c(Asym=8,delta=5,k=.025),sigma=.05,seed=4);f<-nl_fit(data=d,model="mitscherlich",response="y",predictor="x",engine="nls");expect_s3_class(nl_diagnose(f),"nlrdiag");expect_s3_class(nl_identify(f),"nlr_identifiability");expect_s3_class(nl_derive(f),"nlrderived")
})
