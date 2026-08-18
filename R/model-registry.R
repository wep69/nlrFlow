# Model registry ------------------------------------------------------------
.nl_registry <- function() {
  list(
    logistic = list(category="sigmoidal", parameters=c("Asym","xmid","scal"),
      rhs="Asym/(1 + exp((xmid - x)/scal))", equation="y = Asym/[1 + exp((xmid-x)/scal)]"),
    gompertz = list(category="sigmoidal", parameters=c("Asym","k","xmid"),
      rhs="Asym * exp(-exp(-k * (x - xmid)))", equation="y = Asym exp{-exp[-k(x-xmid)]}"),
    richards = list(category="sigmoidal", parameters=c("Asym","xmid","scal","nu"),
      rhs="Asym/(1 + exp((xmid - x)/scal))^(1/nu)", equation="y = Asym/[1+exp((xmid-x)/scal)]^(1/nu)"),
    chapman_richards = list(category="growth", parameters=c("Asym","k","m"),
      rhs="Asym * (1 - exp(-k * x))^m", equation="y = Asym(1-exp(-kx))^m"),
    mitscherlich = list(category="fertility", parameters=c("Asym","delta","k"),
      rhs="Asym - delta * exp(-k * x)", equation="y = Asym - delta exp(-kx)"),
    michaelis_menten = list(category="saturation", parameters=c("Vmax","Km"),
      rhs="Vmax * x/(Km + x)", equation="y = Vmax x/(Km+x)"),
    hill = list(category="dose_response", parameters=c("bottom","top","EC50","h"),
      rhs="bottom + (top-bottom) * x^h/(EC50^h + x^h)", equation="y = bottom + (top-bottom)x^h/(EC50^h+x^h)"),
    monomolecular = list(category="growth", parameters=c("Asym","y0","k"),
      rhs="Asym - (Asym-y0) * exp(-k*x)", equation="y = Asym-(Asym-y0)exp(-kx)"),
    power = list(category="allometry", parameters=c("a","b"),
      rhs="a * x^b", equation="y = ax^b"),
    linear_plateau = list(category="fertility", parameters=c("intercept","slope","breakpoint"),
      rhs="ifelse(x < breakpoint, intercept + slope*x, intercept + slope*breakpoint)", equation="linear-plateau"),
    quadratic_plateau = list(category="fertility", parameters=c("b0","b1","b2"),
      rhs="ifelse(x < -b1/(2*b2), b0+b1*x+b2*x^2, b0-b1^2/(4*b2))", equation="quadratic-plateau with stationary plateau"),
    rectangular_hyperbola = list(category="physiology", parameters=c("Amax","alpha","Rd"),
      rhs="Amax*alpha*x/(Amax + alpha*x) - Rd", equation="A = Amax alpha I/(Amax+alpha I)-Rd"),
    nonrectangular_hyperbola = list(category="physiology", parameters=c("Amax","alpha","theta","Rd"),
      rhs="((alpha*x + Amax) - sqrt(pmax((alpha*x + Amax)^2 - 4*theta*alpha*x*Amax, 1e-12)))/(2*theta) - Rd", equation="non-rectangular photosynthetic light response"),
    gaussian_peak = list(category="peak", parameters=c("baseline","amplitude","mu","sigma"),
      rhs="baseline + amplitude*exp(-0.5*((x-mu)/sigma)^2)", equation="y = baseline + amplitude exp[-0.5((x-mu)/sigma)^2]"),
    weibull_growth = list(category="growth", parameters=c("Asym","scal","shape"),
      rhs="Asym * (1 - exp(-(pmax(x,0)/scal)^shape))", equation="y = Asym{1-exp[-(x/scal)^shape]}"),
    von_bertalanffy = list(category="growth", parameters=c("Asym","b","k"),
      rhs="Asym * (1 - b*exp(-k*x))^3", equation="y = Asym[1-b exp(-kx)]^3"),
    emax = list(category="dose_response", parameters=c("E0","Emax","EC50"),
      rhs="E0 + Emax*x/(EC50 + x)", equation="y = E0 + Emax x/(EC50+x)"),
    exponential_decay = list(category="decay", parameters=c("plateau","amplitude","k"),
      rhs="plateau + amplitude*exp(-k*x)", equation="y = plateau + amplitude exp(-kx)"),
    langmuir = list(category="soil_sorption", parameters=c("qmax","K"),
      rhs="qmax*K*x/(1 + K*x)", equation="q = qmax K C/(1+KC)"),
    freundlich = list(category="soil_sorption", parameters=c("Kf","n"),
      rhs="Kf * pmax(x,1e-12)^(1/n)", equation="q = Kf C^(1/n)"),
    van_genuchten = list(category="soil_hydraulic", parameters=c("theta_r","theta_s","alpha","n"),
      rhs="theta_r + (theta_s-theta_r)/(1 + (alpha*pmax(x,0))^n)^(1-1/n)", equation="theta(h) = theta_r + (theta_s-theta_r)/[1+(alpha|h|)^n]^(1-1/n)"),
    log_logistic4 = list(category="dose_response", parameters=c("bottom","top","EC50","slope"),
      rhs="bottom + (top-bottom)/(1 + exp(slope*(log(pmax(x,1e-12))-log(EC50))))", equation="four-parameter log-logistic"),
    substrate_inhibition = list(category="physiology", parameters=c("Vmax","Km","Ki"),
      rhs="Vmax*x/(Km + x + x^2/Ki)", equation="y = Vmax x/(Km+x+x^2/Ki)"),
    brain_cousens = list(category="dose_response", parameters=c("bottom","top","EC50","slope","f"),
      rhs="bottom + (top-bottom + f*x)/(1 + exp(slope*(log(pmax(x,1e-12))-log(EC50))))", equation="Brain-Cousens-type hormetic response")
  )
}
.nl_model_formula <- function(model, response, predictor) {
  reg <- .nl_registry(); if (!model %in% names(reg)) stop("Unknown model: ", model, call. = FALSE)
  rhs <- gsub("\\bx\\b", predictor, reg[[model]]$rhs, perl = TRUE)
  stats::as.formula(paste(response, "~", rhs), env = parent.frame())
}
