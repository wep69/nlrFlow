#' Solve a deterministic ODE model
#'
#' Routes initial-value ODE systems to `deSolve::ode`, enabling agronomic,
#' soil-process, physiological, and environmental dynamic models that do not
#' have a convenient closed-form nonlinear regression equation.
#' @param state Named initial state vector.
#' @param times Numeric output times.
#' @param func ODE derivative function accepted by `deSolve::ode`.
#' @param parms Named parameter vector/list.
#' @param method ODE solver method.
#' @param ... Additional arguments to `deSolve::ode`.
#' @return An `nlr_ode` object. Its `$solution` element is the numeric matrix
#'   returned by `deSolve::ode` (first column `time`, one column per state),
#'   together with `$times`, `$states`, `$parms`, `$method`, `$engine`, and
#'   `$diagnostics`. `print()` shows the solution, `summary()` lists the model
#'   specification, and `[` and `as.data.frame()` are forwarded to the solution
#'   matrix, so `sol[, "B"]` and `as.data.frame(sol)` keep working.
#' @examples
#' \dontrun{
#' # Example 1: crop biomass with first-order approach to carrying capacity.
#' f <- function(t,state,parms) list(c(parms["r"]*(parms["K"]-state[1])))
#' nl_ode_solve(c(B=1),0:30,f,c(r=.08,K=20))
#' # Example 2: soil nutrient mineralization pool.
#' g <- function(t,state,parms) list(c(-parms["k"]*state[1]))
#' nl_ode_solve(c(N=100),0:60,g,c(k=.03))
#' # Example 3: physiological recovery after stress.
#' h <- function(t,state,parms) list(c(parms["k"]*(parms["Amax"]-state[1])))
#' nl_ode_solve(c(A=5),0:24,h,c(k=.2,Amax=30))
#' }
#' @export
nl_ode_solve <- function(state,times,func,parms,method="lsoda",...) {
  .nl_require("deSolve","ODE solving")
  sol <- deSolve::ode(y=state,times=times,func=func,parms=parms,method=method,...)
  structure(list(solution=sol,times=as.numeric(sol[,1L]),states=names(state),
                 parms=parms,method=method,engine="deSolve",
                 diagnostics=summary(sol)),
            class="nlr_ode")
}

#' @export
#' @noRd
print.nlr_ode <- function(x,...) {
  cat("<nlr_ode> deSolve method:",x$method,"| states:",paste(x$states,collapse=", "),
      "| times:",length(x$times),"\n",sep=" ")
  print(x$solution)
  invisible(x)
}
#' @export
#' @noRd
summary.nlr_ode <- function(object,...) {
  list(method=object$method,engine=object$engine,states=object$states,parms=object$parms,
       times=range(object$times),n_times=length(object$times),solution=object$solution)
}
#' @export
#' @noRd
as.data.frame.nlr_ode <- function(x,row.names=NULL,optional=FALSE,...) {
  as.data.frame(x$solution,row.names=row.names,optional=optional,...)
}
#' @export
#' @noRd
`[.nlr_ode` <- function(x,i,j,...,drop=TRUE) x$solution[i,j,...,drop=drop]

#' Fit or solve advanced dynamic nonlinear mixed models
#'
#' Provides a thin, auditable adapter to `nlmixr2::nlmixr2` for ODE-based
#' nonlinear mixed-effects models. The model function retains native nlmixr2
#' syntax so that differential equations, random effects, covariates, and
#' residual models are not silently simplified by nlrFlow.
#' @param model An nlmixr2 model function/object.
#' @param data Event/observation data accepted by nlmixr2.
#' @param est Estimation method, for example `saem` or `focei`.
#' @param control Optional nlmixr2 control object/list.
#' @param ... Additional arguments to `nlmixr2::nlmixr2`.
#' @return An `nlrfit` wrapping the nlmixr2 fitted object.
#' @examples
#' \dontrun{
#' # Example 1: dynamic crop growth with plot-level random carrying capacity.
#' nl_dynamic(crop_ode_model, crop_longitudinal, est="saem")
#' # Example 2: soil nutrient-pool turnover with soil-specific covariates.
#' nl_dynamic(soil_pool_model, soil_longitudinal, est="focei")
#' # Example 3: plant physiological induction/recovery ODE model.
#' nl_dynamic(physiology_ode_model, physiology_longitudinal, est="saem")
#' }
#' @export
nl_dynamic <- function(model,data,est="saem",control=list(),...) {
  .nl_require("nlmixr2","dynamic nonlinear mixed-effects models")
  f <- NULL
  for (pk in c("nlmixr2est", "nlmixr2")) {
    if (requireNamespace(pk, quietly = TRUE) && "nlmixr2" %in% getNamespaceExports(pk)) {
      f <- getExportedValue(pk, "nlmixr2")
      break
    }
  }
  if (is.null(f)) stop("Could not find nlmixr2() in nlmixr2est or nlmixr2. Install nlmixr2est or update the nlmixr2 stack.", call. = FALSE)
  fit <- f(model,data,est=est,control=control,...)
  .nl_wrap(fit,"nlmixr2",stats::as.formula("response ~ time"),data,start=NULL,metadata=list(est=est,control=control))
}
