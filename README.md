# Code and data to accompany the article "Leveraging public data to forecast HPAI spillovers in unusual/new wild hosts"

## Description

This repository contains the data and code used to perform the analyses, described in the article *Leveraging public data to forecast HPAI spillovers in unusual/new wild hosts*.

The repository is divided as follows:

-   `Input`
-   `Scripts`

It assumes that:

-   the dataset used for modelling and the spatial adjacency matrix generated during analysis will be saved in the `Input/Data_model` folder.

-   the results will be saved in a folder called `Output` and relative subfolders.

## Data Availability

All datasets are publicly available.

### HPAI Outbreak Data

-   **Source:** [World Animal Health Information System (WAHIS)](https://wahis.woah.org/)
-   **Description:** WAHIS compiles official outbreak reports submitted by veterinary services of WOAH Members.
-   **Coverage:** Global, updated weekly since 2005.
-   **Access:** Available upon request through the WAHIS Support team.
    -   Contact: [wahis-support\@woah.org](mailto:wahis-support@woah.org)

### Wild Bird Abundance

-   **Source:** [eBird](https://ebird.org/st/request) via the R package [`ebirdst`](https://ebird.github.io/ebirdst/)
-   **Description:** Provides spatial and temporal estimates of bird abundance and occurrence based on eBird data.
-   **Access:** Data can be obtained programmatically through the eBird API.

### Land Cover Data

-   **Source:** [North American Land Change Monitoring System (NALCMS)](http://www.cec.org/north-american-land-change-monitoring-system/)
-   **Dataset:** 2020 North American Land Cover (30 m resolution)
-   **Coverage:** North America (Canada, United States, Mexico)

### Normalized Vegetation Index (NDVI)

-   **Source:** [MOD13C2 Version 6](https://lpdaac.usgs.gov/products/mod13c2v006/)
-   **Description:** Monthly NDVI composite data derived from MODIS.
-   **Resolution:** 0.05° (\~5.6 km) global grid.
-   **Access:** Freely available via NASA’s LP DAAC.

### Biodiversity Intactness

-   **Source:** [GLOBIO](https://www.globio.info/resources)
-   **Description:** Global model outputs of biodiversity intactness and human impact indicators.
-   **Coverage:** Global, various years available.

## Files in this repository

The `Scripts` folder contains all R scripts, while the `Input` folder holds the data files sourced by these scripts.

### Input

The `Input` folder contains the following files and subfolders:

#### USA/grid.RDS

USA grid obtained using the **shapefile level 0 of the USA** downloaded from\
[Global Administrative Areas (GADM)](https://gadm.org/download_country.html).\
The shapefile was reprojected to the target projection **USA_counties_WGS_1984_Lambert_Azimuthal_Equal_Area**, and a **hexagonal grid** was created with cells defined by a distance of approximately **102 kilometres** between opposite edges.

#### Covariates/grid_covariates.RDS

Contains gathered **covariates** from public sources.\
Mean values of each covariate were extracted using **hexagonal cells** that matched the gridded spatial structure of the USA grid.

#### WAHIS/infur_20240701.xlsx

Contains the **HPAI outbreak extraction** as of **01 July 2024** from the WAHIS database.

#### WAHIS/Species_positive_HPAI.xlsx

List of **bird species (IBIRD)** for which **HPAI detections** were reported to the **WOAH** at the global level since **2005**.

### Session info

```         
─ Session info ────────────────────────────────────────────────────────────────────
 setting  value
 version  R version 4.5.0 (2025-04-11)
 os       Ubuntu 22.04.5 LTS
 system   x86_64, linux-gnu
 ui       RStudio
 language (EN)
 collate  en_US.UTF-8
 ctype    en_US.UTF-8
 tz       Europe/Rome
 date     2025-10-18
 rstudio  2025.05.0+496 Mariposa Orchid (desktop)
 pandoc   3.4 @ /usr/lib/rstudio/resources/app/bin/quarto/bin/tools/x86_64/ (via rmarkdown)

─ Packages ────────────────────────────────────────────────────────────────────────
 package           * version   date (UTC) lib source
 abind               1.4-8     2024-09-12 [1] CRAN (R 4.5.0)
 askpass             1.2.0     2023-09-03 [3] CRAN (R 4.3.1)
 base              * 4.5.0     2025-05-04 [4] local
 base64enc           0.1-3     2015-07-28 [3] CRAN (R 4.0.2)
 boot                1.3-31    2024-08-28 [4] CRAN (R 4.4.2)
 cellranger          1.1.0     2016-07-27 [3] CRAN (R 4.0.1)
 class               7.3-23    2025-01-01 [4] CRAN (R 4.4.2)
 classInt            0.4-11    2025-01-08 [1] CRAN (R 4.5.0)
 cli                 3.6.5     2025-04-23 [1] CRAN (R 4.5.0)
 codetools           0.2-19    2023-02-01 [4] CRAN (R 4.2.2)
 colorspace        * 2.1-1     2024-07-26 [1] CRAN (R 4.5.0)
 cols4all            0.8       2024-10-16 [1] CRAN (R 4.5.0)
 compiler            4.5.0     2025-05-04 [4] local
 corrplot          * 0.92      2021-11-18 [3] CRAN (R 4.2.0)
 crosstalk           1.2.1     2023-11-23 [3] CRAN (R 4.3.2)
 data.table          1.17.2    2025-05-12 [1] CRAN (R 4.5.0)
 datasets          * 4.5.0     2025-05-04 [4] local
 DBI                 1.2.3     2024-06-02 [1] CRAN (R 4.5.0)
 deldir              2.0-2     2023-11-23 [3] CRAN (R 4.3.2)
 dichromat           2.0-0.1   2022-05-02 [3] CRAN (R 4.2.0)
 digest              0.6.37    2024-08-19 [1] CRAN (R 4.5.0)
 dplyr             * 1.1.4     2023-11-17 [3] CRAN (R 4.3.2)
 e1071               1.7-16    2024-09-16 [1] CRAN (R 4.5.0)
 evaluate            1.0.3     2025-01-10 [1] CRAN (R 4.5.0)
 fansi               1.0.6     2023-12-08 [3] CRAN (R 4.3.2)
 farver              2.1.2     2024-05-13 [1] CRAN (R 4.5.0)
 fastmap             1.2.0     2024-05-15 [1] CRAN (R 4.5.0)
 flextable         * 0.9.7     2024-10-27 [1] CRAN (R 4.5.0)
 fmesher             0.5.0     2025-07-07 [1] CRAN (R 4.5.0)
 fontBitstreamVera   0.1.1     2017-02-01 [2] CRAN (R 4.5.0)
 fontLiberation      0.1.0     2016-10-15 [2] CRAN (R 4.5.0)
 fontquiver          0.2.1     2017-02-01 [2] CRAN (R 4.5.0)
 gdtools             0.4.2     2025-03-27 [2] CRAN (R 4.5.0)
 generics            0.1.3     2022-07-05 [3] CRAN (R 4.2.1)
 ggplot2           * 3.5.2     2025-04-09 [2] CRAN (R 4.5.0)
 glue              * 1.8.0     2024-09-30 [2] CRAN (R 4.5.0)
 graphics          * 4.5.0     2025-05-04 [4] local
 grDevices         * 4.5.0     2025-05-04 [4] local
 grid                4.5.0     2025-05-04 [4] local
 gtable              0.3.4     2023-08-21 [3] CRAN (R 4.3.1)
 htmltools           0.5.8.1   2024-04-04 [1] CRAN (R 4.5.0)
 htmlwidgets         1.6.4     2023-12-06 [3] CRAN (R 4.3.2)
 INLA              * 25.09.04  2025-09-04 [1] local
 KernSmooth          2.23-26   2025-01-01 [4] CRAN (R 4.4.2)
 knitr               1.50      2025-03-16 [1] CRAN (R 4.5.0)
 lattice             0.22-5    2023-10-24 [4] CRAN (R 4.3.1)
 leafem              0.2.4     2025-05-01 [1] CRAN (R 4.5.0)
 leaflegend          1.2.1     2024-05-09 [1] CRAN (R 4.5.0)
 leaflet             2.2.2     2024-03-26 [1] CRAN (R 4.5.0)
 leaflet.providers   2.0.0     2023-10-17 [3] CRAN (R 4.3.2)
 leafsync            0.1.0     2019-03-05 [3] CRAN (R 4.2.0)
 lifecycle           1.0.4     2023-11-07 [3] CRAN (R 4.3.2)
 logger              0.4.0     2024-10-22 [1] CRAN (R 4.5.0)
 lubridate         * 1.9.3     2023-09-27 [3] CRAN (R 4.3.1)
 lwgeom              0.2-14    2024-02-21 [1] CRAN (R 4.5.0)
 magrittr            2.0.3     2022-03-30 [3] CRAN (R 4.2.0)
 maptiles            0.10.0    2025-05-07 [1] CRAN (R 4.5.0)
 Matrix            * 1.7-3     2025-03-11 [4] CRAN (R 4.4.3)
 methods           * 4.5.0     2025-05-04 [4] local
 officer             0.6.8     2025-03-23 [1] CRAN (R 4.5.0)
 openssl             2.0.6     2023-03-09 [3] CRAN (R 4.2.2)
 parallel            4.5.0     2025-05-04 [4] local
 pillar              1.9.0     2023-03-22 [3] CRAN (R 4.2.3)
 pkgconfig           2.0.3     2019-09-22 [3] CRAN (R 4.0.1)
 plyr                1.8.9     2023-10-02 [3] CRAN (R 4.3.1)
 png                 0.1-8     2022-11-29 [1] CRAN (R 4.5.0)
 pROC              * 1.18.5    2023-11-01 [3] CRAN (R 4.3.2)
 proxy               0.4-27    2022-06-09 [3] CRAN (R 4.2.0)
 purrr             * 1.0.4     2025-02-05 [2] CRAN (R 4.5.0)
 R6                  2.6.1     2025-02-15 [1] CRAN (R 4.5.0)
 ragg                1.2.5     2023-01-12 [3] CRAN (R 4.3.1)
 raster              3.6-32    2025-03-28 [1] CRAN (R 4.5.0)
 RColorBrewer        1.1-3     2022-04-03 [3] CRAN (R 4.2.0)
 Rcpp                1.0.14    2025-01-12 [1] CRAN (R 4.5.0)
 readxl            * 1.4.3     2023-07-06 [3] CRAN (R 4.3.1)
 rlang               1.1.6     2025-04-11 [2] CRAN (R 4.5.0)
 rmarkdown           2.29      2024-11-04 [1] CRAN (R 4.5.0)
 rsconnect           0.8.25    2021-11-19 [3] CRAN (R 4.1.2)
 rstudioapi          0.15.0    2023-07-07 [3] CRAN (R 4.3.1)
 s2                  1.1.9     2025-05-23 [1] CRAN (R 4.5.0)
 scales              1.4.0     2025-04-24 [1] CRAN (R 4.5.0)
 sessioninfo         1.2.2     2021-12-06 [3] CRAN (R 4.2.0)
 sf                * 1.0-21    2025-05-15 [1] CRAN (R 4.5.0)
 sp                  2.2-0     2025-02-01 [1] CRAN (R 4.5.0)
 spacesXYZ           1.5-1     2025-02-10 [1] CRAN (R 4.5.0)
 spData            * 2.3.0     2023-07-06 [3] CRAN (R 4.3.1)
 spdep             * 1.3-1     2023-11-23 [3] CRAN (R 4.3.2)
 splines             4.5.0     2025-05-04 [4] local
 stars               0.6-8     2025-02-01 [1] CRAN (R 4.5.0)
 stats             * 4.5.0     2025-05-04 [4] local
 stringi             1.8.3     2023-12-11 [3] CRAN (R 4.3.2)
 stringr           * 1.5.1     2023-11-14 [3] CRAN (R 4.3.2)
 systemfonts         1.2.3     2025-04-30 [2] CRAN (R 4.5.0)
 terra             * 1.8-50    2025-05-09 [1] CRAN (R 4.5.0)
 textshaping         0.3.6     2021-10-13 [3] CRAN (R 4.3.1)
 tibble            * 3.2.1     2023-03-20 [3] CRAN (R 4.3.1)
 tidyr             * 1.3.1     2024-01-24 [3] CRAN (R 4.3.2)
 tidyselect          1.2.0     2022-10-10 [3] CRAN (R 4.2.1)
 timechange          0.3.0     2024-01-18 [3] CRAN (R 4.3.2)
 tmap              * 4.1       2025-05-26 [1] Github (r-tmap/tmap@e24262a)
 tmaptools           3.2       2025-01-13 [1] CRAN (R 4.5.0)
 tools               4.5.0     2025-05-04 [4] local
 units               0.8-7     2025-03-11 [1] CRAN (R 4.5.0)
 utf8                1.2.4     2023-10-22 [3] CRAN (R 4.3.2)
 utils             * 4.5.0     2025-05-04 [4] local
 uuid                1.2-0     2024-01-14 [3] CRAN (R 4.3.2)
 vctrs               0.6.5     2023-12-01 [3] CRAN (R 4.3.2)
 viridisLite         0.4.2     2023-05-02 [3] CRAN (R 4.3.0)
 withr               3.0.2     2024-10-28 [2] CRAN (R 4.5.0)
 wk                  0.9.4     2024-10-11 [1] CRAN (R 4.5.0)
 xfun                0.52      2025-04-02 [1] CRAN (R 4.5.0)
 XML                 3.99-0.18 2025-01-01 [1] CRAN (R 4.5.0)
 xml2                1.3.6     2023-12-04 [3] CRAN (R 4.3.2)
 zip                 2.3.0     2023-04-17 [3] CRAN (R 4.3.0)

 [1] /home/panelan/R/x86_64-pc-linux-gnu-library/4.5
 [2] /usr/local/lib/R/site-library
 [3] /usr/lib/R/site-library
 [4] /usr/lib/R/library
```
