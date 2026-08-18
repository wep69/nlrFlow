# Reference metadata verification

Verification date: **2026-08-17**.

This file records the metadata policy for references introduced by the 45-74 expansions. DOI/title/author/year fields were checked against at least two independent metadata surfaces when feasible, preferring publisher/journal/CRAN records over secondary aggregators. No DOI was inferred when a stable DOI was not confirmed.

Machine-readable records:

- `references/references.bib`
- `references/references.ris`
- `inst/metadata/reference_metadata.csv`

## Verification ledger

| Key | Topic | DOI/version | Verification sources |
|---|---|---|---|
| `Kristensen2016TMB` | automatic differentiation / Laplace | 10.18637/jss.v070.i05 | Journal of Statistical Software DOI; CRAN RTMB documentation |
| `Galarza2020` | nonlinear mixed quantile regression | 10.1007/s00362-018-0988-y | Springer/RePEc DOI metadata; CRAN qrNLMM description |
| `Burger2025` | resistant mixed quantiles / cGAL benchmark | 10.1007/s00180-025-01651-0 | Springer; RePEc/EBSCO |
| `Zhang2024` | measurement error in nonlinear mixed effects | 10.1002/cjs.11812 | Wiley; journal citation metadata |
| `Ye2025` | joint mean-variance / measurement error / outliers | 10.1093/biomtc/ujaf018 | Oxford Academic; PubMed |
| `Heinrich2025` | structural and practical identifiability | 10.1016/j.coisb.2025.100546 | ScienceDirect; Wageningen Research Portal |
| `Dixit2022` | global sensitivity / Julia | 10.21105/joss.04561 | JOSS; Zenodo |
| `BubelDesign2025` | optimal experimental design | 10.1007/s00362-025-01725-7 | Springer; RePEc |
| `Ghosh2026PICS` | sequential nonlinear optimal design | 10.1080/00401706.2025.2573234 | Taylor & Francis article; Technometrics issue table of contents |
| `BubelCubature2025` | nonlinear uncertainty propagation / cubature | 10.1016/j.compchemeng.2025.109035 | ScienceDirect; Fraunhofer publication portal |
| `Rogers2024` | knowledge-guided symbolic regression / model-based design | 10.1016/j.ces.2024.120580 | ScienceDirect; arXiv 2405.04592 |
| `Cranmer2023` | symbolic regression / PySR | No DOI inserted | arXiv; PySR project citation/Zenodo |
| `Cordier2023MAPIE` | conformal prediction / MAPIE | v204 | PMLR article; PMLR volume/GitHub citation |
| `Randahl2026` | conditional/bin conformal prediction | 10.1017/pan.2025.10010 | Cambridge Core; CRAN pintervals description |
| `RTMB2026` | software / automatic differentiation | 10.32614/CRAN.package.RTMB | CRAN RTMB; R-universe RTMB |
| `BayesRTMB2026` | software / Bayesian RTMB | 10.32614/CRAN.package.BayesRTMB | CRAN mirror metadata; CRAN source index |
| `qrNLMM2025` | software / nonlinear mixed quantiles | 10.32614/CRAN.package.qrNLMM | CRAN qrNLMM; CRAN metadata mirror |
| `ctsmTMB2026` | software / continuous-time stochastic models | 10.32614/CRAN.package.ctsmTMB | CRAN ctsmTMB; CRAN DOI metadata |
| `pintervals2026` | software / conformal prediction | 10.32614/CRAN.package.pintervals | CRAN pintervals; CRAN mirror/R-universe manual |
| `Chen2018NeuralODE` | Neural ODE foundation | No DOI confirmed for conference paper | NeurIPS proceedings; DBLP |
| `Raissi2019PINN` | PINN foundation | 10.1016/j.jcp.2018.10.045 | Elsevier JCP; Crossref Crossmark |
| `Rackauckas2020UDE` | Universal Differential Equations | 10.48550/arXiv.2001.04385 | arXiv; official SciML missing-physics documentation |
| `Philipps2025UDEReview` | UDE training/noise/identifiability | 10.1038/s41540-025-00550-w | Nature/npj; PubMed PMID 40885733 |
| `Li2025PINNSoil` | physics-informed Richards soil-water flow | 10.1029/2024WR039108 | Wiley/Water Resources Research article; volume/DOI metadata |
| `Gong2025PINNRichards` | heterogeneous unsaturated-flow PINN | 10.1029/2025WR040040 | Wiley/Water Resources Research; DOI/citation metadata |
| `Qi2026PINNPTF` | site-specific physics-informed pedotransfer functions | 10.1029/2025WR041265 | Wiley article; Wiley issue TOC/AGRIS metadata |
| `Shao2026PlantHeight` | physics-informed longitudinal plant-height modelling | 10.1016/j.compag.2026.111988 | Elsevier metadata; Wageningen University Research Portal |
| `Gress2025SOCUDE` | UDE for soil organic carbon | 10.48550/arXiv.2509.24306 | arXiv; ResearchGate mirror metadata; **preprint** |

## Important interpretive boundaries

- Burger et al. (2025) is included as a state-of-the-art **benchmark**. `nl_quantile_mixed_robust()` is not described as a cGAL implementation.
- Heinrich et al. (2025) and the Julia structural-identifiability ecosystem motivate the distinction between structural and practical identifiability. `nl_structural_identify()` remains a local rank screen.
- Bubel et al. (2025) motivates sparse cubature. `nl_propagate()` uses a simpler transparent deterministic rule and is not labelled as exact reproduction of their algorithm.
- Ghosh et al. (2026) PICS is a sequential nonlinear-design reference. `nl_sequential_discovery()` is a predictive-disagreement design and is not labelled PICS.
- Rogers et al. (2024) motivates the equation-discovery loop; the package requires explicit scientific validation after symbolic search.


- `Rackauckas2020UDE` is a foundational **preprint**; UDE claims in the package are additionally contextualized by the peer-reviewed Philipps et al. (2025) assessment.
- `Gress2025SOCUDE` is explicitly retained as an **agronomic preprint example**. It is not used as evidence that UDE soil-carbon prediction is field-validated.
- The publisher and Wageningen records for `Shao2026PlantHeight` list *Computers and Electronics in Agriculture* volume 251, article 111988, with an issue/publication date of **1 September 2026**. Because this package metadata audit occurred on **17 August 2026**, the record is treated as verified publisher/forthcoming-issue metadata rather than as evidence that the September issue date had already passed.
- Phase-E software APIs are time-dependent. The package ships an environment setup and requires preserving the locally resolved Julia `Project.toml` and `Manifest.toml` rather than inventing a Manifest in an environment where Julia was unavailable.

Software package versions are time-dependent. The versions listed here are those verified on 2026-08-17 and should be refreshed before a later manuscript or CRAN release.