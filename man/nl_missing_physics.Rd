\name{nl_missing_physics}
\alias{nl_missing_physics}
\title{Extract and summarize the missing mechanism learned by a UDE}
\description{Separates known and neural derivative contributions, computes their relative importance, and identifies where the learned correction is largest.}
\usage{nl_missing_physics(object,state=NULL,threshold=.25)}
\arguments{
  \item{object}{An `nlr_ude` object.}
  \item{state}{Optional state name; defaults to all states.}
  \item{threshold}{Relative neural contribution used to flag important regions.}
}
\value{An `nlr_missing_physics` object.}
\examples{
fake1<-structure(list(decomposition=data.frame(time=0:2,state="biomass",known=c(2,2,1),neural=c(.2,.6,.1),total=c(2.2,2.6,1.1))),class="nlr_ude");nl_missing_physics(fake1)
fake2<-structure(list(decomposition=data.frame(time=0:2,state="fruit",known=c(3,2,1),neural=c(.1,-.2,.5),total=c(3.1,1.8,1.5))),class="nlr_ude");nl_missing_physics(fake2,threshold=.15)
fake3<-structure(list(decomposition=data.frame(time=0:2,state=c("plantN","plantN","plantN"),known=c(.5,.4,.3),neural=c(.3,.1,.05),total=c(.8,.5,.35))),class="nlr_ude");nl_missing_physics(fake3,"plantN")
}
