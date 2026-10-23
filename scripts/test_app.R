# ==============================================================================
# TEST_APP.R: Script de validación automatizada de la app climática
# ==============================================================================

message("Iniciando validación de la aplicación Shiny...")

version_r <- paste(R.version$major, strsplit(R.version$minor, "\\.")[[1]][1], sep = ".")
bibliotecas_usuario <- c(
  file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", version_r),
  file.path(Sys.getenv("USERPROFILE"), "AppData", "Local", "R", "win-library", version_r)
)
for (biblioteca_usuario in unique(bibliotecas_usuario)) {
  if (dir.exists(biblioteca_usuario)) .libPaths(c(biblioteca_usuario, .libPaths()))
}
invisible(try(Sys.setlocale("LC_CTYPE", "English_United States.utf8"), silent = TRUE))

# 1. Comprobar librerías
suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(leaflet)
  library(plotly)
  library(reactable)
  library(dplyr)
  library(sf)
  library(terra)
  library(htmltools)
})
message(" Librerías cargadas exitosamente.")

# 2. Cargar utilidades y módulos
source("R/utils_data.R", encoding = "UTF-8")
source("R/mod_guia_indicadores.R", encoding = "UTF-8")
source("R/mod_portada_situacion.R", encoding = "UTF-8")
source("R/mod_clima_anual.R", encoding = "UTF-8")
source("R/mod_evolucion_tendencias.R", encoding = "UTF-8")
source("R/mod_balance_aridez.R", encoding = "UTF-8")
source("R/mod_priorizacion_territorial.R", encoding = "UTF-8")
source("R/mod_consulta_ubicacion.R", encoding = "UTF-8")
source("R/mod_metodologia_datos.R", encoding = "UTF-8")
message(" Módulos R cargados sin errores de sintaxis.")

# 3. Comprobar carga de datos
app_data <- load_app_data()
stopifnot(!is.null(app_data$resumen))
stopifnot(!is.null(app_data$series_anuales))
stopifnot(!is.null(app_data$distritos_wgs84))
stopifnot(!is.null(app_data$r_disp_wgs84))
stopifnot(!is.null(app_data$p_30m_ref))
message(" Caché maestro de datos cargado correctamente:")
message("   - Distritos en resumen: ", nrow(app_data$resumen))
message("   - Filas en series anuales: ", nrow(app_data$series_anuales))
message("   - Bandas en P_anual_30m: ", terra::nlyr(app_data$p_30m_ref))
message("   - Bandas en T_anual_30m: ", terra::nlyr(app_data$t_30m_ref))
message("   - Bandas en Estres_30m: ", terra::nlyr(app_data$estres_30m_ref))

# Las cifras distritales y provinciales deben derivarse de las mismas series
# finales corregidas con PISCO que se muestran en los gráficos.
for (territorio in unique(app_data$series_anuales$NOMBDIST)) {
  serie <- app_data$series_anuales |>
    dplyr::filter(NOMBDIST == territorio) |>
    dplyr::arrange(Year)
  resumen <- app_data$resumen |>
    dplyr::filter(NOMBDIST == territorio)
  stopifnot(nrow(serie) == 25L, nrow(resumen) == 1L)
  pendiente_p <- unname(coef(lm(Precipitacion_mm ~ Year, data = serie))["Year"]) * 10
  pendiente_t <- unname(coef(lm(Temperatura_C ~ Year, data = serie))["Year"]) * 10
  stopifnot(
    abs(pendiente_p - resumen$P_trend_decada) < 0.01,
    abs(pendiente_t - resumen$T_trend_decada) < 0.001
  )
}
stopifnot(all(terra::datatype(app_data$r_disp_wgs84) == "FLT4S"))
message(" Tendencias de los 10 territorios coherentes con las series finales PISCO.")

# El resumen instrumental que ve el público debe existir y corresponder a los
# rásteres y CSV de estación actuales. No se usa para recalibrar el modelo.
archivo_validacion <- "app_data/validacion_red_estaciones.csv"
insumos_validacion <- c(
  "Clima_Anta/P_anual_30m_PISCOv3_Anta_2001_2025.tif",
  "Clima_Anta/T_anual_30m_PISCOt_Anta_2001_2025.tif",
  list.files("estaciones", pattern = "\\.csv$", full.names = TRUE)
)
stopifnot(file.exists(archivo_validacion), length(insumos_validacion) >= 6L,
          file.info(archivo_validacion)$mtime >= max(file.info(insumos_validacion)$mtime))
validacion <- read.csv(archivo_validacion, stringsAsFactors = FALSE)
stopifnot(all(c("ANCACHURO", "SORAYPAMPA", "CURAHUASI", "URUBAMBA") %in% validacion$estacion))
interior_t <- subset(validacion, variable == "T" & producto == "modelo" &
                      estacion %in% c("ANCACHURO", "SORAYPAMPA"))
stopifnot(nrow(interior_t) == 2L, all(interior_t$n >= 1L),
          all(is.finite(interior_t$MAE)))
message(" Contraste de estaciones vigente: sesgo térmico Ancachuro ",
        round(interior_t$sesgo[interior_t$estacion == "ANCACHURO"], 2),
        " °C; Soraypampa ",
        round(interior_t$sesgo[interior_t$estacion == "SORAYPAMPA"], 2), " °C.")

# Los archivos que se ofrecen desde Netlify deben corresponder a las tablas
# internas vigentes y no conservar encabezados que sugieran probabilidades.
pares_publicos <- c(
  "series_anuales_2001_2025_anta.csv",
  "resumen_hidroclimatico_distrital_anta.csv",
  "validacion_red_estaciones.csv",
  "distritos_anta.geojson"
)
for (nombre in pares_publicos) {
  origen <- file.path("app_data", nombre)
  publico <- file.path("public_data", nombre)
  stopifnot(file.exists(origen), file.exists(publico),
            file.info(publico)$mtime >= file.info(origen)$mtime)
}
resumen_publico <- read.csv("public_data/resumen_hidroclimatico_distrital_anta.csv")
stopifnot(nrow(resumen_publico) == 10L,
          all(c("Indice_susceptibilidad_WSI_0_100", "Diferencia_climatica_P_menos_ETo_mm",
                "ETo_climatologica_ajustada_mm") %in% names(resumen_publico)),
          !any(c("Prob_Estres_Hidrico_pct", "Balance_Hidrico_P_PET_mm",
                 "ETo_PenmanMonteith_mm") %in% names(resumen_publico)))
message(" Copias públicas vigentes y con encabezados corregidos.")

# 4. Probar instanciación de UIs de los módulos
ui_portada      <- mod_portada_situacion_ui("test_portada")
ui_clima        <- mod_clima_anual_ui("test_clima")
ui_evolucion    <- mod_evolucion_tendencias_ui("test_evolucion")
ui_balance      <- mod_balance_aridez_ui("test_balance")
ui_priorizacion <- mod_priorizacion_territorial_ui("test_priorizacion")
ui_consulta     <- mod_consulta_ubicacion_ui("test_consulta")
ui_metodologia  <- mod_metodologia_datos_ui("test_metodologia")
message(" Todas las UIs de los 7 módulos se generaron correctamente.")

# 5. Probar generación de mensaje interpretativo
msg_test <- generar_mensaje_interpretativo("CACHIMAYO", 2024, -18.5, 0.45, 77.1, "Muy Alto", 99.9)
stopifnot(grepl("CACHIMAYO", msg_test$titulo))
stopifnot(grepl("año", msg_test$mensaje))
message(" Generador de mensajes interpretativos validado.")

# 6. Probar extracción puntual a 30m en coordenadas de prueba (Plaza de Anta)
pt_test <- terra::vect(matrix(c(794200, 8511500), ncol = 2), crs = "EPSG:32718")
p_val_test <- as.numeric(terra::extract(app_data$p_30m_ref[["P_2024"]], pt_test)[1, 2])
wsi_val_test <- as.numeric(terra::extract(app_data$estres_30m_ref[["Prob_Estres_Hidrico_pct"]], pt_test)[1, 2])
serie_p_pixel <- as.numeric(terra::extract(app_data$p_30m_ref, pt_test)[1, -1])
serie_t_pixel <- as.numeric(terra::extract(app_data$t_30m_ref, pt_test)[1, -1])
pendiente_p_pixel <- as.numeric(terra::extract(app_data$var_30m_ref[["P_trend_decada"]], pt_test)[1, 2])
pendiente_t_pixel <- as.numeric(terra::extract(app_data$var_30m_ref[["T_trend_decada"]], pt_test)[1, 2])
stopifnot(
  abs(unname(coef(lm(serie_p_pixel ~ I(2001:2025)))[2]) * 10 - pendiente_p_pixel) < 0.01,
  abs(unname(coef(lm(serie_t_pixel ~ I(2001:2025)))[2]) * 10 - pendiente_t_pixel) < 0.001
)
message(" Extracción puntual nativa de 30 m:")
message("   - Precipitación 2024 en punto de prueba: ", round(p_val_test, 1), " mm")
message("   - Índice WSI en punto de prueba: ", round(wsi_val_test, 1), " / 100")

message("\n[OK] Carga, consistencia y vigencia del contraste instrumental superadas; la precisión provincial sigue sin certificarse.")
