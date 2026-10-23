# Comparación reproducible de los productos finales con la estación Ancachuro.
# Los CSV de origen no se modifican. Ejecutar desde la raíz del proyecto.
library(terra)
library(sf)

dir.create("auditoria_ancachuro", showWarnings = FALSE)
lon <- -(72 + 13 / 60 + 7.54 / 3600)
lat <- -(13 + 28 / 60 + 20.71 / 3600)
xy <- terra::vect(data.frame(lon = lon, lat = lat), geom = c("lon", "lat"), crs = "EPSG:4326")
st_xy <- sf::st_as_sf(data.frame(lon = lon, lat = lat), coords = c("lon", "lat"), crs = 4326)
distritos <- readRDS("app_data/distritos_wgs84.rds")
ubicacion <- sf::st_join(st_xy, distritos["NOMBDIST"])
stopifnot(ubicacion$NOMBDIST[[1]] == "ZURITE")

daily_files <- sort(list.files("estaciones", pattern = "^ancachuro_01_.*\\.csv$", full.names = TRUE))
daily <- do.call(rbind, lapply(daily_files, function(f) {
  x <- read.csv(f, check.names = FALSE, stringsAsFactors = FALSE)
  data.frame(fecha = as.Date(x[[1]], "%d/%m/%Y"),
             tmax = suppressWarnings(as.numeric(x[[2]])),
             tmin = suppressWarnings(as.numeric(x[[3]])),
             humedad = suppressWarnings(as.numeric(x[[4]])),
             p = suppressWarnings(as.numeric(x[[5]])), fuente = basename(f))
}))
stopifnot(!anyNA(daily$fecha), !anyDuplicated(daily$fecha))
daily$tmean <- (daily$tmax + daily$tmin) / 2
daily$year <- as.integer(format(daily$fecha, "%Y"))

hour_file <- "estaciones/ancachuro_12_2024_10_2026.csv"
h <- read.csv(hour_file, check.names = FALSE, stringsAsFactors = FALSE)
hourly <- data.frame(fecha = as.Date(h[[1]], "%d/%m/%Y"), hora = h[[2]],
                     temp = suppressWarnings(as.numeric(h[[3]])),
                     p = suppressWarnings(as.numeric(h[[4]])),
                     humedad = suppressWarnings(as.numeric(h[[5]])))
hourly$year <- as.integer(format(hourly$fecha, "%Y"))
stopifnot(!anyNA(hourly$fecha), !anyDuplicated(paste(hourly$fecha, hourly$hora)))

p <- terra::rast("Clima_Anta/P_anual_30m_PISCOv3_Anta_2001_2025.tif")
t <- terra::rast("Clima_Anta/T_anual_30m_PISCOt_Anta_2001_2025.tif")
est <- terra::rast("Clima_Anta/Estres_y_Balance_Hidrico_30m_PISCO_Anta.tif")
model_p <- as.numeric(terra::extract(p, xy)[1, -1])
model_t <- as.numeric(terra::extract(t, xy)[1, -1])
raw_p <- as.numeric(terra::extract(terra::rast("Clima_Anta/P_anual_Multibanda_Anta_2001_2025.tif"), xy)[1, -1])
raw_t <- as.numeric(terra::extract(terra::rast("Clima_Anta/T_anual_Multibanda_Anta_2001_2025.tif"), xy)[1, -1])
stopifnot(length(model_p) == 25, length(model_t) == 25,
          all(is.finite(model_p)), all(is.finite(model_t)))

pisco_file <- file.path(Sys.getenv("USERPROFILE"), "AppData/Local/R/cache/R/rpisco/PISCOp_m.nc")
if (!file.exists(pisco_file)) stop("No se encontró el NetCDF mensual PISCOp en la caché local")
pisco_month <- terra::rast(pisco_file)
stopifnot(terra::nlyr(pisco_month) == 540)
pisco_year <- terra::tapp(pisco_month[[241:540]], rep(2001:2025, each = 12), sum)
pisco_p <- as.numeric(terra::extract(pisco_year, xy)[1, -1])
pisco_t <- rep(NA_real_, 25)
tmax <- terra::rast(file.path(Sys.getenv("USERPROFILE"), "AppData/Local/R/cache/R/rpisco/tmax_daily_1981_2020_010.nc"))
tmin <- terra::rast(file.path(Sys.getenv("USERPROFILE"), "AppData/Local/R/cache/R/rpisco/tmin_daily_1981_2020_010.nc"))
idx_t <- which(as.integer(format(terra::time(tmax), "%Y")) %in% 2017:2020)
tmax_pt <- as.numeric(terra::extract(tmax[[idx_t]], xy)[1, -1])
tmin_pt <- as.numeric(terra::extract(tmin[[idx_t]], xy)[1, -1])
t_year <- as.integer(format(terra::time(tmax)[idx_t], "%Y"))
pisco_t[17:20] <- as.numeric(tapply((tmax_pt + tmin_pt) / 2, t_year, mean))

yr <- 2017:2024
daily_annual <- do.call(rbind, lapply(yr, function(y) {
  z <- daily[daily$year == y, ]
  expected <- as.integer(as.Date(sprintf("%d-01-01", y + 1)) - as.Date(sprintf("%d-01-01", y)))
  data.frame(anio = y, origen = "diario", dias_esperados = expected,
             dias_presentes = nrow(z), dias_P_validos = sum(is.finite(z$p)),
             dias_T_validos = sum(is.finite(z$tmean)),
             P_estacion_mm = sum(z$p, na.rm = TRUE),
             T_estacion_C = mean(z$tmean, na.rm = TRUE))
}))

z25 <- hourly[hourly$year == 2025, ]
hour_annual <- data.frame(anio = 2025, origen = "horario", dias_esperados = 365,
                          dias_presentes = length(unique(z25$fecha)),
                          dias_P_validos = NA_integer_, dias_T_validos = NA_integer_,
                          P_estacion_mm = sum(z25$p, na.rm = TRUE),
                          T_estacion_C = mean(z25$temp, na.rm = TRUE),
                          horas_esperadas = 8760, horas_presentes = nrow(z25),
                          horas_P_validas = sum(is.finite(z25$p)),
                          horas_T_validas = sum(is.finite(z25$temp)))
annual <- rbind(daily_annual, hour_annual[names(daily_annual)])
annual$P_modelo_mm <- model_p[annual$anio - 2000]
annual$T_modelo_C <- model_t[annual$anio - 2000]
annual$P_PISCO_mm <- pisco_p[annual$anio - 2000]
annual$T_PISCO_C <- pisco_t[annual$anio - 2000]
annual$P_GEE_preajuste_mm <- raw_p[annual$anio - 2000]
annual$T_GEE_preajuste_C <- raw_t[annual$anio - 2000]
annual$P_diferencia_modelo_menos_estacion_mm <- annual$P_modelo_mm - annual$P_estacion_mm
annual$T_diferencia_modelo_menos_estacion_C <- annual$T_modelo_C - annual$T_estacion_C
annual$P_cobertura <- ifelse(annual$origen == "diario", annual$dias_P_validos / annual$dias_esperados,
                            hour_annual$horas_P_validas / hour_annual$horas_esperadas)
annual$T_cobertura <- ifelse(annual$origen == "diario", annual$dias_T_validos / annual$dias_esperados,
                            hour_annual$horas_T_validas / hour_annual$horas_esperadas)
write.csv(annual, "auditoria_ancachuro/comparacion_anual.csv", row.names = FALSE, na = "")

metric <- function(obs, pred) c(n = length(obs), sesgo = mean(pred - obs),
                                MAE = mean(abs(pred - obs)), RMSE = sqrt(mean((pred - obs)^2)),
                                r = cor(obs, pred))
valid <- subset(annual, origen == "diario" & P_cobertura >= 0.99 & T_cobertura >= 0.99)
metrics <- rbind(P_modelo = metric(valid$P_estacion_mm, valid$P_modelo_mm),
                 P_PISCO = metric(valid$P_estacion_mm, valid$P_PISCO_mm),
                 P_GEE_preajuste = metric(valid$P_estacion_mm, valid$P_GEE_preajuste_mm),
                 T_modelo = metric(valid$T_estacion_C, valid$T_modelo_C),
                 T_GEE_preajuste = metric(valid$T_estacion_C, valid$T_GEE_preajuste_C))
valid_t_pisco <- subset(valid, anio <= 2020)
metrics <- rbind(metrics, T_PISCO_2018_2020 = metric(valid_t_pisco$T_estacion_C, valid_t_pisco$T_PISCO_C))
write.csv(data.frame(variable = rownames(metrics), metrics, row.names = NULL),
          "auditoria_ancachuro/metricas_2018_2024.csv", row.names = FALSE)
resumen_publico <- data.frame(
  estacion = "Anta Ancachuro", distrito = "ZURITE",
  anios_diarios = paste(valid$anio, collapse = ", "),
  n_anios = nrow(valid), cobertura_minima = min(valid$P_cobertura, valid$T_cobertura),
  P_MAE_mm_anio = unname(metrics["P_modelo", "MAE"]),
  P_sesgo_mm_anio = unname(metrics["P_modelo", "sesgo"]),
  P_correlacion_anual = unname(metrics["P_modelo", "r"]),
  T_sesgo_C = unname(metrics["T_modelo", "sesgo"]),
  T_MAE_C = unname(metrics["T_modelo", "MAE"])
)
write.csv(resumen_publico, "app_data/validacion_ancachuro.csv", row.names = FALSE)

qc <- data.frame(control = c("coordenada_lon", "coordenada_lat", "distrito",
                             "filas_diarias", "fechas_diarias_ausentes_2017_2024",
                             "P_diaria_S_D", "Tmax_diaria_S_D", "Tmin_diaria_S_D",
                             "P_diaria_negativa", "Tmax_menor_Tmin",
                             "filas_horarias_2025", "horas_horarias_ausentes_2025",
                             "P_horaria_S_D_2025", "T_horaria_S_D_2025"),
                 valor = c(lon, lat, ubicacion$NOMBDIST[[1]], nrow(daily),
                           sum(annual$dias_esperados[annual$origen == "diario"]) - nrow(daily),
                           sum(!is.finite(daily$p)), sum(!is.finite(daily$tmax)),
                           sum(!is.finite(daily$tmin)), sum(daily$p < 0, na.rm = TRUE),
                           sum(daily$tmax < daily$tmin, na.rm = TRUE), nrow(z25),
                           8760 - nrow(z25), sum(!is.finite(z25$p)), sum(!is.finite(z25$temp))))
write.csv(qc, "auditoria_ancachuro/control_calidad.csv", row.names = FALSE)
print(annual)
print(metrics)
print(qc)
