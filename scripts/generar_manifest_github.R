# Genera el manifest.json de la aplicación completa publicada desde GitHub.
# Ejecutar desde la raíz después de preparar los rásteres por partes.

version_r <- paste(R.version$major, strsplit(R.version$minor, "\\.")[[1]][1], sep = ".")
bibliotecas <- c(
  file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", version_r),
  file.path(Sys.getenv("USERPROFILE"), "AppData", "Local", "R", "win-library", version_r)
)
for (ruta in unique(bibliotecas)) {
  if (dir.exists(ruta)) .libPaths(c(ruta, .libPaths()))
}

datos <- c(
  "P_anual_150m.tif", "P_anual_wgs84.tif",
  "T_anual_150m.tif", "T_anual_wgs84.tif",
  "rasters_display_150m.tif", "rasters_display_wgs84.tif",
  "distritos_anta.geojson", "distritos_info.rds",
  "distritos_sf.rds", "distritos_wgs84.rds",
  "provincia_sf.rds", "provincia_wgs84.rds",
  "resumen_distrital.rds", "resumen_hidroclimatico_distrital_anta.csv",
  "series_anuales.rds", "series_anuales_2001_2025_anta.csv",
  "validacion_red_estaciones.csv"
)
rasters_pequenos <- c(
  "Estres_Hidrico_Anta_2001_2025.tif",
  "Estres_y_Balance_Hidrico_30m_PISCO_Anta.tif",
  "Variabilidad_y_Tendencias_PISCO_Anta_2001_2025.tif"
)
partes <- list.files("Clima_Anta/github_parts", full.names = TRUE)
archivos <- c(
  "app.R", "DESCRIPTION",
  list.files("R", pattern = "\\.R$", full.names = TRUE),
  "www/custom.css", "www/logo_anta.jpg",
  file.path("app_data", datos),
  file.path("Clima_Anta", rasters_pequenos),
  partes
)
faltantes <- archivos[!file.exists(archivos)]
if (length(faltantes)) stop("Faltan archivos: ", paste(faltantes, collapse = ", "))
grandes <- archivos[file.info(archivos)$size > 100000000]
if (length(grandes)) stop("Archivos mayores de 100 MB: ", paste(grandes, collapse = ", "))

rsconnect::writeManifest(appFiles = archivos, appMode = "shiny")
manifest <- jsonlite::fromJSON("manifest.json", simplifyVector = FALSE)
manifest$platform <- "4.6.0"
for (nombre in names(manifest$packages)) {
  pkg_desc <- manifest$packages[[nombre]]$description
  if (is.null(pkg_desc$Version) || length(pkg_desc) <= 2) {
    ruta_pkg <- tryCatch(find.package(nombre), error = function(e) NULL)
    if (!is.null(ruta_pkg)) {
      archivo_desc <- file.path(ruta_pkg, "DESCRIPTION")
      if (file.exists(archivo_desc)) {
        dcf <- read.dcf(archivo_desc)
        manifest$packages[[nombre]]$description <- as.list(setNames(as.character(dcf[1, ]), colnames(dcf)))
      }
    }
  }
}
json <- jsonlite::toJSON(manifest, pretty = TRUE, auto_unbox = TRUE,
                         null = "null", digits = NA)
writeLines(json, "manifest.json", useBytes = TRUE)
cat(length(archivos), "archivos y", length(manifest$packages),
    "paquetes declarados; R", manifest$platform, "\n")
