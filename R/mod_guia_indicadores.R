# ==============================================================================
# MOD_GUIA_INDICADORES.R
# Guía pública para interpretar los indicadores del Sistema Hidroclimático.
# Describe qué es cada indicador, cómo se calculó y qué no permite concluir.
# Presentación enriquecida con tarjetas visuales por familia de indicadores.
# Fuente metodológica: metodologia_tecnica_proceso_datos_clima_anta.qmd
# ==============================================================================

mod_guia_indicadores_ui <- function(id) {
  ns <- NS(id)

  div(
    id = ns("seccion-guia-indicadores"),
    class = "content-card mt-4",

    # ── Encabezado ─────────────────────────────────────────────────────────
    div(
      class = "content-card-header",
      tags$h5(class = "content-card-title",
              icon("book-open-reader"),
              " Guía para interpretar los indicadores"),
      tags$span(
        class = "content-card-subtitle",
        "Qué representa cada cifra, de dónde procede y qué no permite concluir"
      )
    ),

    # ── Nota de origen de datos ────────────────────────────────────────────
    div(
      class = "alert alert-info d-flex align-items-start gap-2 mx-3 mt-3 mb-0",
      style = "font-size:0.87rem;",
      icon("circle-info", class = "mt-1 flex-shrink-0"),
      tags$div(
        tags$strong("Origen de los datos — flujo de dos fases:"),
        tags$ul(
          class = "mb-0 mt-1",
          tags$li(
            tags$strong("Fase 1 · Google Earth Engine:"),
            " downscaling espacial a 30 m usando ERA5-Land (temperatura),
            CHIRPS con Random Forest 250 árboles (precipitación),
            SRTM (topografía) y Sentinel-2 (NDMI, NDVI)."
          ),
          tags$li(
            tags$strong("Fase 2 · R con rpisco:"),
            " corrección de sesgo con mallas oficiales SENAMHI
            (PISCOp v3.0 · PISCOt v1.2 · PISCOeo_pm), preservando la
            textura topográfica de 30 m. Los resultados son estimaciones
            modeladas, no lecturas directas de estaciones meteorológicas."
          )
        )
      )
    ),

    # ── Tabs por familia de indicadores ───────────────────────────────────
    div(
      class = "p-3",
      navset_pill(
        id = ns("nav_indicadores"),

        # ── Tab 1: Lluvia y Temperatura ────────────────────────────────────
        nav_panel(
          title = tagList(icon("cloud-rain"), " Lluvia y Temperatura"),
          div(
            class = "row g-3 mt-1",

            # Precipitación anual
            div(
              class = "col-md-6",
              div(
                class = "guia-card h-100",
                div(class = "guia-card-icon text-primary", icon("droplet")),
                tags$h6(class = "guia-card-title",
                        "Precipitación anual (mm / año)"),
                tags$p(class = "guia-card-body",
                  "Lámina de agua precipitada acumulada en el año calendario.
                  Se generó con un modelo ", tags$strong("Random Forest de regresión
                  (250 árboles, 6 000 muestras)"), " entrenado con CHIRPS (5,5 km)
                  y covariables topográficas de SRTM + Sentinel-2 a 30 m,
                  más interpolación de residuales para reducir diferencias regionales.
                  La textura fina a 30 m procede del downscaling en GEE;
                  el volumen total fue corregido año a año mediante ",
                  tags$em("ratio scaling"), " multiplicativo con PISCOp v3.0.
                  La reagregación del producto final no reproduce exactamente
                  todas las celdas PISCO (~10 km)."
                ),
                div(
                  class = "guia-card-limits",
                  icon("triangle-exclamation", class = "text-warning me-1"),
                  "En la comparación regional previa al ajuste se estimó un sesgo
                  de lluvia de +27,9 % frente a PISCO. El ajuste no garantiza
                  conservación exacta por celda ni precisión local; en Soraypampa,
                  el único año de lluvia con cobertura suficiente difirió −539,2 mm
                  de la estación."
                )
              )
            ),

            # Temperatura media anual
            div(
              class = "col-md-6",
              div(
                class = "guia-card h-100",
                div(class = "guia-card-icon text-danger", icon("temperature-half")),
                tags$h6(class = "guia-card-title",
                        "Temperatura media anual (°C)"),
                tags$p(class = "guia-card-body",
                  "Temperatura media del aire a 2 m de altura, promediada para el año calendario.
                  Se calculó en dos tramos:",
                  tags$ul(
                    tags$li(
                      tags$strong("2001–2020:"),
                      " downscaling topoclimático de ERA5-Land aplicando gradiente
                      vertical regional (−0,55 a −0,62 °C / 100 m), modulación por humedad
                      foliar (ΔNDMI × −0,8 °C) y exposición norte (Northness × +0,3 °C).
                      Corregido con ", tags$em("delta additive scaling"), " contra PISCOt v1.2
                      ((Tmax + Tmin) / 2)."
                    ),
                    tags$li(
                      tags$strong("2021–2025:"),
                      " el downscaling de ERA5-Land se ajustó con el sesgo medio espacial
                      de los 20 años calibrados (ΔT̄₂₀₀₁₋₂₀₂₀), ya que PISCOt
                      no cubre ese quinquenio."
                    )
                  )
                ),
                div(
                  class = "guia-card-limits",
                  icon("triangle-exclamation", class = "text-warning me-1"),
                  "La comparación regional previa al ajuste mostró sesgo frío
                  de ERA5-Land frente a PISCO. El producto final conserva sesgos
                  locales: +1,81 °C en Ancachuro y +4,92 °C en Soraypampa.
                  Los años 2021–2025 usan un sesgo histórico, sin PISCOt nuevo."
                )
              )
            ),

            # Anomalía
            div(
              class = "col-md-6",
              div(
                class = "guia-card h-100",
                div(class = "guia-card-icon text-info", icon("chart-bar")),
                tags$h6(class = "guia-card-title",
                        "Anomalía respecto a la media del periodo"),
                tags$p(class = "guia-card-body",
                  "Diferencia entre el valor de un año y la media de todo el periodo
                  2001–2025 en el mismo píxel (30 m). Para la lluvia puede expresarse
                  también como porcentaje de esa media (anomalía relativa).
                  Permite identificar años excepcionalmente húmedos, secos,
                  cálidos o fríos respecto al comportamiento típico del periodo analizado."
                ),
                div(
                  class = "guia-card-limits",
                  icon("circle-info", class = "text-info me-1"),
                  "La media 2001–2025 (25 años) no equivale a la normal climatológica
                  estándar OMM (30 años, 1991–2020). Úsela solo para
                  comparaciones internas de esta serie."
                )
              )
            ),

            # Tendencia por década
            div(
              class = "col-md-6",
              div(
                class = "guia-card h-100",
                div(class = "guia-card-icon text-success", icon("arrow-trend-up")),
                tags$h6(class = "guia-card-title",
                        "Tendencia por década (°C o mm / década)"),
                tags$p(class = "guia-card-body",
                  "Pendiente de la regresión lineal por mínimos cuadrados ajustada
                  sobre las 25 estimaciones anuales finales corregidas con PISCO,
                  multiplicada por diez para expresarla por década.
                  Se calculó píxel a píxel sobre los rásteres a 30 m con el script
                  ", tags$code("recalcular_variabilidad_pisco.R"), "; en la app se
                  muestra el promedio zonal por distrito o provincia."
                ),
                div(
                  class = "guia-card-limits",
                  icon("triangle-exclamation", class = "text-warning me-1"),
                  "La pendiente describe la serie modelada, sin demostrar causa
                  ni evolución futura. La tendencia provincial de lluvia no fue
                  estadísticamente concluyente en la auditoría; el ajuste lineal
                  tampoco incorpora la incertidumbre de PISCO ni del modelo espacial."
                )
              )
            )

          ) # /row
        ), # /tab lluvia y temperatura

        # ── Tab 2: Balance Hídrico y ETo ───────────────────────────────────
        nav_panel(
          title = tagList(icon("water"), " Balance Hídrico y ETo"),
          div(
            class = "row g-3 mt-1",

            # ETo
            div(
              class = "col-md-6",
              div(
                class = "guia-card h-100",
                div(class = "guia-card-icon text-warning", icon("sun")),
                tags$h6(class = "guia-card-title",
                        "Evapotranspiración de referencia — ETo (mm / año)"),
                tags$p(class = "guia-card-body",
                  "Demanda de vapor de agua de la atmósfera sobre una superficie
                  hipotética de pradera bien regada (FAO-56). La base empleada es
                  ", tags$strong("PISCOeo_pm"), ": normal climatológica mensual 1981–2010
                  del SENAMHI calculada con Penman-Monteith completo (radiación, viento,
                  humedad y temperatura). Esta base se dinamizó anualmente a 30 m
                  con la fórmula:",
                  tags$div(
                    class = "bg-light border rounded p-2 my-2",
                    style = "font-size:0.84rem; font-family:monospace;",
                    "ETo(x,y,t) = max(200, ETo_base(x,y) + 35 × [T_corr(x,y,t) − T_ref(x,y)])"
                  ),
                  "donde 35 mm/°C es un coeficiente empírico del modelo,
                  aún pendiente de justificación y validación; T_ref es la temperatura media
                  PISCO 2001–2020 proyectada a 30 m."
                ),
                div(
                  class = "guia-card-limits",
                  icon("triangle-exclamation", class = "text-warning me-1"),
                  "No se recalculó Penman-Monteith completo para cada año con datos
                  reales de radiación, viento y humedad. La variación interanual
                  de ETo se aproxima solo mediante la anomalía térmica.
                  El piso de 200 mm/año es una restricción técnica del modelo."
                )
              )
            ),

            # Índice de aridez
            div(
              class = "col-md-6",
              div(
                class = "guia-card h-100",
                div(class = "guia-card-icon text-danger", icon("khanda")),
                tags$h6(class = "guia-card-title",
                        "Índice de Aridez UNESCO — P / ETo (adimensional)"),
                tags$p(class = "guia-card-body",
                  "Cociente entre la precipitación media multianual y la ETo media
                  multianual (periodo 2001–2025). Clasifica el régimen hídrico climático:"
                ),
                tags$table(
                  class = "table table-sm table-bordered",
                  style = "font-size:0.82rem;",
                  tags$thead(
                    class = "table-light",
                    tags$tr(
                      tags$th("P / ETo"), tags$th("Categoría UNESCO")
                    )
                  ),
                  tags$tbody(
                    tags$tr(tags$td("< 0,20"), tags$td("Árido")),
                    tags$tr(tags$td("0,20 – 0,50"), tags$td("Semiárido")),
                    tags$tr(tags$td("0,50 – 0,65"), tags$td("Subhúmedo seco")),
                    tags$tr(tags$td("0,65 – 1,00"), tags$td("Subhúmedo húmedo")),
                    tags$tr(tags$td("> 1,00"), tags$td("Húmedo"))
                  )
                ),
                div(
                  class = "guia-card-limits",
                  icon("circle-info", class = "text-info me-1"),
                  "Este índice caracteriza el clima medio del periodo completo.
                  No varía al seleccionar un año en los mapas anuales."
                )
              )
            ),

            # Balance P - ETo
            div(
              class = "col-md-6",
              div(
                class = "guia-card h-100",
                div(class = "guia-card-icon text-primary", icon("scale-balanced")),
                tags$h6(class = "guia-card-title",
                        "Diferencia climática P − ETo (mm / año)"),
                tags$p(class = "guia-card-body",
                  "Diferencia entre la precipitación media y la ETo media para el
                  periodo 2001–2025 en cada píxel de 30 m. Compara lluvia
                  con demanda evaporativa de referencia:",
                  tags$ul(
                    tags$li(tags$strong("P − ETo > 0:"), " lluvia media mayor que ETo media."),
                    tags$li(tags$strong("P − ETo < 0:"), " lluvia media menor que ETo media.")
                  )
                ),
                div(
                  class = "guia-card-limits",
                  icon("triangle-exclamation", class = "text-warning me-1"),
                  "Esta diferencia no mide agua disponible para cultivos o
                  abastecimiento. No incluye escorrentía,
                  infiltración, almacenamiento en suelo, acuíferos, riego ni
                  demanda humana."
                )
              )
            ),

            # NDMI
            div(
              class = "col-md-6",
              div(
                class = "guia-card h-100",
                div(class = "guia-card-icon text-success", icon("leaf")),
                tags$h6(class = "guia-card-title",
                        "NDMI — Índice de Humedad Normalizada (Sentinel-2)"),
                tags$p(class = "guia-card-body",
                  "Es un indicador espectral relacionado con el contenido de agua
                  de la vegetación: (B8 NIR − B11 SWIR1) / (B8 + B11).
                  Se obtuvo del compuesto mediano de Sentinel-2 libre de nubes
                  del periodo 2019–2025 (máscaras QA60 y SCL), remuestreado a
                  30 m alineado con el SRTM.",
                  tags$ul(
                    tags$li(tags$strong("NDMI mayor:"), " respuesta espectral compatible con más agua en la vegetación."),
                    tags$li(tags$strong("NDMI menor:"), " respuesta compatible con menos agua; requiere contexto de cobertura.")
                  )
                ),
                div(
                  class = "guia-card-limits",
                  icon("circle-info", class = "text-info me-1"),
                  "El NDMI es un predictor espacial estático representativo del
                  periodo 2019–2025. No representa el estado de humedad para cada
                  año desde 2001. Funciona como covariable del WSI y del
                  downscaling de temperatura."
                )
              )
            )

          ) # /row
        ), # /tab balance hídrico

        # ── Tab 3: Variabilidad y WSI ──────────────────────────────────────
        nav_panel(
          title = tagList(icon("bullseye"), " Variabilidad y WSI"),
          div(
            class = "row g-3 mt-1",

            # CV
            div(
              class = "col-md-6",
              div(
                class = "guia-card h-100",
                div(class = "guia-card-icon text-info", icon("chart-simple")),
                tags$h6(class = "guia-card-title",
                        "Coeficiente de variación interanual de lluvia (CV %)"),
                tags$p(class = "guia-card-body",
                  "Desviación estándar de las 25 estimaciones anuales de precipitación
                  corregidas con PISCOp, dividida entre la media del periodo,
                  expresada en porcentaje. Un valor mayor indica más variación
                  interanual relativa en la serie modelada. Por sí solo no mide
                  frecuencia de sequías, extremos ni riesgo agronómico."
                ),
                div(
                  class = "guia-card-limits",
                  icon("circle-info", class = "text-info me-1"),
                  "El CV se recalculó sobre las capas finales corregidas con PISCO
                  (", tags$code("recalcular_variabilidad_pisco.R"), "),
                  no sobre el producto GEE pre-corrección."
                )
              )
            ),

            # WSI
            div(
              class = "col-md-6",
              div(
                class = "guia-card h-100",
                div(class = "guia-card-icon", style = "color:#b45309;", icon("fire")),
                tags$h6(class = "guia-card-title",
                        "Índice relativo de susceptibilidad hídrica — WSI (0–100)"),
                tags$p(class = "guia-card-body",
                  "Modelo espacial multicriterio que sintetiza cuatro factores biofísicos
                  normalizados por percentiles robustos (P₂–P₉₈) a 30 m:"
                ),
                tags$table(
                  class = "table table-sm table-bordered",
                  style = "font-size:0.82rem;",
                  tags$thead(
                    class = "table-light",
                    tags$tr(
                      tags$th("Componente"), tags$th("Peso"), tags$th("Fuente")
                    )
                  ),
                  tags$tbody(
                    tags$tr(
                      tags$td("Riesgo por aridez (1 − AI normalizado)"),
                      tags$td("35 %"), tags$td("P / ETo PISCO")
                    ),
                    tags$tr(
                      tags$td("NDMI de vegetación invertido y normalizado"),
                      tags$td("30 %"), tags$td("Sentinel-2")
                    ),
                    tags$tr(
                      tags$td("Variabilidad pluviométrica (CV % normalizado)"),
                      tags$td("20 %"), tags$td("CHIRPS + PISCO")
                    ),
                    tags$tr(
                      tags$td("Pendiente normalizada"),
                      tags$td("15 %"), tags$td("SRTM 30 m")
                    )
                  )
                ),
                div(
                  class = "guia-card-limits",
                  icon("triangle-exclamation", class = "text-warning me-1"),
                  "Un WSI de 70 no significa 70 % de probabilidad de sequía.
                  Es un índice relativo dentro del territorio de Anta.
                  Pesos y umbrales son decisiones de modelado pendientes de validación de campo."
                )
              )
            ),

            # Clases WSI
            div(
              class = "col-12",
              div(
                class = "guia-card",
                div(class = "guia-card-icon", style = "color:#7c3aed;",
                    icon("layer-group")),
                tags$h6(class = "guia-card-title",
                        "Clases de susceptibilidad hídrica territorial (WSI)"),
                div(
                  class = "row g-2 mt-1",
                  div(
                    class = "col-sm-6 col-lg-3",
                    div(
                      class = "wsi-class-card wsi-class-1",
                      tags$strong("Clase 1 — Bajo (WSI < 35)"),
                      tags$p(class = "mb-0 mt-1",
                        "Valor relativo bajo dentro del modelo. No determina
                        aptitud agrícola ni disponibilidad de agua."
                      )
                    )
                  ),
                  div(
                    class = "col-sm-6 col-lg-3",
                    div(
                      class = "wsi-class-card wsi-class-2",
                      tags$strong("Clase 2 — Medio (35 ≤ WSI < 55)"),
                      tags$p(class = "mb-0 mt-1",
                        "Valor relativo intermedio según los pesos y umbrales
                        elegidos; requiere contraste con información local."
                      )
                    )
                  ),
                  div(
                    class = "col-sm-6 col-lg-3",
                    div(
                      class = "wsi-class-card wsi-class-3",
                      tags$strong("Clase 3 — Alto (55 ≤ WSI < 70)"),
                      tags$p(class = "mb-0 mt-1",
                        "Valor relativo alto que señala un área para revisar
                        con observaciones y estudios de campo."
                      )
                    )
                  ),
                  div(
                    class = "col-sm-6 col-lg-3",
                    div(
                      class = "wsi-class-card wsi-class-4",
                      tags$strong("Clase 4 — Muy Alto (WSI ≥ 70)"),
                      tags$p(class = "mb-0 mt-1",
                        "Valor relativo más alto del modelo. No equivale a una
                        prohibición de uso ni prescribe una obra o intervención."
                      )
                    )
                  )
                )
              )
            )

          ) # /row
        ), # /tab variabilidad y WSI

        # ── Tab 4: Alcance y Limitaciones ─────────────────────────────────
        nav_panel(
          title = tagList(icon("circle-exclamation"), " Alcance y Limitaciones"),
          div(
            class = "row g-3 mt-1",

            div(
              class = "col-md-6",
              div(
                class = "guia-card h-100",
                div(class = "guia-card-icon text-secondary", icon("ruler-combined")),
                tags$h6(class = "guia-card-title",
                        "Resolución espacial y representatividad"),
                tags$p(class = "guia-card-body",
                  "Los archivos raster fuente tienen píxeles de 30 m × 30 m
                  (0,09 ha; proyección UTM Zona 18S / EPSG:32718),
                  alineados con el DEM SRTM. El tamaño de píxel no garantiza
                  representatividad ni exactitud a escala de parcela.",
                  tags$ul(
                    tags$li(
                      "Los ", tags$strong("mapas interactivos"), " de la app se
                      generalizan a ~150 m por límites de la API Leaflet / tiles web."
                    ),
                    tags$li(
                      "La ", tags$strong("consulta puntual"), " por ubicación
                      extrae el valor exacto del píxel a 30 m."
                    ),
                    tags$li(
                      tags$strong("Resolución ≠ exactitud:"),
                      " el modelo tiene incertidumbre propia, independientemente
                      del tamaño de celda."
                    )
                  )
                )
              )
            ),

            div(
              class = "col-md-6",
              div(
                class = "guia-card h-100",
                div(class = "guia-card-icon text-secondary", icon("tower-broadcast")),
                tags$h6(class = "guia-card-title",
                        "Contraste con estaciones meteorológicas"),
                tags$p(class = "guia-card-body",
                  "El ajuste regional se comparó con mallas PISCO. Esto no
                  constituye validación independiente del producto a 30 m.
                  En las dos estaciones interiores con años suficientes:",
                  tags$ul(
                    tags$li(
                      tags$strong("Ancachuro:"),
                      " sesgo térmico medio de +1,81 °C en seis años válidos."
                    ),
                    tags$li(
                      tags$strong("Soraypampa:"),
                      " sesgo térmico medio de +4,92 °C en cinco años válidos."
                    )
                  ),
                  "Estas estaciones pudieron contribuir a PISCO. Curahuasi y
                  Urubamba están fuera del ráster y solo aportan contexto regional."
                )
              )
            ),

            div(
              class = "col-12",
              div(
                class = "alert alert-warning d-flex align-items-start gap-2 mb-0",
                style = "font-size:0.87rem;",
                icon("triangle-exclamation", class = "mt-1 flex-shrink-0"),
                tags$div(
                  tags$strong("Uso apropiado de esta plataforma:"),
                  " Los mapas y series son estimaciones modeladas ajustadas con PISCO,
                  no mediciones directas de cada lugar. Sirven para explorar patrones
                  climáticos generales, comparar territorios y apoyar la planificación
                  a escala distrital o provincial. Cualquier decisión sobre una parcela,
                  obra de riego, habilitación urbana o gestión de riesgo agroclimático
                  requiere datos instrumentales locales y evaluación técnica en campo.
                  Consulte la sección ", tags$strong("Datos y Metodología"),
                  " para el detalle completo del flujo metodológico."
                )
              )
            )

          ) # /row
        ) # /tab alcance

      ) # /navset_pill
    ) # /div p-3

  ) # /div content-card
}

mod_guia_indicadores_server <- function(id) {
  moduleServer(id, function(input, output, session) invisible(NULL))
}
