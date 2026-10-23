# ==============================================================================
# FLUJO DE TRABAJO LOCAL COMPLETO: GEE (30m) + PISCOp (2001-2025) & PISCOt (2001-2020)
# CASO DE ESTUDIO: PROVINCIA DE ANTA, CUSCO
# ==============================================================================
library(rpisco)
library(terra)
library(sf)
library(dplyr)
library(tidyr)
library(tibble)

dir_clima <- "Clima_Anta"

# ------------------------------------------------------------------------------
# 1. OBTENCIÓN DE LÍMITES OFICIALES (GEOPERU Y SHAPEFILE LOCAL)
# ------------------------------------------------------------------------------
anta_sf   <- st_read("data_vectorial/PROV_ANTA.shp") |> st_transform(32718)
anta_vect <- st_read("data_vectorial/DISTRITOS_PROV_ANTA.shp") |> st_transform(32718)
anta_vect <- vect(anta_vect)
anta_buf_wgs <- st_buffer(st_transform(anta_sf, 4326), 20000)

# ------------------------------------------------------------------------------
# 2. DESCARGA Y PROCESAMIENTO DE PRECIPITACIÓN Y TEMPERATURA CON {rpisco}
# ------------------------------------------------------------------------------
# A) Precipitación mensual (PISCOp v3.0: dataset "monthly" -> 2001-2025)
pisco_download("monthly")
pisco_mensual_raw <- pisco_read(dataset = "monthly", dates = 2001:2025)
pisco_anta_mensual <- pisco_clip(pisco_mensual_raw, mask = anta_buf_wgs)

n_capas   <- nlyr(pisco_anta_mensual)
anios_rep <- rep(2001:2025, each = 12)[1:n_capas]
pisco_p_anual <- tapp(pisco_anta_mensual, index = anios_rep, fun = sum)
names(pisco_p_anual) <- paste0("PISCO_P_", unique(anios_rep))

# B) Temperatura diaria (tmax_daily y tmin_daily de PISCOt -> Limitado a 2001-2020)
pisco_download("tmax_daily")
pisco_download("tmin_daily")

tmax_raw <- pisco_read(dataset = "tmax_daily", dates = 2001:2020)
tmin_raw <- pisco_read(dataset = "tmin_daily", dates = 2001:2020)

tmax_anta <- pisco_clip(tmax_raw, mask = anta_buf_wgs)
tmin_anta <- pisco_clip(tmin_raw, mask = anta_buf_wgs)

# Temperatura media diaria = (Tmax + Tmin) / 2
t_media_diaria <- (tmax_anta + tmin_anta) / 2

# Agregación de temperatura diaria a escala ANUAL (promedio anual 2001-2020)
fechas_t <- time(t_media_diaria)
anios_t  <- as.numeric(format(fechas_t, "%Y"))
pisco_t_anual <- tapp(t_media_diaria, index = anios_t, fun = mean, na.rm = TRUE)
names(pisco_t_anual) <- paste0("PISCO_T_", unique(anios_t))

# C) Evapotranspiración Potencial de Referencia (PISCOeo_pm: dataset "eto_clim" 1981-2010)
pisco_download("eto_clim")
pisco_pet_raw  <- pisco_read(dataset = "eto_clim")
pisco_pet_anta <- pisco_clip(pisco_pet_raw, mask = anta_buf_wgs)
pisco_pet_clim <- sum(pisco_pet_anta) # Suma anual climatológica (mm/año)

# ------------------------------------------------------------------------------
# 3. CARGA DE STACKS A 30 METROS PROVENIENTES DE GOOGLE EARTH ENGINE
# ------------------------------------------------------------------------------
t_gee_30m  <- rast(file.path(dir_clima, "T_anual_Multibanda_Anta_2001_2025.tif"))
p_gee_30m  <- rast(file.path(dir_clima, "P_anual_Multibanda_Anta_2001_2025.tif"))
estres_gee <- rast(file.path(dir_clima, "Estres_Hidrico_Anta_2001_2025.tif"))

ndmi_30m  <- estres_gee[["ndmi"]]
slope_30m <- estres_gee[["slope"]]

# ------------------------------------------------------------------------------
# 4. AUDITORÍA Y VALIDACIÓN ESTADÍSTICA (Soporte nativo ~10 km)
# ------------------------------------------------------------------------------
pisco_p_utm <- project(pisco_p_anual, "EPSG:32718", method = "bilinear")
pisco_t_utm <- project(pisco_t_anual, "EPSG:32718", method = "bilinear")

p_gee_10km  <- project(p_gee_30m, pisco_p_utm, method = "average")
t_gee_10km  <- project(t_gee_30m[[paste0("T_", 2001:2020)]], pisco_t_utm, method = "average")

calcular_metricas <- function(sim_stack, obs_stack, nombre_var) {
  v_sim <- as.numeric(values(mask(sim_stack, anta_vect)))
  v_obs <- as.numeric(values(mask(obs_stack, anta_vect)))
  idx   <- complete.cases(v_sim, v_obs)
  s <- v_sim[idx]; o <- v_obs[idx]
  
  r     <- cor(s, o)
  alpha <- sd(s) / sd(o)
  beta  <- mean(s) / mean(o)
  kge   <- 1 - sqrt((r - 1)^2 + (alpha - 1)^2 + (beta - 1)^2)
  rmse  <- sqrt(mean((s - o)^2))
  pbias <- 100 * sum(s - o) / sum(o)
  
  tibble(Variable = nombre_var, r_Pearson = round(r, 3), KGE = round(kge, 3), 
         RMSE = round(rmse, 2), PBIAS_pct = round(pbias, 2))
}

val_p <- calcular_metricas(p_gee_10km, pisco_p_utm, "Precipitación Anual (mm) [2001-2025]")
val_t <- calcular_metricas(t_gee_10km, pisco_t_utm, "Temperatura Media (°C) [2001-2020]")

print("=== VALIDACIÓN ESTADÍSTICA VS PISCO ===")
print(bind_rows(val_p, val_t))

# ------------------------------------------------------------------------------
# 5. AJUSTE DE SESGO Y FUSIÓN A 30 METROS (sin garantía de conservación exacta)
# ------------------------------------------------------------------------------
# A) Precipitación: Ratio Scaling anual proyectado a 30 m (2001-2025)
ratio_p_10km     <- pisco_p_utm / clamp(p_gee_10km, lower = 1)
ratio_p_30m      <- project(ratio_p_10km, p_gee_30m, method = "bilinear")
p_anta_pisco_30m <- (p_gee_30m * ratio_p_30m) |> mask(anta_vect)
names(p_anta_pisco_30m) <- paste0("P_", 2001:2025)

# B) Temperatura: Delta Additive Scaling proyectado a 30 m (2001-2020)
# Para el periodo 2021-2025, se proyecta usando la señal base de GEE corregida con el sesgo medio 2001-2020
delta_t_10km     <- pisco_t_utm - t_gee_10km
delta_t_30m      <- project(delta_t_10km, t_gee_30m[[paste0("T_", 2001:2020)]], method = "bilinear")
delta_t_mean_30m <- mean(delta_t_30m) # Sesgo medio espacial 2001-2020

t_2001_2020_corr <- (t_gee_30m[[paste0("T_", 2001:2020)]] + delta_t_30m)
t_2021_2025_corr <- (t_gee_30m[[paste0("T_", 2021:2025)]] + delta_t_mean_30m)
t_anta_pisco_30m <- c(t_2001_2020_corr, t_2021_2025_corr) |> mask(anta_vect)
names(t_anta_pisco_30m) <- paste0("T_", 2001:2025)

p_media_30m <- mean(p_anta_pisco_30m)
t_media_30m <- mean(t_anta_pisco_30m)

# ------------------------------------------------------------------------------
# 6. BALANCE HÍDRICO DINÁMICO (PISCOeo_pm) Y ESTRÉS HÍDRICO (WSI) A 30 METROS
# ------------------------------------------------------------------------------
# A) Proyección de la ETo base de PISCO y temperatura media de referencia a 30 m
t_pisco_mean_30m <- project(mean(pisco_t_utm), t_gee_30m, method = "bilinear")
pet_base_30m     <- project(pisco_pet_clim, t_gee_30m, method = "bilinear")

# B) Modulación dinámica anual de la ETo (2001-2025) usando broadcasting nativo de terra
# (Operación vectorizada en C++ que ajusta la ETo año a año según la anomalía térmica corregida)
pet_dinamico_stack <- clamp(pet_base_30m + 35 * (t_anta_pisco_30m - t_pisco_mean_30m), lower = 200)
names(pet_dinamico_stack) <- paste0("ETo_", 2001:2025)

# C) Climatologías multianuales y cálculo de indicadores físicos
pet_multianual_30m   <- mean(pet_dinamico_stack)
p_media_30m          <- mean(p_anta_pisco_30m)
t_media_30m          <- mean(t_anta_pisco_30m)

indice_aridez_unesco <- p_media_30m / pet_multianual_30m
deficit_hidrico_mm   <- p_media_30m - pet_multianual_30m

norm_robusta <- function(r) {
  q <- global(r, fun = quantile, probs = c(0.02, 0.98), na.rm = TRUE)
  clamp((r - q[1, 1]) / (q[1, 2] - q[1, 1]), lower = 0, upper = 1)
}

p_std_30m <- stdev(p_anta_pisco_30m, pop = FALSE)
p_cv_30m  <- (p_std_30m / clamp(p_media_30m, lower = 1)) * 100

r_aridez <- 1 - norm_robusta(indice_aridez_unesco)
r_ndmi   <- 1 - norm_robusta(ndmi_30m)
r_cv     <- norm_robusta(p_cv_30m)
r_slope  <- norm_robusta(slope_30m)

# D) Índice relativo compuesto de susceptibilidad hídrica (WSI, 0–100)
wsi_pisco_30m <- (0.35 * r_aridez + 0.30 * r_ndmi + 0.20 * r_cv + 0.15 * r_slope) * 100

clase_wsi_30m <- classify(
  wsi_pisco_30m,
  rcl = matrix(c(-Inf, 35, 1,
                 35, 55, 2,
                 55, 70, 3,
                 70, Inf, 4), ncol = 3, byrow = TRUE)
)

estres_pisco_30m <- c(wsi_pisco_30m, clase_wsi_30m, indice_aridez_unesco, 
                      deficit_hidrico_mm, pet_multianual_30m, ndmi_30m)
names(estres_pisco_30m) <- c("Prob_Estres_Hidrico_pct", "Clase_Estres_Hidrico",
                             "Indice_Aridez_UNESCO", "Balance_Hidrico_P_PET_mm",
                             "ETo_PenmanMonteith_mm", "ndmi")

# ------------------------------------------------------------------------------
# 7. EXTRACCIÓN DISTRITAL OFICIAL Y CONTROL DE CALIDAD (30 m)
# ------------------------------------------------------------------------------
precip_distrital_anual <- terra::extract(
  p_anta_pisco_30m, 
  anta_vect, 
  fun = mean, 
  na.rm = TRUE
)
precip_distrital_anual$distrito <- anta_vect$NOMBDIST
print("=== PRECIPITACIÓN MEDIA ANUAL POR DISTRITO (2001-2025) ===")
print(head(precip_distrital_anual))

# Verificación estricta de resolución espacial de salida (30 m x 30 m)
stopifnot(all(res(p_anta_pisco_30m) == c(30, 30)))
stopifnot(all(res(t_anta_pisco_30m) == c(30, 30)))
stopifnot(all(res(estres_pisco_30m) == c(30, 30)))

# Escritura de resultados finales a disco
writeRaster(
  p_anta_pisco_30m, 
  file.path(dir_clima, "P_anual_30m_PISCOv3_Anta_2001_2025.tif"), 
  overwrite = TRUE
)

writeRaster(
  t_anta_pisco_30m, 
  file.path(dir_clima, "T_anual_30m_PISCOt_Anta_2001_2025.tif"), 
  overwrite = TRUE
)

writeRaster(
  estres_pisco_30m, 
  file.path(dir_clima, "Estres_y_Balance_Hidrico_30m_PISCO_Anta.tif"), 
  overwrite = TRUE
)

# La variabilidad y las tendencias publicadas deben corresponder a estos
# rásteres finales corregidos, no al producto preliminar exportado por GEE.
source("scripts/recalcular_variabilidad_pisco.R", encoding = "UTF-8")

# Contraste instrumental separado del ajuste. Dos estaciones caen dentro del
# dominio y dos aportan contexto externo; no se extrapolan sus sesgos.
source("scripts/validar_red_estaciones.R", encoding = "UTF-8")

cat("\n[OK] Flujo ejecutado sin errores. Stacks de precipitación, temperatura y balance hídrico exportados a 30 metros en EPSG:32718.\n")
