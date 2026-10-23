# Segunda auditoría de validez técnica — aplicación hidroclimática de Anta

**Clasificación de uso:** beta referencial para explorar patrones y diferencias climáticas generales del territorio. Los valores proceden de modelos matemáticos ajustados con PISCO y no equivalen a mediciones en cada píxel. Solo hay dos estaciones disponibles dentro de Anta para el contraste local y pudieron alimentar PISCO; este contraste no constituye validación independiente. La prueba beta debe comunicar los sesgos observados y exigir observaciones y estudios locales para decisiones sobre parcelas, obras o disponibilidad de agua. Esta clasificación no resuelve los hallazgos técnicos pendientes.

**Actualización por nuevas estaciones:** El contraste ampliado de `VALIDACION_RED_ESTACIONES_2026-10-21.md` reemplaza la interpretación basada solo en Ancachuro. Soraypampa, dentro de Mollepata, muestra un sesgo térmico medio de +4,92 °C en cinco años válidos y una subestimación de 539,2 mm de lluvia en el único año con cobertura ≥99 %. Estos hallazgos impiden certificar la precisión espacial provincial y requieren revisar el modelo antes de una difusión como dato apto para diseño local.

**Fecha:** 21 de octubre de 2026  
**Alcance:** código y productos locales que carga la aplicación. Las comprobaciones numéricas se hicieron sobre los archivos finales, no sobre una nueva ejecución de Google Earth Engine. Se añadió un contraste puntual con la estación Ancachuro; no basta para certificar exactitud provincial a 30 m y está pendiente confirmar su independencia respecto del entrenamiento de PISCO. Véase `VALIDACION_ANCACHURO_2026-10-21.md`.

## Dictamen

**La estructura de las series y las tendencias corregidas es coherente, pero la exactitud física local y el índice de estrés todavía no están validados de forma independiente.** La aplicación puede comunicar estimaciones climáticas exploratorias con sus límites; no debe presentar el WSI como probabilidad, la diferencia P − ETo como disponibilidad de agua, ni las tendencias de lluvia como evidencia concluyente de disminución provincial.

## Comprobaciones realizadas

| Control | Resultado | Interpretación |
|---|---:|---|
| Cobertura de series | 250 filas: 25 años × 10 ámbitos; sin duplicados ni ausentes | Estructura tabular consistente. |
| Tendencias | Las 10 pendientes territoriales coinciden con la regresión de las series corregidas con PISCO; `scripts/test_app.R` pasó | Se resolvió la discrepancia de tendencias de la revisión anterior. |
| Identidades derivadas | En muestra de 10 000 píxeles, error máximo de `P_media − ETo − balance`: 0,000092 mm; de `P_media/ETo − índice de aridez`: 0,000000096 | Diferencias de redondeo numérico. |
| Clases WSI | 0 discordancias entre valor y umbrales del modelo en 10 000 píxeles | Clasificación interna coherente; no demuestra validez externa de pesos y umbrales. |
| Rango físico de muestra | P media 391–1246 mm/año; T media 4,5–23,9 °C; ETo 681–1646 mm/año | Sin valores groseramente imposibles en la muestra; no prueba precisión local. |
| Geometría | 9 distritos y provincia válidos; diferencia simétrica entre unión distrital y provincia: 0,398 km² (0,0165 %) | Pequeña discrepancia limítrofe que conviene documentar. |
| Sintaxis y carga | Cinco módulos editados analizados por `parse()`; `scripts/test_app.R` terminó sin error | No se realizó prueba visual en navegador. |

## Hallazgos técnicos aún abiertos

### 1. Ajuste de precipitación respecto de PISCO

`correccion_clima_gee_pisco.R` interpola una razón de ajuste desde la malla PISCO y la multiplica por la predicción fina. Esto **no es un algoritmo estrictamente conservativo**. Reagregué el producto final a la malla del NetCDF PISCOp y comparé celdas con más de 90 % de cobertura del ráster de Anta (11 celdas en los tres años examinados). La diferencia media producto final menos PISCOp fue **−22,4 mm en 2001, −28,6 mm en 2013 y −17,9 mm en 2025**; algunas celdas se apartan bastante más. La comparación depende de bordes, proyección y método de agregación, pero basta para refutar una garantía de igualdad exacta. Antes de una afirmación de conservación debe definirse el soporte espacial, comprobar los 25 años y aplicar renormalización conservativa si corresponde.

### 2. Tendencias y evidencia estadística

La pendiente provincial ajustada es **−16,885 mm/década** en precipitación y **+0,398 °C/década** en temperatura (2001–2025). Con una regresión lineal ordinaria simple, la primera tiene `p = 0,436` e intervalo de confianza aproximado de 95 % **[−60,95; +27,18] mm/década**; la segunda `p = 0,0000047` e intervalo **[+0,259; +0,536] °C/década**. Estos intervalos no incluyen la incertidumbre de PISCO, del escalamiento espacial, ni la posible autocorrelación temporal. Por tanto, la serie no respalda afirmar un descenso provincial de lluvia estadísticamente demostrado. La temperatura de 2021–2025 se obtiene con ERA5-Land y el sesgo medio calibrado contra PISCOt 2001–2020; esos cinco años no son observaciones directas de PISCOt.

### 3. ETo, balance y WSI

El código calcula la ETo anual como climatología PISCOeo_pm 1981–2010 más `35 × (T_anual − T_referencia)` mm, con piso de 200 mm/año. **No ejecuta Penman–Monteith anual** con radiación, humedad y viento anuales. El coeficiente y el piso requieren justificación y validación. `P − ETo` es una diferencia climática, no un balance hidrológico ni una estimación de agua disponible. El WSI es una suma ponderada y normalizada (35 % aridez, 30 % NDMI, 20 % CV de lluvia, 15 % pendiente): su escala 0–100 **no es una probabilidad observada ni calibrada**. Deben evaluarse sensibilidad de pesos, umbrales y concordancia con indicadores independientes de estrés.

### 4. Resolución y temporalidad

Los rásteres fuente y la consulta puntual usan celdas de 30 m, pero el mapa de Leaflet usa capas agregadas por factor cinco y reproyectadas, aproximadamente 150 m. En una muestra de 10 000 centros de celda del mapa, **4,97 %** de las clases WSI difirieron de la clase nativa consultada en el mismo punto. La clase se calcula actualmente con media y redondeo, más interpolación bilineal; para categorías conviene usar moda o vecino más próximo y rotular la visualización como generalizada. La covariable NDMI es un compuesto Sentinel-2 2019–2025 usado para toda la serie 2001–2025, no una medición anual histórica. El filtro de GEE termina en `2025-12-31`, fecha de término exclusiva, por lo que omite ese día.

### 5. Contraste con Ancachuro

La estación disponible está en Zurite. En seis años diarios con al menos 99 % de cobertura válida, la precipitación final tuvo MAE de 42,44 mm/año y sesgo de +21,93 mm/año; la temperatura final tuvo un sesgo de **+1,81 °C** respecto de la media de Tmax y Tmin de la estación. El contraste detecta un sesgo térmico local que impide certificar precisión puntual. La estación podría formar parte de la red usada por PISCO, por lo que su independencia estricta sigue sin demostrarse. El detalle, control de faltantes y comparaciones con los productos originales constan en `VALIDACION_ANCACHURO_2026-10-21.md`.

### 6. Contenido y trazabilidad

La guía `R/mod_guia_indicadores.R` **sí aparecía dentro de la portada**, aunque no tenía una pestaña principal propia. Esta corrección de alcance surgió al ejecutar los módulos: la guía anterior contenía cifras fijas erróneas y se sustituyó por una versión descriptiva sin diagnósticos territoriales fijos. Las salidas aún mantienen nombres internos como `Prob_Estres_Hidrico_pct` y `ETo_PenmanMonteith_mm`, que pueden inducir a error fuera de la interfaz. Renombrar columnas y bandas requerirá migración coordinada de código, descargas y documentación. Falta validación independiente por regiones altitudinales y distritos, e incertidumbre espacial para ETo y WSI.

## Cambios aplicados en esta revisión

- Corregí en la metodología pública la afirmación de conservación exacta de lluvia y la descripción de la ETo anual; precisé el carácter relativo del WSI y el periodo del NDMI.
- Corregí el texto metodológico de la descarga puntual y la etiqueta WSI como escala 0–100.
- Corregí la tabla de priorización: `P_CV_pct` ya viene expresado como porcentaje y se mostraba multiplicado otra vez por 100.
- Sustituí la ficha distrital con números fijos y prescripciones de obras por un resumen calculado a partir de la tabla cargada, con advertencia explícita de alcance. La matriz se presenta ahora como exploratoria y la columna demográfica indica que procede del censo de 2017.
- Actualicé etiquetas principales del WSI en portada y mapa. Aún quedan textos y nombres de campos con terminología heredada que requieren una revisión editorial completa.
- Añadí a la metodología pública el resultado y el alcance del contraste con Ancachuro, incluido el sesgo térmico local, y precisé los límites de uso de las celdas de 30 m.
- Sustituí la guía visible en portada por explicaciones de los indicadores realmente calculados. El resultado instrumental se genera ahora desde los CSV y rásteres vigentes; las pruebas y el script de despliegue rechazan un resumen desactualizado.

## Requisitos para validación pública más fuerte

1. Contrastar los productos finales con estaciones independientes y declarar error, sesgo e intervalos por región altitudinal y periodo. Separar claramente evaluación contra PISCO de validación independiente.
2. Auditar la reagregación a PISCO para los 25 años, publicar las diferencias por celda y corregir si se desea declarar conservación.
3. Justificar y validar la fórmula anual de ETo y el WSI; retirar lenguaje probabilístico y de disponibilidad de agua hasta contar con evidencia específica.
4. Corregir la visualización categórica a 150 m, las etiquetas restantes y los metadatos de descargas. Probar la aplicación en navegador y con usuarios antes de distribución general.

## Referencias técnicas

- FAO-56, definición y cálculo de evapotranspiración de referencia: <https://www.fao.org/4/X0490E/x0490e06.htm>
- OMM, normales climatológicas estándar de 30 años: <https://wmo.int/wmo-climatological-normals>
- Catálogo Sentinel-2 SR Harmonized de Earth Engine: <https://developers.google.com/earth-engine/datasets/catalog/COPERNICUS_S2_SR_HARMONIZED>
- Fecha final exclusiva en `ee.Filter.date`: <https://developers.google.com/earth-engine/apidocs/ee-filter-date>
