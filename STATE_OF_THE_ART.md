# State of the Art and Ecosystem Rationale

Search and metadata verification date: **2026-08-17**.

## Position of nlrFlow

`nlrFlow` is an orchestration and scientific-validation layer rather than a replacement for established numerical libraries. Version 0.3.0.9000 expands the original 44-block workflow to 74 blocks by adding automatic differentiation, mixed quantiles, conformal inference, measurement-error models, mean-variance models, censoring/truncation, sensitivity, design of experiments, stochastic states, surrogates, uncertainty propagation, and knowledge-guided equation discovery.

## 1. Automatic differentiation and Laplace/Bayesian computation

The current CRAN release of **RTMB 1.9** (2026-03-20) provides native R bindings to TMB and automatic differentiation to arbitrary order for a substantial subset of R. `nl_rtmb()` and `nl_ad()` expose this route for custom nonlinear likelihoods. **BayesRTMB 0.2.4** (2026-07-24) adds MAP/MCMC-oriented Bayesian inference on RTMB models; `nl_bayes_rtmb()` and `nl_bayes_approx()` are optional routers. The methodological foundation remains the TMB framework of Kristensen et al. (2016).

Implemented boundary: simple NLS is not redirected to RTMB without a reason. RTMB is reserved for likelihoods/latent structures where automatic differentiation or Laplace integration adds value.

## 2. Nonlinear mixed quantiles

**qrNLMM 4.0** (2025-05-21) implements likelihood-based nonlinear mixed-effects quantile regression using asymmetric-Laplace/SAEM methodology derived from Galarza et al. (2020). `nl_quantile_mixed()` delegates to this established backend.

Burger, van der Merwe and Lesaffre (2025) proposed a contaminated generalized asymmetric-Laplace Bayesian mixed-effects quantile model for skewness and outliers. `nlrFlow` does **not** claim to implement that cGAL method. `nl_quantile_mixed_robust()` is deliberately labelled as an experimental sensitivity estimator until a validated cGAL-compatible backend is available.

## 3. Conformal prediction

Python's MAPIE provides a broad model-agnostic conformal ecosystem, while the R package **pintervals 1.1.1** (2026-03-03) provides model-agnostic prediction intervals including conformal methods. `nlrFlow` adds split conformal directly around nonlinear fits and a cluster/group variant that assigns whole clusters to calibration/training.

Scientific boundary: conformal coverage guarantees depend on the calibration/exchangeability structure. The package therefore does not describe a generic conformal interval as conditional coverage for every treatment, soil class or time point. Group/Mondrian calibration is exposed when such stratification is scientifically defensible.

## 4. Measurement error and joint mean-variance modelling

Measurement error in nonlinear covariates can bias parameter estimates and invalidate standard inference. Zhang, Liu and Wu (2024) studied hypothesis testing for nonlinear mixed-effects models with covariate measurement errors. Ye, Wu and Lima (2025) jointly modelled longitudinal nonlinear means and within-individual variances while addressing measurement error and outliers.

`nl_measurement_error()` provides a transparent Gaussian errors-in-variables likelihood. `nl_mean_variance()` models a nonlinear mean jointly with a log-SD predictor. These are useful for laboratory concentrations, soil measurements, irradiance, water potential and other predictors whose uncertainty is scientifically material.

## 5. Identifiability

Heinrich et al. (2025) emphasize that structural and practical identifiability are distinct problems and should be considered before interpreting fitted parameters. Julia's `StructuralIdentifiability.jl` offers symbolic local/global structural-identifiability tools for ODE systems.

`nlrFlow` retains `nl_identify()` for practical/local diagnostics and adds `nl_structural_identify()` as a **local sensitivity-rank screen**. This distinction is intentional: the R function is not presented as a proof of global structural identifiability.

## 6. Global sensitivity analysis

Julia's `GlobalSensitivity.jl` implements Sobol, Morris, eFAST, DGSM and related algorithms and is documented in Dixit and Rackauckas (2022). `nl_sensitivity()` adds local, Morris and Sobol workflows directly in R so parameter influence can be examined over scientifically plausible ranges rather than only at the optimum.

## 7. Optimal and sequential experimental design

Nonlinear optimal design is local because the Fisher information depends on unknown parameters. Bubel et al. (2025) studied uncertainty in optimal design locations and design regions. Ghosh, Khamaru and Dasgupta developed PICS, published online in 2025 and in *Technometrics* 68(2), 2026, as a sequential approach for nonlinear D-optimal designs when closed-form designs are available.

`nl_design()` implements local Fisher-information D/A/E/c criteria and `nl_next_measurement()` supports sequential updating. `nl_sequential_discovery()` has a different purpose: it scores candidate points by between-model predictive disagreement relative to residual noise to help distinguish competing equations. It is **not** labelled as an exact implementation of PICS.

## 8. Stochastic state-space modelling

**ctsmTMB 1.1.1** (2026-07-14) provides continuous-time stochastic modelling using TMB/RTMB with Kalman and Laplace-related workflows. `nl_state_space()` is an optional adapter, while `nl_error_decompose()` makes the distinction between process and observation uncertainty explicit.

This extends deterministic ODE fitting to sensor-rich agronomic settings such as soil moisture, gas exchange, microclimate and irregular repeated observations.

## 9. Uncertainty propagation beyond first-order linearization

Bubel et al. (2025) proposed sparse-cubature approaches for prediction-uncertainty estimation in nonlinear regression and demonstrated a useful accuracy/computational-efficiency trade-off. `nl_propagate()` currently implements a transparent spherical-radial deterministic sigma-point rule. The paper motivates future richer cubature rules, but the package does not claim exact reproduction of that publication.

## 10. Symbolic regression and knowledge-guided equation discovery

PySR is a Python interface to `SymbolicRegression.jl` for interpretable symbolic regression. The current nlrFlow adapter uses PySR through `reticulate` only as a candidate-expression generator.

Rogers et al. (2024) demonstrated the scientific value of combining knowledge-guided symbolic regression with model-based design of experiments so that candidate mechanistic equations and informative experiments are selected iteratively. This idea directly motivates blocks 64-67:

1. `nl_symbolic()` proposes expressions.
2. `nl_validate_candidate()` applies scientific and numerical constraints.
3. `nl_discover()` evaluates registered and candidate equations in a common workflow.
4. `nl_discriminate()` ranks only surviving, scientifically admissible candidates.
5. `nl_sequential_discovery()` suggests a new measurement region where plausible models disagree.

The package therefore treats symbolic regression as **scientific hypothesis generation**, not automatic discovery of biological law.

## 11. Neural Ordinary Differential Equations

Chen et al. (2018) introduced Neural ODEs by parameterizing the derivative of a continuous hidden state with a neural network and evaluating it through an ODE solver. In `nlrFlow`, `nl_neural_ode()` is reserved for dynamic systems where the rate law itself is inadequately known. It is not positioned as a replacement for interpretable Gompertz, Richards, Mitscherlich or mechanistic ODE models when those are scientifically adequate.

The Phase-E implementation delegates ODE integration, neural layers, differentiable sensitivities and optimization to the Julia SciML ecosystem. Training history and fitted trajectories are returned to R for common plotting/table/report interfaces.

## 12. Universal Differential Equations and missing physics

Rackauckas et al. (2020) formulated Universal Differential Equations as a framework that combines known scientific equations with universal approximators. `nl_ude()` follows this additive grey-box idea: the known agronomic rate law remains explicit and a neural term represents unresolved dynamics.

Philipps, Schmid and Hasenauer (2025) show that sparse/noisy biological data, multimodal optimization, over-flexible neural components and mechanistic-parameter identifiability are major UDE challenges. Version 0.3.0.9000 therefore exposes neural weight decay, seed-aware diagnostics, the size of the neural contribution and a clear mechanistic-versus-learned decomposition. The learned term is called *missing process representation*, not a newly discovered mechanism.

A 2025 preprint by Satyanarayana Raju G. V. V. et al. explores UDEs for soil-organic-carbon depth/time dynamics. `nlrFlow` cites it explicitly as a **preprint and emerging agronomic example**, not as settled validation of UDEs for field SOC prediction.

## 13. Physics-informed neural networks for agronomy and soil-water processes

The foundational PINN formulation of Raissi, Perdikaris and Karniadakis (2019) combines observation loss with governing differential-equation constraints. The agronomic relevance is particularly strong for unsaturated flow:

- Li et al. (2025) developed an adaptively weighted physics-informed approach for Richards-equation soil-water flows and constitutive relations.
- Gong and Zha (2025) studied inverse unsaturated flow in heterogeneous soils with parameter–state coupling under sparse observations and boundary uncertainty.
- Qi et al. (2026) combined deep learning with a 1-D Richardson–Richards process model for site-specific pedotransfer functions.

These papers motivate the dedicated `nl_pinn(problem="richards_1d")` adapter rather than a generic black-box PINN example. The current source implementation uses a **method-of-lines depth discretization** of Richards dynamics and the ODE-specialized `NeuralPDE::NNODE` interface. It retains Richards physical parameters, time-varying rainfall/irrigation and ET-like forcing, and returns depth × time prediction fields plus a numerical physics-residual diagnostic. This is deliberately described as a semidiscretized physics-informed Richards workflow, not as a claim of direct continuous-PDE collocation. Runtime comparison with an independent Richards solver remains mandatory.

Shao et al. (2026) provide a directly agricultural example of a hybrid physics-informed model for longitudinal wheat plant height. Publisher and Wageningen metadata list the article in *Computers and Electronics in Agriculture*, volume 251, article 111988; the issue date is 1 September 2026, later than this 17 August 2026 build date. The bibliography therefore records the verified 2026 article metadata without implying that the September issue had already occurred at build time.

## 14. UDE → symbolic equation → experimental validation

Block 72 links the learned UDE correction to `SymbolicRegression.jl`. This is a model-discovery aid, not an equation-certification algorithm. For reproducibility-focused scientific runs, `nl_ude_discover()` defaults to seeded serial search with deterministic birth-order bookkeeping; multithreading is an explicit stochastic option. `nl_ude_discover()` returns an error–complexity Pareto set; candidate expressions then re-enter the established knowledge-guided workflow (`nl_validate_candidate()`, `nl_discriminate()`, cross-validation, extrapolation and biological constraints).

This architecture extends the blocks 64–67 symbolic workflow by learning *what the known differential equation failed to represent* before searching for a compact expression. The scientific endpoint is a falsifiable candidate process that can be tested in new experiments.

## 15. Dynamic optimal measurement and control

`nl_dynamic_design()` ranks candidate times or Richards-profile depths using spacing-aware trajectory curvature, ensemble uncertainty, or disagreement among competing dynamic models. It complements `nl_design()` and `nl_next_measurement()`: the older functions operate on local nonlinear-regression information, whereas the Phase-E function works directly with fitted dynamic trajectories.

`nl_control()` defines a bounded piecewise control input and optimizes a terminal model target penalized by **time-integrated** input over the fitted control horizon. Agronomic examples include irrigation and fertigation schedules. Such outputs are **model-conditional decision aids**. They do not incorporate unmodelled field constraints, economics, crop safety or regulatory requirements unless these are explicitly represented in the objective/constraints.

## 16. Recommended methodological hierarchy

The package deliberately uses the following escalation:

1. interpretable nonlinear regression when adequate;
2. mechanistic ODE/state-space model when the process is dynamic but known;
3. UDE when a credible mechanism is incomplete;
4. PINN when governing differential equations and physical constraints are central to the inverse problem;
5. Neural ODE when the dynamic law is largely unknown;
6. symbolic compression and a new experiment only after diagnostic evidence supports missing structure.

This hierarchy is designed to avoid using Scientific Machine Learning only because it is more flexible.

## Verified key references

Machine-readable BibTeX and RIS records are supplied in `references/references.bib` and `references/references.ris`. Verification provenance is in `references/REFERENCE_VERIFICATION.md` and `inst/metadata/reference_metadata.csv`.
