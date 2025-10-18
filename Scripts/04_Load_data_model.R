#####################
### Author: Angela Fanelli
### Role: Epidemiologist
### Institution: JRC
### Project: Spillover HPAI
#####################

# ============================================================
# LOAD PACKAGES ----
# ============================================================

source("Scripts/00_Load_packages.R")

# ============================================================
# DEFINE THE PATH ----
# ============================================================

my_path<-"/storage/panelan/SpilloverHPAI"

# ============================================================
# CREATE ADJACENCY MATRIX (if not already created) ----
# ============================================================

graph_path <- glue("{my_path}/Input/Data_model/graph")

if (!file.exists(graph_path)) {
  
  message(glue("Adjacency graph not found — creating new map_graph at {Sys.time()}"))
  
  # --- Load spatial and attribute data
  USA       <- readRDS(glue("{my_path}/Input/USA/grid.RDS"))
  covar     <- readRDS(glue("{my_path}/Input/Covariates/grid_covariates.RDS"))
  spillover <- readRDS(glue("{my_path}/Input/WAHIS/grid_spillover_HPAI_USA.RDS"))
  
  # --- Join spillover and covariates, keeping only complete covariate cells
  df <- spillover |>
    st_drop_geometry() |>
    mutate(t0 = as.numeric(t0)) |>
    right_join(covar |> st_drop_geometry(), by = c("ID", "X", "Y", "t0"))
  
  # --- Reorder data and grid cells by year and ID
  df  <- df |> arrange(t0, ID)
  USA <- USA |>
    filter(ID %in% unique(df$ID)) |>
    arrange(match(ID, df$ID)) |>
    st_as_sf()
  
  # --- Create adjacency matrix (neighbour relationships)
  nb <- poly2nb(as_Spatial(USA$x))
  nb2INLA(graph_path, nb)
  
  # --- Load adjacency graph into memory
  g <- inla.read.graph(filename = glue("{my_path}/Input/Data_model/graph"))
  
} else {
  
  message(glue("Adjacency graph already exists — loading existing file at {Sys.time()}"))
  g <- inla.read.graph(filename = glue("{my_path}/Input/Data_model/graph"))
}

# ============================================================
# CREATE DATA FOR MODELLING (if not already created) ----
# ============================================================

data_model_path <- glue("{my_path}/Input/Data_model/data_model.csv")

if (!file.exists(data_model_path)) {
  
  message(glue("data_model not found — creating new data_model at {Sys.time()}"))
  
  # --- Load datasets
  covar     <- readRDS(glue("{my_path}/Input/Covariates/grid_covariates.RDS"))
  spillover <- readRDS(glue("{my_path}/Input/WAHIS/grid_spillover_HPAI_USA.RDS"))
  
  # --- Merge spillover and covariates
  df <- spillover |>
    st_drop_geometry() |>
    mutate(t0 = as.numeric(t0)) |>
    right_join(covar |> st_drop_geometry(), by = c("ID", "X", "Y", "t0"))
  
  # Standardize the variables (convert to numeric and scale)
  df <- df |> 
    mutate(across(-c(ID, X, Y, out, t0), ~ as.numeric(scale(.))))
  
  # --- Prepare modelling dataset
  data_model <- df |>
    # Remove coords
    select(!c(X,Y))|>
    mutate(cell_index=as.integer(factor(ID)),
           BioIntact_g=inla.group(BioIntact, method = "cut", n = 20)) |> 
    # Rename and arrange
    rename(Y = out) |>
    arrange(t0, ID) |> 
    mutate(t0=as.factor(t0)) |> 
    select(!c(BioIntact))
  
  # --- Save dataset for later use
  write.csv(data_model, data_model_path, row.names = FALSE)
  
  message(glue("data_model successfully created and saved at {Sys.time()}"))
  
} else {
  
  message(glue("data_model already exists — loading from file at {Sys.time()}"))
  data_model <- read.csv(data_model_path)
}

