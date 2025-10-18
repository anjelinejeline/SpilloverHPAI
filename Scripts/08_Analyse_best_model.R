#####################
### Author: Angela Fanelli
### Role: Epidemiologist
### Institution: JRC
### Project: Spillover HPAI
#####################


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
# ASSESS MODEL METRICS ----
# ============================================================

metrics_files <- list.files(
  glue("{my_path}/Output/Metrics"),
  full.names = TRUE
)

# Load the metrics
metrics <- metrics_files |>
  map(\(x) read.csv(x)) |>
  list_rbind()

# Filter for the models of interest
metrics_filtered <- metrics |> 
  filter(grepl("Anser_albifrons|Corvus_corax", fixed) | model == "base_model")

head(metrics_filtered |> arrange(dic))

# Write filtered metrics
metrics_filtered |> 
  arrange(dic) |> 
  write.csv(
    glue("{my_path}/Output/Metrics/metrics_models_of_interest.csv"),
    row.names = FALSE
  )


# ============================================================
# SELECT THE BEST MODEL WITH LOWEST DIC ----
# ============================================================

best_model_name <- metrics_filtered |> 
  arrange(dic) |> 
  slice(1) |> 
  pull(model)

# Load the best model
best_model <- readRDS(glue("{my_path}/Output/Models/{best_model_name}.RDS"))

# ============================================================
# CORRELATION PLOT ----
# ============================================================

tiff(glue("{my_path}/Output/Figures/corr_plot.tiff"), width = 8, height = 6, units = "in", res = 300)

data_model |> 
  filter(!is.na(Y)) |> 
  select(Wetland,Anser_albifrons,Corvus_corax, BioIntact_g) |> 
  cor(use = "complete.obs") |> 
  corrplot(
    method = "number", 
    order = "hclust", 
    tl.col = "black",
    number.cex = 1, 
    tl.cex = 1, 
    pch.cex = 1,
    main = ""
  )

dev.off()

# ============================================================
# PLOT FIXED EFFECTS ----
# ============================================================

fe <- get_fixed_INLA(
  model   = best_model,
  covars  = c("as.factor(t0)2023", "Wetland", "Anser_albifrons", "Corvus_corax"),
  transform = TRUE
)

fe_plot <- fe |> 
  ggplot() +
  geom_linerange(aes(x = covar, ymin = lower, ymax = upper),
                 color = "black", show.legend = FALSE) +
  geom_point(aes(x = covar, y = mean),
             color = "darkred", size = 2, show.legend = FALSE) +
  geom_hline(yintercept = 1, lty = 2) +
  scale_x_discrete(
    labels = c(
      "as.factor(t0)2023" = "Year 2023 vs 2022",
      "Wetland"           = expression("Wetland area (km"^2*")"),
      "Anser_albifrons"   = expression(italic("Anser albifrons")),
      "Corvus_corax"      = expression(italic("Corvus corax"))
    )
  ) +
  theme_classic(base_size = 14) +
  labs(
    x = "",
    y = "Relative risk",
    title = "Fixed effects"
  ) +
  theme(
    legend.position = "none",
    axis.line       = element_line(color = "black"),
    axis.ticks      = element_line(color = "black"),
    axis.ticks.x    = element_blank(),
    axis.text.x     = element_text(color = "black", size = 13),
    axis.text.y     = element_text(color = "black", size = 13),
    axis.title.y    = element_text(color = "black", size = 13, angle = 90, margin = margin(r = 10)),
    plot.title      = element_text(hjust = 0.5, color = "black")
  )

print(fe_plot)

ggsave(
  glue("{my_path}/Output/Figures/fixed_effects.tiff"),
  plot   = last_plot(),
  width  = 8,
  height = 6,
  units  = "in",
  dpi    = 300
)


# ============================================================
# PLOT RANDOM EFFECT ----
# ============================================================

re <- get_random_INLA(
  model   = best_model,
  covars  = "BioIntact_g",
  transform = TRUE
)

re_plot <- re |>
  ggplot(aes(x = value, y = mean)) +
  geom_line(linewidth = 0.5, color = "black") +
  geom_ribbon(aes(ymin = lower, ymax = upper),
              alpha = 0.2, fill = "grey", size = 0.3) +
  geom_hline(yintercept = 1, lty = 2) +
  theme_classic(base_size = 14) +
  labs(
    x = "Biodiversity intactness",
    y = "Relative risk",
    title = "Random effect"
  ) +
  theme(
    legend.position = "none",
    axis.line       = element_line(color = "black"),
    axis.ticks      = element_line(color = "black"),
    axis.ticks.x    = element_blank(),
    axis.text.x     = element_text(color = "black", size = 13),
    axis.text.y     = element_text(color = "black", size = 13),
    axis.title.y    = element_text(color = "black", size = 13, angle = 90, margin = margin(r = 10)),
    plot.title      = element_text(hjust = 0.5, color = "black")
  )

print(re_plot)

ggsave(
  glue("{my_path}/Output/Figures/random_effect.tiff"),
  plot   = last_plot(),
  width  = 8,
  height = 6,
  units  = "in",
  dpi    = 300
)


# ============================================================
# CROSS-VALIDATION (LOOCV & LGOCV) ----
# ============================================================

alpha <- 0.01
u <- 1
precision_prior <- list(prec = list(prior = "pc.prec", param = c(u, alpha)))

loocv_res <- inla.group.cv(best_model)
cv <- loocv_res$cv[!is.na(loocv_res$cv)]
ULOOCV <- exp(mean(log(cv)))  # Probability of predicting observed outcomes

lgocv_auto_res <- inla.group.cv(result = best_model, num.level.sets = 3)
ULGOCV_auto <- exp(mean(log(lgocv_auto_res$cv), na.rm = TRUE)) # Probability of predicting observed outcomes

print(c(ULOOCV , ULGOCV_auto))

# ============================================================
# ASSESS PREDICTIVE PERFORMANCE ----
# ============================================================

pred <- read.csv(glue("{my_path}/Output/Predictions/pred_full.csv"))

# ROC and AUC
set.seed(27092019)

roc_object <- roc(
  pred |> filter(!is.na(Y)) |> pull(Y),
  pred |> filter(!is.na(Y)) |> pull(mean)
)
AUC_object <- auc(roc_object)

# Optimal threshold (Youden’s J)
pred_metrics <- coords(
  roc_object,
  x = "best",
  best.method = "youden",
  input = "threshold",
  ret = c(
    "threshold", "tn", "tp", "fn", "fp",
    "sensitivity", "specificity", "accuracy", "npv",
    "ppv", "precision", "tpr", "fpr", "tnr", "fnr", "fdr"
  )
)

pred_metrics$AUC     <- AUC_object[[1]]
pred_metrics$ULOOCV  <- ULOOCV
pred_metrics$ULGOCV  <- ULGOCV_auto

# Save predictive metrics
write.csv(
  pred_metrics,
  glue("{my_path}/Output/Metrics/predictive_metrics_full.csv"),
  row.names = FALSE
)


# ============================================================
# PLOT PREDICTIVE METRICS ----
# ============================================================

pred_metrics |> 
  select(c("accuracy", "AUC", "sensitivity", "specificity",
           "ppv", "npv", "ULOOCV", "ULGOCV")) |> 
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "value"
  ) |> 
  ggplot(aes(x = variable, y = value)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = "grey") +
  xlab("") +
  ylab("Value") +
  scale_x_discrete(labels = c("CCR", "AUC", "NPV", "PPV", "Se", "Sp", "ULOOCV", "ULGOCV")) +
  theme_classic(base_size = 14) +
  theme(
    legend.position = "none",
    axis.line       = element_line(color = "black"),
    axis.ticks      = element_line(color = "black"),
    axis.ticks.x    = element_blank(),
    axis.text.x     = element_text(color = "black", size = 13),
    axis.text.y     = element_text(color = "black", size = 13),
    axis.title.y    = element_text(color = "black", size = 13, angle = 90, margin = margin(r = 10)),
    plot.title      = element_text(hjust = 0.5, color = "black")
  )

ggsave(
  glue("{my_path}/Output/Figures/metrics.tiff"),
  plot   = last_plot(),
  width  = 8,
  height = 6,
  units  = "in",
  dpi    = 300
)


# ============================================================
# PREDICTIVE MAP ----
# ============================================================

risk_palette <- rev(sequential_hcl(5, palette = "Inferno"))
breaks_cat   <- c(0, 0.15, 0.30, 0.45, 0.6, 1)

data("World")                 # Load world data
USA <- World[World$name == "United States of America", ]
bbox_usa <- st_bbox(USA)

usa_grid <- readRDS(glue("{my_path}/Input/USA/grid.RDS"))
pred_sf  <- usa_grid |> right_join(pred, by = c("ID")) |> st_as_sf()

# Create and export map
tiff(
  glue("{my_path}/Output/Figures/spillover_prediction_map.tiff"),
  width  = 8.27,
  height = 11.69 / 2,
  res    = 300,
  units  = "in"
)

tm_shape(World, bbox = bbox_usa) +
  tm_borders(col = "black") +
  tm_shape(pred_sf) +
  tm_borders(col = "grey86", fill_alpha = 0.5) +
  tm_shape(pred_sf) +
  tm_polygons(
    fill = "mean",
    fill.scale = tm_scale_intervals(
      n = 5,
      style = "fixed",
      breaks = breaks_cat,
      interval.closure = "left",
      values = risk_palette,
      labels = c("Very low", "Low", "Medium", "High", "Very high")
    ),
    fill.legend = tm_legend(
      title      = "Probability of spillover in unusual/new wild hosts",
      frame      = FALSE,
      orientation = "landscape",
      text.size  = 1,
      title.size=1.1,
      ticks.col  = "black",
      position   = tm_pos_out("center", "bottom", pos.h = "center"),
      show       = TRUE
    )
  ) +
  tm_facets(by = "t0", ncol = 2) +
  tm_layout(
    outer.margins        = c(0, 0, 0, 0),
    frame                = TRUE,
    panel.label.bg.color = "white",
    panel.label.size     = 1.5
  )

dev.off()

# ============================================================
# PLOT 95% CI BOUNDS OF SPATIAL PREDICTIONS ----
# ============================================================

# Prepare data: pivot longer to plot lower and upper bounds
pred_bounds <- pred_sf |>
  pivot_longer(
    cols      = c(lower, upper),
    names_to  = "bound",
    values_to = "value"
  ) |>
  mutate(
    bound = recode(bound,
                   lower = "Lower 95% bound",
                   upper = "Upper 95% bound")
  ) |> st_as_sf()

# --- Create and export the maps -----------------------------------
tiff(
  glue("{my_path}/Output/Figures/spillover_prediction_bounds_2022.tiff"),
  width  = 8.27,
  height = 11.69 / 2,
  res    = 300,
  units  = "in"
)

tm_shape(World, bbox = bbox_usa) +
  tm_borders(col = "black") +
  tm_shape(pred_bounds |> filter(t0==2022)) +
  tm_borders(col = "grey86", fill_alpha = 0.5) +
  tm_shape(pred_bounds |> filter(t0==2022)) +
  tm_polygons(
    fill = "value",
    fill.scale = tm_scale_continuous(
      values = "scico.roma",
      limits = c(0,1)
    ),
    fill.legend = tm_legend(
      title       = "95% Credible Interval of predicted spillover in unusual/new wild hosts in 2022",
      frame       = FALSE,
      orientation = "landscape",
      text.size   = 0.8,
      title.size = 1.1,
      ticks.col   = "black",
      position    = tm_pos_out("center", "bottom", pos.h = "center"),
      show        = TRUE
    )
  ) +
  tm_facets(by = "bound", ncol = 2) +
  tm_layout(
    outer.margins        = c(0, 0, 0, 0),
    frame                = TRUE,
    panel.label.bg.color = "white",
    panel.label.size     = 1.3
  )

dev.off()

tiff(
  glue("{my_path}/Output/Figures/spillover_prediction_bounds_2023.tiff"),
  width  = 8.27,
  height = 11.69 / 2,
  res    = 300,
  units  = "in"
)

tm_shape(World, bbox = bbox_usa) +
  tm_borders(col = "black") +
  tm_shape(pred_bounds |> filter(t0==2023)) +
  tm_borders(col = "grey86", fill_alpha = 0.5) +
  tm_shape(pred_bounds |> filter(t0==2023)) +
  tm_polygons(
    fill = "value",
    fill.scale = tm_scale_continuous(
      values = "scico.roma",
      limits = c(0,1)
    ),
    fill.legend = tm_legend(
      title       = "95% Credible Interval of predicted spillover in unusual/new wild hosts in 2023",
      frame       = FALSE,
      orientation = "landscape",
      text.size   = 0.8,
      title.size = 1.1,
      ticks.col   = "black",
      position    = tm_pos_out("center", "bottom", pos.h = "center"),
      show        = TRUE
    )
  ) +
  tm_facets(by = "bound", ncol = 2) +
  tm_layout(
    outer.margins        = c(0, 0, 0, 0),
    frame                = TRUE,
    panel.label.bg.color = "white",
    panel.label.size     = 1.3
  )

dev.off()

# ============================================================
# CLASSIFY PREDICTIONS INTO RISK CATEGORIES ----
# ============================================================

breaks_cat  <- c(0, 0.15, 0.30, 0.45, 0.6, 1)
labels_cat  <- c("Very low", "Low", "Medium", "High", "Very high")

pred <- pred |>
  mutate(
    risk_cat = cut(
      mean,
      breaks = breaks_cat,
      labels = labels_cat,
      include.lowest = TRUE,
      right = FALSE    # Left-closed, right-open intervals [a, b)
    )
  )


# ============================================================
# CREATE RISK DATAFRAME ----
# SUMMARIZE RISK BY YEAR AND CATEGORY
# ============================================================

risk_df <- pred |>
  st_drop_geometry() |>
  select(ID, t0, Y, mean, risk_cat)

print(risk_df)

risk_df_grouped <- risk_df |>
  group_by(t0, risk_cat) |>
  summarise(n = n(), .groups = "drop") |>
  pivot_wider(names_from = t0, values_from = n)

print(risk_df_grouped)

write.csv(
  risk_df_grouped,
  glue("{my_path}/Output/Predictions/risk_df_grouped.csv"),
  row.names = FALSE
)


# ============================================================
# ASSESS RISK CHANGES BETWEEN 2022 AND 2023 ----
# ============================================================

risk_22 <- risk_df |>
  filter(t0 == 2022) |>
  arrange(ID) |>
  rename(pred22 = mean, risk_cat22 = risk_cat)

risk_23 <- risk_df |>
  filter(t0 == 2023) |>
  arrange(ID) |>
  rename(pred23 = mean, risk_cat23 = risk_cat)

risk_all <- inner_join(risk_22, risk_23, by = "ID")

# Calculate differences
risk_all <- risk_all |>
  mutate(
    pred_change = pred23 - pred22,
    risk_change = if_else(risk_cat22 == risk_cat23, 0, 1)
  )

# Mean difference in predicted risk
mean_change <- mean(risk_all$pred_change, na.rm = TRUE)
print(mean_change)

# Number of cells that changed risk category
n_changes <- risk_all |>
  filter(risk_change == 1) |>
  nrow()
print(n_changes)


# ============================================================
# SUMMARIZE DIRECTION OF CHANGE ----
# ============================================================

change_table <- risk_all |>
  filter(risk_change == 1) |>
  mutate(
    change_type = if_else(pred_change < 0, "DECREASE", "INCREASE")
  ) |>
  group_by(change_type) |>
  summarise(value = n(), .groups = "drop") |>
  bind_rows(
    tibble(change_type = "mean_change", value = round(mean_change, 3))
  )

print(change_table)

write.csv(
  change_table,
  glue("{my_path}/Output/Predictions/risk_changes.csv"),
  row.names = FALSE
)
           