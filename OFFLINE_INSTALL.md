# Offline installation strategy for nlrFlow 0.3.0.9000 on Windows

## Principle

Heavy engines remain in `Suggests`, so a minimal installation can use core NLS without Stan, SAEM, RTMB, state-space or symbolic-regression stacks. A feature may only be claimed as locally validated when its optional dependencies are present and tested.

## Online staging machine

```powershell
$Repo = "https://cloud.r-project.org"
$Out  = "D:\temp\nlrFlow-offline"
New-Item -ItemType Directory -Force $Out | Out-Null
```

Use the same R minor version and Windows architecture as the offline computer whenever possible.

Recommended full dependency set:

```r
pkg <- c(
  "minpack.lm", "nls.multstart", "GA", "nlme", "robustbase", "quantreg",
  "brms", "loo", "cmdstanr", "saemix", "nlstools", "IPEC",
  "deSolve", "rxode2", "nlmixr2", "nlraa", "drc", "emmeans",
  "qrNLMM", "RTMB", "BayesRTMB", "ctsmTMB", "DiceKriging", "reticulate",
  "ggplot2", "patchwork", "gt", "writexl", "webshot2", "shiny",
  "testthat", "knitr", "rmarkdown", "vdiffr", "roxygen2", "devtools",
  "rcmdcheck"
)
```

Resolve recursive dependencies and archive package files plus a manifest containing package version, repository, R version, architecture and SHA-256.

## Additional runtimes

A complete offline bundle may also require:

- Rtools compatible with the target R release for source compilation;
- a functioning CmdStan toolchain for `cmdstanr`/Stan-backed `brms`;
- compilers/runtime requirements reported by RTMB/TMB, `rxode2`, `nlmixr2` and `ctsmTMB`;
- Pandoc/Quarto for local documentation workflows;
- Python + a prebuilt environment containing PySR for block 64. PySR also uses Julia/SymbolicRegression.jl internally, so the environment must be staged and tested on the online machine before transfer.

## Install order offline

1. Install R and matching Rtools.
2. Configure a local CRAN-style repository or package folder.
3. Install base numerical, graphics and reporting dependencies.
4. Install classical/mixed/resistant/quantile engines.
5. Install RTMB/BayesRTMB/state-space dependencies.
6. Install Bayesian/Stan and dynamic engines only when required.
7. Restore the dedicated PySR Python environment if symbolic regression is required.
8. Install `nlrFlow_0.3.0.9000` from the source snapshot.
9. Run `nl_doctor()`, `nl_capabilities()` and the full local validation protocol.

## Acceptance rule

A missing optional backend is acceptable only when its capability is not claimed as validated. Core package installation, loading, examples and tests remain release gates.


## Optional Phase-E Julia/SciML environment

Blocks 68–74 are optional and require Julia plus a resolved Julia project. For a truly offline target machine, prepare the Julia environment on a compatible connected machine, preserve its `Project.toml` and `Manifest.toml`, and use Julia's package/artifact facilities to stage the required registries/packages/artifacts. Do not assume that copying only the R package ZIP is sufficient for NeuralPDE/SciML execution.

The R core remains installable and usable without this Julia environment. See `SCIML_BACKEND.md` for the online setup and validation sequence.
