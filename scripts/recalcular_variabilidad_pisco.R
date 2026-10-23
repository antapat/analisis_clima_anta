# Recalcula la variabilidad y las tendencias desde las series finales corregidas
# con PISCOp v3.0 y PISCOt. El producto original de GEE no debe usarse en la app.
version_r <- paste(R.version$major, strsplit(R.version$minor, "\\.")[[1]][1], sep = ".")
bibliotecas_usuario <- c(
  file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", version_r),
  file.path(Sys.getenv("USERPROFILE"), "AppData", "Local", "R", "win-library", version_r)
)
for (biblioteca_usuario in unique(bibliotecas_usuario)) {
  if (dir.exists(biblioteca_usuario)) .libPaths(c(biblioteca_usuario, .libPaths()))
}
suppressPackageStartupMessages(library(terra))

anios <- 2001:2025
p <- rast("Clima_Anta/P_anual_30m_PISCOv3_Anta_2001_2025.tif")
t <- rast("Clima_Anta/T_anual_30m_PISCOt_Anta_2001_2025.tif")
stopifnot(
  identical(names(p), paste0("P_", anios)),
  identical(names(t), paste0("T_", anios)),
  compareGeom(p, t, stopOnError = FALSE),
  all(res(p) == c(30, 30))
)

# Pendiente de mínimos cuadrados por año, multiplicada por diez. Centrar los
# años evita operaciones con valores grandes y coincide con lm(valor ~ Year).
anios_centrados <- anios - mean(anios)
factor_decada <- 10 / sum(anios_centrados^2)

t_std <- stdev(t, pop = FALSE)
p_std <- stdev(p, pop = FALSE)
p_cv <- 100 * p_std / mean(p)
t_trend <- sum(t * anios_centrados) * factor_decada
p_trend <- sum(p * anios_centrados) * factor_decada

resultado <- c(t_std, p_std, p_cv, t_trend, p_trend)
names(resultado) <- c(
  "T_std_interanual", "P_std_interanual", "P_CV_pct",
  "T_trend_decada", "P_trend_decada"
)

salida <- "Clima_Anta/Variabilidad_y_Tendencias_PISCO_Anta_2001_2025.tif"
writeRaster(resultado, salida, overwrite = TRUE,
            datatype = "FLT4S", gdal = c("COMPRESS=DEFLATE", "PREDICTOR=3"))
cat("Producto de variabilidad y tendencias PISCO corregidas:", salida, "\n")
