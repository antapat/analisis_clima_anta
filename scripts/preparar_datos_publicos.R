# Copias agregadas destinadas a GitHub y al portal Netlify.
# Ejecutar desde la raíz del proyecto, después de actualizar app_data/.

dir.create("public_data", showWarnings = FALSE)

archivos <- c(
  series = "app_data/series_anuales_2001_2025_anta.csv",
  resumen = "app_data/resumen_hidroclimatico_distrital_anta.csv",
  validacion = "app_data/validacion_red_estaciones.csv",
  distritos = "app_data/distritos_anta.geojson"
)
stopifnot(all(file.exists(archivos)))

series <- read.csv(archivos[["series"]], check.names = FALSE)
stopifnot(nrow(series) == 250L, length(unique(series$NOMBDIST)) == 10L,
          identical(sort(unique(series$Year)), 2001:2025))
write.csv(series, "public_data/series_anuales_2001_2025_anta.csv", row.names = FALSE, na = "")

resumen <- read.csv(archivos[["resumen"]], check.names = FALSE)
renombrar <- c(
  ETo_PenmanMonteith_mm = "ETo_climatologica_ajustada_mm",
  Balance_Hidrico_P_PET_mm = "Diferencia_climatica_P_menos_ETo_mm",
  Prob_Estres_Hidrico_pct = "Indice_susceptibilidad_WSI_0_100"
)
stopifnot(nrow(resumen) == 10L, all(names(renombrar) %in% names(resumen)))
names(resumen)[match(names(renombrar), names(resumen))] <- unname(renombrar)
write.csv(resumen, "public_data/resumen_hidroclimatico_distrital_anta.csv", row.names = FALSE, na = "")

validacion <- read.csv(archivos[["validacion"]], check.names = FALSE)
stopifnot(all(c("ANCACHURO", "SORAYPAMPA", "CURAHUASI", "URUBAMBA") %in% validacion$estacion))
write.csv(validacion, "public_data/validacion_red_estaciones.csv", row.names = FALSE, na = "")

file.copy(archivos[["distritos"]], "public_data/distritos_anta.geojson", overwrite = TRUE)
message("Copias públicas agregadas actualizadas en public_data/.")
