# Phase D visualization/table adapters -------------------------------------

.nl_phase_d_plot <- function(object, x=NULL, y=NULL, ...) {
  pe <- .nl_phase_e_plot(object,x=x,y=y,...); if(!is.null(pe)) return(pe)
  .nl_require("ggplot2","Phase D publication graphics")
  if(inherits(object,"nlr_conformal") || inherits(object,"nlr_conformal_group")) {
    nd <- object$newdata %||% object$fit$data
    if(is.null(x)) {
      v <- .nl_predictor_names(object$fit$formula)
      x <- v[vapply(nd[v],is.numeric,logical(1))][1]
    }
    if(is.null(x)||is.na(x)||!x%in%names(nd)) stop("Specify x= for the conformal interval plot.",call.=FALSE)
    d <- cbind(nd,object$interval)
    p <- ggplot2::ggplot(d,ggplot2::aes(x=.data[[x]],y=.data[[".prediction"]])) +
      ggplot2::geom_ribbon(ggplot2::aes(ymin=.lower,ymax=.upper),alpha=.18) +
      ggplot2::geom_line(linewidth=.8) + ggplot2::theme_classic(base_size=11) +
      ggplot2::labs(y="Prediction",subtitle=object$method)
    return(p)
  }
  if(inherits(object,"nlr_sensitivity")) {
    d<-object$indices
    value <- if("ST"%in%names(d)) "ST" else if("mu_star"%in%names(d)) "mu_star" else if("elasticity"%in%names(d)) "elasticity" else names(d)[2]
    d$parameter_plot <- stats::reorder(d$parameter,d[[value]])
    return(ggplot2::ggplot(d,ggplot2::aes(x=.data[["parameter_plot"]],y=.data[[value]]))+
      ggplot2::geom_point(size=2.4)+ggplot2::coord_flip()+ggplot2::theme_classic(base_size=11)+
      ggplot2::labs(x="Parameter",y=value,subtitle=paste("Sensitivity method:",object$method)))
  }
  if(inherits(object,"nlr_design")) {
    d<-object$trajectory
    return(ggplot2::ggplot(d,ggplot2::aes(x=point,y=score))+
      ggplot2::geom_line()+ggplot2::geom_point(size=2.4)+ggplot2::theme_classic(base_size=11)+
      ggplot2::labs(x=object$predictor,y=paste0(object$criterion,"-optimal score"),subtitle="Sequentially selected design points"))
  }
  if(inherits(object,"nlr_candidate_validation")) {
    d<-object$grid;d$.prediction<-object$prediction
    return(ggplot2::ggplot(d,ggplot2::aes(x=.data[[object$predictor]],y=.data[[".prediction"]]))+
      ggplot2::geom_line(linewidth=.8)+ggplot2::theme_classic(base_size=11)+
      ggplot2::labs(y="Candidate prediction",subtitle=paste("Scientific checks:",if(object$pass)"PASS" else "FAIL")))
  }
  if(inherits(object,"nlr_discrimination")) {
    d<-object$ranking
    return(ggplot2::ggplot(d,ggplot2::aes(x=reorder(model,AICc),y=AICc))+
      ggplot2::geom_point(ggplot2::aes(shape=valid),size=2.5)+ggplot2::coord_flip()+ggplot2::theme_classic(base_size=11)+
      ggplot2::labs(x="Model",y="AICc",shape="Constraint-valid",subtitle="Model discrimination ranking"))
  }
  if(inherits(object,"nlr_sequential_discovery")) {
    d<-object$scores[[length(object$scores)]]
    return(ggplot2::ggplot(d,ggplot2::aes(x=candidate,y=score))+
      ggplot2::geom_line()+ggplot2::geom_point(ggplot2::aes(shape=eligible),size=1.8)+
      ggplot2::geom_vline(xintercept=object$selected,linetype=2,alpha=.5)+ggplot2::theme_classic(base_size=11)+
      ggplot2::labs(x=object$predictor,y="Discrimination score",shape="Eligible",subtitle="Sequential model-discrimination design"))
  }
  if(inherits(object,"nlr_gp_discrepancy")) {
    nd<-object$newdata
    if(is.null(x)) x<-object$predictors[1]
    d<-data.frame(x=nd[[x]],mechanistic=object$mechanistic,corrected=object$corrected,
                  lower=object$corrected-1.96*object$discrepancy_se,upper=object$corrected+1.96*object$discrepancy_se)
    return(ggplot2::ggplot(d,ggplot2::aes(x=x,y=corrected))+
      ggplot2::geom_ribbon(ggplot2::aes(ymin=lower,ymax=upper),alpha=.18)+
      ggplot2::geom_line(linewidth=.8)+ggplot2::geom_line(ggplot2::aes(y=mechanistic),linetype=2)+
      ggplot2::theme_classic(base_size=11)+ggplot2::labs(x=x,y="Response",subtitle="Mechanistic fit plus GP discrepancy"))
  }
  if(inherits(object,"nlr_surrogate_validation")) {
    d<-object$predictions
    return(ggplot2::ggplot(d,ggplot2::aes(x=observed,y=.prediction))+
      ggplot2::geom_abline(slope=1,intercept=0,linetype=2)+ggplot2::geom_point(size=2)+
      ggplot2::geom_errorbar(ggplot2::aes(ymin=lower,ymax=upper),width=0,alpha=.5)+
      ggplot2::theme_classic(base_size=11)+ggplot2::labs(y="Surrogate prediction",subtitle="Surrogate validation"))
  }
  NULL
}

.nl_phase_d_table <- function(object) {
  te <- .nl_phase_e_table(object); if(!is.null(te)) return(te)
  if(inherits(object,"nlr_conformal")||inherits(object,"nlr_conformal_group")) return(object$interval)
  if(inherits(object,"nlr_sensitivity")) return(object$indices)
  if(inherits(object,"nlr_design")) return(object$trajectory)
  if(inherits(object,"nlr_candidate_validation")) return(cbind(object$checks,object$metrics[rep(1,nrow(object$checks)),,drop=FALSE]))
  if(inherits(object,"nlr_discovery")) return(object$table)
  if(inherits(object,"nlr_discrimination")) return(object$ranking)
  if(inherits(object,"nlr_sequential_discovery")) return(object$scores[[length(object$scores)]])
  if(inherits(object,"nlr_surrogate_validation")) return(object$metrics)
  if(inherits(object,"nlr_structural_identifiability")) return(data.frame(parameter=colnames(object$jacobian),status=object$status,stringsAsFactors=FALSE))
  if(inherits(object,"nlr_error_decomposition")) return(data.frame(component=c(names(object$process_parameters),names(object$observation_parameters)),value=c(object$process_parameters,object$observation_parameters),type=c(rep("process",length(object$process_parameters)),rep("observation",length(object$observation_parameters)))))
  NULL
}
