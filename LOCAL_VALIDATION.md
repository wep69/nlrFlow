# Detailed local validation protocol for nlrFlow 0.3.0.9000

Target platform: Windows 10/11 with R >= 4.2. Use a clean library whenever possible.

## 1. Prepare paths

```powershell
$Pkg = "D:\temp\nlrFlow_0.3.0.9000"
$Lib = "D:\temp\nlrFlow-r-lib"
New-Item -ItemType Directory -Force $Lib | Out-Null
```

Confirm R is visible:

```powershell
R --version
Rscript --version
```

If not, call the full path to `R.exe`/`Rscript.exe` or add the matching R `bin` directory to PATH.

## 2. Install core development dependencies

```r
install.packages(c(
  "devtools", "roxygen2", "testthat", "rcmdcheck", "knitr", "rmarkdown",
  "ggplot2", "patchwork", "gt", "writexl"
))
```

## 3. Install scientific optional backends

Install only the capabilities you intend to validate, but a full release check should include:

```r
install.packages(c(
  "minpack.lm", "nls.multstart", "GA", "nlme", "robustbase", "quantreg",
  "loo", "saemix", "nlstools", "IPEC", "deSolve", "rxode2", "nlmixr2",
  "nlraa", "drc", "emmeans", "qrNLMM", "RTMB", "BayesRTMB",
  "ctsmTMB", "DiceKriging", "reticulate", "webshot2", "shiny", "vdiffr"
))
```

For Bayesian Stan workflows install/configure `brms` and `cmdstanr` according to their current toolchain requirements.

## 4. Configure PySR for block 64

PySR is optional and is called through `reticulate`. Use a dedicated Python environment rather than the system Python. Example:

```r
library(reticulate)
virtualenv_create("nlrflow-pysr")
py_install("pysr", envname = "nlrflow-pysr", pip = TRUE)
use_virtualenv("nlrflow-pysr", required = TRUE)
py_module_available("pysr")
```

Record the Python, PySR and Julia/backend versions in the validation log. A successful `reticulate` installation alone does not certify PySR.


## 4A. Configure the Phase-E Julia/SciML project

Install Julia separately and verify it is visible:

```powershell
julia --version
```

From R, inspect the setup without modifying the machine:

```r
library(nlrFlow)
nl_sciml_setup(install = FALSE)
nl_sciml_info()
```

Then prepare the dedicated Julia project:

```r
setup <- nl_sciml_setup(install = TRUE)
stopifnot(isTRUE(setup$installed))
stopifnot(nl_sciml_available(check_packages = TRUE))
```

For a non-default project:

```r
Sys.setenv(NLRFLOW_JULIA_PROJECT = "D:/temp/nlrFlow-julia")
nl_sciml_setup(install = TRUE, env_dir = Sys.getenv("NLRFLOW_JULIA_PROJECT"))
```

Archive the resulting Julia `Project.toml` and `Manifest.toml`, plus `julia --version`, `sessionInfo()` and the validation seeds. The runner must use the same project that was validated.

## 5. Regenerate documentation

```powershell
Rscript -e ".libPaths('$Lib'); devtools::document('$Pkg')"
```

Inspect changes to `NAMESPACE` and `man/`. Unexpected export removals are release-blocking.

## 6. Run package tests

```powershell
Rscript -e ".libPaths('$Lib'); devtools::test('$Pkg', reporter='summary')"
```

Phase-D tests are in `tests/testthat/test-phase-d1-core.R` and `test-phase-d2-discovery.R`; Phase-E source-contract tests are in `tests/testthat/test-phase-e-sciml.R`.

## 7. Core numerical golden tests

For each adapter, fit a frozen problem both directly and through `nlrFlow`. Compare coefficients, fitted values, objective/log-likelihood and predictions within predeclared tolerances. Required direct engines include:

- `stats::nls`;
- `minpack.lm::nlsLM`;
- `nlme::gnls`;
- `robustbase::nlrob`;
- `quantreg::nlrq`;
- `nlme::nlme`;
- `saemix`;
- `brms`;
- `qrNLMM::QRNLMM`;
- `RTMB`;
- `BayesRTMB`;
- `ctsmTMB`;
- PySR for symbolic-search smoke tests.

## 8. Data integrity and experimental units

```r
library(nlrFlow)
raw <- nl_data("okra_growth_raw")
means <- nl_data("okra_growth_means")
stopifnot(nrow(raw) == 530L, nrow(means) == 10L)
```

Verify that raw okra rows are not falsely treated as repeated measurements of a longitudinal subject: the supplied raw script has no subject identifier.

## 9. Conformal validation

Use frozen simulated datasets under exchangeability to assess empirical marginal coverage over >= 1000 repetitions. Repeat with clustered data for `nl_conformal_group()` and verify that whole clusters, not individual rows, are split. Report coverage and mean interval width.

## 10. Measurement-error and mean-variance simulation

Simulate known nonlinear curves with controlled predictor and response error. For `nl_measurement_error()`, verify parameter bias as measurement error increases and compare against naive NLS. For `nl_mean_variance()`, simulate known variance functions and assess recovery, CI coverage and convergence.

## 11. Censoring/truncation validation

Simulate exact, left-, right- and interval-censored outcomes and compare likelihood/objective values against an independent implementation. For truncation, verify normalization constants numerically.

## 12. Identifiability validation

Use models with known full rank and deliberately confounded/redundant parameterizations. Confirm that `nl_structural_identify()` is reported as a local sensitivity-rank screen. Do not use it as evidence of global structural identifiability. For ODE models requiring a proof, cross-check in `StructuralIdentifiability.jl`.

## 13. Sensitivity validation

Validate Morris/Sobol outputs on standard analytic benchmark functions with known or published indices. Freeze random seeds and report Monte Carlo uncertainty/stability across sample sizes.

## 14. Optimal-design validation

For a simple logistic/Gompertz model, compare `nl_design()` information matrices and D/A/E criteria with an independent numerical calculation. Repeat after perturbing parameter guesses. Verify `nl_next_measurement()` after refitting rather than treating a local design as parameter-free.

## 15. State-space validation

Fit a frozen continuous-time model directly in `ctsmTMB` and through `nl_state_space()`. Compare objective values, estimated parameters, filtered states and uncertainty.

## 16. GP discrepancy and surrogate validation

Use a mechanistic model with a known smooth omitted component. Verify that the residual GP detects structure without changing the meaning of the original mechanistic parameter estimates. For surrogates, require held-out RMSE/MAE and visual residual checks before use in optimization or uncertainty propagation.

## 17. Cubature-like propagation and ABC

Compare `nl_propagate()` against high-replication Monte Carlo for several nonlinear transformations. For `nl_abc()`, verify posterior recovery on small models with an available exact/likelihood reference and explore sensitivity to tolerance and summary statistics.

## 18. Symbolic regression validation

Run PySR on synthetic datasets where the generating equation is known and on the package domain datasets. Record search space, operators, seed, complexity limit and elapsed evaluations. Treat output as candidate equations only.

Every symbolic candidate that proceeds scientifically must pass `nl_validate_candidate()` with domain-specific constraints and must be compared against established registered equations.

## 19. Model discrimination and sequential discovery

Construct frozen scenarios with two or more plausible generating models. Verify:

1. invalid candidates are removed or clearly marked;
2. non-nested models are not compared with an invalid LRT;
3. predictive disagreement identifies regions where the curves separate;
4. adding the suggested observation and refitting improves discrimination on average over repeated simulations.

## 20. Bayesian validation

Inspect prior predictive checks, R-hat, effective sample size, divergences, posterior predictive checks and Pareto-k. Validate `nl_confint(..., "posterior")`, prediction intervals and `nl_bayes_compare()` against direct `brms`/`loo` outputs.

## 21. Phase-E Neural ODE validation

Use a synthetic ODE with known dynamics before using agronomic observations. Require:

1. recovery of held-out trajectories;
2. repeated-seed stability;
3. training-loss trace without silent solver failures;
4. comparison with a conventional parametric or mechanistic ODE;
5. extrapolation beyond the training interval reported separately from interpolation.

Run the package fruit/crop examples using an executed model, not only `dry_run=TRUE`, and store the returned `julia.log`.

## 22. UDE and missing-physics validation

Construct at least three frozen simulation scenarios:

- correctly specified mechanism with zero missing term;
- mechanism with a known omitted rate term;
- incorrect mechanistic structure that cannot be repaired parsimoniously.

For every scenario compare mechanistic-only, Neural ODE and UDE fits. Repeat seeds and regularization strengths. Verify that `nl_missing_physics()` is evaluated along the fitted trajectory and that a large neural fraction is treated as a warning about mechanistic adequacy rather than automatic biological discovery.

Before publication, demonstrate recovery of the known omitted term under increasing noise and decreasing sampling density.

## 23. Richards PINN validation

The `richards_1d` adapter is release-blocking for the soil-water claim. Validate it against an independent numerical Richards-equation solver over multiple hydraulic parameter sets.

At minimum vary:

- texture/hydraulic parameter regimes;
- rainfall/irrigation boundary forcing;
- ET forcing;
- sensor depths;
- temporal sparsity;
- observation noise;
- initial-condition misspecification.

Compare depth × time water content, hydraulic parameters when estimation is enabled, mass-balance behavior, RMSE and the physics-residual diagnostic. Do not accept a visually smooth heatmap as validation.

## 24. UDE → symbolic discovery validation

Use a synthetic UDE with a known omitted term. Freeze:

- symbolic operators;
- maximum complexity;
- random seed;
- training/validation/extrapolation ranges.

The expected output is a Pareto set, not a single asserted law. Each selected expression must then enter `nl_validate_candidate()`, `nl_discriminate()` and held-out/new-experiment tests. Report dimensional/shape constraints explicitly.

## 25. Dynamic optimal measurement validation

For `nl_dynamic_design()`:

1. fit competing dynamic models;
2. select the suggested times;
3. simulate or collect those observations;
4. refit all models;
5. quantify change in parameter uncertainty, predictive uncertainty or model discrimination;
6. compare against random/equidistant designs over repeated simulations.

This closes the loop; merely plotting high design scores is insufficient.

## 26. Dynamic control validation

For `nl_control()` compare at least:

- zero/unchanged control;
- constant control;
- a simple agronomic rule-based schedule;
- the optimized schedule.

Perturb weather/covariate trajectories and fitted parameters to test sensitivity. Confirm all lower/upper control bounds. A model-conditional schedule must not be described as a field recommendation unless economic, operational, crop-safety and other relevant constraints have been represented and independently validated.

## 27. Examples and all 41 vignettes

```powershell
Rscript -e ".libPaths('$Lib'); devtools::run_examples('$Pkg')"
Rscript -e ".libPaths('$Lib'); devtools::build_vignettes('$Pkg')"
```

Heavy Phase-E vignette chunks may be `eval=FALSE` in routine documentation builds, but a **separate full SciML validation run** must execute the code paths in vignettes 31–41 before release of those capabilities.

No vignette may depend on an optional backend without either an explicit availability guard or an intentional non-evaluated teaching chunk.

## 28. Publication figures and tables

Generate representative outputs from every object class supported by `nl_plot()`/`nl_table()`.

For Phase E specifically inspect:

- observed + predicted dynamic trajectories;
- UDE known/neural/total rate decomposition;
- Richards time × depth heatmap with observed residual overlay;
- symbolic error × complexity Pareto front;
- SciML diagnostic/training plots;
- dynamic-design score plot and selected points;
- bounded control schedule and resulting trajectory.

Verify axis labels/units, observed-data visibility, uncertainty representation when available, clipping, group separation, vector editability and 600-dpi raster export. Open every DOCX/XLSX/PDF/HTML/LaTeX table export manually.

## 29. Reference and provenance audit

Verify that:

```r
# conceptual checks after installation
nrow(nl_data("sciml_crop_growth")) == 180L
nrow(nl_data("sciml_fruit_growth")) == 132L
nrow(nl_data("sciml_soil_water")) == 105L
```

All six `sciml_*` datasets must remain labelled synthetic/non-empirical. Recompute SHA-256 hashes and compare with `inst/metadata/dataset_manifest.csv`.

Check that every vignette citation is present in `references/references.bib`, `references/references.ris` and `inst/metadata/reference_metadata.csv`. Preserve the distinction between peer-reviewed publications and preprints.

## 30. Build and CRAN-style check

```powershell
Set-Location (Split-Path $Pkg)
R CMD build "$Pkg"
R CMD check --as-cran nlrFlow_0.3.0.9000.tar.gz
```

Prefer `Status: OK`. Any package-code ERROR is release-blocking. Warnings/notes must be individually justified rather than ignored.

## 31. Release decision

Do not label version 0.3.0.9000 CRAN-ready or Phase-E numerically certified until core tests, claimed optional backends, all 41 vignettes, frozen simulations, SciML recovery/ablation tests, output validation and `R CMD check --as-cran` pass in a clean environment. Preserve complete logs, `sessionInfo()`, Julia `Project.toml`/`Manifest.toml`, Julia version and all random seeds.
