# ==============================================================================
# OPTIMIZACIÓN Y PRE-PROCESAMIENTO DE DATOS PARA LA APP SHINYREACT
# ==============================================================================
message("Iniciando optimización de datos para la aplicación Shiny...")

library(terra)
library(sf)
library(dplyr)
library(tidyr)

dir_out <- "app_data"
if (!dir.exists(dir_out)) dir.create(dir_out)

# 1. Cargar geometrías
distritos_sf <- st_read("data_vectorial/DISTRITOS_PROV_ANTA.shp", quiet = TRUE) |>
  st_transform(32718)
provincia_sf <- st_read("data_vectorial/PROV_ANTA.shp", quiet = TRUE) |>
  st_transform(32718)

# Calcular centroides y coordenadas en WGS84 para visualización e inspección
centroides_utm <- st_centroid(distritos_sf)
centroides_wgs <- st_transform(centroides_utm, 4326)
coords_utm <- st_coordinates(centroides_utm)
coords_wgs <- st_coordinates(centroides_wgs)

distritos_info <- distritos_sf |>
  st_drop_geometry() |>
  mutate(
    x_utm = round(coords_utm[, 1], 1),
    y_utm = round(coords_utm[, 2], 1),
    lon   = round(coords_wgs[, 1], 4),
    lat   = round(coords_wgs[, 2], 4)
  )

# 2. Cargar rasters a 30m
message("Cargando rasters a 30m...")
p_30m <- rast("Clima_Anta/P_anual_30m_PISCOv3_Anta_2001_2025.tif")
t_30m <- rast("Clima_Anta/T_anual_30m_PISCOt_Anta_2001_2025.tif")
estres_30m <- rast("Clima_Anta/Estres_y_Balance_Hidrico_30m_PISCO_Anta.tif")
var_30m <- rast("Clima_Anta/Variabilidad_y_Tendencias_PISCO_Anta_2001_2025.tif")
estres_base_30m <- rast("Clima_Anta/Estres_Hidrico_Anta_2001_2025.tif")

# Climatologías medias
p_mean_30m <- mean(p_30m)
names(p_mean_30m) <- "P_media"
t_mean_30m <- mean(t_30m)
names(t_mean_30m) <- "T_media"

slope_30m <- estres_base_30m[["slope"]]

# 3. Pre-calcular extracciones distritales completas (2001-2025)
message("Calculando series temporales por distrito...")
dist_vect <- vect(distritos_sf)
prov_vect <- vect(provincia_sf)

# Extracción distrital de Precipitación anual
p_dist <- terra::extract(p_30m, dist_vect, fun = mean, na.rm = TRUE)
p_dist$NOMBDIST <- dist_vect$NOMBDIST

p_prov <- terra::extract(p_30m, prov_vect, fun = mean, na.rm = TRUE)
p_prov$NOMBDIST <- "PROVINCIA DE ANTA"

p_all <- bind_rows(p_dist, p_prov) |>
  select(-ID) |>
  pivot_longer(cols = starts_with("P_"), names_to = "Year_str", values_to = "Precipitacion_mm") |>
  mutate(Year = as.integer(gsub("P_", "", Year_str))) |>
  select(NOMBDIST, Year, Precipitacion_mm)

# Extracción distrital de Temperatura anual
t_dist <- terra::extract(t_30m, dist_vect, fun = mean, na.rm = TRUE)
t_dist$NOMBDIST <- dist_vect$NOMBDIST

t_prov <- terra::extract(t_30m, prov_vect, fun = mean, na.rm = TRUE)
t_prov$NOMBDIST <- "PROVINCIA DE ANTA"

t_all <- bind_rows(t_dist, t_prov) |>
  select(-ID) |>
  pivot_longer(cols = starts_with("T_"), names_to = "Year_str", values_to = "Temperatura_C") |>
  mutate(Year = as.integer(gsub("T_", "", Year_str))) |>
  select(NOMBDIST, Year, Temperatura_C)

# Unir series anuales
series_anuales <- left_join(p_all, t_all, by = c("NOMBDIST", "Year"))

# 4. Extracción de variables multianuales e indicadores
message("Calculando indicadores estáticos y de balance hídrico...")
eto_30m     <- estres_30m[["ETo_PenmanMonteith_mm"]]
bal_30m     <- estres_30m[["Balance_Hidrico_P_PET_mm"]]
aridez_30m  <- estres_30m[["Indice_Aridez_UNESCO"]]
wsi_30m     <- estres_30m[["Prob_Estres_Hidrico_pct"]]
clase_30m   <- estres_30m[["Clase_Estres_Hidrico"]]
ndmi_30m    <- estres_30m[["ndmi"]]
p_cv_30m    <- var_30m[["P_CV_pct"]]
t_trend_30m <- var_30m[["T_trend_decada"]]
p_trend_30m <- var_30m[["P_trend_decada"]]

stack_indicadores <- c(p_mean_30m, t_mean_30m, eto_30m, bal_30m, aridez_30m, 
                       wsi_30m, ndmi_30m, slope_30m, p_cv_30m, t_trend_30m, p_trend_30m)

ind_dist <- terra::extract(stack_indicadores, dist_vect, fun = mean, na.rm = TRUE)
ind_dist$NOMBDIST <- dist_vect$NOMBDIST

ind_prov <- terra::extract(stack_indicadores, prov_vect, fun = mean, na.rm = TRUE)
ind_prov$NOMBDIST <- "PROVINCIA DE ANTA"

indicadores_df <- bind_rows(ind_dist, ind_prov) |> select(-ID)

# Distribución porcentual de clases de estrés hídrico por distrito
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

resumen_completo <- bind_cols(indicadores_df, as.data.frame(mat_clases))

# Agregar metadatos distritales (área, población, capital)
resumen_completo <- resumen_completo |>
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
    lat = ifelse(NOMBDIST == "PROVINCIA DE ANTA", round(mean(distritos_info$lat), 4), lat)
  )

# 5. GENERAR STACK AGREGADO (DOWN-SAMPLED) ULTRA RÁPIDO PARA GGPLOT EN LA APP
message("Creando rasters ligeros agregados (~150m) para renderizado instantáneo...")

# Agregamos capas clave para visualización: fact = 5 (30m -> 150m)
# Esto reduce de ~7 millones de píxeles a ~270,000 píxeles por capa: renderizado en <0.1 segundos!
r_display_stack <- c(
  p_mean_30m,
  t_mean_30m,
  p_30m[["P_2025"]],
  t_30m[["T_2025"]],
  wsi_30m,
  clase_30m,
  bal_30m,
  aridez_30m,
  eto_30m,
  ndmi_30m,
  slope_30m,
  p_trend_30m,
  t_trend_30m
)

# Agregamos con terra::aggregate
r_display_agg <- terra::aggregate(r_display_stack, fact = 5, fun = "mean")

# Redondeamos clase de estrés al entero más cercano
r_display_agg[["Clase_Estres_Hidrico"]] <- round(r_display_agg[["Clase_Estres_Hidrico"]])

# 6. Guardar archivos optimizados
message("Guardando datos optimizados en app_data/...")
saveRDS(distritos_sf, file.path(dir_out, "distritos_sf.rds"))
saveRDS(provincia_sf, file.path(dir_out, "provincia_sf.rds"))
saveRDS(distritos_info, file.path(dir_out, "distritos_info.rds"))
saveRDS(series_anuales, file.path(dir_out, "series_anuales.rds"))
saveRDS(resumen_completo, file.path(dir_out, "resumen_distrital.rds"))

# Guardar SpatRaster agregado como archivo GeoTIFF ligero (sólo ~10-15 MB vs 1GB+)
writeRaster(
  r_display_agg, 
  file.path(dir_out, "rasters_display_150m.tif"), 
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = c("COMPRESS=DEFLATE", "PREDICTOR=3")
)

message("Optimización finalizada con éxito. Todos los archivos están listos para la app.")
