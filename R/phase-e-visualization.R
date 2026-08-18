# Phase E plotting and table adapters ---------------------------------------

.nl_phase_e_plot <- function(object, x=NULL, y=NULL, ...) {
  if(!inherits(object,c("nlr_neural_ode","nlr_ude","nlr_pinn","nlr_missing_physics","nlr_ude_discovery","nlr_sciml_diagnostics","nlr_dynamic_design","nlr_dynamic_control"))) return(NULL)
  .nl_require("ggplot2","SciML publication graphics")
  if(inherits(object,c("nlr_neural_ode","nlr_ude"))) {
    d<-object$predictions;if(is.null(d))return(NULL);time<-object$time %||% names(d)[1];states<-object$states
    pieces<-lapply(states,function(st){po<-paste0(st,"_observed");pp<-paste0(st,"_predicted");if(!all(c(po,pp)%in%names(d)))return(NULL);data.frame(time=d[[time]],state=st,observed=d[[po]],predicted=d[[pp]])});z<-do.call(rbind,pieces[!vapply(pieces,is.null,logical(1))]);if(is.null(z))return(NULL)
    return(ggplot2::ggplot(z,ggplot2::aes(time,predicted))+ggplot2::geom_line(linewidth=.8)+ggplot2::geom_point(ggplot2::aes(y=observed),alpha=.65,size=1.6)+ggplot2::facet_wrap(~state,scales="free_y")+ggplot2::theme_classic(base_size=11)+ggplot2::labs(x=time,y="State",subtitle=if(inherits(object,"nlr_ude"))"Universal differential equation" else "Neural ODE"))
  }
  if(inherits(object,"nlr_pinn")) {
    d<-object$predictions;if(is.null(d))return(NULL)
    if(all(c("time","depth","predicted")%in%names(d))) return(ggplot2::ggplot(d,ggplot2::aes(time,depth,fill=predicted))+ggplot2::geom_tile()+ggplot2::geom_point(ggplot2::aes(color=observed-predicted),size=1.5,alpha=.75)+ggplot2::scale_y_reverse()+ggplot2::theme_classic(base_size=11)+ggplot2::labs(x=object$time,y=object$depth,fill="Predicted water content",color="Observed - predicted",subtitle="Physics-informed Richards-equation trajectory"))
    pred<-grep("_predicted$",names(d),value=TRUE)[1];obs<-sub("_predicted$","_observed",pred);return(ggplot2::ggplot(d,ggplot2::aes(x=.data[[names(d)[1]]],y=.data[[pred]]))+ggplot2::geom_line(linewidth=.8)+ggplot2::geom_point(ggplot2::aes(y=.data[[obs]]),alpha=.65)+ggplot2::theme_classic(base_size=11)+ggplot2::labs(y=object$response,subtitle=paste("PINN:",object$problem)))
  }
  if(inherits(object,"nlr_missing_physics")) {
    d<-object$decomposition;return(ggplot2::ggplot(d,ggplot2::aes(time))+ggplot2::geom_line(ggplot2::aes(y=known,linetype="Known mechanism"),linewidth=.75)+ggplot2::geom_line(ggplot2::aes(y=neural,linetype="Learned correction"),linewidth=.75)+ggplot2::geom_line(ggplot2::aes(y=total,linetype="Combined derivative"),linewidth=.85)+ggplot2::facet_wrap(~state,scales="free_y")+ggplot2::theme_classic(base_size=11)+ggplot2::labs(y="Derivative contribution",linetype=NULL,subtitle="Known versus learned dynamics"))
  }
  if(inherits(object,"nlr_ude_discovery")) {
    d<-object$candidates;if(is.null(d))return(NULL);return(ggplot2::ggplot(d,ggplot2::aes(complexity,loss))+ggplot2::geom_line()+ggplot2::geom_point(size=2.2)+ggplot2::theme_classic(base_size=11)+ggplot2::labs(y="Symbolic-regression loss",subtitle="Pareto frontier: accuracy versus equation complexity"))
  }
  if(inherits(object,"nlr_sciml_diagnostics")) {
    tr<-object$training;if(!is.null(tr)&&all(c("iteration","loss")%in%names(tr)))return(ggplot2::ggplot(tr,ggplot2::aes(iteration,loss))+ggplot2::geom_line()+ggplot2::scale_y_log10()+ggplot2::theme_classic(base_size=11)+ggplot2::labs(subtitle="SciML training convergence"));d<-object$table;return(ggplot2::ggplot(d,ggplot2::aes(reorder(metric,value),value))+ggplot2::geom_point()+ggplot2::coord_flip()+ggplot2::theme_classic(base_size=11)+ggplot2::labs(x=NULL,subtitle="SciML diagnostic indicators"))
  }
  if(inherits(object,"nlr_dynamic_design")) {d<-object$scores;axis<-object$dimension %||% names(d)[1];return(ggplot2::ggplot(d,ggplot2::aes(x=.data[[axis]],y=.data[["score"]]))+ggplot2::geom_line()+ggplot2::geom_point(ggplot2::aes(shape=selected),size=2.2)+ggplot2::theme_classic(base_size=11)+ggplot2::labs(x=axis,y="Design score",shape="Selected",subtitle=paste("Dynamic design criterion:",object$criterion)))}
  if(inherits(object,"nlr_dynamic_control")) {d<-object$control;if(is.null(d))return(NULL);return(ggplot2::ggplot(d,ggplot2::aes(time,control))+ggplot2::geom_step(linewidth=.8)+ggplot2::geom_point(size=2)+ggplot2::theme_classic(base_size=11)+ggplot2::labs(y="Optimized control",subtitle="Bounded dynamic-control schedule"))}
  NULL
}

.nl_phase_e_table <- function(object) {
  if(inherits(object,c("nlr_neural_ode","nlr_pinn"))) return(object$summary %||% object$predictions)
  if(inherits(object,"nlr_ude")) return(object$summary %||% object$decomposition)
  if(inherits(object,"nlr_missing_physics")) return(object$summary)
  if(inherits(object,"nlr_ude_discovery")) return(object$candidates)
  if(inherits(object,"nlr_sciml_diagnostics")) return(object$table)
  if(inherits(object,"nlr_dynamic_design")) return(object$scores)
  if(inherits(object,"nlr_dynamic_control")) return(object$control %||% object$summary)
  NULL
}

.nl_sciml_report <- function(object,file,title="nlrFlow SciML report",include_session=TRUE) {
  tab<-.nl_phase_e_table(object);con<-file(file,"wt");on.exit(close(con),add=TRUE)
  cls<-class(object)[1];writeLines(c(paste0("# ",title),"",paste0("Generated: ",Sys.time()),"",paste0("SciML object: `",cls,"`"),"","## Main results",paste(capture.output(print(tab,row.names=FALSE)),collapse="\n")),con)
  if(!is.null(object$predictions))writeLines(c("","## Prediction output",paste0("Rows: ",nrow(object$predictions))),con)
  if(!is.null(object$training))writeLines(c("","## Training",paste0("Recorded iterations: ",nrow(object$training))),con)
  writeLines(c("","## Interpretation safeguards","- Compare against a simpler mechanistic or nonlinear model whenever possible.","- Inspect extrapolation and seed-to-seed stability before scientific interpretation.","- A learned neural correction is a hypothesis about missing dynamics, not proof of a mechanism.","- Symbolic equations discovered from a UDE require independent validation or a new experiment."),con)
  if(include_session)writeLines(c("","## Reproducibility",paste(capture.output(utils::sessionInfo()),collapse="\n")),con)
  invisible(normalizePath(file,mustWork=FALSE))
}
