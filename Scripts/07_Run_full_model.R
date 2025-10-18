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
# LOAD SIGNFICIANT SPECIES ----
# ============================================================

significant_birds<-read.csv(glue("{my_path}/Output/Models/significant_bird_coefficients.csv")) |> pull(covar)

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
# DEFINE THE FORMULA ----
# ============================================================

formula <- Y ~ 1 + as.factor(t0) + Wetland + 
  f(BioIntact_g, model = "rw2", hyper = precision_prior, scale.model = TRUE, constr = TRUE) +
  f(cell_index, model = "bym2",
    graph = g,
    scale.model = TRUE,
    hyper = precision_prior
  )

birds_terms<-paste0(significant_birds,collapse = " + ")

formula<-update.formula(formula, as.formula(paste("~ . +", birds_terms)))

# ============================================================
# SET PARALLELIZATION OPTIONS ----
# ============================================================

inla.setOption(num.threads = 70)

# ============================================================
# RUN THE MODEL ----
# ============================================================

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
start_msg <- glue("Full model: processing started at {Sys.time()}\n")
print(start_msg)
write(start_msg, glue("{my_path}/Output/Models/log_file.txt"), append = TRUE)

# ------------------------------------------------------------
# Fit the INLA model
# ------------------------------------------------------------
model <- fit_INLA(
  formula = formula,
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
end_msg <- glue("Full model: processing ended at {Sys.time()}\n")
print(end_msg)
write(end_msg, glue("{my_path}/Output/Models/log_file.txt"), append = TRUE)

# ------------------------------------------------------------
# Delete temporary directory
# ------------------------------------------------------------
unlink(temp_dir, recursive = TRUE)

# ------------------------------------------------------------
# Save model
# ------------------------------------------------------------
saveRDS(model, glue("{my_path}/Output/Models/model_full.RDS"))

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
  glue("{my_path}/Output/Predictions/pred_full.csv"),
  row.names = FALSE
)

# ------------------------------------------------------------
# Extract and save model metrics
# ------------------------------------------------------------
model_metrics <- get_metrics_INLA(model = model, label = "model_full")

write.csv(
  model_metrics,
  glue("{my_path}/Output/Metrics/metrics_full.csv"),
  row.names = FALSE
)

