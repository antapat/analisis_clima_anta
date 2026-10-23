# ==============================================================================
# UTILS_DATA.R: Funciones de carga y estructuración de datos climáticos
# Municipalidad Provincial de Anta - Gerencia de Desarrollo Urbano y Rural
# ==============================================================================

# Shiny carga automáticamente todos los archivos de R/ antes de evaluar
# app.R. En Connect Cloud desde GitHub solo se sirve cloud_lite y no están
# presentes los datos de la aplicación espacial ni sus paquetes.
if (file.exists("app_data/resumen_distrital.rds")) {
  suppressPackageStartupMessages({
    library(sf)
    library(terra)
    library(dplyr)
    library(tidyr)
  })
}

# Formateadores numéricos consistentes
fmt_num <- function(x, digits = 0) {
  if (is.null(x) || length(x) == 0) return("--")
  x <- as.numeric(x)
  out <- rep("--", length(x))
  ok <- !is.na(x)
  out[ok] <- format(round(x[ok], digits), big.mark = ",", scientific = FALSE, trim = TRUE)
  out
}

fmt_dec <- function(x, digits = 1) {
  if (is.null(x) || length(x) == 0) return("--")
  x <- as.numeric(x)
  out <- rep("--", length(x))
  ok <- !is.na(x)
  out[ok] <- format(round(x[ok], digits), nsmall = digits, trim = TRUE)
  out
}

fmt_pct <- function(x, digits = 1) {
  if (is.null(x) || length(x) == 0) return("--%")
  x <- as.numeric(x)
  out <- rep("--%", length(x))
  ok <- !is.na(x)
  out[ok] <- paste0(format(round(x[ok], digits), nsmall = digits, trim = TRUE), "%")
  out
}

fmt_sign <- function(x, digits = 1, unit = "") {
  if (is.null(x) || length(x) == 0) return("--")
  val <- round(as.numeric(x), digits)
  out <- rep("--", length(val))
  ok <- !is.na(val)
  sgn <- ifelse(val[ok] > 0, "+", "")
  out[ok] <- paste0(sgn, format(val[ok], nsmall = digits, trim = TRUE), if (unit != "") paste0(" ", unit) else "")
  out
}

# Generador de mensaje interpretativo territorial dinámico
generar_mensaje_interpretativo <- function(territorio, yr, p_anom_pct, t_anom_c, wsi_pct, wsi_cat, pct_critica) {
  # Caracterización pluvial
  txt_lluvia <- if (p_anom_pct <= -20) {
    "año significativamente más seco que la media histórica (déficit pronunciado de lluvias)"
  } else if (p_anom_pct <= -5) {
    "año más seco que el promedio multianual"
  } else if (p_anom_pct >= 20) {
    "año extraordinariamente húmedo con lluvias muy superiores a la media"
  } else if (p_anom_pct >= 5) {
    "año más húmedo que el promedio multianual"
  } else {
    "año con precipitaciones en torno a la media del periodo 2001–2025"
  }

  # Caracterización térmica
  txt_temp <- if (t_anom_c >= 0.6) {
    "temperatura marcadamente superior al promedio (fuerte anomalía cálida)"
  } else if (t_anom_c >= 0.2) {
    "temperatura superior a la media histórica"
  } else if (t_anom_c <= -0.6) {
    "temperatura marcadamente inferior al promedio (anomalía fría persistente)"
  } else if (t_anom_c <= -0.2) {
    "temperatura ligeramente más fría que el promedio"
  } else {
    "temperatura próxima a la media del periodo 2001–2025"
  }

  # Caracterización estructural de estrés hídrico
  txt_estres <- if (wsi_cat == "Muy Alto") {
    paste0("En términos estructurales, presenta susceptibilidad MUY ALTA al estrés hídrico (WSI: ", 
           fmt_dec(wsi_pct, 1), " / 100), con un ", fmt_dec(pct_critica, 1), "% de su territorio clasificado en clases 3 y 4 del modelo.")
  } else if (wsi_cat == "Alto") {
    paste0("En términos estructurales, presenta susceptibilidad ALTA al estrés hídrico (WSI: ", 
           fmt_dec(wsi_pct, 1), " / 100), con un ", fmt_dec(pct_critica, 1), "% de su superficie en clases 3 y 4 del modelo.")
  } else if (wsi_cat == "Medio") {
    paste0("Presenta susceptibilidad MODERADA al estrés hídrico (WSI: ", 
           fmt_dec(wsi_pct, 1), " / 100) según el índice relativo del modelo.")
  } else {
    paste0("Presenta susceptibilidad BAJA al estrés hídrico (WSI: ", 
           fmt_dec(wsi_pct, 1), " / 100) según el índice relativo del modelo.")
  }

  tipo_alerta <- if (wsi_cat %in% c("Muy Alto", "Alto") && (p_anom_pct < -5 || t_anom_c > 0.3)) {
    "alert-danger"
  } else if (p_anom_pct < -10 || t_anom_c > 0.5 || wsi_cat == "Alto") {
    "alert-warning"
  } else {
    "alert-info"
  }

  icono <- if (tipo_alerta == "alert-danger") {
    "exclamation-triangle"
  } else if (tipo_alerta == "alert-warning") {
    "info-circle"
  } else {
    "check-circle"
  }

  titulo <- paste0("Diagnóstico Territorial Integrado: ", territorio, " (Año ", yr, ")")
  cuerpo <- paste0("Para el año ", yr, ", el modelo estima un ", txt_lluvia, " (", fmt_sign(p_anom_pct, 1, "%"),
                   ") y ", txt_temp, " (", fmt_sign(t_anom_c, 2, "°C"), "). ", txt_estres)

  list(
    tipo = tipo_alerta,
    icono = icono,
    titulo = titulo,
    mensaje = cuerpo
  )
}

# Caché compartido por todos los usuarios de un mismo proceso Shiny
load_app_data <- local({
  cache <- NULL

  function(refresh = FALSE) {
    if (is.null(cache) || isTRUE(refresh)) {
      message("Inicializando caché maestro de datos climáticos...")
      
      # Datos tabulares y vectoriales
      distritos_sf    <- readRDS("app_data/distritos_sf.rds")
      provincia_sf    <- readRDS("app_data/provincia_sf.rds")
      distritos_wgs84 <- readRDS("app_data/distritos_wgs84.rds")
      provincia_wgs84 <- readRDS("app_data/provincia_wgs84.rds")
      distritos_info  <- readRDS("app_data/distritos_info.rds")
      series_anuales  <- readRDS("app_data/series_anuales.rds")
      resumen_dist    <- readRDS("app_data/resumen_distrital.rds")
      
      # Rasters ligeros WGS84 para visualización instantánea en Leaflet
      r_disp_wgs84    <- rast("app_data/rasters_display_wgs84.tif")
      p_wgs84         <- rast("app_data/P_anual_wgs84.tif")
      t_wgs84         <- rast("app_data/T_anual_wgs84.tif")
      
      # Rásteres del modelo a 30 m (EPSG:32718); resolución no implica exactitud puntual.
      p_30m_ref       <- rast("Clima_Anta/P_anual_30m_PISCOv3_Anta_2001_2025.tif")
      t_30m_ref       <- rast("Clima_Anta/T_anual_30m_PISCOt_Anta_2001_2025.tif")
      estres_30m_ref  <- rast("Clima_Anta/Estres_y_Balance_Hidrico_30m_PISCO_Anta.tif")
      var_30m_ref     <- rast("Clima_Anta/Variabilidad_y_Tendencias_PISCO_Anta_2001_2025.tif")
      estres_base_ref <- rast("Clima_Anta/Estres_Hidrico_Anta_2001_2025.tif")

      cache <<- list(
        distritos_sf    = distritos_sf,
        provincia_sf    = provincia_sf,
        distritos_wgs84 = distritos_wgs84,
        provincia_wgs84 = provincia_wgs84,
        distritos_info  = distritos_info,
        series_anuales  = series_anuales,
        resumen         = resumen_dist,
        r_disp_wgs84    = r_disp_wgs84,
        p_wgs84         = p_wgs84,
        t_wgs84         = t_wgs84,
        p_30m_ref       = p_30m_ref,
        t_30m_ref       = t_30m_ref,
        estres_30m_ref  = estres_30m_ref,
        var_30m_ref     = var_30m_ref,
        estres_base_ref = estres_base_ref
      )
    }

    cache
  }
})
