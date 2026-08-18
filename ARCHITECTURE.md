# nlrFlow scientific architecture

Version: **0.3.0.9000**  
Architecture update: **2026-08-17**

## Mission

Provide an auditable nonlinear-modelling and scientific-discovery workflow for agronomy and related biological/environmental sciences, from scientific equation choice through uncertainty quantification, dynamic process modelling, missing-mechanism discovery, and design of the next informative experiment.

## Architecture by phase

### Core, blocks 1–44

1. Data/design audit and preservation of experimental units.
2. Nonlinear-model registry, parameterization, starting values and teaching.
3. NLS, bounded LM, GNLS, heteroscedastic/correlated errors and factors.
4. Bootstrap, profile, Wald, posterior and joint confidence procedures.
5. Resistant, quantile, nonlinear mixed-effects, SAEM and Bayesian models.
6. Diagnostics, influence, curvature and practical identifiability.
7. Prediction and biologically derived quantities such as AGR, RGR, inflection, t50 and AUC.
8. Deterministic ODE/dynamic adapters.
9. Publication-oriented figures, tables and reports.

### Phase D1, blocks 45–63

10. RTMB automatic differentiation and Laplace-compatible objectives.
11. BayesRTMB routing and approximate Bayesian inference.
12. Nonlinear mixed quantiles and resistant sensitivity analysis.
13. Split/cluster conformal prediction and measurement-error models.
14. Joint mean–variance modelling, censoring and truncation.
15. Structural-sensitivity screening and global sensitivity.
16. Fisher-information optimal design and next-measurement selection.
17. Continuous-time stochastic models and process/measurement-error decomposition.
18. GP discrepancy, surrogates, deterministic uncertainty propagation and ABC.

### Phase D2, blocks 64–67

19. Symbolic regression as hypothesis generation.
20. Knowledge-guided equation validation.
21. Automated model discrimination without non-nested LRT shortcuts.
22. Sequential experimental discovery from predictive disagreement.

### Phase E, blocks 68–74: Scientific Machine Learning

23. **Block 68 — Neural ODE:** `nl_neural_ode()` learns a continuous-time derivative when the dynamic law is not adequately specified.
24. **Block 69 — UDE:** `nl_ude()` combines a mechanistic derivative with a neural correction. Built-in agronomic templates cover crop growth, fruit growth, nitrogen uptake and soil-carbon turnover.
25. **Block 70 — PINN:** `nl_pinn()` supports ODE PINNs and a dedicated 1-D Richards soil-water workflow with physical parameters and depth × time outputs.
26. **Block 71 — Missing physics:** `nl_missing_physics()` separates known, learned and total rate contributions and flags regions where the learned correction is scientifically material.
27. **Block 72 — UDE → symbolic equation:** `nl_ude_discover()` sends the learned correction to `SymbolicRegression.jl`; the result remains a candidate mechanism until validation.
28. **Block 73 — SciML diagnostics:** `nl_sciml_diagnose()` summarizes data fit, physics loss, neural contribution and seed-to-seed stability.
29. **Block 74 — Dynamic design/control:** `nl_dynamic_design()` chooses informative times/conditions; `nl_control()` creates bounded piecewise control problems for irrigation/fertigation-like decisions.

The authoritative one-row-per-block map is `inst/metadata/74_BLOCKS_IMPLEMENTATION.csv`.

## Layered execution model

### Layer A — scientific specification

The scientific question, data units, state variables, covariates, known mechanism, candidate models and allowed interventions are defined before an optimizer is selected.

### Layer B — estimator/backends

Base-R and established R packages remain the default where adequate. Phase E uses an **optional Julia project** because differentiation through differential-equation solvers and NeuralPDE/SciMLSensitivity capabilities are provided by the SciML ecosystem. Julia is not required to load or use the classical `nlrFlow` core.

### Layer C — inference and validation

Point estimation is separated from bootstrap/conformal/posterior uncertainty, physical residual diagnostics, identifiability, sensitivity, symbolic-candidate validation and out-of-sample checks.

### Layer D — scientific communication

`nl_plot()`, `nl_table()` and `nl_report()` route both classical and Phase-E object classes to interpretable outputs. Phase-E figures include trajectories, Richards depth × time fields, known-versus-neural rate decomposition, symbolic error–complexity fronts, design scores and control schedules.

### Layer E — experimental learning

The intended high-level discovery cycle is

```text
experiment
  -> known mechanism
  -> UDE / PINN / Neural ODE when justified
  -> diagnose missing process representation
  -> symbolic candidate mechanism
  -> validate / discriminate
  -> choose the next informative experiment
```

## SciML dependency policy

- The default Julia project is `~/.nlrFlow/julia`.
- `nl_sciml_setup(install = FALSE)` is non-invasive and only reports the setup specification.
- `nl_sciml_setup(install = TRUE)` invokes the bundled setup script but **never installs Julia itself**.
- A custom environment can be selected with `NLRFLOW_JULIA_PROJECT`.
- SciML adapters support `dry_run = TRUE` so the full executable specification can be inspected without Julia.
- Source implementation is not equivalent to numerical certification. The Julia/R runtime tests in `LOCAL_VALIDATION.md` remain release-blocking.

## Methodological boundaries

- Neural ODEs are not preferred merely because they are flexible; conventional interpretable equations remain the first choice when they answer the scientific question.
- A UDE neural correction is **not automatically a biological mechanism**. `nl_missing_physics()` describes it as missing process representation, and `nl_ude_discover()` generates hypotheses only.
- The built-in UDE mechanistic parameters are presently supplied as fixed scientific inputs during neural-correction fitting; sensitivity analysis and external refitting should be used before mechanistic interpretation.
- PINN performance depends on the correctness of the governing equation, boundary/initial assumptions and scaling. “Physics informed” does not imply that the supplied physics is correct.
- The 1-D Richards implementation is a teaching/research adapter requiring runtime comparison with an independent numerical solution before substantive use.
- `nl_control()` optimizes the model supplied to it; it does not prove agronomic optimality under unmodelled constraints, uncertainty, economics or safety restrictions.
- Symbolic discovery must pass dimensional/shape/biological plausibility, stability, extrapolation and new-experiment validation before being presented as a scientific relation.

## Provenance

The six `sciml_*` teaching datasets are frozen simulations with seed `20260817` and are explicitly marked as non-empirical in `inst/metadata/DATA_PROVENANCE.json`. They support reproducible examples but must not be cited as observed agronomic results.
