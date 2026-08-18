#' Create publication-ready fitted-curve graphics
#'
#' Creates a ggplot with observed data, fitted curve, and optional uncertainty ribbon. Raw observations are shown by default and an alternative raw-data table can be overlaid when a model was fitted to summaries.
#' @param object An `nlrfit` or a supported Phase D result such as conformal, sensitivity, design, validation, discrimination, sequential-discovery, GP-discrepancy, or surrogate-validation output.
#' @param newdata Optional prediction grid.
#' @param interval Prediction interval type.
#' @param level Interval level.
#' @param x X variable name.
#' @param y Y variable name.
#' @param group Optional grouping aesthetic for observed points.
#' @param boot Optional bootstrap object.
#' @param raw_data Optional data frame used only for plotting observed points, for example individual observations when the fitted object used time-specific means.
#' @param point_alpha Point transparency.
#' @param point_size Point size.
#' @param ... Additional arguments reserved for future themes.
#' @return A `ggplot` object.
#' @examples
#' \dontrun{
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_plot(f,raw_data=nl_data("okra_growth_raw"))
#' f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_plot(f)
#' f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_plot(f)
#' }
#' @export
nl_plot <- function(object,newdata=NULL,interval="confidence",level=.95,x=NULL,y=NULL,group=NULL,boot=NULL,raw_data=NULL,point_alpha=.65,point_size=1.8,...) {
  .nl_require("ggplot2","publication-ready graphics")
  if(!inherits(object,"nlrfit")) {
    p_phase <- .nl_phase_d_plot(object,x=x,y=y,...)
    if(!is.null(p_phase)) return(p_phase)
    stop("Unsupported object class for nl_plot().",call.=FALSE)
  }
  if(identical(object$engine,"brms") && (is.null(x) || is.null(y))) stop("For Bayesian brms fits, specify x= and y= explicitly in nl_plot().",call.=FALSE)
  y <- y %||% .nl_response_name(object$formula)
  if(is.null(x)){v <- .nl_predictor_names(object$formula); v <- v[v %in% names(object$data)]; x <- v[vapply(object$data[v],is.numeric,logical(1))][1]}
  if(is.null(x) || is.na(x) || !x %in% names(object$data)) stop("Specify a valid numeric x variable.",call.=FALSE)
  if(!is.null(group) && !group %in% names(object$data)) stop("group is not present in the fitted data.",call.=FALSE)
  if(is.null(newdata)) {
    grid <- seq(min(object$data[[x]],na.rm=TRUE),max(object$data[[x]],na.rm=TRUE),length.out=200)
    if(is.null(group)) {
      newdata <- object$data[rep(1,length(grid)),,drop=FALSE]; newdata[[x]] <- grid
    } else {
      lev <- unique(object$data[[group]])
      pieces <- lapply(lev,function(g){base <- object$data[which(object$data[[group]]==g)[1],,drop=FALSE]; z <- base[rep(1,length(grid)),,drop=FALSE]; z[[x]]<-grid; z[[group]]<-g; z})
      newdata <- do.call(rbind,pieces); rownames(newdata)<-NULL
      if(is.factor(object$data[[group]])) newdata[[group]] <- factor(newdata[[group]],levels=levels(object$data[[group]]))
    }
  }
  pr <- nl_predict(object,newdata,interval=interval,level=level,boot=boot,nsim=500,...)
  points <- raw_data %||% object$data
  if(!all(c(x,y) %in% names(points))) stop("raw_data must contain the plotted x and y columns.",call.=FALSE)
  if(!is.null(group) && !group %in% names(points)) stop("group is not present in plotting data.",call.=FALSE)
  aes_points <- if(is.null(group)) ggplot2::aes_string(x=x,y=y) else ggplot2::aes_string(x=x,y=y,shape=group)
  p <- ggplot2::ggplot(points,aes_points) + ggplot2::geom_point(alpha=point_alpha,size=point_size) + ggplot2::labs(x=x,y=y) + ggplot2::theme_classic(base_size=11)
  if(is.null(group)) {
    p <- p + ggplot2::geom_line(data=pr,ggplot2::aes_string(x=x,y=".fitted"),inherit.aes=FALSE,linewidth=.8)
    if(interval!="none") p <- p + ggplot2::geom_ribbon(data=pr,ggplot2::aes_string(x=x,ymin=".lower",ymax=".upper"),inherit.aes=FALSE,alpha=.18)
  } else {
    p <- p + ggplot2::geom_line(data=pr,ggplot2::aes_string(x=x,y=".fitted",group=group,linetype=group),inherit.aes=FALSE,linewidth=.8)
    if(interval!="none") p <- p + ggplot2::geom_ribbon(data=pr,ggplot2::aes_string(x=x,ymin=".lower",ymax=".upper",group=group),inherit.aes=FALSE,alpha=.14)
  }
  p
}
#' Create a publication-ready diagnostic panel
#'
#' Builds four standard nonlinear-regression diagnostic ggplots from observed/fitted/residual information.
#' @param object An `nlrfit`.
#' @return A patchwork object when `patchwork` is installed, otherwise a list of ggplots.
#' @examples
#' \dontrun{
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_plot_diagnostics(f)
#' f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_plot_diagnostics(f)
#' f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_plot_diagnostics(f)
#' }
#' @export
nl_plot_diagnostics <- function(object) {.nl_require("ggplot2");if(inherits(object,"nlrfit")&&identical(object$engine,"brms"))stop("Use nl_ppcheck() and nl_bayes_diagnose() for Bayesian posterior diagnostics.",call.=FALSE);r<-as.numeric(residuals(object));f<-as.numeric(fitted(object));resp<-.nl_response_name(object$formula);obs<-object$data[[resp]];d<-data.frame(fitted=f,residual=r,observed=obs,std=r/sqrt(mean(r^2)));p1<-ggplot2::ggplot(d,ggplot2::aes(fitted,residual))+ggplot2::geom_point()+ggplot2::geom_hline(yintercept=0,lty=2)+ggplot2::theme_classic();p2<-ggplot2::ggplot(d,ggplot2::aes(sample=std))+ggplot2::stat_qq()+ggplot2::stat_qq_line()+ggplot2::theme_classic();p3<-ggplot2::ggplot(d,ggplot2::aes(fitted,sqrt(abs(std))))+ggplot2::geom_point()+ggplot2::theme_classic();p4<-ggplot2::ggplot(d,ggplot2::aes(observed,fitted))+ggplot2::geom_point()+ggplot2::geom_abline(slope=1,intercept=0,lty=2)+ggplot2::theme_classic();if(requireNamespace("patchwork",quietly=TRUE))return((p1+p2)/(p3+p4));list(residual_fitted=p1,qq=p2,scale_location=p3,observed_predicted=p4)}
#' Create scientific result tables
#'
#' Returns parameter, fit, diagnostic, or derived-quantity tables in data-frame form, with optional `gt` rendering.
#' @param object An `nlrfit`, `nlrfit_list`, `nlrdiag`, or `nlrderived`.
#' @param type Requested table type.
#' @param render Output mode: `data.frame`, `gt`, `csv`, `xlsx`, `html`, `pdf`, `png`, `latex`, `rtf`, or `docx`.
#' @param file Output path for file-rendering modes.
#' @param ... Additional arguments passed to `gt::gtsave()` for gt-based file exports.
#' @return A data frame or `gt` table for in-memory modes, otherwise the normalized output path invisibly.
#' @examples
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_table(f,"parameters")
#' x <- nl_fit_many(subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),"grain_yield_Mg_ha","P2O5_kg_ha",c("mitscherlich","michaelis_menten"),engine="nls"); nl_table(x,"fit")
#' nl_table(nl_derive(f),"derived")
#' @export
nl_table <- function(object,type=c("parameters","fit","diagnostics","derived"),render=c("data.frame","gt","csv","xlsx","html","pdf","png","latex","rtf","docx"),file=NULL,...) {
  type<-match.arg(type); render<-match.arg(render)
  tab_phase <- .nl_phase_d_table(object)
  tab<-if(!is.null(tab_phase)) tab_phase else switch(type,
    parameters={if(!inherits(object,"nlrfit"))stop("parameters requires nlrfit",call.=FALSE);if(identical(object$engine,"brms")) nl_confint(object,"posterior") else nl_confint(object,"wald")},
    fit={nl_compare(object)},
    diagnostics={if(inherits(object,"nlr_bayes_diagnostic"))data.frame(metric=c("Maximum R-hat","Minimum relative ESS","Divergences","Maximum observed tree depth"),value=c(object$max_rhat,object$min_neff_ratio,object$divergences,object$max_treedepth_observed)) else if(inherits(object,"nlrfit")&&identical(object$engine,"brms")) nl_table(nl_bayes_diagnose(object),"diagnostics") else if(inherits(object,"nlrdiag"))data.frame(metric=c("RMSE","Mean residual","Normal-score correlation","Residual-fitted correlation","Variance log-slope"),value=c(object$rmse,object$mean_residual,object$normal_score_correlation,object$variance_log_slope)) else nl_table(nl_diagnose(object),"diagnostics")},
    derived={if(!inherits(object,"nlrderived"))object<-nl_derive(object);object$summary})
  if(render=="data.frame") return(tab)
  if(render=="gt") {.nl_require("gt","gt table rendering"); return(gt::gt(tab))}
  if(is.null(file) || !nzchar(file)) stop("file= is required for file-rendering table modes.",call.=FALSE)
  if(render=="csv") {utils::write.csv(tab,file,row.names=FALSE,na=""); return(invisible(normalizePath(file,mustWork=FALSE)))}
  if(render=="xlsx") {.nl_require("writexl","XLSX table export"); writexl::write_xlsx(tab,path=file); return(invisible(normalizePath(file,mustWork=FALSE)))}
  .nl_require("gt","publication table export")
  if(render %in% c("pdf","png")) .nl_require("webshot2",paste0(toupper(render)," table export"))
  if(render=="docx") .nl_require("rmarkdown","Word table export")
  expected <- c(html="html",pdf="pdf",png="png",latex="tex",rtf="rtf",docx="docx")[[render]]
  valid <- list(html=c("html","htm"),pdf="pdf",png="png",latex=c("tex","ltx","rnw"),rtf="rtf",docx="docx")[[render]]
  base <- basename(file); has_ext <- grepl("\\.[^.]+$",base); ext <- if(has_ext) tolower(sub("^.*\\.","",base)) else ""
  if(!ext %in% valid) file <- if(has_ext) sub("\\.[^.]+$",paste0(".",expected),file) else paste0(file,".",expected)
  gt::gtsave(gt::gt(tab),filename=file,...)
  invisible(normalizePath(file,mustWork=FALSE))
}
#' Save publication graphics
#'
#' Exports a plot to SVG, PDF, PNG, or TIFF with explicit physical dimensions and resolution.
#' @param plot A ggplot or compatible grid plot.
#' @param file Output filename.
#' @param width Width.
#' @param height Height.
#' @param units Dimension units.
#' @param dpi Raster resolution.
#' @return The normalized output path invisibly.
#' @examples
#' \dontrun{
#' p <- nl_plot(nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls")); nl_save_plot(p,"okra.svg")
#' nl_save_plot(p,"okra.tiff",width=180,height=120,units="mm",dpi=600)
#' nl_save_plot(p,"okra.pdf",width=180,height=120,units="mm")
#' }
#' @export
nl_save_plot <- function(plot,file,width=180,height=120,units="mm",dpi=600) {.nl_require("ggplot2");ggplot2::ggsave(filename=file,plot=plot,width=width,height=height,units=units,dpi=dpi,limitsize=FALSE);invisible(normalizePath(file,mustWork=FALSE))}
#' Generate a reproducible Markdown analysis report
#'
#' Writes a concise scientific report containing specification, coefficients, fit metrics, diagnostics, warnings, and reproducibility information.
#' @param object An `nlrfit`.
#' @param file Markdown output file.
#' @param title Report title.
#' @param include_session Include session information.
#' @return The report path invisibly.
#' @examples
#' \dontrun{
#' f <- nl_fit(data=nl_data("okra_growth_means"),model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls"); nl_report(f,tempfile(fileext=".md"))
#' f <- nl_fit(data=subset(nl_data("soil_fertility_p"),soil_class=="Loamy"),model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls"); nl_report(f,tempfile(fileext=".md"),"Soil fertility nonlinear report")
#' f <- nl_fit(data=subset(nl_data("soil_infiltration"),management=="NoTill"),model="michaelis_menten",response="cumulative_infiltration_mm",predictor="time_min",engine="nls"); nl_report(f,tempfile(fileext=".md"),"Soil infiltration nonlinear report")
#' }
#' @export
nl_report <- function(object,file="nlrFlow_report.md",title="nlrFlow nonlinear regression report",include_session=TRUE) {
  if(inherits(object,c("nlr_neural_ode","nlr_ude","nlr_pinn","nlr_missing_physics","nlr_ude_discovery","nlr_sciml_diagnostics","nlr_dynamic_design","nlr_dynamic_control"))) return(.nl_sciml_report(object,file,title,include_session))
  tab <- nl_table(object,"parameters")
  if(identical(object$engine,"brms")) {
    bd <- nl_bayes_diagnose(object)
    fit_section <- "Bayesian model comparison is intentionally omitted for a single fit; use nl_bayes_compare() for two or more candidate models."
    diag_table <- data.frame(metric=c("Maximum R-hat","Minimum relative ESS","Divergences","Maximum observed tree depth"),value=c(bd$max_rhat,bd$min_neff_ratio,bd$divergences,bd$max_treedepth_observed))
    diag_warnings <- if(length(bd$warnings)) paste("-",bd$warnings,collapse="\n") else "No sampler warning flagged by the compact Bayesian diagnostic screen."
  } else {
    cmp <- nl_compare(list(model=object)); dg <- nl_diagnose(object)
    fit_section <- paste(capture.output(print(cmp,row.names=FALSE)),collapse="\n")
    diag_table <- nl_table(dg,"diagnostics")
    diag_warnings <- if(length(dg$warnings)) paste("-",dg$warnings,collapse="\n") else "None flagged by the compact diagnostic screen."
  }
  con<-file(file,"wt");on.exit(close(con),add=TRUE)
  writeLines(c(paste0("# ",title),"",paste0("Generated: ",Sys.time()),"", "## Model",paste0("Engine: `",object$engine,"`"),paste0("Formula: `",paste(deparse(object$formula),collapse=" "),"`"),"","## Parameters",paste(capture.output(print(tab,row.names=FALSE)),collapse="\n"),"","## Fit",fit_section,"","## Diagnostics",paste(capture.output(print(diag_table,row.names=FALSE)),collapse="\n"),"","## Diagnostic warnings",diag_warnings),con)
  if(include_session)writeLines(c("","## Reproducibility",paste(capture.output(utils::sessionInfo()),collapse="\n")),con)
  invisible(normalizePath(file,mustWork=FALSE))
}
#' Teach a registered nonlinear model
#'
#' Returns a pedagogical model card covering equation, parameters, interpretation, identifiability cautions, starting values, diagnostics, and suitable scientific domains.
#' @param model Registered model name.
#' @return An `nlr_teaching_card` list.
#' @examples
#' nl_teach("richards")
#' nl_teach("mitscherlich")
#' nl_teach("nonrectangular_hyperbola")
#' @export
nl_teach <- function(model) {z<-nl_model_info(model);z$workflow=c("Plot raw observations and identify the scientific mechanism.","Audit predictor support and replication.","Generate biologically plausible starting values.","Fit and verify convergence.","Inspect identifiability, residual structure and influence.","Quantify uncertainty with profile likelihood, bootstrap or posterior distributions.","Interpret parameters and derived biological quantities, not only global fit metrics.");z$warnings=c("Do not select a curve solely by p-values or R-squared.","Do not use likelihood-ratio tests for non-nested curve families.","Do not average replicated data when within-dose/time variability is required for inference.");class(z)<-c("nlr_teaching_card","list");z}
#' Launch or return the nonlinear-regression tutor
#'
#' Returns all teaching cards, or launches an interactive Shiny tutor with model selection, parameter sliders, a predictor-range control, live curve visualization, equations and parameter interpretation when `interactive = TRUE`.
#' @param interactive Logical; request an interactive tutor when possible.
#' @return A list of teaching cards, or a running Shiny application.
#' @examples
#' cards <- nl_tutor(FALSE); names(cards)
#' nl_tutor(FALSE)$richards
#' nl_tutor(FALSE)$nonrectangular_hyperbola
#' @export
nl_tutor <- function(interactive=FALSE) {
  cards <- setNames(lapply(nl_models()$model,nl_teach),nl_models()$model)
  if(!interactive) return(cards)
  if(!requireNamespace("shiny",quietly=TRUE)) stop("Interactive tutor requires the optional shiny package.",call.=FALSE)
  ui <- shiny::fluidPage(
    shiny::titlePanel("nlrFlow interactive nonlinear-model tutor"),
    shiny::sidebarLayout(
      shiny::sidebarPanel(
        shiny::selectInput("model","Model",names(cards)),
        shiny::sliderInput("xrange","Predictor range",min=0,max=100,value=c(0,25),step=1),
        shiny::uiOutput("parameter_controls")
      ),
      shiny::mainPanel(shiny::plotOutput("curve",height="420px"),shiny::verbatimTextOutput("info"))
    )
  )
  server <- function(input,output,session) {
    output$parameter_controls <- shiny::renderUI({
      pars <- cards[[input$model]]$parameters
      shiny::tagList(lapply(pars,function(nm){r <- .nl_tutor_ranges(nm); step <- (r[2]-r[1])/200; shiny::sliderInput(paste0("par_",nm),nm,min=r[1],max=r[2],value=r[3],step=step)}))
    })
    params <- shiny::reactive({
      pars <- cards[[input$model]]$parameters; vals <- vapply(pars,function(nm) input[[paste0("par_",nm)]] %||% .nl_tutor_ranges(nm)[3],numeric(1)); stats::setNames(vals,pars)
    })
    output$curve <- shiny::renderPlot({
      shiny::req(input$model,input$xrange)
      x <- seq(input$xrange[1],input$xrange[2],length.out=400); f <- .nl_model_formula(input$model,"y","x")
      y <- try(.nl_rhs_eval(f,data.frame(x=x),params()),silent=TRUE)
      if(inherits(y,"try-error") || any(!is.finite(y))) {graphics::plot.new();graphics::text(.5,.5,"Current parameter combination is outside the numerically stable region.");return(invisible())}
      graphics::plot(x,y,type="l",lwd=2,xlab="Predictor",ylab="Response",main=input$model)
      graphics::grid()
    })
    output$info <- shiny::renderPrint({
      z <- cards[[input$model]]; list(equation=z$equation,parameters=z$parameter_table,teaching_note=z$notes,workflow=z$workflow)
    })
  }
  shiny::shinyApp(ui,server)
}
#' Check the local nlrFlow scientific environment
#'
#' Checks optional engines, R version, package source version, and capability availability without installing anything.
#' @return A structured environment report.
#' @examples
#' nl_doctor()
#' subset(nl_doctor()$capabilities, !available)
#' nl_doctor()$r_version
#' @export
nl_doctor <- function() {list(package_version=tryCatch(as.character(utils::packageVersion("nlrFlow")),error=function(e)"source-tree"),r_version=R.version.string,capabilities=nl_capabilities(),note="Unavailable optional packages disable only their corresponding advanced backends; core NLS remains available through base R.")}
