test_that("SciML backend map covers blocks 68 through 74", {
  x <- nl_sciml_info()
  expect_true(all(68:74 %in% x$block))
  expect_true(all(c("package","role","required") %in% names(x)))
})

test_that("SciML setup is non-invasive by default", {
  x <- nl_sciml_setup(install = FALSE, env_dir = tempdir())
  expect_false(x$installed)
  expect_true("NeuralPDE" %in% x$packages)
  expect_true("SymbolicRegression" %in% x$packages)
})

test_that("new SciML teaching datasets are loadable and finite", {
  nms <- c("sciml_crop_growth","sciml_fruit_growth","sciml_soil_water",
           "sciml_fertility_dynamic","sciml_physiology_dynamic","sciml_irrigation_horizon")
  for(nm in nms) {
    d <- nl_data(nm)
    expect_gt(nrow(d), 0)
    num <- vapply(d, is.numeric, logical(1))
    expect_true(all(is.finite(as.matrix(d[num]))))
  }
})

test_that("Neural ODE dry-run preserves a complete execution specification", {
  d <- nl_data("sciml_fruit_growth")
  d <- subset(d, fruit_id == unique(d$fruit_id)[1])
  z <- nl_neural_ode(d,"day_after_set","fruit_mass_g",c("temperature_C","soil_water_rel"),dry_run=TRUE)
  expect_s3_class(z,"nlr_sciml_spec")
  expect_identical(z$mode,"neural_ode")
  expect_equal(z$config$states,"fruit_mass_g")
})

test_that("UDE templates validate scientific inputs", {
  d <- nl_data("sciml_crop_growth")
  d <- subset(d, plot_id == unique(d$plot_id)[1])
  z <- nl_ude(d,"day","biomass_g_m2",c("temperature_C","PAR_MJ_m2_d","soil_water_rel","nitrogen_rel"),
              template="crop_growth_rue",known_parameters=c(RUE=2.8,Topt=26,Twidth=10,respiration=.01),dry_run=TRUE)
  expect_s3_class(z,"nlr_sciml_spec")
  expect_error(nl_ude(d,"day","biomass_g_m2",c("temperature_C","PAR_MJ_m2_d"),
                      template="crop_growth_rue",known_parameters=c(RUE=2.8,Topt=26,Twidth=10,respiration=.01),dry_run=TRUE),
               "requires covariate")
})

test_that("PINN dry-run validates Richards hydraulic parameters", {
  d <- nl_data("sciml_soil_water")
  z <- nl_pinn(d,"richards_1d","day","theta_cm3_cm3",depth="depth_cm",
               covariates=c("rain_mm_d","ET0_mm_d"),
               parameters=c(theta_r=.06,theta_s=.46,alpha=.035,n=1.55,Ks=8),dry_run=TRUE)
  expect_s3_class(z,"nlr_sciml_spec")
  expect_error(nl_pinn(d,"richards_1d","day","theta_cm3_cm3",depth="depth_cm",
                       parameters=c(theta_r=.06,theta_s=.46)),"requires")
})

test_that("missing-physics decomposition produces interpretable fractions", {
  d <- data.frame(time=1:4,state="biomass",known=c(1,1,1,1),neural=c(.1,.2,.8,.1),total=c(1.1,1.2,1.8,1.1))
  u <- structure(list(decomposition=d),class="nlr_ude")
  z <- nl_missing_physics(u,threshold=.30)
  expect_s3_class(z,"nlr_missing_physics")
  expect_true(any(z$decomposition$important))
  expect_true(all(z$decomposition$neural_fraction >= 0))
})

test_that("UDE symbolic discovery can be inspected without Julia", {
  d <- nl_data("sciml_fruit_growth")
  d <- subset(d,fruit_id==unique(d$fruit_id)[1])
  u <- nl_ude(d,"day_after_set","fruit_mass_g",c("temperature_C","soil_water_rel"),
              template="fruit_growth",known_parameters=c(r=.2,K=200),dry_run=TRUE)
  s <- nl_ude_discover(u,c("temperature_C","soil_water_rel"),dry_run=TRUE)
  expect_s3_class(s,"nlr_sciml_spec")
  expect_identical(s$mode,"ude_symbolic")
})

test_that("SciML diagnostics flag large UDE neural contribution", {
  p <- data.frame(time=0:2,y_observed=c(1,2,3),y_predicted=c(1,2,3))
  d <- data.frame(time=0:2,state="y",known=c(1,.2,.1),neural=c(.1,.8,.9),total=c(1.1,1,1))
  u <- structure(list(predictions=p,time="time",states="y",decomposition=d,training=data.frame(iteration=1:2,loss=c(.2,.02))),class="nlr_ude")
  z <- nl_sciml_diagnose(u,thresholds=c(rmse_ratio=.2,physics_loss=.05,neural_fraction=.5))
  expect_s3_class(z,"nlr_sciml_diagnostics")
  expect_true("mean_neural_fraction" %in% z$table$metric)
})

test_that("dynamic design honors spacing and supports Richards long output", {
  f <- structure(list(predictions=data.frame(time=0:10,y_predicted=(0:10)^2),time="time",states="y"),class="nlr_neural_ode")
  z <- nl_dynamic_design(f,0:10,n_points=3,min_distance=2)
  expect_length(z$selected,3)
  expect_true(all(diff(sort(z$selected)) >= 2))
  long <- expand.grid(time=0:5,depth=c(10,20)); long$predicted <- with(long,.3+.01*time-.001*depth)
  p <- structure(list(predictions=long,time="day",response="theta_cm3_cm3",problem="richards_1d"),class="nlr_pinn")
  expect_s3_class(nl_dynamic_design(p,0:5,2),"nlr_dynamic_design")
  zd <- nl_dynamic_design(p,c(10,20),2,dimension="depth")
  expect_identical(zd$dimension,"depth")
})

test_that("dynamic control dry-run enforces vectorized bounds", {
  d <- nl_data("sciml_fruit_growth"); d <- subset(d,fruit_id==unique(d$fruit_id)[1])
  u <- nl_ude(d,"day_after_set","fruit_mass_g",c("temperature_C","soil_water_rel"),template="fruit_growth",known_parameters=c(r=.2,K=200),dry_run=TRUE)
  z <- nl_control(u,"soil_water_rel",seq(0,30,5),.45,.95,"fruit_mass_g",dry_run=TRUE)
  expect_s3_class(z,"nlr_sciml_spec")
  expect_equal(length(z$config$lower),length(z$config$control_times))
})

test_that("Neural ODE and PINN dry-run expose regularization and modern collocation settings", {
  d <- nl_data("sciml_fruit_growth"); d <- subset(d, fruit_id == unique(d$fruit_id)[1])
  n <- nl_neural_ode(d,"day_after_set","fruit_mass_g",c("temperature_C","soil_water_rel"),weight_decay=1e-5,dry_run=TRUE)
  expect_equal(n$config$weight_decay,1e-5)
  p <- nl_pinn(d,"logistic_growth","day_after_set","fruit_mass_g",parameters=c(r=.2,K=200),strategy="weighted_interval",collocation_points=600,dry_run=TRUE)
  expect_identical(p$config$strategy,"weighted_interval")
  expect_equal(p$config$collocation_points,600L)
})

test_that("SciML diagnostics compute data-fit RMSE metrics", {
  f <- structure(list(predictions=data.frame(time=0:2,y_observed=c(1,2,3),y_predicted=c(1.1,2.1,2.9)),time="time",states="y"),class="nlr_neural_ode")
  z <- nl_sciml_diagnose(f)
  expect_true(any(grepl("RMSE_ratio:y",z$table$metric,fixed=TRUE)))
  long <- structure(list(predictions=data.frame(time=rep(0:2,2),depth=rep(c(10,20),each=3),observed=c(.3,.31,.32,.28,.29,.30),predicted=c(.3,.30,.31,.28,.30,.30)),response="theta",diagnostics=data.frame(metric="physics_loss",value=.01)),class="nlr_pinn")
  z2 <- nl_sciml_diagnose(long)
  expect_true(any(grepl("RMSE_ratio:theta",z2$table$metric,fixed=TRUE)))
})

test_that("dynamic-design uncertainty requires an ensemble", {
  f <- structure(list(predictions=data.frame(time=0:5,y_predicted=0:5),time="time",states="y"),class="nlr_neural_ode")
  expect_error(nl_dynamic_design(f,0:5,2,criterion="uncertainty"),"ensemble")
})

test_that("curvature design handles irregular candidate spacing", {
  tt <- c(0,1,4,10)
  f <- structure(list(predictions=data.frame(time=tt,y_predicted=tt^2),time="time",states="y"),class="nlr_neural_ode")
  z <- nl_dynamic_design(f,tt,n_points=2,criterion="curvature")
  expect_true(all(is.finite(z$scores$score)))
  expect_equal(z$scores$score[c(1,4)],c(0,0))
  expect_true(all(z$scores$score[2:3] > 0))
})

test_that("dynamic control requires a schedule covering the fitted horizon start", {
  d <- nl_data("sciml_fruit_growth"); d <- subset(d,fruit_id==unique(d$fruit_id)[1])
  u <- nl_ude(d,"day_after_set","fruit_mass_g",c("temperature_C","soil_water_rel"),template="fruit_growth",known_parameters=c(r=.2,K=200),dry_run=TRUE)
  t0 <- min(d$day_after_set); t1 <- max(d$day_after_set)
  expect_error(nl_control(u,"soil_water_rel",seq(t0+5,t1,5),.45,.95,"fruit_mass_g",dry_run=TRUE),"begin at or before")
  expect_error(nl_control(u,"soil_water_rel",c(t0,t1+5),.45,.95,"fruit_mass_g",dry_run=TRUE),"cannot extend")
})

test_that("symbolic discovery defaults to reproducibility-focused serial search", {
  d <- nl_data("sciml_fruit_growth"); d <- subset(d,fruit_id==unique(d$fruit_id)[1])
  u <- nl_ude(d,"day_after_set","fruit_mass_g",c("temperature_C","soil_water_rel"),template="fruit_growth",known_parameters=c(r=.2,K=200),dry_run=TRUE)
  s <- nl_ude_discover(u,c("temperature_C","soil_water_rel"),seed=11,dry_run=TRUE)
  expect_identical(s$config$parallelism,"serial")
  expect_true(s$config$deterministic)
  expect_equal(s$config$seed,11L)
  expect_error(nl_ude_discover(u,c("temperature_C","soil_water_rel"),parallelism="multithreading",deterministic=TRUE,dry_run=TRUE),"requires parallelism='serial'")
})
