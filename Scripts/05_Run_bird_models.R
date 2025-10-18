#####################
### Author: Angela Fanelli
### Role: Epidemiologist
### Institution: JRC
### Project: Spillover HPAI
#####################


# ============================================================
# LOAD PACKAGES, DATA & FUNCTIONS ----
# ============================================================

source("Scripts/00_Load_packages.R")      # Load required R packages
source("Scripts/01_Functions.R")          # Load custom functions
source("Scripts/04_Load_data_model.R")    # Load model data


# ============================================================
# DEFINE THE PATH ----
# ============================================================

my_path <- "/storage/panelan/SpilloverHPAI"


# ============================================================
# DEFINE PRIORS ----
# ============================================================

# Define the combination of U and alpha for the precision prior
# Note: larger values of alpha lead to a greater prior belief on large σ
# alpha = 0.01 (1% chance that σ > U) for a weakly informative prior

alpha <- 0.01
u <- 1

precision_prior <- list(
  prec = list(
    prior = "pc.prec",
    param = c(u, alpha)
  )
)


# ============================================================
# DEFINE BASE FORMULA ----
# ============================================================

base_formula <- Y ~ 1 + as.factor(t0) + Wetland + 
  f(BioIntact_g, model = "rw2", hyper = precision_prior, scale.model = TRUE, constr = TRUE) +
  f(cell_index, model = "bym2",
    graph = g,
    scale.model = TRUE,
    hyper = precision_prior
  )


# ============================================================
# SELECT BIRD SPECIES ----
# ============================================================

# Select bird species names 
birds<-colnames(data_model)[4:37]

# ============================================================
# TRANSFORM TERMS INTO FORMULAE ----
# ============================================================

formulae_fixed <- map(birds, function(x) {
  formula_fixed <- as.formula(paste("~ . +", x))
  return(formula_fixed)
})


# ============================================================
# ADD FIXED TERMS TO BASE FORMULA ----
# ============================================================

formulae_fixed <- map(formulae_fixed, function(x) {
  formula_updated <- update.formula(base_formula, x)
  return(formula_updated)
})


# ============================================================
# ADD BASE MODEL & LABELS ----
# ============================================================

formulae <- c(formulae_fixed, base_formula)
labs <- c(paste0("model_bird_", 1:length(formulae_fixed)), "base_model")

# ============================================================
# SET PARALLELIZATION OPTIONS ----
# ============================================================

inla.setOption(num.threads = 70)


# ============================================================
# RUN MODELS ----
# ============================================================

walk2(formulae, labs, function(f, l) {
  
  # ------------------------------------------------------------
  # Create temporary directory
  # ------------------------------------------------------------
  temp_dir <- paste0(
    "/scratch/panelan/INLA",
    "/inla_tmp_",
    format(Sys.time(), "%Y%m%d_%H%M%S")
  )
  dir.create(temp_dir, recursive = TRUE)
  
  # ------------------------------------------------------------
  # Log start time
  # ------------------------------------------------------------
  start_msg <- glue("{l}: processing started at {Sys.time()}\n")
  print(start_msg)
  write(start_msg, glue("{my_path}/Output/Models/log_file.txt"), append = TRUE)
  
  # ------------------------------------------------------------
  # Fit the INLA model
  # ------------------------------------------------------------
  model <- fit_INLA(
    formula = f,
    data = data_model,
    family = "binomial",
    config = FALSE,
    temp_dir = temp_dir,
    return_marginals = TRUE,
    verbose = TRUE
  )
  
  # ------------------------------------------------------------
  # Log end time
  # ------------------------------------------------------------
  end_msg <- glue("{l} processing ended at {Sys.time()}\n")
  print(end_msg)
  write(end_msg, glue("{my_path}/Output/Models/log_file.txt"), append = TRUE)
  
  # ------------------------------------------------------------
  # Delete temporary directory
  # ------------------------------------------------------------
  unlink(temp_dir, recursive = TRUE)
  
  # ------------------------------------------------------------
  # Save model
  # ------------------------------------------------------------
  saveRDS(model, glue("{my_path}/Output/Models/{l}.RDS"))
  
  # ------------------------------------------------------------
  # Save predictions
  # ------------------------------------------------------------
  pred <- data_model |>
    mutate(
      mean  = model$summary.fitted.values$mean,
      sd    = model$summary.fitted.values$sd,
      upper = model$summary.fitted.values$`0.975quant`,
      lower = model$summary.fitted.values$`0.025quant`
    )
  
  write.csv(
    pred,
    glue("{my_path}/Output/Predictions/pred_{l}.csv"),
    row.names = FALSE
  )
  
  # ------------------------------------------------------------
  # Extract and save model metrics
  # ------------------------------------------------------------
  model_metrics <- get_metrics_INLA(model = model, label = l)
  
  write.csv(
    model_metrics,
    glue("{my_path}/Output/Metrics/metrics_{l}.csv"),
    row.names = FALSE
  )
  
}, .progress = TRUE)
