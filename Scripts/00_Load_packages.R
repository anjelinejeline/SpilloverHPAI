#####################
### Script: 00_Load_packages.R
### Purpose: Install (if missing) and load required packages
### Author: Angela Fanelli
#####################

# List of required packages
libraries <- c(
  "dplyr",
  "tidyr",
  "tibble",
  "corrplot",
  "sf",
  "terra",
  "tmap",
  "purrr",
  "readxl",
  "lubridate",
  "colorspace",
  "ggplot2",
  "pROC",
  "spdep",
  "INLA",
  "flextable",
  "glue",
  "stringr"
)

# Install and load required packages
for (lib in libraries) {
  if (!(lib %in% installed.packages())) {
    if (lib == "INLA") {
      install.packages("INLA", repos = c(getOption("repos"), INLA = "https://inla.r-inla-download.org/R/stable"), dep = TRUE)
    } else {
      install.packages(lib)
    }
  }
  library(lib, character.only = TRUE)
}
