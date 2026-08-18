\name{nl_ude}
\alias{nl_ude}
\title{Fit a Universal Differential Equation (UDE)}
\description{Combines a known mechanistic derivative with a neural correction. This is the preferred SciML mode when agronomic knowledge is available but incomplete. Built-in templates cover radiation-use-efficiency crop growth, fruit growth, N uptake, and soil-carbon turnover; advanced users may supply Julia derivative expressions through `known_rhs`.}
\usage{nl_ude(data,time,states,covariates=character(),template=c("generic","crop_growth_rue","fruit_growth","nitrogen_uptake","soil_carbon"), known_parameters=numeric(),known_rhs=NULL,neural_scale=1,hidden=c(16,16),maxiters=600, learning_rate=.01,weight_decay=1e-6,refine=TRUE,seed=20260817,julia=NULL,output_dir=NULL,dry_run=FALSE)}
\arguments{
  \item{data}{One dynamic trajectory.}
  \item{time}{Time column.}
  \item{states}{State columns.}
  \item{covariates}{Numeric covariates.}
  \item{template}{Mechanistic template or `generic`.}
  \item{known_parameters}{Named numeric vector/list of mechanistic parameters.}
  \item{known_rhs}{Optional character vector of Julia expressions, one per state.}
  \item{neural_scale}{Multiplicative scale for the learned correction.}
  \item{hidden}{Hidden-layer widths.}
  \item{maxiters}{Training iterations.}
  \item{learning_rate}{Adam learning rate.}
  \item{weight_decay}{Nonnegative L2 penalty on the neural correction; useful for protecting mechanistic interpretability.}
  \item{refine}{Logical BFGS refinement.}
  \item{seed}{Seed.}
  \item{julia}{Julia executable.}
  \item{output_dir}{Optional output directory.}
  \item{dry_run}{Return specification only.}
}
\value{An `nlr_ude` object or dry-run specification.}
\examples{
d<-subset(nl_data("sciml_crop_growth"),plot_id==unique(nl_data("sciml_crop_growth")$plot_id)[1]);nl_ude(d,"day","biomass_g_m2",c("temperature_C","PAR_MJ_m2_d","soil_water_rel","nitrogen_rel"),template="crop_growth_rue",known_parameters=c(RUE=2.8,Topt=26,Twidth=10,respiration=.01),dry_run=TRUE)
d<-subset(nl_data("sciml_fruit_growth"),fruit_id==unique(nl_data("sciml_fruit_growth")$fruit_id)[1]);nl_ude(d,"day_after_set","fruit_mass_g",c("temperature_C","soil_water_rel"),template="fruit_growth",known_parameters=c(r=.2,K=200),dry_run=TRUE)
d<-subset(nl_data("sciml_fertility_dynamic"),plot_id==unique(nl_data("sciml_fertility_dynamic")$plot_id)[1]);nl_ude(d,"day",c("plant_N_g_m2","soil_mineral_N_mg_kg"),c("temperature_C","soil_water_rel"),template="nitrogen_uptake",known_parameters=c(vmax=.08,Km=20),dry_run=TRUE)
}
