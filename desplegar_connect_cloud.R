# Publica la beta referencial en Posit Connect Cloud desde los archivos locales.
# La lista es explícita para excluir estaciones originales y productos de trabajo.

if (dir.exists(".r-library")) {
  .libPaths(c(file.path(getwd(), ".r-library"), .libPaths()))
}
version_r <- paste(R.version$major, strsplit(R.version$minor, "\\.")[[1]][1], sep = ".")
bibliotecas_usuario <- c(
  file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", version_r),
  file.path(Sys.getenv("USERPROFILE"), "AppData", "Local", "R", "win-library", version_r)
)
for (biblioteca_usuario in unique(bibliotecas_usuario)) {
  if (dir.exists(biblioteca_usuario)) .libPaths(c(biblioteca_usuario, .libPaths()))
}

if (!requireNamespace("rsconnect", quietly = TRUE)) {
  stop("Instale el paquete rsconnect en la biblioteca de R usada por este proyecto.")
}

archivos_clima <- c(
  "Clima_Anta/P_anual_30m_PISCOv3_Anta_2001_2025.tif",
  "Clima_Anta/T_anual_30m_PISCOt_Anta_2001_2025.tif",
  "Clima_Anta/Estres_y_Balance_Hidrico_30m_PISCO_Anta.tif",
  "Clima_Anta/Variabilidad_y_Tendencias_PISCO_Anta_2001_2025.tif",
  "Clima_Anta/Estres_Hidrico_Anta_2001_2025.tif"
)
archivo_validacion <- "app_data/validacion_red_estaciones.csv"
insumos_validacion <- c(
  archivos_clima[1:2],
  list.files("estaciones", pattern = "\\.csv$", full.names = TRUE)
)
if (!file.exists(archivo_validacion) || length(insumos_validacion) < 6L ||
    !all(file.exists(insumos_validacion)) ||
    file.info(archivo_validacion)$mtime < max(file.info(insumos_validacion)$mtime)) {
  stop("El contraste de estaciones falta o está desactualizado. Ejecute scripts/validar_red_estaciones.R.")
}

archivos <- c(
  "app.R", "DESCRIPTION",
  list.files("R", pattern = "\\.R$", full.names = TRUE),
  "www/custom.css", "www/logo_anta.jpg",
  setdiff(
    list.files("app_data", pattern = "\\.(rds|geojson|tif|csv)$", full.names = TRUE),
    "app_data/validacion_ancachuro.csv"
  ),
  archivos_clima
)
archivos <- unique(gsub("^\\./", "", archivos))
faltantes <- archivos[!file.exists(archivos)]
if (length(faltantes)) {
  stop("Faltan archivos para el despliegue: ", paste(faltantes, collapse = ", "))
}

tamanio_mib <- sum(file.info(archivos)$size) / 1024^2
cat(sprintf("Archivos: %d; tamaño sin comprimir: %.2f MiB\n", length(archivos), tamanio_mib))
if (tamanio_mib >= 1024) {
  stop("El paquete supera 1 GiB antes de comprimir; revise los datos incluidos.")
}
if (identical(Sys.getenv("CONNECT_CLOUD_DRY_RUN"), "1")) {
  cat(paste(archivos, collapse = "\n"), "\n")
  quit(save = "no", status = 0)
}

cuentas <- rsconnect::accounts()
cuentas_cloud <- cuentas[grepl("(^|\\.)connect\\.posit\\.cloud$", cuentas$server), , drop = FALSE]
if (nrow(cuentas_cloud) != 1L) {
  stop("Se requiere exactamente una cuenta de Posit Connect Cloud. Conéctela con rsconnect::connectCloudUser().")
}

rsconnect::deployApp(
  appDir = getwd(),
  appFiles = archivos,
  appName = "clima_anta_30m",
  appTitle = "Clima de Anta — beta referencial",
  account = cuentas_cloud$name[[1]],
  server = cuentas_cloud$server[[1]],
  appVisibility = "public",
  forceUpdate = TRUE,
  launch.browser = FALSE,
  lint = FALSE
)
