# nlrFlow

`nlrFlow` 0.3.0.9000 is an integrated scientific workflow for nonlinear regression and dynamic scientific modelling in R. The package implements a 74-block architecture spanning classical/generalized NLS, resistant and quantile methods, nonlinear mixed effects, Bayesian inference, bootstrap/conformal prediction, measurement error, joint mean-variance models, censoring/truncation, automatic differentiation, stochastic state-space models, sensitivity and optimal design, symbolic equation discovery, Neural ODEs, Universal Differential Equations, physics-informed neural networks, missing-process discovery, and dynamic experimental design/control.

The scientific objective is not to hide methodology behind a single black-box estimator. `nlrFlow` keeps a stable workflow while exposing the estimator, assumptions, uncertainty method, experimental unit, and optional backend used at each step.

## Current scope

- **74 scientific blocks** documented in `inst/metadata/74_BLOCKS_IMPLEMENTATION.csv`.
- **83 exported functions** with at least three examples in the package documentation/vignette collection.
- **24 registered nonlinear model families**, including growth, dose-response, plateau, sorption, soil-water retention and physiological response functions.
- **41 English vignettes** from foundations through the complete UDE → symbolic candidate → next-experiment cycle.
- **Fourteen frozen teaching datasets**, including six explicitly simulated Phase-E dynamic datasets for crop/fruit growth, soil water, fertility, physiology and irrigation.
- Publication-oriented plotting, tables, reports and audit trails.

## Scientific design principles

1. Preserve replication, cluster and experimental-unit information.
2. Separate nonlinear mean structure from residual distribution, variance and dependence.
3. Use likelihood-ratio tests only for genuinely nested models.
4. Treat starting values, convergence and identifiability as part of inference.
5. Quantify uncertainty for primary parameters, predictions and derived biological quantities.
6. Use established backends where they add validated numerical methodology; use transparent internal implementations where the algorithm can be audited directly.
7. Distinguish structural identifiability from practical/local identifiability.
8. Treat symbolic regression as hypothesis generation, never as automatic mechanistic truth.
9. Make sequential design decisions explicit and reproducible.
10. Record method choices, constraints and failed alternatives in the audit trail.

## Installation

### From GitHub (recommended)

```r
# Install remotes if not already installed
install.packages("remotes")

# Install from GitHub WITHOUT building vignettes (fast)
remotes::install_github("wep69/nlrFlow", build_vignettes = FALSE)

# Install from GitHub WITH vignettes (slower, requires Pandoc)
remotes::install_github("wep69/nlrFlow", build_vignettes = TRUE)
```

### Using pak (faster alternative)

```r
install.packages("pak")

# Without vignettes
pak::pak("wep69/nlrFlow")

# With vignettes (requires Pandoc)
pak::pak("wep69/nlrFlow", dependencies = TRUE)
```

### Verify installation

```r
library(nlrFlow)
packageVersion("nlrFlow")
```

## Quick start

```r
okra <- nl_data("okra_growth_means")
fits <- nl_fit_many(okra, "fruit_length", "day_after_flowering",
                    c("logistic", "gompertz", "richards"), engine = "nls")
nl_compare(fits)
best <- nl_select(fits)
nl_diagnose(best)
nl_derive(best)
nl_plot(best)
```

For formal inference on the okra case, use `okra_growth_raw` whenever the individual observations are relevant to the inferential target. The mean dataset is retained for descriptive and teaching demonstrations, not as a silent replacement for replication.

## Phase D: advanced inference and experimental learning

The 2026 expansion adds three complementary workflows.

### Advanced nonlinear inference

```r
# distribution-free prediction interval
cp <- nl_conformal(fit, newdata = newdata, level = 0.95)

# nonlinear errors-in-variables
eiv <- nl_measurement_error(...)

# global sensitivity
gsa <- nl_sensitivity(fun, bounds, method = "sobol")

# local optimal design
des <- nl_design(model_fun, theta, candidate_x, criterion = "D")
```

### Mechanistic uncertainty and dynamics

```r
# automatic differentiation / Laplace-ready model
ad <- nl_ad(objective, parameters)

# stochastic continuous-time model, optional ctsmTMB backend
ss <- nl_state_space(model, data)

# residual GP discrepancy diagnostic
gp <- nl_gp_discrepancy(fit, predictor = "x")
```

### Knowledge-guided equation discovery

```r
# optional PySR search: hypotheses only
sr <- nl_symbolic(data, response = "y", predictors = "x")

# validate known and candidate equations under the same workflow
disc <- nl_discover(data, "y", "x",
                    c("gompertz", "logistic", "richards"),
                    constraints = list(positive = TRUE))

# discriminate surviving models
cmp <- nl_discriminate(disc)

# choose a next measurement that maximizes predictive disagreement
next_x <- nl_sequential_discovery(cmp, candidate_x = seq(1, 25, by = 0.5))
```



## Phase E: Scientific Machine Learning, blocks 68–74

The optional SciML layer is intended for dynamic questions where a conventional nonlinear curve or deterministic ODE is insufficient.

```r
# inspect without installing or executing Julia
nl_sciml_info()
nl_sciml_setup(install = FALSE)

# Neural ODE specification for one fruit trajectory
fruit <- nl_data("sciml_fruit_growth")
fruit1 <- subset(fruit, fruit_id == unique(fruit_id)[1])
nod <- nl_neural_ode(
  fruit1, "day_after_set", "fruit_mass_g",
  c("temperature_C", "soil_water_rel"),
  dry_run = TRUE
)

# UDE: known fruit-growth term + learnable correction
ude <- nl_ude(
  fruit1, "day_after_set", "fruit_mass_g",
  c("temperature_C", "soil_water_rel"),
  template = "fruit_growth",
  known_parameters = c(r = 0.20, K = 200),
  weight_decay = 1e-6,
  dry_run = TRUE
)

# PINN / Richards-equation specification
soil <- nl_data("sciml_soil_water")
pinn <- nl_pinn(
  soil, "richards_1d", "day", "theta_cm3_cm3",
  depth = "depth_cm", covariates = c("rain_mm_d", "ET0_mm_d"),
  parameters = c(theta_r=.06, theta_s=.46, alpha=.035, n=1.55, Ks=8),
  dry_run = TRUE
)
```

After an executed UDE, the scientific-discovery cycle is:

```r
miss <- nl_missing_physics(ude_fit)
candidates <- nl_ude_discover(ude_fit,
                              predictors = c("temperature_C", "soil_water_rel"))
diag <- nl_sciml_diagnose(ude_fit)
next_times <- nl_dynamic_design(ude_fit, candidates = 0:100, n_points = 4)
```

`nl_ude_discover()` does not declare a discovered law. Symbolic expressions remain hypotheses until they pass the existing `nl_validate_candidate()`, `nl_discriminate()` and new-experiment checks.

### Julia/SciML setup

The core package remains usable without Julia. For blocks 68–74, install Julia separately, then from R:

```r
nl_sciml_setup(install = TRUE)
nl_sciml_available(check_packages = TRUE)
```

The dedicated project defaults to `~/.nlrFlow/julia`. A custom project can be selected with `Sys.setenv(NLRFLOW_JULIA_PROJECT = "...")`. Preserve the resulting Julia `Project.toml` and `Manifest.toml` with the local validation log for reproducibility.


## Teaching datasets

The source snapshot includes the original nonlinear-regression teaching datasets plus six frozen Phase-E SciML simulations: crop growth, fruit growth, soil-water profiles, dynamic soil-fertility/N data, plant-physiology dynamics and an irrigation horizon. Simulated datasets are explicitly identified in `inst/metadata/DATA_PROVENANCE.json`; they are teaching data, not empirical agronomic claims.

## Optional backends

Heavy or specialized engines remain in `Suggests`. Important additions are `RTMB`, `BayesRTMB`, `qrNLMM`, `ctsmTMB`, `DiceKriging` and `reticulate`/PySR. Their absence does not prevent base/core NLS workflows from loading. `nl_doctor()` and `nl_capabilities()` report availability.

## Publication output

`nl_plot()` supports both the original fitted-model objects and Phase-D diagnostic/design objects. `nl_save_plot()` exports vector PDF/SVG and high-resolution raster formats. `nl_table()` returns editable objects and can export CSV, XLSX, HTML, PDF, PNG, LaTeX, RTF and DOCX when optional rendering dependencies are installed.

## Validation status

Static source gates pass for all 83 exported functions in this construction environment. R/Rscript is not installed here, so numerical execution, optional-backend golden tests, vignette rendering and `R CMD check --as-cran` are explicitly deferred to local validation. See `VALIDATION.md` and `LOCAL_VALIDATION.md`.
