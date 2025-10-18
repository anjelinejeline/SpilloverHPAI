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
# LOAD THE DATA ----
# ============================================================

# WHAIS outbreaks
data <- read_excel(glue("{my_path}/Input/WAHIS/infur_20240701.xlsx"), sheet = 2)

# USA grid
grid <- readRDS(glue("{my_path}/Input/USA/grid.RDS"))

# Create a grid containing duplicate IDs for both 2022 and 2023 
grid_all <- grid |> 
  mutate(t0 = 2022) |> 
  rbind(grid |> mutate(t0 = 2023)) |> 
  st_as_sf()


# ============================================================
# CREATE THE UNUSUAL SPILLOVER DATASET FOR THE USA ----
# ============================================================

data_spillover <- data |> 
  filter(disease_eng == "Influenza A viruses of high pathogenicity (Inf. with) (non-poultry including wild birds) (2017-)") |> 
  filter(country == "United States of America") |> 
  filter(`reason of notification` == "unusual/new host") |> 
  select(Outbreak_id, Outbreak_start_date, Longitude, Latitude, Location_aprox, Location_name, 
         level2_name, level1_name, Species, cases, is_wild) |> 
  filter(format(Outbreak_start_date, "%Y") %in% c("2022", "2023")) |> 
  filter(is_wild == TRUE) |> 
  mutate(
    Outbreak_start_date = as.Date(Outbreak_start_date, "%d/%m/%Y"),
    # Extract the year
    t0 = format(as.Date(Outbreak_start_date), "%Y")
  ) |> 
  filter(!Species == "Tursiops truncatus (fau)") |>  # Delete outbreaks in Dolphin
  # Remove duplicate outbreaks 
  select(!c(Outbreak_start_date, cases)) |> 
  relocate(t0, .after = Outbreak_id) |> 
  distinct(Outbreak_id, t0, Species, .keep_all = TRUE)

write.csv(data_spillover, glue("{my_path}/Input/WAHIS/spillover_HPAI_USA.csv", row.names = FALSE))

nrow(data_spillover)
length(unique(data_spillover$Outbreak_id))

# 165 outbreaks with 3 involving multiple species 


# ============================================================
# CREATE DATASET WITHOUT UNUSUAL SPILLOVER ----
# ============================================================

data_no_spillover <- data |> 
  filter(disease_eng %in% c(
    "Influenza A viruses of high pathogenicity (Inf. with) (non-poultry including wild birds) (2017-)",
    "High pathogenicity avian influenza viruses (poultry) (Inf. with)")
  ) |> 
  filter(country == "United States of America") |>  
  select(Outbreak_id, Outbreak_start_date, Longitude, Latitude, Location_aprox, Location_name, 
         level2_name, level1_name, Species, cases, is_wild) |> 
  filter(format(Outbreak_start_date, "%Y") %in% c("2022", "2023")) |> 
  mutate(
    Outbreak_start_date = as.Date(Outbreak_start_date, "%d/%m/%Y"),
    # Extract the year
    t0 = format(as.Date(Outbreak_start_date), "%Y")
  ) |> 
  filter(!Species == "Tursiops truncatus (fau)") |>  # Delete outbreaks in Dolphin
  # Remove duplicate outbreaks 
  select(!c(Outbreak_start_date, cases)) |> 
  relocate(t0, .after = Outbreak_id) |> 
  distinct(Outbreak_id, t0, Species, .keep_all = TRUE) |> 
  # Delete those outbreaks with unusual spillover
  filter(!Outbreak_id %in% unique(data_spillover$Outbreak_id))

write.csv(data_no_spillover, glue("{my_path}/Input/WAHIS/no_spillover_HPAI_USA.csv", row.names = FALSE))

nrow(data_no_spillover)
length(unique(data_no_spillover$Outbreak_id))

# 1253 outbreaks with 22 involving multiple species


# ============================================================
# TRANSFORM DATA INTO GRIDS ----
# ============================================================

## --- Unusual spillover

data_spillover_unique <- data_spillover |> 
  select(!Species) |> 
  distinct(Outbreak_id, t0, .keep_all = TRUE) |> 
  mutate(out = 1) |>  # Create column for outbreak occurrence
  st_as_sf(coords = c("Longitude", "Latitude"), crs = st_crs(4326)) |> 
  st_transform(data_spillover_unique, crs = st_crs(grid)) |> 
  rename(State = level1_name) |> 
  select(Outbreak_id, t0, State, out)

tm_shape(grid) +
  tm_borders(col = "black") +
  tm_shape(data_spillover_unique) +
  tm_dots(col = "red")

# Join data with grid and keep only cells with outbreaks 
grid_out <- st_join(grid, data_spillover_unique, left = TRUE) |> 
  filter(out == 1) |> 
  group_by(ID, t0) |> 
  summarise(n = sum(out)) |> 
  filter(n > 0) |> 
  mutate(out = 1) |> 
  ungroup() |> 
  st_drop_geometry() |> 
  select(!n)


## --- No unusual spillover

data_no_spillover_unique <- data_no_spillover |> 
  select(!Species) |> 
  distinct(Outbreak_id, t0, .keep_all = TRUE) |> 
  mutate(out = 1) |>  # Create column for outbreak occurrence
  st_as_sf(coords = c("Longitude", "Latitude"), crs = st_crs(4326)) |> 
  st_transform(data_spillover_unique, crs = st_crs(grid)) |> 
  rename(State = level1_name) |> 
  select(Outbreak_id, t0, State, out)

tm_shape(grid) +
  tm_borders(col = "black") +
  tm_shape(data_no_spillover_unique) +
  tm_dots(col = "red")


# Join data with grid and keep outbreaks without unusual spillover 
grid_no_out <- st_join(grid, data_no_spillover_unique, left = TRUE)
head(grid_no_out)

# Exclude cells where an unusual spillover occurred (for both 2022 and 2023)
grid_no_out <- grid_no_out |> 
  filter(out == 1) |> 
  group_by(ID, t0) |> 
  summarise(n = sum(out)) |> 
  filter(n > 0) |> 
  # Exclude unusual spillover
  filter(!ID %in% c(grid_out |> distinct(ID) |> pull())) |> 
  mutate(out = 0) |>  # Set out = 0 (no spillover)
  ungroup() |> 
  st_drop_geometry() |> 
  select(!n)

# Check overlaps
intersect(grid_out$ID, grid_no_out$ID)  # 0 → perfect


# ============================================================
# FINAL MERGE AND SAVE ----
# ============================================================

# Bind spillover and no-spillover data 
grid_out_all <- grid_out |> rbind(grid_no_out)

# Join all together with the grid  
grid_out_all <- grid_all |> 
  mutate(t0 = as.character(t0)) |> 
  left_join(grid_out_all, by = c("ID", "t0")) |> 
  st_as_sf()

# RENAME THE GEOMETRY COLUMN
names(grid_out_all)[names(grid_out_all) == "x"] <- "geometry"
st_geometry(grid_out_all) <- "geometry"

# Save final dataset
saveRDS(grid_out_all, glue("{my_path}/Input/WAHIS/grid_spillover_HPAI_USA.RDS"))
