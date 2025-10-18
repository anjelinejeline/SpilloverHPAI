###############################################################
### Author: Angela Fanelli
### Role: Epidemiologist
### Institution: JRC
### Project: Spillover HPAI
###############################################################


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

# --- Unusual wild hosts -------------------------------------
unusual_wild_hosts <- read.csv(
  glue("{my_path}/Input/WAHIS/spillover_HPAI_USA.csv")
) |> 
  st_as_sf(coords = c("Longitude", "Latitude"), crs = st_crs(4326))

data("World")  # Load the World dataset


# --- USA grid with spillover and outbreak events ------------
spillover <- readRDS(
  glue("{my_path}/Input/WAHIS/grid_spillover_HPAI_USA.RDS")
)

# --- USA grid with covariates -------------------------------
covar <- readRDS(
  glue("{my_path}/Input/Covariates/grid_covariates.RDS")
)


# ============================================================
# ASSESS UNUSUAL WILD HOSTS ----
# ============================================================

unusual_wild_hosts |> 
  st_drop_geometry() |> 
  select(Species) |> 
  distinct(Species)  # 19 unique species


# --- Define color palette -----------------------------------
colorblind_palette <- c(
  "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", 
  "#D55E00", "#CC79A7", "#000000", "#999999", "#66CCCC", 
  "#FF9900", "#66CC00", "#33CCCC", "#CC0033", "#3366CC", 
  "#CC66CC", "#9999CC", "#6633CC", "#CC9966"
)


# --- Plot species count -------------------------------------
unusual_wild_hosts |> 
  group_by(Species) |> 
  summarise(n = n()) |> 
  ggplot(aes(x = Species, y = n, fill = Species)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = n), vjust = -0.3, size = 3.5) +
  scale_fill_manual(values = colorblind_palette) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)), limits = c(0, NA)) +
  labs(
    title = "",
    x = "",
    y = "Spillover in unusual/new wild hosts"
  ) +
  theme_classic(base_size = 16) +
  theme(
    axis.line       = element_line(color = "black"),
    axis.ticks      = element_line(color = "black"),
    axis.text.x     = element_text(color = "black", size = 13, angle = 45, hjust = 1, face = "italic"),
    axis.text.y     = element_text(color = "black", size = 13, angle = 90),
    axis.title.x    = element_text(color = "black", size = 13, margin = margin(t = 10)),
    axis.title.y    = element_text(color = "black", size = 13, angle = 90, margin = margin(r = 10)),
    panel.grid.major= element_blank(),
    panel.grid.minor= element_blank(),
    panel.background= element_rect(fill = "white"),
    plot.title      = element_text(hjust = 0.5, color = "black"),
    legend.position = "none"
  )

ggsave(
  glue("{my_path}/Output/Figures/Unusual_wild_hosts.tiff"),
  plot   = last_plot(),
  width  = 10,
  height = 6,
  units  = "in",
  dpi    = 300
)


# ============================================================
# MAP SPILLOVER EVENTS ----
# ============================================================

# --- Subset world data to USA --------------------------------
USA <- World[World$name == "United States of America", ]

# --- Create bounding box for USA -----------------------------
bbox_usa <- st_bbox(USA)

# --- Add factor column for outbreak type ---------------------
spillover <- spillover |> mutate(out_f = as.factor(out))

# --- Create and export map -----------------------------------
tiff(
  glue("{my_path}/Output/Figures/spillover_map.tiff"),
  width  = 8.27,
  height = 11.69 / 2,
  res    = 300,
  units  = "in"
)

tm_shape(World, bbox = bbox_usa) +
  tm_borders(col = "black") +
  tm_shape(spillover) +
  tm_borders(col = "grey86", col_alpha = 0.5) +
  tm_shape(spillover |> filter(!is.na(out))) +
  tm_polygons(
    fill = "out_f",
    fill.scale = tm_scale_categorical(
      values = c("darkgreen", "darkred"),
      labels = c(
        "without unusual/new wild hosts",
        "with unusual/new wild hosts"
      )
    ),
    fill.legend = tm_legend(
      title       = "HPAI outbreaks",
      frame       = FALSE,
      orientation = "landscape",
      text.size  = 1,
      title.size = 1.1,
      ticks.col   = "black",
      position    = tm_pos_out("center", "bottom", pos.h = "center"),
      show        = TRUE
    )
  ) +
  tm_facets(by = "t0", ncol = 2) +
  tm_layout(
    outer.margins     = c(0, 0, 0, 0),
    frame             = TRUE,
    panel.label.bg.color = "white",
    panel.label.size  = 1.5
  )

dev.off()


# ============================================================
# COVARIATE ANALYSIS ----
# ============================================================

# --- Join covariates and spillover ---------------------------
df <- spillover |> 
  st_drop_geometry() |> 
  mutate(t0 = as.numeric(t0)) |> 
  right_join(covar, by = c("ID", "X", "Y", "t0"))


# ============================================================
# BIODIVERSITY INTACTNESS ----
# ============================================================

df |> 
  st_drop_geometry() |> 
  select(out, BioIntact) |> 
  filter(!is.na(out)) |> 
  ggplot(aes(x = factor(out), y = BioIntact, fill = factor(out))) +
  geom_boxplot(
    width         = 0.6,
    outlier.shape = 1,
    outlier.size  = 1.5,
    outlier.alpha = 0.1,
    alpha         = 0.8,
    color         = "black",
    linewidth     = 0.6
  ) +
  xlab("") +
  ylab("Biodiversity intactness") +
  scale_fill_manual(values = c("darkgreen", "darkred")) +
  scale_x_discrete(
    labels = c(
      "0" = "HPAI outbreaks\nwithout unusual/new wild hosts",
      "1" = "HPAI outbreaks\nwith unusual/new wild hosts"
    )
  ) +
  theme_classic(base_size = 16) +
  theme(
    legend.position = "none",
    axis.line       = element_line(color = "black"),
    axis.ticks      = element_line(color = "black"),
    axis.ticks.x    = element_blank(),
    axis.text.x     = element_text(color = "black", size = 14),
    axis.text.y     = element_text(color = "black", size = 14),
    axis.title.y    = element_text(color = "black", size = 14, angle = 90, margin = margin(r = 10)),
    panel.grid.major= element_blank(),
    panel.grid.minor= element_blank(),
    panel.background= element_rect(fill = "white"),
    plot.title      = element_text(hjust = 0.5, color = "black")
  )

ggsave(
  glue("{my_path}/Output/Figures/biodiversity_intactness.tiff"),
  plot   = last_plot(),
  width  = 8,
  height = 6,
  units  = "in",
  dpi    = 300
)


# ============================================================
# WILD BIRD ABUNDANCE ----
# ============================================================

df |> 
  st_drop_geometry() |> 
  select(out, BirdSum) |> 
  filter(!is.na(out)) |> 
  ggplot(aes(x = factor(out), y = BirdSum, fill = factor(out))) +
  geom_boxplot(
    width         = 0.6,
    outlier.shape = 1,
    outlier.size  = 1.5,
    outlier.alpha = 0.1,
    alpha         = 0.8,
    color         = "black",
    linewidth     = 0.6
  ) +
  xlab("") +
  ylab("Wild bird abundance") +
  scale_fill_manual(values = c("darkgreen", "darkred")) +
  scale_x_discrete(
    labels = c(
      "0" = "HPAI outbreaks\nwithout unusual/new wild hosts",
      "1" = "HPAI outbreaks\nwith unusual/new wild hosts"
    )
  ) +
  theme_classic(base_size = 16) +
  theme(
    legend.position = "none",
    axis.line       = element_line(color = "black"),
    axis.ticks      = element_line(color = "black"),
    axis.ticks.x    = element_blank(),
    axis.text.x     = element_text(color = "black", size = 14),
    axis.text.y     = element_text(color = "black", size = 14),
    axis.title.y    = element_text(color = "black", size = 14, angle = 90, margin = margin(r = 10)),
    panel.grid.major= element_blank(),
    panel.grid.minor= element_blank(),
    panel.background= element_rect(fill = "white"),
    plot.title      = element_text(hjust = 0.5, color = "black")
  )

ggsave(
  glue("{my_path}/Output/Figures/wild_birds.tiff"),
  plot   = last_plot(),
  width  = 8,
  height = 6,
  units  = "in",
  dpi    = 300
)


# ============================================================
# LAND COVER TYPES ----
# ============================================================

# --- Prepare data --------------------------------------------
land_cover_vars <- c(
  "NeedleleavedForest", "BroadleavedForest", "MixedForest", "Shrubland",
  "Herbaceous", "Lichens_moss", "Wetland", "Cropland",
  "Barrenlands", "Urban", "Water", "Snow"
)

df_long <- df |>
  st_drop_geometry() |>
  select(ID, X, Y, out, all_of(land_cover_vars)) |>
  pivot_longer(
    cols      = all_of(land_cover_vars),
    names_to  = "land_cover_type",
    values_to = "area"
  ) |>
  mutate(out = factor(out, levels = c(0, 1)))

facet_names <- c(
  "0" = "HPAI outbreaks\nwithout unusual/new wild hosts",
  "1" = "HPAI outbreaks\nwith unusual/new wild hosts"
)

# --- Define colors and labels -------------------------------
land_cover_palette <- c(
  "NeedleleavedForest" = rgb(0, 61, 0, maxColorValue = 255),
  "BroadleavedForest"  = rgb(0, 99, 0, maxColorValue = 255),
  "MixedForest"        = rgb(91, 117, 43, maxColorValue = 255),
  "Shrubland"          = rgb(178, 158, 43, maxColorValue = 255),
  "Herbaceous"         = rgb(232, 219, 94, maxColorValue = 255),
  "Lichens_moss"       = rgb(186, 211, 142, maxColorValue = 255),
  "Wetland"            = rgb(107, 163, 138, maxColorValue = 255),
  "Cropland"           = rgb(230, 174, 102, maxColorValue = 255),
  "Barrenlands"        = rgb(168, 171, 174, maxColorValue = 255),
  "Urban"              = rgb(220, 33, 38, maxColorValue = 255),
  "Water"              = rgb(76, 112, 163, maxColorValue = 255),
  "Snow"               = rgb(255, 250, 255, maxColorValue = 255)
)

land_cover_labels <- c(
  "Needle\nleaved forest", "Broadleaved forest", "Mixed forest",
  "Shrubland", "Herbaceous", "Lichens\nmoss", "Wetland",
  "Cropland", "Barren land", "Urban", "Water", "Snow and ice"
)

# --- Plot boxplots ------------------------------------------
ggplot(
  df_long |> filter(!is.na(out)),
  aes(x = land_cover_type, y = area, fill = land_cover_type)
) +
  geom_boxplot(
    width         = 0.6,
    alpha         = 0.8,
    color         = "black",
    linewidth     = 0.5,
    outlier.shape = 16,
    outlier.size  = 1
  ) +
  facet_grid(out ~ ., labeller = as_labeller(facet_names)) +
  scale_fill_manual(values = land_cover_palette) +
  scale_x_discrete(labels = str_wrap(land_cover_labels, width = 10)) +
  xlab("") +
  ylab("Land cover area (km²)") +
  theme_classic(base_size = 14) +
  theme(
    legend.position = "none",
    axis.line       = element_line(color = "black"),
    axis.ticks      = element_line(color = "black"),
    axis.text.x     = element_text(color = "black", size = 10, angle = 45, hjust = 1),
    axis.text.y     = element_text(color = "black", size = 10),
    axis.title.y    = element_text(color = "black", size = 12, margin = margin(r = 10)),
    panel.grid.major= element_blank(),
    panel.grid.minor= element_blank(),
    panel.background= element_rect(fill = "white"),
    plot.title      = element_text(hjust = 0.5, color = "black")
  )

ggsave(
  glue("{my_path}/Output/Figures/land_cover.tiff"),
  plot   = last_plot(),
  width  = 10,
  height = 8,
  units  = "in",
  dpi    = 300
)


# ============================================================
# NDVI ----
# ============================================================

df |> 
  st_drop_geometry() |> 
  select(out, NDVI) |> 
  filter(!is.na(out)) |> 
  ggplot(aes(x = factor(out), y = NDVI, fill = factor(out))) +
  geom_boxplot(
    width         = 0.6,
    outlier.shape = 1,
    outlier.size  = 1.5,
    outlier.alpha = 0.1,
    alpha         = 0.8,
    color         = "black",
    linewidth     = 0.6
  ) +
  xlab("") +
  ylab("NDVI") +
  scale_fill_manual(values = c("darkgreen", "darkred")) +
  scale_x_discrete(
    labels = c(
      "0" = "HPAI outbreaks\nwithout unusual/new wild hosts",
      "1" = "HPAI outbreaks\nwith unusual/new wild hosts"
    )
  ) +
  theme_classic(base_size = 16) +
  theme(
    legend.position = "none",
    axis.line       = element_line(color = "black"),
    axis.ticks      = element_line(color = "black"),
    axis.ticks.x    = element_blank(),
    axis.text.x     = element_text(color = "black", size = 14),
    axis.text.y     = element_text(color = "black", size = 14),
    axis.title.y    = element_text(color = "black", size = 14, angle = 90, margin = margin(r = 10)),
    panel.grid.major= element_blank(),
    panel.grid.minor= element_blank(),
    panel.background= element_rect(fill = "white"),
    plot.title      = element_text(hjust = 0.5, color = "black")
  )

ggsave(
  glue("{my_path}/Output/Figures/NDVI.tiff"),
  plot   = last_plot(),
  width  = 8,
  height = 6,
  units  = "in",
  dpi    = 300
)
