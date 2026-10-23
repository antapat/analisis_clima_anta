# Contraste de la red de estaciones cercana a Anta

**Fecha:** 21 de octubre de 2026. **Alcance:** comparación de archivos de `estaciones/` con los rásteres finales de 30 m dentro de Anta y con PISCO en los cuatro puntos. El script reproducible `scripts/validar_red_estaciones.R` genera `auditoria_estaciones/comparacion_anual.csv`, `auditoria_estaciones/metricas.csv`, `auditoria_estaciones/metadata_estaciones.csv` y el resumen para la aplicación `app_data/validacion_red_estaciones.csv`. Los CSV originales no se modificaron.

## Ubicación y utilidad de cada estación

| Estación | Código informado | Altitud | Relación con el ráster de Anta | Serie disponible |
|---|---|---:|---|---|
| Anta Ancachuro | 000684 | 3324 m | Dentro de Zurite | Diaria 2017–2024; horaria 2025–2026. |
| Soraypampa | 47294362 | 3854 m | Dentro de Mollepata | Horaria 2011–2026, con interrupciones. |
| Curahuasi | 113253 | 2741 m | Fuera del dominio, en Apurímac | Horaria junio 2023–mayo 2025, muy incompleta. |
| Urubamba | 000683 | 2850 m | Fuera del dominio de Anta | Diaria 2017–2026, con faltantes. |

Las coordenadas se transcribieron de las fichas proporcionadas y se transformaron de grados, minutos y segundos a grados decimales. La pertenencia territorial se comprobó contra los polígonos usados por la aplicación. Curahuasi y Urubamba **no pueden validar el ráster de 30 m de Anta**, que no tiene valores en sus puntos; sí permiten examinar PISCO regionalmente.

## Reglas de calidad y comparabilidad

- Para las métricas principales se exige **al menos 99 % de cobertura válida por variable y año**. Los datos `S/D` y horas o días ausentes permanecen ausentes, nunca se convierten en cero.
- La temperatura diaria de estaciones convencionales es `(Tmax + Tmin)/2`. En estaciones horarias se calcula primero esa misma media a partir del mínimo y máximo de cada día con al menos 20 horas válidas; luego se promedian los días. Esto acerca las definiciones, pero sigue sujeto a las diferencias de instrumental y horario.
- La serie de Ancachuro cambia de diaria a horaria en 2025; ese año no se mezcla con 2018–2024 en la métrica principal. Los totales anuales de precipitación con horas ausentes son límites inferiores de lo registrado, sujetos además a calidad instrumental.
- La precipitación de Soraypampa está sin dato desde 2021. En Curahuasi ningún año llega al umbral de 99 %; por ejemplo, en 2024 solo se dispone de aproximadamente 36 % de horas válidas para lluvia y temperatura. No se reportan totales anuales de esos segmentos como si fueran completos.
- PISCO se construye con observaciones de redes meteorológicas. Dado que estas estaciones pertenecen a la red disponible en una región de baja densidad de observaciones, **se tratan como potencialmente utilizadas por PISCO** hasta cotejar los códigos y periodos con el inventario de entrada de cada versión. La comparación sirve para detectar sesgos puntuales del producto final de 30 m, pero **no se denomina validación independiente de PISCO ni del modelo completo**. La inclusión puede variar por estación, variable y año.

## Resultados del modelo final dentro de Anta

Sesgo = modelo menos estación. MAE = error absoluto medio. Las correlaciones sobre pocos años no prueban habilidad espacial general.

| Estación y variable | Años válidos | n | Sesgo | MAE | Resultado principal |
|---|---|---:|---:|---:|---|
| Ancachuro, lluvia anual | 2018, 2019, 2020, 2021, 2023, 2024 | 6 | +21,9 mm | 42,4 mm | Correlación anual 0,205: débil seguimiento de la variación entre años. |
| Ancachuro, temperatura | mismos | 6 | **+1,81 °C** | 1,81 °C | Desplazamiento positivo persistente. |
| Soraypampa, temperatura | 2014, 2019, 2020, 2022, 2024 | 5 | **+4,92 °C** | 4,92 °C | Error térmico elevado en este punto alto. |
| Soraypampa, lluvia anual | 2019 | 1 | **−539,2 mm** | 539,2 mm | La estación sumó 1458,0 mm en las horas válidas; el modelo 918,8 mm. No se infiere un error medio plurianual a partir de un año. |

En Soraypampa, el campo GEE previo al ajuste tenía un sesgo térmico medio de **+0,88 °C** en los cinco años válidos; PISCOt original tenía **+3,95 °C** en los tres años disponibles. El producto final de **+4,92 °C** quedó más lejos de la estación. Para lluvia de 2019, GEE previo estimó 1166,5 mm y PISCOp 978,3 mm, frente a 918,8 mm del producto final. En este punto y año, la corrección con PISCO **empeoró el acuerdo instrumental**. Esto no autoriza a descartar PISCO en todo el territorio, pero sí impide declarar que el ajuste mejora universalmente el resultado.

### Contraste entre altitudes

Ancachuro y Soraypampa están separadas por **530 m de altitud informada**. En los años 2019, 2020 y 2024, comparables en ambas, Soraypampa fue en promedio **2,92 °C más fría** que Ancachuro. El producto final la representó en promedio **0,13 °C más cálida**. Es evidencia de un patrón térmico espacial deficiente en este transecto. No debe interpretarse el cociente entre diferencia térmica y altitud como una tasa vertical universal: las estaciones también difieren en exposición, valle, cobertura y posible instrumental.

### Escenario de ajuste térmico, aún no aplicado

`scripts/evaluar_ajuste_termico_altitud.R` ajustó, solo como sensibilidad, una recta de sesgo frente a altitud con **2019 y 2020** de Ancachuro y Soraypampa: sesgo estimado = `1,894 + 5,818 × (altitud_m − 3324) / 1000` °C. Al evaluarla en **2024 en esas mismas estaciones**, los errores residuales fueron +0,003 °C y −0,107 °C, respectivamente (`auditoria_estaciones/ajuste_termico_exploratorio.csv`). Esta es una prueba temporal, **no una validación espacial independiente**: la recta fue definida por las mismas dos ubicaciones y no se dispone de un DEM local verificado y exportado para aplicarla a todas las celdas. No se cambió ningún GeoTIFF de producción.

## Estaciones vecinas

- **Curahuasi:** fuera del mapa de Anta y sin años con 99 % de cobertura; no permite una métrica anual robusta con estos archivos.
- **Urubamba:** fuera del mapa de Anta. Frente a PISCOp, los años diarios válidos 2018, 2019 y 2021 dieron MAE de **41,2 mm/año**. La comparación con PISCOt solo tiene dos años válidos (2018 y 2019), con sesgo **−0,81 °C**. Son controles regionales limitados, no validación del ráster fino de Anta.

## Consecuencia para ajustes y publicación

1. **No aplicar una corrección provincial uniforme** calculada con Ancachuro o Soraypampa. Sus sesgos térmicos difieren en más de 3 °C y un ajuste uniforme dejaría al menos uno de los puntos mal representado.
2. Revisar la construcción del campo térmico fino y la transferencia del sesgo PISCO: DEM y altura en cada estación, gradiente vertical regional, malla PISCO, residual local GEE y método de proyección. Repetir el contraste por estación y año después de cada candidato de corrección, manteniendo periodos de evaluación no usados para ajustar. El código GEE quedó preparado para exportar `DEM_SRTM_30m_Anta`; **esa tarea no se ha ejecutado** y el DEM aún no existe en los archivos locales.
3. Investigar el contraste de lluvia alta de Soraypampa con metadatos de precipitación, nieve, mantenimiento, calibración y horarios. Un solo año con cobertura alta no sustenta una superficie de corrección de precipitación en toda Anta.
4. Mantener la advertencia pública de que los productos son estimaciones en revisión. La ETo y el WSI derivados también pueden heredar el sesgo térmico y de lluvia, y no cuentan con validación directa de campo.
5. No se dispone de otras estaciones dentro de Anta. Antes de atribuir independencia a cualquier contraste instrumental, cotejar la lista de estaciones de PISCOt v1.2 y solicitar a SENAMHI el inventario y los periodos efectivamente usados en PISCOp v3.0. Si hubo reutilización, describir estos resultados como comprobación de coherencia local. Una reserva temporal en las mismas estaciones no elimina esa dependencia; una evaluación verdaderamente externa requeriría registros no incorporados o reconstruir el producto sin las estaciones evaluadas.

**Referencias de alcance:** [SENAMHI, PISCOp v3.0 y redes de estaciones](https://www.gob.pe/institucion/senamhi/noticias/1398654-piscop-v3-0-la-nueva-referencia-de-datos-de-precipitacion-para-la-gestion-hidrica-y-el-monitoreo-climatico-en-el-peru); [inventario publicado de estaciones de PISCOt v1.2](https://figshare.com/articles/dataset/Weather_stations_used_in_PISCOt_v1_2/14329208).
