# ==============================================================================
# PREPARAR_DATOS_CLIMA.R
# Preprocesamiento y enriquecimiento de datos hidroclimáticos de Anta (2001-2025)
# Base metodológica: PISCO-SENAMHI, GEE, ERA5-Land, CHIRPS, Sentinel-2, SRTM
# ==============================================================================

version_r <- paste(R.version$major, strsplit(R.version$minor, "\\.")[[1]][1], sep = ".")
bibliotecas_usuario <- c(
  file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", version_r),
  file.path(Sys.getenv("USERPROFILE"), "AppData", "Local", "R", "win-library", version_r)
)
for (biblioteca_usuario in unique(bibliotecas_usuario)) {
  if (dir.exists(biblioteca_usuario)) .libPaths(c(biblioteca_usuario, .libPaths()))
}

suppressPackageStartupMessages({
  library(terra)
  library(sf)
  library(dplyr)
  library(tidyr)
})

dir_out <- "app_data"
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)

message("1. Procesando geometrías distritales y provinciales...")
distritos_sf <- st_read("data_vectorial/DISTRITOS_PROV_ANTA.shp", quiet = TRUE) |>
  st_transform(32718)
provincia_sf <- st_read("data_vectorial/PROV_ANTA.shp", quiet = TRUE) |>
  st_transform(32718)

# Versiones WGS84 optimizadas para Leaflet
distritos_wgs84 <- st_transform(distritos_sf, 4326)
provincia_wgs84 <- st_transform(provincia_sf, 4326)

# Centroides y metadatos
centroides_utm <- st_centroid(distritos_sf)
centroides_wgs <- st_transform(centroides_utm, 4326)
coords_utm     <- st_coordinates(centroides_utm)
coords_wgs     <- st_coordinates(centroides_wgs)

distritos_info <- distritos_sf |>
  st_drop_geometry() |>
  mutate(
    x_utm = round(coords_utm[, 1], 1),
    y_utm = round(coords_utm[, 2], 1),
    lon   = round(coords_wgs[, 1], 4),
    lat   = round(coords_wgs[, 2], 4)
  )

message("2. Leyendo rasters nativos y calculando métricas de variabilidad...")
p_30m       <- rast("Clima_Anta/P_anual_30m_PISCOv3_Anta_2001_2025.tif")
t_30m       <- rast("Clima_Anta/T_anual_30m_PISCOt_Anta_2001_2025.tif")
estres_30m  <- rast("Clima_Anta/Estres_y_Balance_Hidrico_30m_PISCO_Anta.tif")
archivo_var <- "Clima_Anta/Variabilidad_y_Tendencias_PISCO_Anta_2001_2025.tif"
archivos_series <- c(
  "Clima_Anta/P_anual_30m_PISCOv3_Anta_2001_2025.tif",
  "Clima_Anta/T_anual_30m_PISCOt_Anta_2001_2025.tif"
)
if (!file.exists(archivo_var) ||
    file.info(archivo_var)$mtime < max(file.info(archivos_series)$mtime)) {
  stop("La variabilidad PISCO falta o es anterior a las series corregidas. Ejecute scripts/recalcular_variabilidad_pisco.R.")
}
var_30m     <- rast(archivo_var)
estres_base <- rast("Clima_Anta/Estres_Hidrico_Anta_2001_2025.tif")

p_mean_30m  <- mean(p_30m)
names(p_mean_30m) <- "P_media"
t_mean_30m  <- mean(t_30m)
names(t_mean_30m) <- "T_media"

slope_30m   <- estres_base[["slope"]]
eto_30m     <- estres_30m[["ETo_PenmanMonteith_mm"]]
bal_30m     <- estres_30m[["Balance_Hidrico_P_PET_mm"]]
aridez_30m  <- estres_30m[["Indice_Aridez_UNESCO"]]
wsi_30m     <- estres_30m[["Prob_Estres_Hidrico_pct"]]
clase_30m   <- estres_30m[["Clase_Estres_Hidrico"]]
ndmi_30m    <- estres_30m[["ndmi"]]
p_cv_30m    <- var_30m[["P_CV_pct"]]
t_trend_30m <- var_30m[["T_trend_decada"]]
p_trend_30m <- var_30m[["P_trend_decada"]]
t_std_30m   <- var_30m[["T_std_interanual"]]
p_std_30m   <- var_30m[["P_std_interanual"]]

message("3. Extrayendo series temporales zonales (2001-2025)...")
dist_vect <- vect(distritos_sf)
prov_vect <- vect(provincia_sf)

p_dist <- terra::extract(p_30m, dist_vect, fun = mean, na.rm = TRUE)
p_dist$NOMBDIST <- dist_vect$NOMBDIST
p_prov <- terra::extract(p_30m, prov_vect, fun = mean, na.rm = TRUE)
p_prov$NOMBDIST <- "PROVINCIA DE ANTA"

p_all <- bind_rows(p_dist, p_prov) |>
  select(-ID) |>
  pivot_longer(cols = starts_with("P_"), names_to = "Year_str", values_to = "Precipitacion_mm") |>
  mutate(Year = as.integer(gsub("P_", "", Year_str))) |>
  select(NOMBDIST, Year, Precipitacion_mm)

t_dist <- terra::extract(t_30m, dist_vect, fun = mean, na.rm = TRUE)
t_dist$NOMBDIST <- dist_vect$NOMBDIST
t_prov <- terra::extract(t_30m, prov_vect, fun = mean, na.rm = TRUE)
t_prov$NOMBDIST <- "PROVINCIA DE ANTA"

t_all <- bind_rows(t_dist, t_prov) |>
  select(-ID) |>
  pivot_longer(cols = starts_with("T_"), names_to = "Year_str", values_to = "Temperatura_C") |>
  mutate(Year = as.integer(gsub("T_", "", Year_str))) |>
  select(NOMBDIST, Year, Temperatura_C)

# Enriquecer series anuales con promedios, anomalías y percentiles
series_base <- left_join(p_all, t_all, by = c("NOMBDIST", "Year"))

medias_territorio <- series_base |>
  group_by(NOMBDIST) |>
  summarise(
    P_media = mean(Precipitacion_mm, na.rm = TRUE),
    T_media = mean(Temperatura_C, na.rm = TRUE),
    .groups = "drop"
  )

series_anuales <- series_base |>
  left_join(medias_territorio, by = "NOMBDIST") |>
  group_by(NOMBDIST) |>
  mutate(
    P_anomalia_mm  = Precipitacion_mm - P_media,
    P_anomalia_pct = ((Precipitacion_mm / P_media) - 1) * 100,
    T_anomalia_C   = Temperatura_C - T_media,
    P_percentil    = round((rank(Precipitacion_mm, ties.method = "average") / n()) * 100, 1),
    T_percentil    = round((rank(Temperatura_C, ties.method = "average") / n()) * 100, 1),
    P_semaforo     = case_when(
      P_percentil <= 20 ~ "Déficit Severo",
      P_percentil <= 40 ~ "Déficit Moderado",
      P_percentil <= 60 ~ "Normal",
      P_percentil <= 80 ~ "Superávit Moderado",
      TRUE              ~ "Superávit Alto"
    ),
    T_semaforo     = case_when(
      T_percentil <= 20 ~ "Mucho Más Frío",
      T_percentil <= 40 ~ "Más Frío",
      T_percentil <= 60 ~ "Normal",
      T_percentil <= 80 ~ "Más Cálido",
      TRUE              ~ "Mucho Más Cálido"
    )
  ) |>
  ungroup()

message("4. Extrayendo síntesis multianual de balance, aridez y variabilidad...")
stack_ind <- c(
  p_mean_30m, t_mean_30m, eto_30m, bal_30m, aridez_30m,
  wsi_30m, ndmi_30m, slope_30m, p_cv_30m, t_trend_30m, p_trend_30m,
  t_std_30m, p_std_30m
)

ind_dist <- terra::extract(stack_ind, dist_vect, fun = mean, na.rm = TRUE)
ind_dist$NOMBDIST <- dist_vect$NOMBDIST
ind_prov <- terra::extract(stack_ind, prov_vect, fun = mean, na.rm = TRUE)
ind_prov$NOMBDIST <- "PROVINCIA DE ANTA"
indicadores_df <- bind_rows(ind_dist, ind_prov) |> select(-ID)

# Distribución porcentual y superficie en clases de estrés hídrico
calcular_pct_clases <- function(poly) {
  v <- terra::extract(clase_30m, poly)[[2]]
  v <- v[!is.na(v)]
  t <- table(factor(v, levels = 1:4))
  as.numeric(prop.table(t) * 100)
}

mat_clases_dist <- t(sapply(1:nrow(dist_vect), function(i) calcular_pct_clases(dist_vect[i, ])))
mat_clases_prov <- matrix(calcular_pct_clases(prov_vect), nrow = 1)
mat_clases <- rbind(mat_clases_dist, mat_clases_prov)
colnames(mat_clases) <- c("Pct_Clase1_Bajo", "Pct_Clase2_Medio", "Pct_Clase3_Alto", "Pct_Clase4_MuyAlto")

resumen_completo <- bind_cols(indicadores_df, as.data.frame(mat_clases)) |>
  left_join(
    distritos_info |> select(NOMBDIST, CAPDIST, AREA_KM2, TOT_POB17, x_utm, y_utm, lon, lat),
    by = "NOMBDIST"
  ) |>
  mutate(
    AREA_KM2 = ifelse(NOMBDIST == "PROVINCIA DE ANTA", sum(distritos_info$AREA_KM2, na.rm = TRUE), AREA_KM2),
    TOT_POB17 = ifelse(NOMBDIST == "PROVINCIA DE ANTA", sum(distritos_info$TOT_POB17, na.rm = TRUE), TOT_POB17),
    CAPDIST = ifelse(NOMBDIST == "PROVINCIA DE ANTA", "IZCUCHACA / ANTA", CAPDIST),
    x_utm = ifelse(NOMBDIST == "PROVINCIA DE ANTA", round(mean(distritos_info$x_utm), 1), x_utm),
    y_utm = ifelse(NOMBDIST == "PROVINCIA DE ANTA", round(mean(distritos_info$y_utm), 1), y_utm),
    lon = ifelse(NOMBDIST == "PROVINCIA DE ANTA", round(mean(distritos_info$lon), 4), lon),
    lat = ifelse(NOMBDIST == "PROVINCIA DE ANTA", round(mean(distritos_info$lat), 4), lat),
    # Cálculos derivados de superficie y categorías
    AREA_HA = AREA_KM2 * 100,
    Ha_Clase1_Bajo    = round(AREA_HA * (Pct_Clase1_Bajo / 100), 1),
    Ha_Clase2_Medio   = round(AREA_HA * (Pct_Clase2_Medio / 100), 1),
    Ha_Clase3_Alto    = round(AREA_HA * (Pct_Clase3_Alto / 100), 1),
    Ha_Clase4_MuyAlto = round(AREA_HA * (Pct_Clase4_MuyAlto / 100), 1),
    Pct_Clase3_4      = round(Pct_Clase3_Alto + Pct_Clase4_MuyAlto, 1),
    Ha_Clase3_4       = round(Ha_Clase3_Alto + Ha_Clase4_MuyAlto, 1),
    Aridez_Cat = case_when(
      Indice_Aridez_UNESCO < 0.20 ~ "Árido",
      Indice_Aridez_UNESCO < 0.50 ~ "Semiárido",
      Indice_Aridez_UNESCO < 0.65 ~ "Subhúmedo Seco",
      TRUE                        ~ "Húmedo"
    ),
    WSI_Cat = case_when(
      Prob_Estres_Hidrico_pct < 35 ~ "Bajo",
      Prob_Estres_Hidrico_pct < 55 ~ "Medio",
      Prob_Estres_Hidrico_pct < 70 ~ "Alto",
      TRUE                         ~ "Muy Alto"
    )
  )

message("5. Generando rasters ligeros agregados (~150m) en WGS84 para Leaflet...")
r_disp_stack <- c(
  p_mean_30m,
  t_mean_30m,
  wsi_30m,
  clase_30m,
  bal_30m,
  aridez_30m,
  eto_30m,
  ndmi_30m,
  slope_30m,
  p_cv_30m,
  t_trend_30m,
  p_trend_30m
)
r_disp_agg <- terra::aggregate(r_disp_stack, fact = 5, fun = "mean")
r_disp_agg[["Clase_Estres_Hidrico"]] <- round(r_disp_agg[["Clase_Estres_Hidrico"]])

# Proyección a WGS84 para visualización instantánea en Leaflet
r_disp_wgs84 <- terra::project(r_disp_agg, "EPSG:4326", method = "bilinear")
r_disp_wgs84[["Clase_Estres_Hidrico"]] <- round(r_disp_wgs84[["Clase_Estres_Hidrico"]])

# Stacks anuales agregados y proyectados a WGS84
message("   Proyectando series anuales de P y T...")
p_agg <- terra::aggregate(p_30m, fact = 5, fun = "mean")
t_agg <- terra::aggregate(t_30m, fact = 5, fun = "mean")

p_wgs84 <- terra::project(p_agg, "EPSG:4326", method = "bilinear")
t_wgs84 <- terra::project(t_agg, "EPSG:4326", method = "bilinear")

message("6. Guardando productos optimizados en app_data/...")
saveRDS(distritos_sf,    file.path(dir_out, "distritos_sf.rds"))
saveRDS(provincia_sf,    file.path(dir_out, "provincia_sf.rds"))
saveRDS(distritos_wgs84, file.path(dir_out, "distritos_wgs84.rds"))
saveRDS(provincia_wgs84, file.path(dir_out, "provincia_wgs84.rds"))
saveRDS(distritos_info,  file.path(dir_out, "distritos_info.rds"))
saveRDS(series_anuales,  file.path(dir_out, "series_anuales.rds"))
saveRDS(resumen_completo,file.path(dir_out, "resumen_distrital.rds"))

# GeoJSON para descargas y visualización web
st_write(distritos_wgs84, file.path(dir_out, "distritos_anta.geojson"), delete_dsn = TRUE, quiet = TRUE)

# Guardar GeoTIFFs optimizados
writeRaster(r_disp_agg,   file.path(dir_out, "rasters_display_150m.tif"), overwrite = TRUE,
            datatype = "FLT4S", gdal = c("COMPRESS=DEFLATE", "PREDICTOR=3"))
writeRaster(r_disp_wgs84, file.path(dir_out, "rasters_display_wgs84.tif"), overwrite = TRUE,
            datatype = "FLT4S", gdal = c("COMPRESS=DEFLATE", "PREDICTOR=3"))
writeRaster(p_wgs84,      file.path(dir_out, "P_anual_wgs84.tif"), overwrite = TRUE,
            datatype = "FLT4S", gdal = c("COMPRESS=DEFLATE", "PREDICTOR=3"))
writeRaster(t_wgs84,      file.path(dir_out, "T_anual_wgs84.tif"), overwrite = TRUE,
            datatype = "FLT4S", gdal = c("COMPRESS=DEFLATE", "PREDICTOR=3"))

# CSV exportables para el módulo de metodología y descargas
write.csv(series_anuales,  file.path(dir_out, "series_anuales_2001_2025_anta.csv"), row.names = FALSE)
write.csv(resumen_completo,file.path(dir_out, "resumen_hidroclimatico_distrital_anta.csv"), row.names = FALSE)

message("Preprocesamiento completado con éxito. Todos los archivos están listos.")
