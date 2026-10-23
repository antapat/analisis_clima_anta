# Divide los dos GeoTIFF mayores de 100 MB en partes aptas para GitHub.
# Ejecutar desde la raíz después de actualizar los productos finales.

version_r <- paste(R.version$major, strsplit(R.version$minor, "\\.")[[1]][1], sep = ".")
bibliotecas <- c(
  file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", version_r),
  file.path(Sys.getenv("USERPROFILE"), "AppData", "Local", "R", "win-library", version_r)
)
for (ruta in unique(bibliotecas)) {
  if (dir.exists(ruta)) .libPaths(c(ruta, .libPaths()))
}

archivos <- c(
  "Clima_Anta/P_anual_30m_PISCOv3_Anta_2001_2025.tif",
  "Clima_Anta/T_anual_30m_PISCOt_Anta_2001_2025.tif"
)
directorio <- "Clima_Anta/github_parts"
tamano_parte <- 80 * 1024^2
tamano_bloque <- 1024^2
dir.create(directorio, recursive = TRUE, showWarnings = FALSE)

dividir <- function(origen) {
  if (!file.exists(origen)) stop("Falta el ráster: ", origen)
  comprimido <- sub("\\.tif$", "_zstd.tif", origen)
  original_r <- terra::rast(origen)
  terra::writeRaster(original_r, comprimido, overwrite = TRUE,
                     gdal = c("COMPRESS=ZSTD", "PREDICTOR=3",
                              "ZSTD_LEVEL=9", "TILED=YES"))
  comprimido_r <- terra::rast(comprimido)
  if (!terra::compareGeom(original_r, comprimido_r, stopOnError = FALSE) ||
      max(terra::global(abs(original_r - comprimido_r), "max", na.rm = TRUE)[[1]],
          na.rm = TRUE) != 0) {
    stop("La compresión cambió valores o geometría: ", origen)
  }
  tamano <- file.info(comprimido)$size
  cantidad <- ceiling(tamano / tamano_parte)
  entrada <- file(comprimido, "rb")
  on.exit(close(entrada), add = TRUE)
  partes <- character(cantidad)

  for (i in seq_len(cantidad)) {
    nombre <- sprintf("%s.part%02d", basename(origen), i)
    destino <- file.path(directorio, nombre)
    salida <- file(destino, "wb")
    restante <- min(tamano_parte, tamano - (i - 1) * tamano_parte)
    while (restante > 0) {
      bloque <- readBin(entrada, "raw", n = min(tamano_bloque, restante))
      if (!length(bloque)) stop("Lectura incompleta de ", origen)
      writeBin(bloque, salida)
      restante <- restante - length(bloque)
    }
    close(salida)
    partes[i] <- nombre
    if (file.info(destino)$size > 100000000) stop("Parte mayor de 100 MB: ", destino)
  }

  obsoletas <- list.files(directorio, full.names = TRUE)
  obsoletas <- obsoletas[
    startsWith(basename(obsoletas), paste0(basename(origen), ".part")) &
      grepl("\\.part[0-9]{2}$", obsoletas)
  ]
  unlink(setdiff(obsoletas, file.path(directorio, partes)))

  data.frame(
    target = origen,
    size_bytes = tamano,
    md5 = unname(tools::md5sum(comprimido)),
    parts = paste(partes, collapse = ";"),
    stringsAsFactors = FALSE
  )
}

indice <- do.call(rbind, lapply(archivos, dividir))
write.csv(indice, file.path(directorio, "manifest.csv"), row.names = FALSE,
          fileEncoding = "UTF-8")
print(indice[, c("target", "size_bytes", "md5")], row.names = FALSE)
