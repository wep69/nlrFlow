# nlrFlow Validation Status

Version: **0.3.0.9000**  
Date: **2026-08-17**

## Validated in the construction environment

Source-level gates verify:

1. every `NAMESPACE` export has a source definition;
2. every public formal argument is documented by roxygen;
3. every exported function has at least three documented/example calls;
4. every public function appears in the vignette-call coverage matrix;
5. conservative Rd topics can be materialized from the source;
6. block mapping is continuous through block 74;
7. teaching-data rows and SHA-256 hashes are inventoried;
8. BibTeX/RIS/CSV reference ledgers are synchronized;
9. Phase-E Julia setup/runner files are present and their public specifications can be inspected without execution;
10. the Phase-E cross-file integrity gate checks 74 blocks, 83 exports, 41 vignettes, 14 datasets, 28 synchronized references and required Julia safeguards.

Current source gate target: **83/83 exported functions**. `tools/validate_phase_e_integrity.py` currently reports **PASS**.

## New Phase-E static/integration checks

`tests/testthat/test-phase-e-sciml.R` covers the source contract for:

- blocks 68–74 in `nl_sciml_info()`;
- non-invasive Julia setup;
- six finite teaching datasets;
- Neural ODE, UDE and PINN dry-run specifications;
- UDE input validation;
- Richards hydraulic-parameter validation;
- missing-physics contribution calculations;
- UDE symbolic-discovery specification;
- SciML diagnostic flags;
- dynamic-design spacing, irregular candidate calendars, ensemble-uncertainty requirements and long-form Richards predictions;
- bounded dynamic-control specifications, full-horizon checks and time-integrated input accounting;
- reproducibility-focused symbolic specifications (seed, serial mode and deterministic bookkeeping).

These tests are present but **have not been executed in R in this environment**.

## Not validated here

Neither R/Rscript nor Julia is installed in the construction environment. Therefore no claim is made of:

- successful R installation or `R CMD check`;
- execution of Julia/SciML packages;
- numerical convergence of Neural ODE/UDE/PINN examples;
- agreement with independent ODE/Richards solutions;
- successful differentiation/adjoint gradients on the local toolchain;
- successful SymbolicRegression.jl searches;
- numerical optimal-control solutions;
- rendering of all 41 vignettes;
- CRAN-ready status.

## Release-blocking SciML validation

Before Phase E is described as numerically certified, a clean local machine must verify:

1. Julia project creation and import of the exact packages listed by `nl_sciml_setup()`;
2. preservation of `Project.toml`, `Manifest.toml`, Julia version and R `sessionInfo()`;
3. Neural ODE recovery on known synthetic dynamics and stability across seeds;
4. UDE ablation: mechanistic only vs UDE vs fully neural derivative;
5. known missing-term recovery before symbolic compression;
6. Richards PINN comparison with an independent numerical Richards solver;
7. parameter recovery and physics residuals under noise/sparsity scenarios;
8. symbolic candidate recovery under a frozen operator/search space;
9. dynamic-design improvement after actually collecting/simulating the suggested point and refitting;
10. control schedule feasibility and comparison with no-control/fixed-control baselines;
11. publication figure/table generation for every Phase-E class;
12. all 41 vignettes, all examples, testthat, `R CMD build` and `R CMD check --as-cran`.

See `LOCAL_VALIDATION.md` and `SCIML_BACKEND.md`.
