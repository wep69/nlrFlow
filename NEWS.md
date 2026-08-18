# nlrFlow 0.3.0.9000

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
