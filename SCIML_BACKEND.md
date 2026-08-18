# nlrFlow Phase-E Julia/SciML backend

Version **0.3.0.9000**, blocks **68–74**.

## 1. Why Julia is optional

The classical and Phase-D R workflows do not require Julia. Julia is used only where the SciML ecosystem adds differentiation through differential-equation solvers, NeuralPDE PINN algorithms, Lux neural components, SymbolicRegression.jl, and differentiable optimization.

## 2. Install Julia separately

Install a current Julia release using the official Julia distribution or `juliaup`. `nlrFlow` intentionally does **not** install Julia.

Verify from a terminal:

```text
julia --version
```

## 3. Inspect the setup before changing the machine

```r
library(nlrFlow)
nl_sciml_setup(install = FALSE)
nl_sciml_info()
nl_sciml_available(check_packages = FALSE)
```

## 4. Create the dedicated environment

```r
setup <- nl_sciml_setup(install = TRUE)
setup$environment
nl_sciml_available(check_packages = TRUE)
```

The default project is:

```text
~/.nlrFlow/julia
```

The setup script installs/precompiles the packages inside this project. Runtime calls explicitly use the same project through Julia's `--project` option.

For a custom location:

```r
Sys.setenv(NLRFLOW_JULIA_PROJECT = "D:/nlrFlow/julia")
nl_sciml_setup(install = TRUE, env_dir = Sys.getenv("NLRFLOW_JULIA_PROJECT"))
```

## 5. Preserve the resolved environment

After local setup, archive the generated `Project.toml` and `Manifest.toml` with:

- `julia --version`;
- `R.version.string` and `sessionInfo()`;
- `packageVersion("nlrFlow")`;
- operating system / architecture;
- CPU/GPU information if acceleration is used;
- all training seeds and solver tolerances.

The construction environment cannot generate a trustworthy Manifest because Julia is unavailable here. Do not fabricate one.

## 6. Dry-run first

Every heavy entry point supports a specification-only route. Example:

```r
fruit <- nl_data("sciml_fruit_growth")
fruit1 <- subset(fruit, fruit_id == unique(fruit_id)[1])

spec <- nl_ude(
  fruit1,
  time = "day_after_set",
  states = "fruit_mass_g",
  covariates = c("temperature_C", "soil_water_rel"),
  template = "fruit_growth",
  known_parameters = c(r=.20, K=200),
  dry_run = TRUE
)
str(spec$config)
```

Only remove `dry_run=TRUE` after the specification and units have been audited.

## 7. Main backend packages

`nl_sciml_setup()` currently prepares OrdinaryDiffEq, SciMLSensitivity, Lux, Optimization, OptimizationOptimisers, OptimizationOptimJL, ComponentArrays, NeuralPDE, ModelingToolkit, SymbolicRegression, CSV, DataFrames, JSON3, StableRNGs, LineSearches, Optim and Zygote.

Package APIs change. Before a later release, rerun the Phase-E smoke/golden tests against the resolved Manifest rather than assuming compatibility from package names alone.

## 8. Minimum validation by module

### Neural ODE

- recover a known synthetic ODE;
- repeat several random seeds;
- inspect long-horizon extrapolation;
- compare with a registered parametric/ODE model.

### UDE

- fit mechanistic-only and UDE models on the same split;
- quantify the neural fraction;
- use regularization and repeated starts;
- verify that the neural term does not absorb a known mechanistic term unnecessarily.

### PINN / Richards

- compare to an independent numerical Richards solver;
- test multiple soil textures/parameter sets;
- vary sensor depth/time sparsity;
- report data loss and physics residual separately;
- test boundary forcing uncertainty.

### UDE → symbolic

- first use a simulated system with a known omitted term;
- freeze operators, complexity limit and seed;
- report the Pareto frontier, not only the best expression;
- validate expressions on held-out and extrapolation domains.

### Dynamic design

- simulate/collect the suggested point;
- refit all competing models;
- quantify whether discrimination or parameter precision actually improves.

### Dynamic control

- compare optimized, zero-input, constant-input and rule-based schedules;
- test uncertainty/perturbation scenarios;
- impose agronomic limits before using model output for decisions.

## 9. GPU policy

GPU acceleration is not assumed. It should only be enabled when the local Julia stack and model dimensions justify it. CPU results remain the reference for basic reproducibility tests.

## 10. Security and reproducibility

`nlrFlow` executes the bundled Julia runner and, for advanced custom UDEs, may evaluate user-supplied Julia RHS expressions. Treat custom expressions as executable code and do not run untrusted specifications.

## PINN collocation policy

For the ODE-specialized `NeuralPDE::NNODE` workflows, `nl_pinn()` defaults to `strategy = "weighted_interval"`. This follows the current NeuralPDE guidance that interval/quasi-random or quadrature strategies are preferred for substantive training, while `GridTraining` is retained only as an explicit reproducibility/testing option. The number of collocation samples is controlled by `collocation_points`. The Richards workflow discretizes depth into a coupled ODE state vector and applies the same ODE-specialized PINN interface.

Because the Julia backend was not available in the build environment, this API contract was checked against current NeuralPDE documentation but must still be executed locally before release.

## 12. Reproducible symbolic discovery

`nl_ude_discover()` defaults to `parallelism = "serial"` and `deterministic = TRUE`, and the Julia runner explicitly seeds the Julia RNG with the R-side `seed`. This follows the current `SymbolicRegression.jl` API, where deterministic birth-order bookkeeping is supported only in serial search. Users may opt into `parallelism = "multithreading", deterministic = FALSE` for speed, but such searches should be treated as stochastic hypothesis-generation runs and compared across seeds.

## 13. Dynamic-design and control safeguards

`nl_dynamic_design(..., criterion = "curvature")` uses spacing-aware finite differences, so irregularly spaced candidate dates or depths are not treated as though they were equally spaced. `criterion = "uncertainty"` requires an ensemble of fitted dynamic models rather than using trajectory slope as a proxy for uncertainty. `nl_control()` integrates the control penalty over time and checks that the control schedule covers the start of the fitted horizon and does not extend beyond it. A control result remains a model-conditional experimental design aid, not a field-management prescription.
