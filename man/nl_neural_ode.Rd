\name{nl_neural_ode}
\alias{nl_neural_ode}
\title{Fit a Neural ODE to an agronomic dynamic trajectory}
\description{Fits a continuous-time neural differential equation in which a Lux neural network represents the derivative of one or more observed states. Exogenous covariates are linearly interpolated through time. Julia/SciML is an optional backend; `dry_run=TRUE` returns the complete execution specification without running Julia.}
\usage{nl_neural_ode(data,time,states,covariates=character(),hidden=c(16,16),activation="tanh", maxiters=500,learning_rate=.01,weight_decay=0,refine=TRUE,seed=20260817, julia=NULL,output_dir=NULL,dry_run=FALSE)}
\arguments{
  \item{data}{Data frame for one dynamic trajectory.}
  \item{time}{Time column.}
  \item{states}{Character vector of response/state columns.}
  \item{covariates}{Numeric time-varying covariates.}
  \item{hidden}{Hidden-layer widths.}
  \item{activation}{Activation function (`tanh`, `relu`, or `swish`).}
  \item{maxiters}{Adam iterations before optional BFGS refinement.}
  \item{learning_rate}{Adam learning rate.}
  \item{weight_decay}{Nonnegative L2 penalty on neural-network parameters.}
  \item{refine}{Logical; perform BFGS refinement.}
  \item{seed}{Reproducible seed.}
  \item{julia}{Julia executable.}
  \item{output_dir}{Optional persistent output directory.}
  \item{dry_run}{Return specification without execution.}
}
\value{An `nlr_neural_ode` object or an `nlr_sciml_spec` in dry-run mode.}
\examples{
d<-subset(nl_data("sciml_fruit_growth"),fruit_id==unique(nl_data("sciml_fruit_growth")$fruit_id)[1]);nl_neural_ode(d,"day_after_set","fruit_mass_g",c("temperature_C","soil_water_rel"),dry_run=TRUE)
d<-subset(nl_data("sciml_crop_growth"),plot_id==unique(nl_data("sciml_crop_growth")$plot_id)[1]);nl_neural_ode(d,"day","biomass_g_m2",c("temperature_C","PAR_MJ_m2_d","soil_water_rel","nitrogen_rel"),dry_run=TRUE)
d<-subset(nl_data("sciml_physiology_dynamic"),plant_id==unique(nl_data("sciml_physiology_dynamic")$plant_id)[1]);nl_neural_ode(d,"hour",c("A_umol_CO2_m2_s","gs_mol_H2O_m2_s"),c("PAR_umol_m2_s","VPD_kPa","leaf_temperature_C","soil_water_rel"),dry_run=TRUE)
}
