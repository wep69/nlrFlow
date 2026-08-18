# nlrFlow 0.3.0.9000 Implementation Summary

Implementation date: **2026-08-17**.

## Integrated scope

- **74 scientific blocks**: original 1–44, Phase D1 45–63, Phase D2 64–67 and Phase E 68–74.
- **83 exported/public functions**.
- **24 registered nonlinear model families** plus dynamic/custom-likelihood/SciML adapters.
- **41 English vignettes**, including 11 Phase-E practical-cycle documents.
- **14 frozen teaching datasets**: eight prior datasets plus six Phase-E simulations.
- **28 synchronized bibliographic records** after the Phase-E literature update.

## Phase E, blocks 68–74

### Block 68 — Neural ODE

`nl_neural_ode()` creates continuous-time neural derivative models for one or multiple states with linearly interpolated time-varying covariates. The optional Julia backend uses Lux, OrdinaryDiffEq, SciMLSensitivity and Optimization. The object retains predictions, training history and a serialized model for downstream design/control.

### Block 69 — Universal Differential Equation

`nl_ude()` combines an explicit known derivative with a regularized neural correction. Built-in agronomic templates cover radiation-use-efficiency crop growth, fruit growth, nitrogen uptake and soil-carbon turnover. Custom Julia RHS expressions are also supported. `weight_decay` protects against an unnecessarily dominant neural correction.

### Block 70 — PINN

`nl_pinn()` provides simple ODE PINNs and a dedicated 1-D Richards soil-water adapter using NeuralPDE. The Richards workflow carries `theta_r`, `theta_s`, `alpha`, `n` and `Ks`, constructs depth states, consumes rainfall/irrigation and ET-like forcing when present, and returns a depth × time field and physical-residual diagnostic.

### Block 71 — missing process representation

`nl_missing_physics()` summarizes known, neural and total UDE derivative contributions. The decomposition is evaluated along the **fitted dynamic trajectory**, and high neural fractions are flags for model revision or experimental investigation, not automatic biological labels.

### Block 72 — UDE symbolic discovery

`nl_ude_discover()` passes the learned correction and selected predictors to SymbolicRegression.jl, returning complexity/loss/equation candidates. The default search is serial and deterministic, and the Julia RNG is seeded from the R-side `seed`; users can explicitly request faster stochastic multithreading. Existing validation/discrimination tools remain mandatory before scientific interpretation.

### Block 73 — SciML diagnostics

`nl_sciml_diagnose()` summarizes fit error, physics loss where available, neural contribution and optional seed-to-seed stability. Phase-E vignettes show repeated-seed and ablation workflows.

### Block 74 — dynamic design and control

`nl_dynamic_design()` selects informative observation times or Richards-profile depths by spacing-aware curvature, ensemble uncertainty or competing-model disagreement. `nl_control()` builds a bounded piecewise control problem from an executed Neural ODE/UDE, integrates the input penalty over time, validates the fitted control horizon and is demonstrated for irrigation/fertigation-like experimental schedules.

## Agronomic examples added

The new frozen simulations and vignettes cover:

- crop biomass under genotype × water regime;
- individual fruit growth;
- depth-resolved soil water and Richards-equation PINNs;
- soil mineral N, plant N and biomass dynamics;
- photosynthesis/stomatal dynamics under water treatments;
- irrigation/control horizons;
- soil-carbon UDEs as an emerging/preprint use case;
- UDE → missing physics → symbolic candidate → next experiment.

## Publication output integration

`nl_plot()` and `nl_table()` now route Phase-E classes to dedicated outputs: observed/predicted dynamic trajectories, soil-water depth × time maps, known/neural UDE decomposition, symbolic error–complexity fronts, SciML diagnostics, dynamic-design scores and control schedules. `nl_report()` creates a compact Markdown interpretation scaffold.

## Reproducibility policy

- Julia is optional and isolated in a dedicated project (`~/.nlrFlow/julia` by default).
- The runner is launched with that project explicitly.
- A custom environment is selected with `NLRFLOW_JULIA_PROJECT`.
- Six Phase-E datasets are frozen simulations with seed `20260817` and are labelled non-empirical.
- `dry_run=TRUE` exposes complete backend specifications without requiring Julia.

## Runtime limitation

R/Rscript and Julia are unavailable in the construction environment. Consequently, this source snapshot is **not represented as having passed numerical SciML backend certification, vignette execution, or `R CMD check --as-cran`**. Static gates and manual API checks are reported separately in `VALIDATION.md`; executable acceptance tests are in `LOCAL_VALIDATION.md`.
