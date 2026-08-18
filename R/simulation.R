#' Simulate nonlinear scientific datasets
#'
#' Simulates observations from registered nonlinear models with optional groups, group-specific parameter shifts, Gaussian or Student-t noise, heteroscedasticity, and frozen seeds.
#' @param model Registered model.
#' @param x Predictor vector.
#' @param parameters Named parameter values.
#' @param sigma Residual scale.
#' @param distribution `gaussian` or `student`.
#' @param hetero_power Power controlling residual scale growth with fitted magnitude.
#' @param group Optional group vector.
#' @param group_effects Optional named list whose elements are named parameter-shift vectors for corresponding group labels.
#' @param seed Random seed.
#' @return A data frame with predictor, fitted truth, response, and optional group.
#' @examples
#' nl_simulate("gompertz",1:25,c(Asym=18,k=.44,xmid=3.7),sigma=.5,seed=1)
#' nl_simulate("mitscherlich",c(0,30,60,90,120,180),c(Asym=8,delta=5,k=.025),sigma=.25,hetero_power=.5,seed=2)
#' nl_simulate("rectangular_hyperbola",c(0,100,300,600,1000,1600),c(Amax=30,alpha=.07,Rd=1.2),sigma=.6,distribution="student",seed=3)
#' # Group-specific parameter shifts are explicit and auditable.
#' nl_simulate("gompertz",rep(1:10,2),c(Asym=18,k=.4,xmid=4),group=rep(c("Control","Stress"),each=10),group_effects=list(Stress=c(Asym=-3,k=-.05)),seed=4)
#' @export
nl_simulate <- function(model,x,parameters,sigma=1,distribution=c("gaussian","student"),hetero_power=0,group=NULL,group_effects=NULL,seed=20260817) {
  distribution<-match.arg(distribution); form<-.nl_model_formula(model,"y","x"); dat<-data.frame(x=x)
  if(!is.null(group) && length(group)!=length(x)) stop("group must have the same length as x.",call.=FALSE)
  if(is.null(group)) mu <- .nl_rhs_eval(form,dat,parameters) else {
    g <- as.character(group); mu <- numeric(length(x)); effects <- group_effects %||% list()
    if(length(effects) && (is.null(names(effects)) || !is.list(effects))) stop("group_effects must be a named list of named parameter shifts.",call.=FALSE)
    for(lev in unique(g)) {
      idx <- which(g==lev); par <- parameters
      if(lev %in% names(effects)) {
        sh <- effects[[lev]]; if(is.null(names(sh)) || any(!names(sh)%in%names(par))) stop("Each group-effect vector must be named with valid model parameters.",call.=FALSE)
        par[names(sh)] <- par[names(sh)] + sh
      }
      mu[idx] <- .nl_rhs_eval(form,dat[idx,,drop=FALSE],par)
    }
  }
  sc<-sigma*pmax(abs(mu),1)^hetero_power;set.seed(seed);e<-if(distribution=="gaussian")stats::rnorm(length(x),0,sc) else stats::rt(length(x),df=4)*sc/sqrt(2)
  out<-data.frame(x=x,truth=mu,y=mu+e);if(!is.null(group))out$group<-group;out
}
