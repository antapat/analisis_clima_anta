# Reconstruye en Connect Cloud los GeoTIFF grandes a partir de sus partes Git.
# En un equipo con los rásteres originales, no escribe ningún archivo.
ensure_github_rasters <- function() {
  indice_path <- "Clima_Anta/github_parts/manifest.csv"
  if (!file.exists(indice_path)) {
    stop("Falta el índice de rásteres de GitHub: ", indice_path)
  }
  indice <- read.csv(indice_path, stringsAsFactors = FALSE,
                     fileEncoding = "UTF-8")
  for (i in seq_len(nrow(indice))) {
    destino <- indice$target[i]
    if (file.exists(destino)) next
    partes <- file.path(dirname(indice_path),
                        strsplit(indice$parts[i], ";", fixed = TRUE)[[1]])
    faltantes <- partes[!file.exists(partes)]
    if (length(faltantes)) {
      stop("Faltan partes del ráster ", destino, ": ", paste(faltantes, collapse = ", "))
    }

    temporal <- paste0(destino, ".restoring-", Sys.getpid())
    salida <- file(temporal, "wb")
    for (parte in partes) {
      entrada <- file(parte, "rb")
      repeat {
        bloque <- readBin(entrada, "raw", n = 1024^2)
        if (!length(bloque)) break
        writeBin(bloque, salida)
      }
      close(entrada)
    }
    close(salida)

    correcto <- identical(as.numeric(file.info(temporal)$size),
                          as.numeric(indice$size_bytes[i])) &&
      identical(unname(tools::md5sum(temporal)), indice$md5[i])
    if (!correcto) {
      unlink(temporal)
      stop("La reconstrucción no coincide con el original: ", destino)
    }
    if (!suppressWarnings(file.rename(temporal, destino))) {
      if (!file.exists(destino) && !file.copy(temporal, destino)) {
        unlink(temporal)
        stop("No se pudo crear ", destino)
      }
      unlink(temporal)
    }
    message("Ráster reconstruido: ", destino)
  }
  invisible(TRUE)
}
