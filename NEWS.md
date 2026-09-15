# nlrFlow 0.3.0.9000

## Audit response (RELATORIO-AO-AUTOR, items 1-12)

* **Item 1 (seed hygiene).** Every exported function with a `seed` argument now leaves the caller's random stream untouched: the ten functions that draw from R's generator save and restore `.Random.seed` (`.nl_rng_state()` / `.nl_rng_restore()`, plus the `.nl_with_seed()` wrapper), so a simulation loop that passes a fixed seed to a package function still draws new data per iteration. The Julia/PySR-backed functions forward `seed` to the backend and never draw from R.
* **Item 2 (constraints).** Unknown constraint names are rejected with the accepted keys listed, and documented synonyms (`nonnegative`, `monotone`) are mapped instead of ignored.
* **Item 3 (diagnostics table).** `nl_table(type = "diagnostics")` and `nl_report()` no longer fail on a plain `nls`/`nlrfit` object; the diagnostics data frame has one value per metric.
* **Item 4 (censored fits).** `nl_censored()` derives its residual scale from the NLS fit and searches a multi-start grid of scales, instead of accepting an infeasible point with `convergence = 0`; the number of starts is reported in `$n_starts`.
* **Item 5 (wrong object type).** `nl_sequential_discovery()` and `nl_discriminate()` validate their `fits` argument with an actionable message instead of returning an empty result.
* **Items 6-11 (backend adapters).** `nl_fit()` accepts engines registered with `nl_register_engine()`; `nl_saemix()` works with both `parameter.names` and `name.modpar`; `nl_dynamic()` finds `nlmixr2()` in either `nlmixr2est` or `nlmixr2`; `engine = "gnls"` builds the default `params` itself; `nl_dynamic_design()` refuses a `dry_run` specification; `nl_capabilities()` verifies the Julia packages before advertising SciML as available.
* **Item 12 (interface annoyances).**
  * `nls` bounds are passed only when finite, so the repeated "bounds ignored" warnings are gone.
  * `vcov()`, `logLik()`, `AIC()`, `BIC()`, `nobs()`, `deviance()`, `df.residual()`, `confint()`, `anova()`, `predict()` and `model.frame()` are registered for `nlrfit`; `predict()` refuses `interval`/`se.fit` and points to `nl_predict()`, and `model.frame()` returns a data frame instead of the registered model name.
  * `nl_robust()` names its bounds from `names(start)`, replicates scalars, selects `algorithm = "port"` when finite bounds are given, and explains that the global-search methods need finite bounds.
  * `nl_table(render = "latex")` writes the LaTeX file; all file-rendering modes verify that the file exists.
  * `nl_plot()` gained `xlab`/`ylab`, and `x` no longer has to be guessed from an axis label.
  * `nl_audit()` rejects a non-numeric predictor, listing the accepted numeric columns.
  * Discovery and validation grids no longer extrapolate below zero for non-negative predictors, and rejected candidates report the failing check in the `error` column.
  * `nl_ode_solve()` returns an `nlr_ode` envelope with `$solution`, `$times`, `$states`, `$parms` and `$method`, while remaining matrix-compatible through `[` and `as.data.frame()`.
* Added `tests/testthat/test-interface-contract.R` and `tests/testthat/test-numerical-golden.R` so these contracts are enforced by the test suite (160 passing assertions).

## Packaging fixes found by `R CMD check --as-cran`

* Declared `magrittr` (the `%>%` re-export) and `digest` (cache-key hashing) in `Imports`; both were used in code but absent from `DESCRIPTION`, which made the package unloadable under `--as-cran`.
* Imported the `stats` generics that `nlrfit` registers S3 methods for (`AIC`, `BIC`, `confint`, `vcov`, `logLik`, `nobs`, ...). Without the imports, loading the namespace failed with "object 'BIC' not found" whenever only the base namespace was loaded, as `R CMD check` does.
* Imported `runif`, `setNames`, `weighted.mean` from `stats` and `capture.output`, `combn`, `head`, `tail` from `utils`, and declared `.data` as a known global, removing all "no visible global function definition" notes.
* Replaced the non-ASCII box-drawing banner in `nl_wizard()` with ASCII.
* Added `.github` and `CITATION.cff` to `.Rbuildignore`, removing the two remaining build notes.
* Result: `R CMD check` reports **0 errors, 0 warnings, 0 notes** (with `--no-build-vignettes --no-manual`).

## 0.3.0.9000 features

* Expanded the architecture from 67 to 74 scientific blocks and from 72 to 83 exported functions.
* Added an optional Julia/SciML layer with Neural ODEs, Universal Differential Equations, PINNs, missing-process decomposition, UDE-to-symbolic discovery, SciML diagnostics, dynamic design and bounded dynamic control.
* Added a dedicated 1-D Richards soil-water PINN specification and publication-oriented depth × time outputs.
* Added L2 regularization for Neural ODE/UDE neural components and evaluated UDE missing-process decomposition along the fitted trajectory.
* Added a dedicated reproducible Julia project and explicit `--project` execution; custom projects can be selected with `NLRFLOW_JULIA_PROJECT`.
* Added six frozen SciML teaching datasets and eleven Phase-E vignettes spanning crop/fruit growth, soils, fertility, physiology, irrigation and the full discovery cycle.
* Expanded the bibliography from 19 to 28 synchronized records and explicitly separates peer-reviewed articles from methodological/agronomic preprints.
* Added source-level tests for blocks 68–74. R/Julia runtime certification remains a separate local release gate.

# nlrFlow 0.2.0.9000

* Expanded the scientific architecture from 44 to 67 blocks.
* Added 23 Phase-D1 functions for RTMB/BayesRTMB computation, mixed quantiles, conformal prediction, measurement error, mean-variance modelling, censoring/truncation, structural screens, sensitivity, optimal design, stochastic state-space models, GP discrepancy, surrogates, deterministic uncertainty propagation and ABC.
* Added 5 Phase-D2 functions for symbolic regression, knowledge-guided validation/discovery, model discrimination and sequential experiment discovery.
* Expanded to 30 English vignettes and synchronized publication plotting/table outputs for Phase-D objects.
* Added verified BibTeX/RIS/CSV reference metadata and an updated R/Python/Julia state-of-the-art comparison.
* Preserved explicit methodological boundaries: the resistant mixed-quantile sensitivity estimator is not cGAL; structural screening is not a proof of global identifiability; symbolic regression is hypothesis generation; sequential discovery is not claimed as exact PICS.

# nlrFlow 0.1.0.9000

* Initial development implementation of the 44-block architecture.
