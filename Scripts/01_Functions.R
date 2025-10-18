#####################
### Author: Angela Fanelli
### Role: Epidemiologist
### Institution: JRC
### Project: Spillover HPAI
#####################

# ============================================================
# FIT INLA MODEL ----
# ============================================================

fit_INLA <- function(
    formula,
    data,
    family = "binomial",
    config = FALSE,
    temp_dir,
    return_marginals = FALSE,
    verbose = TRUE
) {
  # Fit an INLA model with default settings and optional configuration
  
  model <- inla(
    # Model structure
    formula = formula,
    data = data,
    family = family,
    
    # INLA approximation strategy
    control.inla = list(strategy = "adaptive"),
    
    # Computation settings
    control.compute = list(
      dic = TRUE,
      waic = TRUE,
      config = config,
      cpo = TRUE,
      return.marginals = return_marginals
    ),
    
    # Weakly regularising priors on fixed effects
    control.fixed = list(
      correlation.matrix = TRUE,
      prec.intercept = 1,
      prec = 1
    ),
    
    # Save predictions on response scale
    control.predictor = list(link = 1, compute = TRUE),
    
    # Verbose output
    verbose = verbose,
    
    # Temporary working directory
    working.directory = temp_dir
  )
  
  # Re-run the model to stabilise estimates
  model <- inla.rerun(model)
  
  return(model)
}

# ============================================================
# EXTRACT MODEL METRICS ----
# ============================================================

get_metrics_INLA <- function(model, label) {
  # Extract model fit and performance metrics from an INLA model object
  
  model_summary <- data.frame(
    model      = label,
    fixed      = paste(model$names.fixed, collapse = " + "),
    random     = paste(names(model$summary.random), collapse = " + "),
    dic        = model$dic$dic,            # Deviance Information Criterion
    waic       = model$waic$waic,          # Watanabe–Akaike Information Criterion
    p_eff      = model$waic$p.eff,         # Effective number of parameters
    logscore   = ifelse(all(model$cpo$cpo == 0),
                        NA, -mean(log(model$cpo$cpo), na.rm = TRUE)),
    cpo_fail   = sum(model$cpo$failure == 1 & !is.na(model$cpo$failure)),
    stringsAsFactors = FALSE
  )
  
  return(model_summary)
}

# ============================================================
# EXTRACT RANDOM EFFECTS ----
# ============================================================

get_random_INLA <- function(model, covars, transform = FALSE) {
  # Extract random effect summaries for specified covariates
  
  summary_random <- model$summary.random
  
  # Keep only selected covariates
  summary_random <- summary_random[names(summary_random) %in% covars]
  
  # Reformat and bind results into a single data frame
  summary_random <- map2(summary_random, names(summary_random), function(x, y) {
    x <- x |>
      rename(value = 1, lower = 4, median = 5, upper = 6)
    x$covar <- y
    x |> relocate(covar, .before = value)
  }) |> 
    list_rbind()
  
  # Optionally exponentiate results
  if (transform) {
    summary_random <- summary_random |>
      mutate(across(c(mean, sd, lower, median, upper, mode), exp))
  }
  
  return(summary_random)
}

# ============================================================
# EXTRACT FIXED EFFECTS ----
# ============================================================

get_fixed_INLA <- function(model, covars, transform = FALSE) {
  # Extract fixed effect summaries for specified covariates
  summary_fixed <- model$summary.fixed
  
  # Extract the coefficient for the bird species
  summary_fixed <-model$summary.fixed |> 
    rownames_to_column(var = "covar") |> 
    filter(covar%in% covars) |> 
    select(covar,mean,`0.025quant`,`0.975quant`)|>
    rename(lower=`0.025quant`,
           upper=`0.975quant`)
  
  # Optionally exponentiate results
  if (transform) {
    summary_fixed <- summary_fixed|>
      mutate(across(c(mean, lower, upper), exp))
  }
  
  return(summary_fixed)
}
