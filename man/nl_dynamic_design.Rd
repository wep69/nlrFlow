\name{nl_dynamic_design}
\alias{nl_dynamic_design}
\title{Optimize measurement times for a dynamic SciML model}
\description{Scores candidate times using trajectory curvature, predictive disagreement, or uncertainty supplied by an executed dynamic model. It can be used after a UDE or Neural ODE to decide when the next destructive or sensor measurement should be collected.}
\usage{nl_dynamic_design(object,candidates,n_points=3,criterion=c("curvature","discrimination","uncertainty"),min_distance=0,dimension=c("time","depth"))}
\arguments{
  \item{object}{Executed SciML model or a list of competing executed models.}
  \item{candidates}{Candidate time or depth values.}
  \item{dimension}{Design axis: `time` for all dynamic models or `depth` for long-form Richards PINN output.}
  \item{n_points}{Number of times to select.}
  \item{criterion}{`curvature`, `discrimination`, or `uncertainty`.}
  \item{min_distance}{Minimum spacing between selected times.}
}
\value{An `nlr_dynamic_design` object.}
\examples{
x<-data.frame(time=seq(0,30,by=3),fruit_mass_g=seq(5,190,length.out=11));fake<-structure(list(predictions=data.frame(time=x$time,fruit_mass_g_predicted=x$fruit_mass_g),time="time",states="fruit_mass_g"),class="nlr_neural_ode");nl_dynamic_design(fake,0:30,3)
x<-data.frame(time=0:20,y_predicted=(0:20)^2);fake<-structure(list(predictions=x,time="time",states="y"),class="nlr_ude");nl_dynamic_design(fake,0:20,4,criterion="curvature")
a<-structure(list(predictions=data.frame(time=0:20,y_predicted=0:20),time="time",states="y"),class="nlr_neural_ode");b<-structure(list(predictions=data.frame(time=0:20,y_predicted=(0:20)^1.15),time="time",states="y"),class="nlr_neural_ode");nl_dynamic_design(list(a,b),0:20,3,criterion="discrimination")
}
