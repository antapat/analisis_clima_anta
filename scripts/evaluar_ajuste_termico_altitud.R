# Escenario de sensibilidad: corrección lineal del sesgo térmico con altitud.
# Entrena en 2019-2020 y evalúa en 2024. No modifica rásteres de producción.
a <- read.csv("auditoria_estaciones/comparacion_anual.csv", stringsAsFactors = FALSE)
z <- c(ANCACHURO = 3324, SORAYPAMPA = 3854)
a <- a[a$estacion %in% names(z) & a$anio %in% c(2019, 2020, 2024), ]
stopifnot(nrow(a) == 6L, all(a$T_cobertura >= 0.99),
          all(is.finite(a$T_observada_C)), all(is.finite(a$T_modelo_C)))
a$sesgo_original_C <- a$T_modelo_C - a$T_observada_C
train <- a[a$anio %in% c(2019, 2020), ]
mean_bias <- tapply(train$sesgo_original_C, train$estacion, mean)
intercepto <- unname(mean_bias["ANCACHURO"])
pendiente_C_km <- unname((mean_bias["SORAYPAMPA"] - mean_bias["ANCACHURO"]) /
                            ((z["SORAYPAMPA"] - z["ANCACHURO"]) / 1000))
a$sesgo_estimado_C <- intercepto + pendiente_C_km * (z[a$estacion] - 3324) / 1000
a$T_candidato_C <- a$T_modelo_C - a$sesgo_estimado_C
a$error_candidato_C <- a$T_candidato_C - a$T_observada_C
a$particion <- ifelse(a$anio == 2024, "evaluacion_temporal", "calibracion")
write.csv(a[, c("estacion", "anio", "particion", "T_cobertura", "T_observada_C",
                "T_modelo_C", "sesgo_original_C", "sesgo_estimado_C",
                "T_candidato_C", "error_candidato_C")],
          "auditoria_estaciones/ajuste_termico_exploratorio.csv", row.names = FALSE)
cat(sprintf("Intercepto a 3324 m: %.3f °C; gradiente adicional: %.3f °C/km\n",
            intercepto, pendiente_C_km))
cat("Errores en 2024 (evaluación temporal en las mismas estaciones):\n")
print(a[a$anio == 2024, c("estacion", "sesgo_original_C", "error_candidato_C")])
