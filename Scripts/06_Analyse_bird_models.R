##############################
### Author: Angela Fanelli
### Role: Epidemiologist
### Institution: JRC
### Project: Spillover HPAI
##############################


# ============================================================
# LOAD PACKAGES, DATA & FUNCTIONS ----
# ============================================================

source("Scripts/00_Load_packages.R")   # Load required R packages
source("Scripts/01_Functions.R")       # Load custom functions
source("Scripts/04_Load_data_model.R") # Load model data


# ============================================================
# DEFINE THE PATH ----
# ============================================================

my_path <- "/storage/panelan/SpilloverHPAI"


# ============================================================
# RETRIEVE FIXED EFFECTS FROM THE BIRD MODELS ----
# ============================================================

# List all model files (excluding the base model)
bird_models_files <- list.files(
  glue("{my_path}/Output/Models"),
  pattern = "bird.*\\.RDS$",
  full.names = TRUE
)

# Extract coefficients for each bird model
all_coefs <- map(bird_models_files, function(x) {
  
  model <- readRDS(x)
  
  # Extract the coefficient for the bird species
  fixed_term <-model$summary.fixed |> 
    rownames_to_column(var = "covar") |> 
    filter(!grepl("Intercept|t0|Wetland", covar)) |> 
    select(covar,mean,`0.025quant`,`0.975quant`)
  
}) |> list_rbind()


# ============================================================
# FILTER SIGNIFICANT COEFFICIENTS ----
# ============================================================

significant_coefs <- all_coefs |> 
  mutate(
    exp_mean  = exp(mean),
    exp_lower = exp(`0.025quant`),
    exp_upper = exp(`0.975quant`)
  ) |> 
  filter(exp_lower > 1 | exp_upper < 1)

print(significant_coefs)

# ============================================================
# SAVE SIGNIFICANT Output ----
# ============================================================

write.csv(
  significant_coefs,
  glue("{my_path}/Output/Models/significant_bird_coefficients.csv"), row.names = FALSE
)
