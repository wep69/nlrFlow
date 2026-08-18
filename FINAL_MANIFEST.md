# nlrFlow 0.3.0.9000 Final Implementation Manifest

Finalization date: **2026-08-17**.

## Implemented scope

The source snapshot integrates the complete approved sequence:

- blocks **1–44**: nonlinear-regression core;
- blocks **45–63**: advanced inference, conformal, RTMB, error structures, design and related Phase-D1 tools;
- blocks **64–67**: knowledge-guided symbolic discovery and sequential model discrimination;
- blocks **68–74**: Scientific Machine Learning for dynamic agronomic systems.

The authoritative block map is `inst/metadata/74_BLOCKS_IMPLEMENTATION.csv`.

## Phase E, blocks 68–74

| Block | Capability | Main public entry point |
|---:|---|---|
| 68 | Neural ordinary differential equations | `nl_neural_ode()` |
| 69 | Universal differential equations | `nl_ude()` |
| 70 | Physics-informed neural differential equations, including semidiscretized Richards soil-water dynamics | `nl_pinn()` |
| 71 | Known-versus-learned missing-process decomposition | `nl_missing_physics()` |
| 72 | UDE correction to symbolic candidate equations | `nl_ude_discover()` |
| 73 | SciML fit, physics, neural-contribution and seed diagnostics | `nl_sciml_diagnose()` |
| 74 | Dynamic measurement design and bounded optimal-control experiments | `nl_dynamic_design()`, `nl_control()` |

Support functions `nl_sciml_available()`, `nl_sciml_info()` and `nl_sciml_setup()` keep Julia optional and make the execution contract inspectable before running external software.

## Package inventory

- **74 scientific blocks**.
- **83 exported/public functions**.
- **24 registered classical nonlinear model families**, plus dynamic/SciML adapters.
- **41 English vignettes**, including 11 Phase-E end-to-end practical documents.
- **14 frozen teaching datasets**, six of them new Phase-E simulations.
- **28 synchronized bibliographic records** in package BibTeX, vignette BibTeX, RIS and metadata CSV.
- Dedicated Julia setup and execution runner under `inst/julia/`.
- Phase-E integrity checker: `tools/validate_phase_e_integrity.py`.

## Agronomic coverage of Phase E

The teaching workflows cover crop biomass, fruit growth, photosynthetic/stomatal dynamics, plant and soil nitrogen, soil-water profiles, Richards-equation inverse problems, irrigation/control horizons, emerging soil-carbon UDE examples, missing-process analysis, symbolic compression and next-experiment design.

All six new Phase-E datasets are **simulated teaching data**, frozen with documented provenance. They are not presented as empirical field datasets.

## Scientific safeguards implemented

1. The package escalates from interpretable nonlinear models to mechanistic ODEs and only then to UDE/PINN/Neural ODE when scientifically justified.
2. UDE known terms and learned corrections are reported separately.
3. Neural weight decay is available to reduce unnecessarily dominant learned corrections.
4. `nl_missing_physics()` describes a learned **missing-process representation**, not proof of a biological mechanism.
5. Symbolic regression is hypothesis generation. Candidate equations must be refitted and validated.
6. `nl_ude_discover()` defaults to seeded, serial, deterministic SymbolicRegression.jl search. Faster multithreading is explicit and stochastic.
7. The Richards workflow uses method-of-lines depth discretization with NeuralPDE's ODE-specialized PINN algorithm and is not described as direct continuous-PDE collocation.
8. `GridTraining` is retained for explicit testing; the ODE PINN default is `WeightedIntervalTraining`.
9. Dynamic curvature design is spacing-aware for irregular sampling calendars.
10. Dynamic uncertainty design requires an ensemble rather than using trajectory slope as a proxy.
11. Dynamic-control input cost is integrated over time and the control schedule is checked against the fitted horizon.
12. Control outputs are model-conditional experimental-design aids, not automatic irrigation or fertigation prescriptions.

## Publication output integration

Phase-E classes are integrated with `nl_plot()`, `nl_table()` and `nl_report()` for:

- observed and fitted dynamic trajectories;
- PINN soil-water depth × time fields and residual displays;
- known versus learned UDE derivative contributions;
- symbolic loss-versus-complexity Pareto fronts;
- SciML training and diagnostic summaries;
- dynamic-design scores with selected dates/depths;
- bounded control schedules and integrated-input summaries.

These functions support the existing package export workflow for vector or high-resolution publication graphics and formatted tables when executed in a local R environment.

## Static source gates

The final source tree passes the available construction-environment gates:

```text
ROXYGEN PARAM CHECK PASS: 83/83 exported functions have documented formals.
Example coverage: 83 / 83 PASS
STATIC VALIDATION PASS: 83 exported functions; all definitions/documentation/vignette-call gates satisfied.
Materialized 83 conservative Rd topics. Regenerate with roxygen2 before release.
Generated Rd example coverage: 83/83 PASS
PHASE-E INTEGRITY: PASS | blocks=74 exports=83 vignettes=41 datasets=14 references=28
R delimiter check: PASS
Julia delimiter check: PASS
```

## Bibliographic integrity

The bibliography contains **28 synchronized records**. The new Phase-E literature distinguishes peer-reviewed articles, conference publications, foundational preprints and software documentation. Metadata provenance is recorded in `references/REFERENCE_VERIFICATION.md` and `inst/metadata/reference_metadata.csv`.

Important evidence boundaries are retained explicitly. In particular, the soil-organic-carbon UDE application is identified as a preprint, while the 2026 plant-height PINN paper is recorded using verified publisher metadata with its 1 September 2026 issue date noted as future relative to this 17 August 2026 build.

## Runtime-validation boundary

**R/Rscript and Julia are not installed in the construction environment.** Therefore this snapshot is not represented as having passed:

- package installation in R;
- `testthat` execution;
- `R CMD build` or `R CMD check --as-cran`;
- Julia package resolution/precompilation;
- Neural ODE/UDE/PINN numerical convergence;
- gradient/adjoint numerical validation;
- independent Richards-solver comparison;
- SymbolicRegression.jl execution;
- optimal-control numerical execution;
- rendering of all 41 vignettes.

These are release-blocking local acceptance tests and are specified in `LOCAL_VALIDATION.md` and `SCIML_BACKEND.md`.

## Authoritative documentation

- `ARCHITECTURE.md`
- `BACKEND_MAP.md`
- `SCIML_BACKEND.md`
- `STATE_OF_THE_ART.md`
- `IMPLEMENTATION_SUMMARY.md`
- `VALIDATION.md`
- `LOCAL_VALIDATION.md`
- `references/REFERENCE_VERIFICATION.md`
- `inst/metadata/74_BLOCKS_IMPLEMENTATION.csv`
- `inst/metadata/dataset_manifest.csv`
- `inst/metadata/reference_metadata.csv`

Historical block maps are retained only under `inst/metadata/history/`.
