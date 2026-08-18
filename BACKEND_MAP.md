# nlrFlow backend capability map

Update date: 2026-08-17. Version 0.3.0.9000.

| Capability | nlrFlow entry point | Backend / algorithm | Status and boundary |
|---|---|---|---|
| Classical NLS | `nl_fit(engine="nls")` | `stats::nls` | Core |
| Bounded Levenberg-Marquardt | `nl_fit(engine="nlsLM")` | `minpack.lm::nlsLM` | Optional adapter |
| Multistart | `nl_multistart()` | internal strategy + `nls.multstart` | Optional enhanced backend |
| GNLS, variance, correlation | `nl_fit(engine="gnls")` | `nlme::gnls` | Optional adapter |
| Resistant NLS | `nl_robust()` | `robustbase::nlrob` | Optional adapter |
| Nonlinear quantiles | `nl_quantile()` | `quantreg::nlrq` | Optional adapter |
| NLME | `nl_mixed()` | `nlme::nlme` | Optional adapter |
| SAEM NLME | `nl_saemix()` | `saemix` | Optional adapter |
| Bayesian nonlinear/multilevel | `nl_bayes()` | `brms`/Stan | Optional adapter |
| PSIS-LOO/stacking | `nl_bayes_compare()` | `loo` | Optional adapter |
| Automatic differentiation | `nl_rtmb()`, `nl_ad()` | `RTMB` | Optional adapter |
| MAP/NUTS/Laplace/ADVI routing | `nl_bayes_rtmb()`, `nl_bayes_approx()` | `BayesRTMB` | Optional adapter; method availability checked at runtime |
| Nonlinear mixed quantiles | `nl_quantile_mixed()` | `qrNLMM::QRNLMM` | Optional adapter |
| Resistant mixed-quantile sensitivity | `nl_quantile_mixed_robust()` | internal smoothed pinball + penalized group deviations | Experimental sensitivity estimator; **not cGAL** |
| Split conformal | `nl_conformal()` | internal finite-sample calibration | Core implementation; marginal coverage relies on exchangeability/calibration design |
| Cluster/group conformal | `nl_conformal_group()` | internal cluster split + optional Mondrian strata | Whole clusters are assigned to calibration/training |
| Measurement error | `nl_measurement_error()` | internal latent-x Gaussian likelihood | EIV likelihood, assumes supplied/estimated error structure |
| Joint mean-variance | `nl_mean_variance()` | internal Gaussian mean/log-SD likelihood | General nonlinear mean plus variance formula |
| Censoring/truncation | `nl_censored()`, `nl_truncated()` | internal Gaussian likelihoods | Exact/left/right/interval censoring; conditional truncation |
| Practical identifiability | `nl_identify()` | Jacobian/Hessian/profile diagnostics | Core |
| Structural screen | `nl_structural_identify()` | local sensitivity-rank screen | Not a global symbolic identifiability proof |
| Global sensitivity | `nl_sensitivity()` | local/Morris/Sobol | Transparent internal implementation; Julia `GlobalSensitivity.jl` is a benchmark ecosystem |
| Local optimal design | `nl_design()` | Fisher-information D/A/E/c criteria | Local in current parameter values |
| Sequential next measurement | `nl_next_measurement()` | updated local information criterion | Requires refitting/update between rounds |
| Continuous-time stochastic model | `nl_state_space()` | `ctsmTMB` | Optional adapter |
| Error decomposition | `nl_error_decompose()` | internal | Separates estimated process/measurement components when supplied by model |
| GP discrepancy | `nl_gp_discrepancy()` | `DiceKriging::km` on residuals | Sequential discrepancy diagnostic, not full joint calibration |
| Surrogate | `nl_surrogate()` | quadratic response surface or `DiceKriging` GP | Must be checked with `nl_surrogate_validate()` |
| Deterministic propagation | `nl_propagate()` | spherical-radial sigma-point/cubature-like rule | Transparent approximation, not claimed as the 2025 sparse cubature method |
| ABC | `nl_abc()` | rejection ABC | Transparent baseline |
| Symbolic regression | `nl_symbolic()` | PySR via `reticulate` | Optional hypothesis generator |
| Candidate validation | `nl_validate_candidate()` | internal constraints + extrapolation + K-fold CV | Core validation layer |
| Equation discovery workflow | `nl_discover()` | registry/candidate fitting + validation | Does not promote an equation automatically |
| Model discrimination | `nl_discriminate()` | AICc/CV/validity/predictive disagreement | No non-nested LRT shortcut |
| Sequential experimental discovery | `nl_sequential_discovery()` | predictive-disagreement scoring | T-optimal-like practical selection, not a claim of exact PICS implementation |

“Optional adapter” means source integration exists. It does not mean that the backend has been numerically certified in the present construction environment. See `VALIDATION.md`.

## Phase E: optional Julia/SciML layer

| Capability | nlrFlow entry point | Backend / algorithm | Status and boundary |
|---|---|---|---|
| SciML environment audit/setup | `nl_sciml_available()`, `nl_sciml_info()`, `nl_sciml_setup()` | Julia project + package import checks | Optional; setup never installs Julia itself |
| Neural ODE | `nl_neural_ode()` | `OrdinaryDiffEq` + `Lux` + `SciMLSensitivity` + `Optimization` | Source adapter implemented; runtime certification pending |
| Universal Differential Equation | `nl_ude()` | mechanistic RHS + `Lux` neural correction + differentiable ODE solve | Built-in agronomic templates; neural correction regularization available |
| Physics-informed ODE/PINN | `nl_pinn()` | `NeuralPDE::NNODE` | ODE templates plus specialized 1-D Richards adapter |
| Missing-process decomposition | `nl_missing_physics()` | internal decomposition of fitted UDE vector field | Diagnostic, not automatic mechanism naming |
| Learned-dynamics symbolic search | `nl_ude_discover()` | `SymbolicRegression.jl` | Hypothesis generator; candidates require validation |
| SciML diagnostics | `nl_sciml_diagnose()` | internal data/physics/neural/stability summaries | Intended for interpretation and reproducibility |
| Dynamic measurement design | `nl_dynamic_design()` | curvature, uncertainty or between-model discrimination score | Practical dynamic design, not a universal optimum |
| Bounded dynamic control | `nl_control()` | saved SciML model + `Optimization`/`Optim` | Piecewise control schedule; model-conditional recommendation |

The SciML runner is executed with the dedicated Julia project selected by `NLRFLOW_JULIA_PROJECT` (default `~/.nlrFlow/julia`). “Source adapter implemented” does not mean that the present build environment has executed the Julia backend; see `VALIDATION.md`.
