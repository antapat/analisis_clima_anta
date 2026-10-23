# Compara productos finales con estaciones disponibles, sin modificar rásteres.
# Ejecutar desde la raíz del proyecto. Los CSV originales quedan intactos.
suppressPackageStartupMessages({library(terra); library(sf)})
dir.create("auditoria_estaciones", showWarnings = FALSE)

meta <- data.frame(
  estacion = c("ANCACHURO", "SORAYPAMPA", "CURAHUASI", "URUBAMBA"),
  codigo = c("000684", "47294362", "113253", "000683"),
  altitud_m = c(3324, 3854, 2741, 2850),
  lon = -c(72 + 13/60 + 7.54/3600, 72 + 34/60 + 24.88/3600,
           72 + 44/60 + 5.64/3600, 72 + 7/60 + 28.40/3600),
  lat = -c(13 + 28/60 + 20.71/3600, 13 + 23/60 + 43.82/3600,
           13 + 33/60 + 9.36/3600, 13 + 18/60 + 18.60/3600)
)
pts_sf <- st_as_sf(meta, coords = c("lon", "lat"), crs = 4326)
districts <- readRDS("app_data/distritos_wgs84.rds")
meta$distrito_modelo <- st_join(pts_sf, districts["NOMBDIST"])$NOMBDIST
stopifnot(identical(meta$distrito_modelo[1:2], c("ZURITE", "MOLLEPATA")),
          all(is.na(meta$distrito_modelo[3:4])))
pts <- vect(pts_sf)

num <- function(x) suppressWarnings(as.numeric(x))
expected_days <- function(y) as.integer(as.Date(sprintf("%d-01-01", y + 1L)) -
                                        as.Date(sprintf("%d-01-01", y)))
annual_daily <- function(files, station) {
  x <- do.call(rbind, lapply(sort(files), function(f) {
    z <- read.csv(f, check.names = FALSE, stringsAsFactors = FALSE)
    data.frame(date = as.Date(z[[1]], "%d/%m/%Y"),
               tmax = num(z[[2]]), tmin = num(z[[3]]), p = num(z[[5]]))
  }))
  stopifnot(!anyNA(x$date), !anyDuplicated(x$date))
  x$tmid <- (x$tmax + x$tmin) / 2
  x$year <- as.integer(format(x$date, "%Y"))
  do.call(rbind, lapply(sort(unique(x$year)), function(y) {
    a <- x[x$year == y, ]; n <- expected_days(y)
    data.frame(estacion = station, anio = y, fuente = "diaria",
               P_observada_mm = if (any(is.finite(a$p))) sum(a$p, na.rm = TRUE) else NA_real_,
               T_observada_C = mean(a$tmid, na.rm = TRUE),
               P_cobertura = sum(is.finite(a$p)) / n,
               T_cobertura = sum(is.finite(a$tmid)) / n,
               registros = nrow(a), P_validos = sum(is.finite(a$p)),
               T_validos = sum(is.finite(a$tmid)), esperado = n)
  }))
}
annual_hourly <- function(files, station) {
  x <- do.call(rbind, lapply(sort(files), function(f) {
    z <- read.csv(f, check.names = FALSE, stringsAsFactors = FALSE)
    data.frame(date = as.Date(z[[1]], "%d/%m/%Y"), hour = z[[2]],
               temp = num(z[[3]]), p = num(z[[4]]))
  }))
  stopifnot(!anyNA(x$date), !anyDuplicated(paste(x$date, x$hour)))
  x$year <- as.integer(format(x$date, "%Y"))
  days <- split(x$temp, x$date)
  day_tmid <- vapply(days, function(z) {
    z <- z[is.finite(z)]
    if (length(z) < 20L) return(NA_real_)
    (min(z) + max(z)) / 2
  }, numeric(1))
  day_year <- as.integer(substr(names(days), 1, 4))
  do.call(rbind, lapply(sort(unique(x$year)), function(y) {
    a <- x[x$year == y, ]; n <- expected_days(y)
    td <- day_tmid[day_year == y]
    data.frame(estacion = station, anio = y, fuente = "horaria",
               P_observada_mm = if (any(is.finite(a$p))) sum(a$p, na.rm = TRUE) else NA_real_,
               T_observada_C = if (any(is.finite(td))) mean(td, na.rm = TRUE) else NA_real_,
               P_cobertura = sum(is.finite(a$p)) / (24 * n),
               T_cobertura = sum(is.finite(td)) / n,
               registros = nrow(a), P_validos = sum(is.finite(a$p)),
               T_validos = sum(is.finite(td)), esperado = 24 * n)
  }))
}

annual <- rbind(
  annual_daily(list.files("estaciones", "^ancachuro_01_.*\\.csv$", full.names = TRUE), "ANCACHURO"),
  annual_hourly("estaciones/ancachuro_12_2024_10_2026.csv", "ANCACHURO"),
  annual_hourly(list.files("estaciones", "^soraypama_.*\\.csv$", full.names = TRUE), "SORAYPAMPA"),
  annual_hourly("estaciones/curahuasi.csv", "CURAHUASI"),
  annual_daily(list.files("estaciones", "^urubamaba_.*\\.csv$", full.names = TRUE), "URUBAMBA")
)
# En el año de solapamiento Ancachuro 2024 se prefiere la serie diaria.
annual <- annual[!(annual$estacion == "ANCACHURO" & annual$anio == 2024 &
                     annual$fuente == "horaria"), ]
annual <- annual[annual$anio >= 2001 & annual$anio <= 2025, ]
stopifnot(!anyDuplicated(paste(annual$estacion, annual$anio)))

extract_years <- function(path, years = 2001:2025) {
  x <- rast(path)
  z <- terra::extract(x, pts)[, -1, drop = FALSE]
  stopifnot(ncol(z) == length(years))
  z
}
model_p <- extract_years("Clima_Anta/P_anual_30m_PISCOv3_Anta_2001_2025.tif")
model_t <- extract_years("Clima_Anta/T_anual_30m_PISCOt_Anta_2001_2025.tif")
raw_p <- extract_years("Clima_Anta/P_anual_Multibanda_Anta_2001_2025.tif")
raw_t <- extract_years("Clima_Anta/T_anual_Multibanda_Anta_2001_2025.tif")
base <- file.path(Sys.getenv("USERPROFILE"), "AppData/Local/R/cache/R/rpisco")
pisco_month <- rast(file.path(base, "PISCOp_m.nc"))
stopifnot(nlyr(pisco_month) == 540L)
pm <- terra::extract(pisco_month[[241:540]], pts)[, -1, drop = FALSE]
pisco_p <- t(vapply(seq_len(nrow(pm)), function(i)
  tapply(as.numeric(pm[i, ]), rep(2001:2025, each = 12), sum), numeric(25)))
tmax <- rast(file.path(base, "tmax_daily_1981_2020_010.nc"))
tmin <- rast(file.path(base, "tmin_daily_1981_2020_010.nc"))
it <- which(as.integer(format(time(tmax), "%Y")) >= 2011)
t_year <- as.integer(format(time(tmax)[it], "%Y"))
tx <- terra::extract(tmax[[it]], pts)[, -1, drop = FALSE]
tn <- terra::extract(tmin[[it]], pts)[, -1, drop = FALSE]
pisco_t <- matrix(NA_real_, 4, 25)
for (i in seq_len(4)) pisco_t[i, 11:20] <-
  as.numeric(tapply((as.numeric(tx[i, ]) + as.numeric(tn[i, ])) / 2, t_year, mean))

key <- match(annual$estacion, meta$estacion)
col_year <- annual$anio - 2000
pick <- function(mat) mat[cbind(key, col_year)]
annual$P_modelo_mm <- pick(model_p)
annual$T_modelo_C <- pick(model_t)
annual$P_GEE_preajuste_mm <- pick(raw_p)
annual$T_GEE_preajuste_C <- pick(raw_t)
annual$P_PISCO_mm <- pick(pisco_p)
annual$T_PISCO_C <- pick(pisco_t)
annual$distrito_modelo <- meta$distrito_modelo[key]
write.csv(annual, "auditoria_estaciones/comparacion_anual.csv", row.names = FALSE, na = "")
write.csv(meta, "auditoria_estaciones/metadata_estaciones.csv", row.names = FALSE, na = "")

metric <- function(obs, pred) {
  ok <- is.finite(obs) & is.finite(pred)
  if (!any(ok)) return(c(n = 0, sesgo = NA, MAE = NA, RMSE = NA, r = NA))
  o <- obs[ok]; q <- pred[ok]
  c(n = length(o), sesgo = mean(q - o), MAE = mean(abs(q - o)),
    RMSE = sqrt(mean((q - o)^2)), r = if (length(o) > 1) cor(o, q) else NA_real_)
}
metrics <- do.call(rbind, lapply(meta$estacion, function(s) {
  a <- annual[annual$estacion == s, ]
  do.call(rbind, lapply(c("P", "T"), function(v) {
    b <- a[is.finite(a[[paste0(v, "_cobertura")]]) & a[[paste0(v, "_cobertura")]] >= 0.99, ]
    # La serie de Ancachuro cambia de observaciones diarias a horarias en 2025.
    # No se mezclan ambos regímenes en la métrica principal.
    if (s == "ANCACHURO") b <- b[b$anio <= 2024, ]
    do.call(rbind, lapply(c("modelo", "PISCO", "GEE_preajuste"), function(prod) {
      obs <- b[[paste0(v, "_observada_", if (v == "P") "mm" else "C")]]
      pred <- b[[paste0(v, "_", prod, if (v == "P") "_mm" else "_C")]]
      z <- metric(obs, pred)
      data.frame(estacion = s, variable = v, producto = prod,
                 anios = paste(b$anio[is.finite(obs) & is.finite(pred)], collapse = ", "),
                 n = unname(z["n"]), sesgo = unname(z["sesgo"]),
                 MAE = unname(z["MAE"]), RMSE = unname(z["RMSE"]), r = unname(z["r"]))
    }))
  }))
}))
write.csv(metrics, "auditoria_estaciones/metricas.csv", row.names = FALSE, na = "")
write.csv(metrics, "app_data/validacion_red_estaciones.csv", row.names = FALSE, na = "")
print(metrics)
