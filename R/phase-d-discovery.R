# Phase D2: symbolic discovery, validation and sequential model discrimination --

#' Symbolic regression through PySR
#'
#' Runs high-performance symbolic regression through the optional Python `pysr`
#' package (whose search engine is SymbolicRegression.jl). The function returns
#' the Pareto-style equation table rather than silently selecting a biological
#' law. Candidate equations should subsequently be screened with
#' `nl_validate_candidate()` or entered into `nl_discover()` with explicit
#' parameterization and domain constraints.
#'
#' @param data Data frame.
#' @param response Numeric response column name.
#' @param predictors Character vector of numeric predictor columns.
#' @param niterations PySR evolutionary iterations.
#' @param binary_operators Allowed binary operators.
#' @param unary_operators Allowed unary operators.
#' @param maxsize Maximum expression complexity/size.
#' @param model_selection PySR model-selection rule.
#' @param python_env Optional reticulate Python environment name/path.
#' @param seed Random seed forwarded when supported by PySR.
#' @param ... Additional named arguments passed to `pysr.PySRRegressor`.
#' @return An `nlr_symbolic` object containing the Python model and equation table.
#' @examples
#' \dontrun{
#' o <- nl_data("okra_growth_means"); nl_symbolic(o,"fruit_length","day_after_flowering",niterations=100)
#' f <- nl_data("soil_fertility_p"); nl_symbolic(f,"grain_yield_Mg_ha","P2O5_kg_ha",niterations=100)
#' p <- nl_data("plant_physiology_light"); nl_symbolic(p,"A_umol_CO2_m2_s","PAR_umol_m2_s",niterations=100)
#' }
#' @export
nl_symbolic <- function(data,response,predictors,niterations=200,
                        binary_operators=c("+","-","*","/"),
                        unary_operators=c("exp","log","sqrt"),maxsize=20,
                        model_selection=c("best","accuracy","score"),
                        python_env=NULL,seed=20260817,...) {
  .nl_require("reticulate","PySR symbolic regression")
  model_selection<-match.arg(model_selection)
  if(!response%in%names(data)||!all(predictors%in%names(data)))stop("response/predictors must be columns in data.",call.=FALSE)
  if(!is.numeric(data[[response]])||any(!vapply(data[predictors],is.numeric,logical(1))))stop("PySR response and predictors must be numeric.",call.=FALSE)
  if(!is.null(python_env)) reticulate::use_python(python_env,required=FALSE)
  pysr<-tryCatch(reticulate::import("pysr",delay_load=FALSE),error=function(e)e)
  if(inherits(pysr,"error"))stop("Python package 'pysr' is not available in the active reticulate environment. Install and configure PySR before using this backend.",call.=FALSE)
  args<-c(list(niterations=as.integer(niterations),binary_operators=as.list(binary_operators),
               unary_operators=as.list(unary_operators),maxsize=as.integer(maxsize),
               model_selection=model_selection,random_state=as.integer(seed),
               deterministic=TRUE,parallelism="serial"),list(...))
  reg<-do.call(pysr$PySRRegressor,args)
  X<-as.matrix(data[,predictors,drop=FALSE]);y<-as.numeric(data[[response]])
  reg$fit(X,y,variable_names=as.list(predictors))
  eq<-tryCatch(reticulate::py_to_r(reg$equations_),error=function(e)NULL)
  structure(list(model=reg,equations=eq,response=response,predictors=predictors,
                 operators=list(binary=binary_operators,unary=unary_operators),
                 niterations=niterations,maxsize=maxsize,seed=seed,call=match.call()),
            class="nlr_symbolic")
}

.nl_mode_value <- function(x) {
  if(is.factor(x))return(factor(levels(x)[1],levels=levels(x)))
  if(is.character(x))return(x[which.max(tabulate(match(x,unique(x))))])
  if(is.logical(x))return(FALSE)
  if(is.numeric(x))return(stats::median(x,na.rm=TRUE))
  x[1]
}

.nl_prediction_grid <- function(object,predictor,grid_n=200,extrapolation=.1,template=NULL) {
  d<-object$data;if(!predictor%in%names(d))stop("predictor is absent from fitted data.",call.=FALSE);x<-as.numeric(d[[predictor]]);r<-range(x,na.rm=TRUE);span<-diff(r);lo<-r[1]-extrapolation*span;hi<-r[2]+extrapolation*span
  if(is.null(template)){template<-d[1,,drop=FALSE];for(nm in names(template))template[[nm]]<-.nl_mode_value(d[[nm]])}
  g<-template[rep(1,grid_n),,drop=FALSE];g[[predictor]]<-seq(lo,hi,length.out=grid_n);g
}

#' Validate a candidate nonlinear equation against scientific constraints
#'
#' Combines predictive diagnostics with shape/domain checks. It can test finite
#' extrapolation, positivity, monotonicity, response bounds, parameter bounds,
#' and k-fold predictive error. Constraints are supplied explicitly so they are
#' scientific assumptions rather than hidden package defaults.
#'
#' @param object A refit-capable `nlrfit`.
#' @param predictor Main predictor used to build a dense validation grid.
#' @param constraints Named list. Supported entries are `positive`, `monotonic`
#'   (`increasing`, `decreasing`, or `none`), `response_range`, and
#'   `parameter_bounds` (two-column matrix with parameter row names).
#' @param grid_n Number of grid points.
#' @param extrapolation Fraction of observed predictor range added on each side.
#' @param k Number of CV folds; set `NULL` to skip cross-validation.
#' @param template Optional one-row covariate template for the prediction grid.
#' @param tolerance Numerical tolerance for shape violations.
#' @return An `nlr_candidate_validation` object with checks and metrics.
#' @examples
#' o<-nl_data("okra_growth_means");fo<-nl_fit(data=o,model="gompertz",response="fruit_length",predictor="day_after_flowering",engine="nls");nl_validate_candidate(fo,"day_after_flowering",list(positive=TRUE,monotonic="increasing",response_range=c(0,30)))
#' f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy");ff<-nl_fit(data=f,model="mitscherlich",response="grain_yield_Mg_ha",predictor="P2O5_kg_ha",engine="nls");nl_validate_candidate(ff,"P2O5_kg_ha",list(positive=TRUE,monotonic="increasing"))
#' s<-subset(nl_data("soil_p_sorption"),soil_class=="Clayey");fs<-nl_fit(data=s,model="langmuir",response="sorbed_P_mg_kg",predictor="solution_P_mg_L",engine="nls");nl_validate_candidate(fs,"solution_P_mg_L",list(positive=TRUE,monotonic="increasing"))
#' @export
nl_validate_candidate <- function(object,predictor,constraints=list(),grid_n=200,
                                  extrapolation=.1,k=5,template=NULL,tolerance=1e-8) {
  if(!inherits(object,"nlrfit"))stop("object must be an nlrfit.",call.=FALSE)
  grid<-.nl_prediction_grid(object,predictor,grid_n,extrapolation,template);pred<-tryCatch(as.numeric(stats::predict(object$fit,newdata=grid)),error=function(e)rep(NA_real_,nrow(grid)))
  finite_ok<-all(is.finite(pred));checks<-data.frame(check="finite_predictions",pass=finite_ok,violations=sum(!is.finite(pred)),stringsAsFactors=FALSE)
  if(isTRUE(constraints$positive)){v<-sum(pred < -tolerance,na.rm=TRUE);checks<-rbind(checks,data.frame(check="positive_response",pass=v==0,violations=v))}
  mono<-constraints$monotonic%||%"none";if(!mono%in%c("none","increasing","decreasing"))stop("constraints$monotonic must be none/increasing/decreasing.",call.=FALSE)
  if(mono!="none"){dp<-diff(pred);v<-if(mono=="increasing")sum(dp < -tolerance,na.rm=TRUE) else sum(dp > tolerance,na.rm=TRUE);checks<-rbind(checks,data.frame(check=paste0("monotonic_",mono),pass=v==0,violations=v))}
  if(!is.null(constraints$response_range)){rr<-as.numeric(constraints$response_range);if(length(rr)!=2||rr[1]>=rr[2])stop("response_range must contain lower < upper.",call.=FALSE);v<-sum(pred<rr[1]-tolerance|pred>rr[2]+tolerance,na.rm=TRUE);checks<-rbind(checks,data.frame(check="response_range",pass=v==0,violations=v))}
  if(!is.null(constraints$parameter_bounds)){pb<-as.matrix(constraints$parameter_bounds);if(ncol(pb)!=2L||is.null(rownames(pb)))stop("parameter_bounds must be a two-column matrix/data frame with parameter row names.",call.=FALSE);cf<-coef(object);common<-intersect(names(cf),rownames(pb));v<-0L;if(length(common)){v<-sum(cf[common]<pb[common,1]-tolerance|cf[common]>pb[common,2]+tolerance)};checks<-rbind(checks,data.frame(check="parameter_bounds",pass=v==0,violations=v))}
  resp<-.nl_response_name(object$formula);ob<-object$data[[resp]];pr<-as.numeric(stats::predict(object$fit,newdata=object$data));metrics<-data.frame(RMSE=.nl_rmse(ob,pr),MAE=.nl_mae(ob,pr),Bias=mean(pr-ob,na.rm=TRUE),AICc=.nl_aicc(object),CV_RMSE=NA_real_,CV_MAE=NA_real_)
  if(!is.null(k)){cv<-tryCatch(nl_cv(object,k=min(k,nrow(object$data)-1L)),error=function(e)NULL);if(!is.null(cv)){metrics$CV_RMSE<-cv$RMSE;metrics$CV_MAE<-cv$MAE}}
  structure(list(pass=all(checks$pass),checks=checks,metrics=metrics,grid=grid,prediction=pred,
                 constraints=constraints,predictor=predictor,extrapolation=extrapolation),class="nlr_candidate_validation")
}

#' Knowledge-guided nonlinear equation discovery
#'
#' Fits a user-defined set of mechanistically plausible registered models and/or
#' additional nonlinear formulas, then applies the same explicit scientific
#' validation constraints to every successful fit. Symbolic-regression output can
#' therefore be reparameterized into interpretable candidate formulas before
#' entering the inferential comparison.
#'
#' @param data Data frame.
#' @param response Response column name.
#' @param predictor Main predictor column name.
#' @param models Registered nlrFlow model names.
#' @param candidate_formulas Optional named list of additional formulas.
#' @param candidate_starts Named list of starts corresponding to `candidate_formulas`.
#' @param constraints Scientific constraint list passed to `nl_validate_candidate`.
#' @param engine Fitting engine.
#' @param k Cross-validation folds.
#' @param ... Additional arguments to `nl_fit` for registered models.
#' @return An `nlr_discovery` object with successful fits, failures and validation table.
#' @examples
#' o<-nl_data("okra_growth_means");nl_discover(o,"fruit_length","day_after_flowering",c("gompertz","logistic","richards"),constraints=list(positive=TRUE,monotonic="increasing"),engine="nls")
#' f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy");nl_discover(f,"grain_yield_Mg_ha","P2O5_kg_ha",c("mitscherlich","michaelis_menten","linear_plateau"),constraints=list(positive=TRUE),engine="nls")
#' s<-subset(nl_data("soil_p_sorption"),soil_class=="Clayey");nl_discover(s,"sorbed_P_mg_kg","solution_P_mg_L",c("langmuir","freundlich"),constraints=list(positive=TRUE,monotonic="increasing"),engine="nls")
#' @export
nl_discover <- function(data,response,predictor,models=character(),candidate_formulas=list(),
                        candidate_starts=list(),constraints=list(),engine="nlsLM",k=5,...) {
  fits<-list();fail<-list()
  for(m in models){z<-try(nl_fit(data=data,model=m,response=response,predictor=predictor,engine=engine,...),silent=TRUE);if(inherits(z,"try-error"))fail[[m]]<-as.character(z) else fits[[m]]<-z}
  if(length(candidate_formulas)){
    if(is.null(names(candidate_formulas))||any(names(candidate_formulas)==""))names(candidate_formulas)<-paste0("candidate_",seq_along(candidate_formulas))
    for(nm in names(candidate_formulas)){st<-candidate_starts[[nm]];if(is.null(st)){fail[[nm]]<-"No starting values supplied for candidate formula.";next};z<-try(nl_fit(candidate_formulas[[nm]],data=data,start=st,engine=engine),silent=TRUE);if(inherits(z,"try-error"))fail[[nm]]<-as.character(z) else fits[[nm]]<-z}
  }
  vals<-lapply(fits,function(z)tryCatch(nl_validate_candidate(z,predictor,constraints=constraints,k=k),error=function(e)e))
  tab<-do.call(rbind,lapply(names(fits),function(nm){v<-vals[[nm]];if(inherits(v,"error"))return(data.frame(model=nm,valid=FALSE,RMSE=NA,MAE=NA,AICc=NA,CV_RMSE=NA,error=conditionMessage(v)));data.frame(model=nm,valid=v$pass,RMSE=v$metrics$RMSE,MAE=v$metrics$MAE,AICc=v$metrics$AICc,CV_RMSE=v$metrics$CV_RMSE,error="")}))
  structure(list(fits=fits,failures=fail,validation=vals,table=tab,constraints=constraints,response=response,predictor=predictor),class="nlr_discovery")
}

#' Discriminate among competing nonlinear models
#'
#' Compares fitted models using AICc weights, predictive error, constraint status,
#' and pairwise prediction disagreement over a common grid. Non-nested models are
#' not subjected to an invalid likelihood-ratio test.
#'
#' @param fits Named list of `nlrfit` objects or an `nlr_discovery` object.
#' @param predictor Main predictor.
#' @param constraints Optional constraint list for candidate validation.
#' @param grid_n Number of common-grid points.
#' @param extrapolation Prediction-grid extension beyond observed range.
#' @param k Cross-validation folds.
#' @return An `nlr_discrimination` object with ranking and disagreement matrix.
#' @examples
#' o<-nl_data("okra_growth_means");d1<-nl_discover(o,"fruit_length","day_after_flowering",c("gompertz","logistic","richards"),engine="nls");nl_discriminate(d1,"day_after_flowering")
#' f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy");d2<-nl_discover(f,"grain_yield_Mg_ha","P2O5_kg_ha",c("mitscherlich","michaelis_menten"),engine="nls");nl_discriminate(d2,"P2O5_kg_ha")
#' s<-subset(nl_data("soil_p_sorption"),soil_class=="Clayey");d3<-nl_discover(s,"sorbed_P_mg_kg","solution_P_mg_L",c("langmuir","freundlich"),engine="nls");nl_discriminate(d3,"solution_P_mg_L")
#' @export
nl_discriminate <- function(fits,predictor,constraints=list(),grid_n=200,extrapolation=.1,k=5) {
  if(inherits(fits,"nlr_discovery"))fits<-fits$fits
  if(!is.list(fits)||length(fits)<2L)stop("At least two fitted models are required.",call.=FALSE)
  if(is.null(names(fits))||any(names(fits)==""))names(fits)<-paste0("model",seq_along(fits));if(!all(vapply(fits,inherits,logical(1),"nlrfit")))stop("All entries must be nlrfit objects.",call.=FALSE)
  base<-fits[[1]];grid<-.nl_prediction_grid(base,predictor,grid_n,extrapolation);P<-matrix(NA_real_,nrow(grid),length(fits),dimnames=list(NULL,names(fits)))
  tab<-vector("list",length(fits))
  for(i in seq_along(fits)){z<-fits[[i]];P[,i]<-tryCatch(as.numeric(stats::predict(z$fit,newdata=grid)),error=function(e)NA_real_);val<-tryCatch(nl_validate_candidate(z,predictor,constraints,grid_n,extrapolation,k),error=function(e)NULL);resp<-.nl_response_name(z$formula);ob<-z$data[[resp]];pr<-tryCatch(as.numeric(stats::predict(z$fit,newdata=z$data)),error=function(e)rep(NA_real_,length(ob)));tab[[i]]<-data.frame(model=names(fits)[i],AICc=.nl_aicc(z),RMSE=.nl_rmse(ob,pr),MAE=.nl_mae(ob,pr),CV_RMSE=if(is.null(val))NA else val$metrics$CV_RMSE,valid=if(is.null(val))FALSE else val$pass)}
  tab<-do.call(rbind,tab); amin<-min(tab$AICc,na.rm=TRUE); if(!is.finite(amin)){tab$delta_AICc<-NA_real_;tab$AICc_weight<-NA_real_}else{tab$delta_AICc<-tab$AICc-amin;w<-exp(-.5*tab$delta_AICc);tab$AICc_weight<-w/sum(w,na.rm=TRUE)};tab<-tab[order(!tab$valid,tab$AICc,tab$CV_RMSE),,drop=FALSE]
  D<-matrix(0,ncol(P),ncol(P),dimnames=list(colnames(P),colnames(P)));for(i in seq_len(ncol(P)))for(j in seq_len(ncol(P)))D[i,j]<-sqrt(mean((P[,i]-P[,j])^2,na.rm=TRUE))
  structure(list(ranking=tab,predictions=P,grid=grid,disagreement=D,predictor=predictor,constraints=constraints),class="nlr_discrimination")
}

#' Sequential experimental design for model discovery and discrimination
#'
#' Selects new predictor values where plausible nonlinear models disagree most,
#' scaled by their residual noise and optionally weighted by current model
#' probabilities. The default criterion is a T-optimal-like weighted pairwise
#' predictive separation. This closes the discovery loop: fit candidates,
#' identify the most informative new experiment, collect data, and refit.
#'
#' @param fits Named list of competing `nlrfit` objects or `nlr_discovery`.
#' @param data_template One-row data frame used to hold other covariates fixed.
#' @param predictor Predictor varied by the new experiment.
#' @param candidates Numeric candidate predictor values.
#' @param model_weights Optional non-negative model weights; defaults to normalized AICc weights.
#' @param existing Optional existing predictor values.
#' @param min_distance Minimum distance from existing/selected values.
#' @param n_points Number of sequential points proposed in the current batch.
#' @param noise_adjust Logical; divide disagreement by average residual variance.
#' @return An `nlr_sequential_discovery` object with candidate scores and selected points.
#' @examples
#' o<-nl_data("okra_growth_means");do<-nl_discover(o,"fruit_length","day_after_flowering",c("gompertz","logistic","richards"),engine="nls");nl_sequential_discovery(do,o[1,,drop=FALSE],"day_after_flowering",1:25,existing=o$day_after_flowering,n_points=2)
#' f<-subset(nl_data("soil_fertility_p"),soil_class=="Loamy");df<-nl_discover(f,"grain_yield_Mg_ha","P2O5_kg_ha",c("mitscherlich","michaelis_menten"),engine="nls");nl_sequential_discovery(df,f[1,,drop=FALSE],"P2O5_kg_ha",seq(0,300,10),existing=f$P2O5_kg_ha,n_points=2)
#' s<-subset(nl_data("soil_p_sorption"),soil_class=="Clayey");ds<-nl_discover(s,"sorbed_P_mg_kg","solution_P_mg_L",c("langmuir","freundlich"),engine="nls");nl_sequential_discovery(ds,s[1,,drop=FALSE],"solution_P_mg_L",seq(0,max(s$solution_P_mg_L)*1.2,length=50),existing=s$solution_P_mg_L,n_points=2)
#' @export
nl_sequential_discovery <- function(fits,data_template,predictor,candidates,model_weights=NULL,
                                    existing=NULL,min_distance=0,n_points=1,noise_adjust=TRUE) {
  if(inherits(fits,"nlr_discovery"))fits<-fits$fits
  if(!is.list(fits)||length(fits)<2L)stop("At least two competing fits are required.",call.=FALSE);if(is.null(names(fits))||any(names(fits)==""))names(fits)<-paste0("model",seq_along(fits))
  m<-length(fits);cand<-sort(unique(as.numeric(candidates)));if(n_points<1||n_points>length(cand))stop("Invalid n_points.",call.=FALSE)
  if(is.null(model_weights)){a<-vapply(fits,.nl_aicc,numeric(1));if(all(!is.finite(a)))w<-rep(1/m,m) else {a[!is.finite(a)]<-max(a[is.finite(a)])+20;ww<-exp(-.5*(a-min(a)));w<-ww/sum(ww)}}else{w<-as.numeric(model_weights);if(length(w)!=m||any(w<0)||sum(w)<=0)stop("model_weights must be non-negative and match fits.",call.=FALSE);w<-w/sum(w)};names(w)<-names(fits)
  noise<-vapply(fits,function(z){r<-tryCatch(as.numeric(stats::residuals(z$fit)),error=function(e)numeric());v<-stats::var(r,na.rm=TRUE);if(!is.finite(v)||v<=0)1 else v},numeric(1));noise_scale<-if(noise_adjust)sum(w*noise) else 1
  score_one<-function(x){d<-data_template[1,,drop=FALSE];d[[predictor]]<-x;mu<-vapply(fits,function(z)tryCatch(as.numeric(stats::predict(z$fit,newdata=d))[1],error=function(e)NA_real_),numeric(1));if(any(!is.finite(mu)))return(NA_real_);wm<-sum(w*mu);sum(w*(mu-wm)^2)/noise_scale}
  selected<-numeric(0);score_tables<-list();avail<-cand
  for(k in seq_len(n_points)){eligible<-rep(TRUE,length(avail));refs<-c(existing,selected);if(length(refs)&&min_distance>0)eligible<-vapply(avail,function(x)all(abs(x-refs)>=min_distance),logical(1));sc<-rep(NA_real_,length(avail));sc[eligible]<-vapply(avail[eligible],score_one,numeric(1));tab<-data.frame(candidate=avail,score=sc,eligible=eligible);score_tables[[k]]<-tab;if(!any(is.finite(sc)))break;j<-which.max(sc);selected<-c(selected,avail[j]);avail<-avail[-j]}
  structure(list(selected=selected,scores=score_tables,weights=w,noise_variance=noise,predictor=predictor,candidates=cand,existing=existing,min_distance=min_distance,criterion="weighted predictive model-disagreement / residual-noise"),class="nlr_sequential_discovery")
}
