# Datos agregados de la beta referencial

Estas copias se generaron con `scripts/preparar_datos_publicos.R` desde los resultados finales de la aplicación. No contienen registros diarios u horarios originales de estaciones ni productos de entrenamiento.

- `series_anuales_2001_2025_anta.csv`: diez ámbitos (nueve distritos y provincia), 25 años por ámbito. Los valores son estimaciones modeladas.
- `resumen_hidroclimatico_distrital_anta.csv`: indicadores agregados por ámbito. `Indice_susceptibilidad_WSI_0_100` es un índice relativo, no una probabilidad; `Diferencia_climatica_P_menos_ETo_mm` no mide agua disponible; `ETo_climatologica_ajustada_mm` no es un cálculo anual completo de Penman–Monteith.
- `validacion_red_estaciones.csv`: métricas agregadas de comparación con cuatro estaciones. Las estaciones pudieron alimentar PISCO; estas métricas detectan discrepancias locales, no constituyen validación independiente.
- `distritos_anta.geojson`: límites usados por la aplicación.

El tamaño de celda de 30 m del modelo no equivale a precisión instrumental. Los valores no deben usarse solos para diseñar obras, evaluar parcelas o estimar disponibilidad de agua. Consulte los informes de auditoría del repositorio antes de reutilizarlos.
