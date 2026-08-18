# Teaching-data provenance

The package ships small frozen CSV datasets so examples never require an internet connection.

- `okra_growth_raw` is transcribed from the user-provided nonlinear-regression R script. It is observational input supplied by the user, not simulated by nlrFlow.
- `okra_growth_means` is a deterministic aggregation of that raw okra dataset by days after flowering and is intended for teaching/descriptive curve fitting only.
- `agronomy_growth`, `soil_infiltration`, `soil_fertility_p`, `plant_physiology_light`, `soil_water_retention`, and `soil_p_sorption` are explicitly simulated teaching data.
- Frozen seeds and the scientific data-generating description are recorded in `inst/metadata/DATA_PROVENANCE.json`.
- Simulated values are examples, not experimental findings. Documentation must never cite their numerical outcomes as empirical evidence.

The two soil datasets added for advanced teaching use standard model forms already implemented in the package: van Genuchten water retention and Langmuir P sorption. Their purpose is to demonstrate parameter constraints, grouping, nonlinear mixed effects, bootstrap uncertainty, and publication-ready output.
