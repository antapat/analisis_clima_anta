# ==============================================================================
# MOD_METODOLOGIA_DATOS.R: Metodología Técnica, Protocolo y Descargas
# ==============================================================================

mod_metodologia_datos_ui <- function(id) {
  ns <- NS(id)
  archivo_validacion <- "app_data/validacion_red_estaciones.csv"
  texto_validacion <- if (file.exists(archivo_validacion)) {
    v <- read.csv(archivo_validacion, stringsAsFactors = FALSE)
    # Índices explícitos para evitar colisiones de nombres en subset().
    anc_t <- v[v$estacion == "ANCACHURO" & v$variable == "T" & v$producto == "modelo", ]
    anc_p <- v[v$estacion == "ANCACHURO" & v$variable == "P" & v$producto == "modelo", ]
    sor_t <- v[v$estacion == "SORAYPAMPA" & v$variable == "T" & v$producto == "modelo", ]
    sor_p <- v[v$estacion == "SORAYPAMPA" & v$variable == "P" & v$producto == "modelo", ]
    if (any(c(nrow(anc_t), nrow(anc_p), nrow(sor_t), nrow(sor_p)) != 1L))
      stop("Resumen de la red de estaciones inválido")
    sprintf(
      "En Ancachuro (Zurite), el error absoluto medio de lluvia fue %.1f mm/año en %d años y el sesgo térmico fue %+.2f °C en %d años. En Soraypampa (Mollepata, 3854 m), el sesgo térmico fue %+.2f °C en %d años. En 2019, único año de lluvia de Soraypampa con al menos 99 %% de cobertura, el modelo quedó %.1f mm por debajo del registro. Curahuasi y Urubamba están fuera del ráster de Anta; Curahuasi no tiene un año con 99 %% de cobertura. No hay otras estaciones disponibles dentro de Anta. Las estaciones comparadas pudieron alimentar PISCO: estos resultados son comprobaciones locales de sesgo, no una validación independiente ni una certificación de exactitud provincial.",
      anc_p$MAE[[1]], anc_p$n[[1]], anc_t$sesgo[[1]], anc_t$n[[1]],
      sor_t$sesgo[[1]], sor_t$n[[1]], abs(sor_p$sesgo[[1]])
    )
  } else {
    "No se encuentra el resumen de la red de estaciones. Ejecute scripts/validar_red_estaciones.R antes de publicar una actualización de los datos."
  }
  
  tagList(
    # Ficha Técnica y Encabezado Metodológico
    div(
      class = "content-card mb-3",
      div(
        class = "content-card-header",
        tags$h5(class = "content-card-title", icon("book-open"), " Protocolo Técnico Metodológico y Auditoría de Datos")
      ),
      p(
        class = "text-muted small mb-3",
        "El sistema resuelve la brecha de escala climática en la cordillera andina mediante un flujo secuencial en dos fases: ",
        tags$strong("Fase 1 (Nube - GEE)"), " para downscaling morfométrico a 30 m mediante Sentinel-2 y SRTM; y ",
        tags$strong("Fase 2 (Local - R {rpisco})"), " para ajuste de sesgo con productos PISCO del SENAMHI."
      ),
      div(
        class = "row g-3",
        div(
          class = "col-md-3 col-sm-6",
          div(
            class = "p-3 bg-light rounded border text-center",
            tags$span(class = "text-muted small d-block", "Resolución de Salida"),
            tags$strong(class = "text-primary h6 m-0", "30.0 m × 30.0 m (0.09 ha/px)")
          )
        ),
        div(
          class = "col-md-3 col-sm-6",
          div(
            class = "p-3 bg-light rounded border text-center",
            tags$span(class = "text-muted small d-block", "Sistema Espacial"),
            tags$strong(class = "text-dark h6 m-0", "UTM Zona 18S (EPSG:32718)")
          )
        ),
        div(
          class = "col-md-3 col-sm-6",
          div(
            class = "p-3 bg-light rounded border text-center",
            tags$span(class = "text-muted small d-block", "Ventana Temporal"),
            tags$strong(class = "text-dark h6 m-0", "2001–2025 (25 Años)")
          )
        ),
        div(
          class = "col-md-3 col-sm-6",
          div(
            class = "p-3 bg-light rounded border text-center",
            tags$span(class = "text-muted small d-block", "Ámbito Territorial"),
            tags$strong(class = "text-dark h6 m-0", "Provincia de Anta (9 Distritos)")
          )
        )
      )
    ),

    # Cuadros Explicativos de Protocolos y Límites de Uso
    div(
      class = "row g-3 mb-4",
      div(
        class = "col-lg-6 col-md-12",
        div(
          class = "content-card",
          tags$h6(class = "content-card-title mb-3", icon("cogs"), " Fuentes Oficiales y Calibración Física"),
          div(
            class = "methodology-box",
            tags$h6("1. Precipitación Anual (2001–2025):"),
            p("Ajustada anualmente con PISCOp v3.0 (SENAMHI, 0,1°) mediante una razón de corrección interpolada a la malla de 30 m. El resultado conserva patrones espaciales del modelo GEE, pero no garantiza igualdad exacta al reagregarlo a la malla PISCO.")
          ),
          div(
            class = "methodology-box",
            tags$h6("2. Temperatura Media Anual (2001–2025):"),
            p("Corregida con Delta Additive Scaling anclado a PISCOt v1.2. Para el quinquenio 2021–2025 (periodo posterior a PISCOt), se extendió la serie acoplando la anomalía interanual de ERA5-Land con el sesgo medio calibrado del periodo de solapamiento.")
          ),
          div(
            class = "methodology-box",
            tags$h6("3. Balance Hídrico y Evapotranspiración (ETo):"),
            p("ETo estimada a partir de la climatología PISCOeo_pm 1981–2010 y un ajuste empírico de 35 mm por cada °C de diferencia de temperatura anual, con piso de 200 mm/año. No se recalculó Penman-Monteith con radiación, humedad y viento de cada año. La diferencia P − ETo es un indicador climático, no una medida de disponibilidad real de agua.")
          )
        )
      ),
      div(
        class = "col-lg-6 col-md-12",
        div(
          class = "content-card",
          tags$h6(class = "content-card-title mb-3", icon("exclamation-circle"), " Distinción de Capas y Límites de Uso"),
          div(
            class = "methodology-box",
            tags$h6("Distinción Estructural Obligatoria:"),
            p("El visor separa explícitamente la dinámica climática anual (P_año, T_año y anomalías del año seleccionado) de los diagnósticos biofísicos multianuales (WSI, aridez UNESCO, balance P-ETo, NDMI). Estos últimos representan la condición media estructural del territorio y no deben confundirse con valores del año evaluado.")
          ),
          div(
            class = "methodology-box",
            tags$h6("Índice de Estrés Hídrico Territorial (WSI):"),
            p("El WSI es un índice relativo de susceptibilidad (0–100) ponderado con 35 % de aridez, 30 % de NDMI, 20 % de variabilidad de lluvia y 15 % de pendiente. No es una probabilidad calibrada ni una alerta meteorológica. El NDMI procede de un compuesto Sentinel-2 de 2019–2025, usado como predictor espacial para toda la serie.")
          ),
          div(
            class = "methodology-box",
            tags$h6("Límites de Uso Cartográfico:"),
            p("Las capas permiten explorar condiciones y diferencias climáticas generales entre ámbitos de Anta. Sus valores proceden de modelos matemáticos y tienen incertidumbre local: solo hay dos estaciones disponibles dentro del territorio para contrastarlos, y pudieron alimentar PISCO. El tamaño de celda de 30 m no representa precisión instrumental de 30 m. Para diseñar obras, evaluar una parcela o estimar agua disponible se requieren mediciones y estudios locales.")
          ),
          div(
            class = "methodology-box",
            tags$h6("Contraste con estaciones meteorológicas:"),
            p(texto_validacion)
          )
        )
      )
    ),

    # Referencias del software y de los insumos utilizados
    div(
      class = "content-card mb-4",
      tags$h6(class = "content-card-title mb-3", icon("book"), " Referencias y fuentes de datos"),
      tags$ul(
        tags$li(
          tags$strong("Software rpisco: "),
          "Santos Andrade, P. (2026). rpisco: Access and Process PISCO High-Resolution Climate Grids for Peru. Paquete de R utilizado para descargar y procesar los productos PISCO. ",
          tags$a("Autoría y cita del paquete", href = "https://paulesantos.github.io/rpisco/authors.html", target = "_blank", rel = "noopener noreferrer")
        ),
        tags$li(
          tags$strong("PISCO — SENAMHI: "),
          "PISCOp v3.0 para precipitación (2001–2025), PISCOt v1.2 para temperatura (2001–2020) y PISCOeo_pm para evapotranspiración de referencia (climatología 1981–2010). ",
          tags$a("Referencias de los productos PISCO", href = "https://paulesantos.github.io/rpisco/", target = "_blank", rel = "noopener noreferrer")
        ),
        tags$li(
          tags$strong("CHIRPS — UCSB Climate Hazards Center: "),
          "precipitación utilizada como insumo del modelo en Google Earth Engine. ",
          tags$a("Catálogo CHIRPS Daily", href = "https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_DAILY", target = "_blank", rel = "noopener noreferrer")
        ),
        tags$li(
          tags$strong("ERA5-Land — ECMWF / Copernicus: "),
          "temperatura y anomalías interanuales empleadas en el modelado y en la extensión de la serie térmica a 2021–2025. ",
          tags$a("Catálogo ERA5-Land", href = "https://developers.google.com/earth-engine/datasets/catalog/ECMWF_ERA5_LAND_MONTHLY_AGGR", target = "_blank", rel = "noopener noreferrer")
        ),
        tags$li(
          tags$strong("Sentinel-2 — Copernicus / ESA: "),
          "reflectancia de superficie para los índices NDVI y NDMI; compuesto 2019–2025 como predictor espacial. ",
          tags$a("Catálogo Sentinel-2", href = "https://developers.google.com/earth-engine/datasets/catalog/COPERNICUS_S2_SR_HARMONIZED", target = "_blank", rel = "noopener noreferrer")
        ),
        tags$li(
          tags$strong("SRTM — NASA / USGS: "),
          "modelo digital de elevación de 30 m y variables derivadas de relieve. ",
          tags$a("Catálogo SRTM", href = "https://developers.google.com/earth-engine/datasets/catalog/USGS_SRTMGL1_003", target = "_blank", rel = "noopener noreferrer")
        ),
        tags$li(
          tags$strong("Cartografía y contraste local: "),
          "archivos vectoriales locales de la provincia y sus distritos, utilizados como geometría espacial referencial, y registros de las estaciones Ancachuro, Soraypampa, Curahuasi y Urubamba para las comprobaciones de sesgo descritas en esta sección."
        )
      )
    ),

    # Catálogo de Descargas de Datos Abiertos
    div(
      class = "content-card",
      div(
        class = "content-card-header",
        div(
          tags$h6(class = "content-card-title", icon("download"), " Catálogo de Descargas y Datos Abiertos"),
          tags$span(class = "content-card-subtitle", "Datos modelados para análisis referencial; consulte las limitaciones antes de reutilizarlos")
        ),
        tags$span(class = "badge bg-info text-dark", "Formato Abierto")
      ),
      div(
        class = "row g-3 mt-1",
        div(
          class = "col-md-4 col-sm-12",
          div(
            class = "p-3 border rounded bg-white text-center h-100 d-flex flex-column justify-content-between",
            div(
              icon("file-csv", class = "fa-2x text-primary mb-2"),
              tags$h6(class = "fw-bold", "Series Anuales 2001–2025"),
              p(class = "small text-muted", "Estimaciones de precipitación, temperatura y anomalías anuales por distrito; no son registros instrumentales.")
            ),
            downloadButton(ns("dl_series_csv"), label = "Descargar CSV (Series)", class = "btn btn-outline-primary btn-sm w-100")
          )
        ),
        div(
          class = "col-md-4 col-sm-12",
          div(
            class = "p-3 border rounded bg-white text-center h-100 d-flex flex-column justify-content-between",
            div(
              icon("table", class = "fa-2x text-success mb-2"),
              tags$h6(class = "fw-bold", "Resumen Distrital Multianual"),
              p(class = "small text-muted", "Indicadores modelados de susceptibilidad, aridez, diferencia P − ETo y tendencias; uso comparativo, no diagnóstico local.")
            ),
            downloadButton(ns("dl_resumen_csv"), label = "Descargar CSV (Resumen)", class = "btn btn-outline-success btn-sm w-100")
          )
        ),
        div(
          class = "col-md-4 col-sm-12",
          div(
            class = "p-3 border rounded bg-white text-center h-100 d-flex flex-column justify-content-between",
            div(
              icon("map-marked", class = "fa-2x text-danger mb-2"),
              tags$h6(class = "fw-bold", "Límites Distritales (GeoJSON)"),
              p(class = "small text-muted", "Geometría espacial referencial de los 9 distritos en WGS84 para visualización en GIS.")
            ),
            downloadButton(ns("dl_distritos_geojson"), label = "Descargar GeoJSON", class = "btn btn-outline-danger btn-sm w-100")
          )
        )
      )
    )
  )
}

mod_metodologia_datos_server <- function(id, data_series, data_resumen) {
  moduleServer(id, function(input, output, session) {
    
    # Manejadores de descarga
    output$dl_series_csv <- downloadHandler(
      filename = function() {
        paste0("series_anuales_clima_anta_2001_2025_", Sys.Date(), ".csv")
      },
      content = function(file) {
        write.csv(data_series(), file, row.names = FALSE)
      }
    )

    output$dl_resumen_csv <- downloadHandler(
      filename = function() {
        paste0("resumen_hidroclimatico_distrital_anta_", Sys.Date(), ".csv")
      },
      content = function(file) {
        write.csv(data_resumen(), file, row.names = FALSE)
      }
    )

    output$dl_distritos_geojson <- downloadHandler(
      filename = function() {
        paste0("distritos_provincia_anta_", Sys.Date(), ".geojson")
      },
      content = function(file) {
        file.copy("app_data/distritos_anta.geojson", file)
      }
    )
  })
}
