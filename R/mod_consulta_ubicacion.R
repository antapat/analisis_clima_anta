# ==============================================================================
# MOD_CONSULTA_UBICACION.R: Consulta Puntual a Resolución Nativa de 30m
# ==============================================================================

# Hojas que se entregan en la descarga del punto. La serie se mantiene en
# valores numéricos para facilitar su uso posterior en Excel o en otros SIG.
crear_hojas_descarga_punto <- function(px) {
  anios <- 2001:2025
  serie_p <- as.numeric(px$p_serie)
  serie_t <- as.numeric(px$t_serie)
  media_p <- mean(serie_p, na.rm = TRUE)
  media_t <- mean(serie_t, na.rm = TRUE)

  serie_anual <- data.frame(
    Anio = anios,
    Precipitacion_anual_mm = serie_p,
    Temperatura_media_anual_C = serie_t,
    Anomalia_precipitacion_mm = serie_p - media_p,
    Anomalia_precipitacion_pct = ((serie_p / media_p) - 1) * 100,
    Anomalia_temperatura_C = serie_t - media_t,
    check.names = FALSE
  )

  ficha_punto <- data.frame(
    Indicador = c(
      "Este UTM", "Norte UTM", "Longitud", "Latitud", "Distrito", "Año consultado",
      "Precipitación anual", "Temperatura media anual", "Media de precipitación 2001–2025",
      "Media de temperatura 2001–2025", "Anomalía de precipitación", "Anomalía porcentual de precipitación",
      "Anomalía térmica", "Diferencia climática P − ETo", "ETo climatológica ajustada", "Índice de aridez UNESCO",
      "Índice relativo de susceptibilidad hídrica (WSI)", "Clase de estrés hídrico", "NDMI", "Pendiente",
      "Resolución espacial", "Sistema de referencia", "Cobertura temporal", "Advertencia de uso"
    ),
    Valor_numerico = c(
      px$x_utm, px$y_utm, px$lon, px$lat, NA, px$year,
      px$p_yr, px$t_yr, media_p, media_t, px$p_yr - media_p, px$p_anom_pct,
      px$t_anom_c, px$balance, px$eto, px$aridez, px$wsi, px$clase, px$ndmi, px$slope,
      30, 32718, NA, NA
    ),
    Unidad_o_detalle = c(
      "m; UTM zona 18S", "m; UTM zona 18S", "grados; WGS84", "grados; WGS84", px$distrito, "año",
      "mm/año", "°C", "mm/año", "°C", "mm/año", "%",
      "°C", "mm/año (P − ETo)", "mm/año", "P / ETo", "escala 0–100", "1 bajo; 2 medio; 3 alto; 4 muy alto", "índice", "grados",
      "m × m", "EPSG:32718 (WGS 84 / UTM 18S)", "2001–2025", "Estimación del modelo a 30 m; no equivale a una observación instrumental puntual."
    ),
    check.names = FALSE
  )

  metodologia <- data.frame(
    Aspecto = c(
      "Producto descargado", "Ámbito y resolución", "Fuentes climáticas base", "Covariables de alta resolución",
      "Downscaling de precipitación", "Calibración de precipitación", "Downscaling de temperatura",
      "Calibración y extensión térmica", "Balance hídrico y ETo", "Estrés hídrico WSI", "Documento técnico", "Limitación"
    ),
    Detalle = c(
      "Serie hidroclimática modelada del Sistema de Información y Análisis Hidroclimático Territorial de Anta.",
      "Provincia de Anta, Cusco; píxel de 30 m (900 m²), periodo 2001–2025, EPSG:32718.",
      "CHIRPS v2.0 para precipitación, ERA5-Land para temperatura y productos oficiales SENAMHI PISCOp v3.0, PISCOt v1.2 y PISCOeo_pm.",
      "SRTM GL1 (elevación, pendiente y northness) y Sentinel-2 MSI BOA (NDMI y NDVI), además de latitud y longitud.",
      "Random Forest (250 árboles; 6 000 muestras) con restitución bilineal de residuales y razón interanual anual, ejecutado en Google Earth Engine.",
      "Razón de ajuste anual respecto de PISCOp v3.0, interpolada a 30 m; no garantiza conservación exacta al reagregar.",
      "Regresión topoclimática físico-empírica: gradiente regional, modulación por NDMI y carga radiativa (northness).",
      "Delta additive scaling con PISCOt v1.2 para 2001–2020; para 2021–2025 se aplica el campo medio de corrección calibrado al patrón ERA5-Land.",
      "ETo basada en la climatología PISCOeo_pm 1981–2010, ajustada empíricamente por temperatura anual (35 mm/°C y piso de 200 mm/año); P − ETo no mide disponibilidad real de agua.",
      "Índice compuesto de susceptibilidad: 35% aridez, 30% NDMI, 20% CV de precipitación y 15% pendiente. Es susceptibilidad territorial, no pronóstico en tiempo real.",
      "metodologia_tecnica_proceso_datos_clima_anta.qmd — Protocolo metodológico técnico, versión 15 de octubre de 2026.",
      "Beta referencial. Los resultados son estimaciones de modelos matemáticos en una malla de 30 m, no mediciones puntuales ni precisión instrumental de 30 m. Hay pocas estaciones en Anta; Ancachuro y Soraypampa muestran diferencias locales y pudieron alimentar PISCO. Consulte Datos y Metodología. Para decisiones sobre parcelas u obras se requieren datos y estudios locales."
    ),
    check.names = FALSE
  )

  list(
    "Serie anual" = serie_anual,
    "Ficha del punto" = ficha_punto,
    "Metodología y fuentes" = metodologia
  )
}

mod_consulta_ubicacion_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    div(
      class = "row g-3 mb-3",
      # Controles y Localizador de Coordenadas
      div(
        class = "col-lg-8 col-md-12",
        div(
          class = "control-panel",
          div(
            class = "control-panel-title",
            icon("crosshairs"), " Localizador y Extracción de Píxel a 30 Metros"
          ),
          div(
            class = "row g-2 align-items-center",
            div(
              class = "col-md-3 col-sm-6",
              sliderInput(
                ns("sel_year"),
                label = "Año a Consultar:",
                min = 2001, max = 2025, value = 2024, step = 1, sep = "",
                width = "100%"
              )
            ),
            div(
              class = "col-md-3 col-sm-6",
              numericInput(
                ns("coord_x_utm"),
                label = "Este UTM (X) [m]:",
                value = 794200,
                step = 100,
                width = "100%"
              )
            ),
            div(
              class = "col-md-3 col-sm-6",
              numericInput(
                ns("coord_y_utm"),
                label = "Norte UTM (Y) [m]:",
                value = 8511500,
                step = 100,
                width = "100%"
              )
            ),
            div(
              class = "col-md-3 col-sm-6",
              tags$label(class = "control-label d-block", "Acción:"),
              actionButton(
                ns("btn_consultar_coords"),
                label = "Consultar Punto",
                icon = icon("search-location"),
                class = "btn btn-primary w-100 fw-bold"
              )
            )
          )
        )
      ),
      # Indicación de uso
      div(
        class = "col-lg-4 col-md-12",
        div(
          class = "control-panel h-100 d-flex flex-column justify-content-center",
          div(class = "control-panel-title", icon("mouse-pointer"), " Interacción Espacial"),
          p(
            class = "text-muted small m-0",
            "Haga clic en cualquier punto del mapa para inspeccionar automáticamente todas las capas biofísicas y climáticas a resolución nativa de 30 metros (EPSG:32718)."
          )
        )
      )
    ),

    # Fila de Mapa y Ficha del Píxel
    div(
      class = "row g-3",
      # Mapa para Clic e Inspección
      div(
        class = "col-lg-7 col-md-12",
        div(
          class = "content-card p-0",
          div(
            class = "p-3 pb-2 d-flex justify-content-between align-items-center border-bottom",
            div(
              tags$h6(class = "content-card-title", icon("map"), " Visor de Inspección de Coordenadas"),
              tags$span(class = "content-card-subtitle", "Haga clic para reposicionar el punto de consulta")
            ),
            tags$span(class = "badge bg-info text-dark", "Clic Activo en Mapa")
          ),
          div(
            class = "map-container-wrapper",
            leaflet::leafletOutput(ns("mapa_inspector"), height = "600px")
          )
        )
      ),

      # Panel Ficha del Píxel a 30m
      div(
        class = "col-lg-5 col-md-12",
        div(
          class = "content-card p-3",
          # Encabezado del Píxel con Coordenadas
          div(
            class = "pixel-coords-box",
            div(
              icon("map-pin"),
              tags$span(class = "ms-1", uiOutput(ns("coords_utm_txt"), inline = TRUE))
            ),
            tags$span(uiOutput(ns("coords_wgs_txt"), inline = TRUE))
          ),
          div(
            class = "d-flex justify-content-between align-items-center mb-3",
            div(
              tags$span(class = "text-muted small d-block", "Distrito Perteneciente:"),
              tags$h5(class = "fw-bold text-primary m-0", uiOutput(ns("distrito_hit")))
            ),
            uiOutput(ns("badge_clase_estres"))
          ),

          # Grid de Métricas del Píxel
          div(
            class = "inspector-grid",
            div(
              class = "inspector-item",
              tags$span(class = "inspector-item-label", "Lluvia Anual:"),
              tags$span(class = "inspector-item-val text-primary", uiOutput(ns("px_p_yr")))
            ),
            div(
              class = "inspector-item",
              tags$span(class = "inspector-item-label", "Media Lluvia:"),
              tags$span(class = "inspector-item-val", uiOutput(ns("px_p_med")))
            ),
            div(
              class = "inspector-item",
              tags$span(class = "inspector-item-label", "Temp. Anual:"),
              tags$span(class = "inspector-item-val text-danger", uiOutput(ns("px_t_yr")))
            ),
            div(
              class = "inspector-item",
              tags$span(class = "inspector-item-label", "Media Temp.:"),
              tags$span(class = "inspector-item-val", uiOutput(ns("px_t_med")))
            ),
            div(
              class = "inspector-item",
              tags$span(class = "inspector-item-label", "Anomalía Lluvia:"),
              tags$span(class = "inspector-item-val", uiOutput(ns("px_p_anom")))
            ),
            div(
              class = "inspector-item",
              tags$span(class = "inspector-item-label", "Anomalía Térmica:"),
              tags$span(class = "inspector-item-val", uiOutput(ns("px_t_anom")))
            ),
            div(
              class = "inspector-item",
              tags$span(class = "inspector-item-label", "Balance Hídrico:"),
              tags$span(class = "inspector-item-val", uiOutput(ns("px_balance")))
            ),
            div(
              class = "inspector-item",
              tags$span(class = "inspector-item-label", "ETo ajustada:"),
              tags$span(class = "inspector-item-val", uiOutput(ns("px_eto")))
            ),
            div(
              class = "inspector-item",
              tags$span(class = "inspector-item-label", "Aridez UNESCO:"),
              tags$span(class = "inspector-item-val", uiOutput(ns("px_aridez")))
            ),
            div(
              class = "inspector-item",
              tags$span(class = "inspector-item-label", "Estrés WSI:"),
              tags$span(class = "inspector-item-val text-danger", uiOutput(ns("px_wsi")))
            ),
            div(
              class = "inspector-item",
              tags$span(class = "inspector-item-label", "NDMI Humedad:"),
              tags$span(class = "inspector-item-val", uiOutput(ns("px_ndmi")))
            ),
            div(
              class = "inspector-item",
              tags$span(class = "inspector-item-label", "Pendiente:"),
              tags$span(class = "inspector-item-val", uiOutput(ns("px_slope")))
            )
          ),

          div(
            class = "mt-3",
            downloadButton(
              ns("download_xlsx_punto"),
              label = "Descargar datos del punto (.xlsx)",
              icon = icon("file-excel"),
              class = "btn btn-outline-success w-100 fw-bold"
            )
          ),

          # Mini-gráfico de la Serie Temporal en ese Punto (2001–2025)
          div(
            class = "border-top pt-2 mt-2",
            tags$strong(class = "small text-muted d-block mb-1", icon("chart-line"), " Serie Temporal de Precipitación y Temperatura (2001–2025):"),
            plotly::plotlyOutput(ns("plot_pixel_serie"), height = "195px")
          ),

          tags$p(
            class = "text-muted small mt-2 mb-0",
            icon("info-circle"), " Las estimaciones corresponden al modelo continuo a 30 m calibrado con PISCO-SENAMHI. No implican precisión de estación meteorológica instrumental puntual."
          )
        )
      )
    )
  )
}

mod_consulta_ubicacion_server <- function(id, sf_distritos, sf_distritos_wgs84, p_30m_ref, t_30m_ref, estres_30m_ref, estres_base_ref, r_disp_wgs84) {
  moduleServer(id, function(input, output, session) {
    
    # Coordenadas activas en UTM 18S (reactivas)
    punto_utm <- reactiveVal(c(x = 794200, y = 8511500))

    # Actualizar si el usuario hace clic en el mapa Leaflet
    observeEvent(input$mapa_inspector_click, {
      clk <- input$mapa_inspector_click
      req(clk$lng, clk$lat)
      
      pt_wgs <- sf::st_sfc(sf::st_point(c(clk$lng, clk$lat)), crs = 4326)
      pt_utm <- sf::st_transform(pt_wgs, 32718)
      crds   <- sf::st_coordinates(pt_utm)

      punto_utm(c(x = crds[1], y = crds[2]))
      
      # Sincronizar inputs numéricos
      updateNumericInput(session, "coord_x_utm", value = round(crds[1]))
      updateNumericInput(session, "coord_y_utm", value = round(crds[2]))
    })

    # Actualizar si el usuario presiona el botón "Consultar Punto"
    observeEvent(input$btn_consultar_coords, {
      req(input$coord_x_utm, input$coord_y_utm)
      punto_utm(c(x = input$coord_x_utm, y = input$coord_y_utm))
    })

    # Extracción en tiempo real a 30m sobre los SpatRasters nativos
    pixel_data <- reactive({
      coords <- punto_utm()
      yr     <- as.integer(input$sel_year)
      req(coords, yr)

      px <- coords["x"]
      py <- coords["y"]

      # Vector temporal para extracción en terra
      pt_v <- terra::vect(matrix(c(px, py), ncol = 2), crs = "EPSG:32718")

      # Extracciones individuales seguras
      b_p <- paste0("P_", yr)
      b_t <- paste0("T_", yr)

      val_p_yr  <- tryCatch(as.numeric(terra::extract(p_30m_ref()[[b_p]], pt_v)[1, 2]), error = function(e) NA)
      val_t_yr  <- tryCatch(as.numeric(terra::extract(t_30m_ref()[[b_t]], pt_v)[1, 2]), error = function(e) NA)
      
      # Series completas de 25 años para el mini-gráfico y la descarga.
      vals_p_serie <- tryCatch(as.numeric(terra::extract(p_30m_ref(), pt_v)[1, -1]), error = function(e) rep(NA, 25))
      vals_t_serie <- tryCatch(as.numeric(terra::extract(t_30m_ref(), pt_v)[1, -1]), error = function(e) rep(NA, 25))

      val_bal   <- tryCatch(as.numeric(terra::extract(estres_30m_ref()[["Balance_Hidrico_P_PET_mm"]], pt_v)[1, 2]), error = function(e) NA)
      val_eto   <- tryCatch(as.numeric(terra::extract(estres_30m_ref()[["ETo_PenmanMonteith_mm"]], pt_v)[1, 2]), error = function(e) NA)
      val_arid  <- tryCatch(as.numeric(terra::extract(estres_30m_ref()[["Indice_Aridez_UNESCO"]], pt_v)[1, 2]), error = function(e) NA)
      val_wsi   <- tryCatch(as.numeric(terra::extract(estres_30m_ref()[["Prob_Estres_Hidrico_pct"]], pt_v)[1, 2]), error = function(e) NA)
      val_clase <- tryCatch(as.integer(terra::extract(estres_30m_ref()[["Clase_Estres_Hidrico"]], pt_v)[1, 2]), error = function(e) NA)
      val_ndmi  <- tryCatch(as.numeric(terra::extract(estres_30m_ref()[["ndmi"]], pt_v)[1, 2]), error = function(e) NA)
      val_slope <- tryCatch(as.numeric(terra::extract(estres_base_ref()[["slope"]], pt_v)[1, 2]), error = function(e) NA)

      # Coordenadas WGS84
      pt_sf <- sf::st_sfc(sf::st_point(c(px, py)), crs = 32718)
      pt_wgs <- sf::st_transform(pt_sf, 4326)
      c_wgs <- sf::st_coordinates(pt_wgs)

      # Identificar distrito sin intersectar atributos de polígonos (evita el
      # aviso de sf sobre atributos asumidos como espacialmente constantes).
      dist_idx <- sf::st_intersects(pt_sf, sf::st_geometry(sf_distritos()))[[1]]
      nom_dist <- if (length(dist_idx) > 0) sf_distritos()$NOMBDIST[dist_idx[1]] else "Fuera del ámbito provincial"

      val_p_med <- mean(vals_p_serie, na.rm = TRUE)
      val_t_med <- mean(vals_t_serie, na.rm = TRUE)
      p_anom_pct <- if (!is.na(val_p_med) && val_p_med > 0 && !is.na(val_p_yr)) ((val_p_yr / val_p_med) - 1) * 100 else NA
      t_anom_c <- if (!is.na(val_t_med) && !is.na(val_t_yr)) val_t_yr - val_t_med else NA

      list(
        x_utm = px,
        y_utm = py,
        lon = c_wgs[1],
        lat = c_wgs[2],
        distrito = nom_dist,
        year = yr,
        p_yr = val_p_yr,
        t_yr = val_t_yr,
        p_med = val_p_med,
        t_med = val_t_med,
        p_anom_pct = p_anom_pct,
        t_anom_c = t_anom_c,
        balance = val_bal,
        eto = val_eto,
        aridez = val_arid,
        wsi = val_wsi,
        clase = val_clase,
        ndmi = val_ndmi,
        slope = val_slope,
        p_serie = vals_p_serie,
        t_serie = vals_t_serie
      )
    })

    # Renderizados de la Ficha
    output$coords_utm_txt <- renderUI({
      px <- pixel_data()
      paste0("UTM 18S: ", fmt_num(px$x_utm), " E, ", fmt_num(px$y_utm), " N")
    })

    output$coords_wgs_txt <- renderUI({
      px <- pixel_data()
      paste0("Lon: ", fmt_dec(px$lon, 4), "° | Lat: ", fmt_dec(px$lat, 4), "°")
    })

    output$distrito_hit <- renderUI({
      pixel_data()$distrito
    })

    output$badge_clase_estres <- renderUI({
      cl <- pixel_data()$clase
      cls <- switch(as.character(cl),
        "1" = "badge-stress-1",
        "2" = "badge-stress-2",
        "3" = "badge-stress-3",
        "4" = "badge-stress-4",
        "badge bg-secondary"
      )
      txt <- switch(as.character(cl),
        "1" = "Clase 1: Bajo",
        "2" = "Clase 2: Medio",
        "3" = "Clase 3: Alto",
        "4" = "Clase 4: Muy Alto",
        "Sin datos"
      )
      tags$span(class = cls, txt)
    })

    output$px_p_yr <- renderUI({
      paste0(fmt_dec(pixel_data()$p_yr, 1), " mm")
    })

    output$px_p_med <- renderUI({
      paste0(fmt_dec(pixel_data()$p_med, 1), " mm")
    })

    output$px_t_yr <- renderUI({
      paste0(fmt_dec(pixel_data()$t_yr, 1), " °C")
    })

    output$px_t_med <- renderUI({
      paste0(fmt_dec(pixel_data()$t_med, 1), " °C")
    })

    output$px_p_anom <- renderUI({
      fmt_sign(pixel_data()$p_anom_pct, 1, "%")
    })

    output$px_t_anom <- renderUI({
      fmt_sign(pixel_data()$t_anom_c, 2, "°C")
    })

    output$download_xlsx_punto <- downloadHandler(
      filename = function() {
        px <- pixel_data()
        # Se usa una identificación basada en coordenadas para evitar que
        # tildes u otras codificaciones del nombre distrital alteren el
        # encabezado HTTP de descarga en Windows.
        paste0(
          "consulta_climatica_punto_", px$year,
          "_", round(px$x_utm), "_", round(px$y_utm), ".xlsx"
        )
      },
      content = function(file) {
        req(pixel_data())
        writexl::write_xlsx(crear_hojas_descarga_punto(pixel_data()), path = file)
      },
      contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )

    output$px_balance <- renderUI({
      fmt_sign(pixel_data()$balance, 1, "mm")
    })

    output$px_eto <- renderUI({
      paste0(fmt_dec(pixel_data()$eto, 1), " mm")
    })

    output$px_aridez <- renderUI({
      fmt_dec(pixel_data()$aridez, 3)
    })

    output$px_wsi <- renderUI({
      paste0(fmt_dec(pixel_data()$wsi, 1), " / 100")
    })

    output$px_ndmi <- renderUI({
      fmt_sign(pixel_data()$ndmi, 3)
    })

    output$px_slope <- renderUI({
      paste0(fmt_dec(pixel_data()$slope, 1), "°")
    })

    # Mini-gráfico de serie en el píxel (Precipitación y Temperatura con doble eje)
    output$plot_pixel_serie <- plotly::renderPlotly({
      px <- pixel_data()
      req(px$p_serie)
      
      df_px <- data.frame(
        Year = 2001:2025,
        P_mm = px$p_serie,
        T_c  = if (!is.null(px$t_serie)) px$t_serie else rep(NA_real_, 25)
      )

      if (all(is.na(df_px$P_mm)) && all(is.na(df_px$T_c))) {
        return(NULL)
      }

      yr_sel <- px$year
      df_sel <- df_px |> dplyr::filter(Year == yr_sel)

      p <- plotly::plot_ly(data = df_px) |>
        plotly::add_trace(
          x = ~Year,
          y = ~P_mm,
          name = "Lluvia (mm)",
          type = "scatter",
          mode = "lines+markers",
          line = list(color = "#0284c7", width = 2),
          marker = list(color = "#0284c7", size = 4),
          hovertemplate = "%{y:.1f} mm"
        ) |>
        plotly::add_trace(
          x = ~Year,
          y = ~T_c,
          name = "Temp. (°C)",
          yaxis = "y2",
          type = "scatter",
          mode = "lines+markers",
          line = list(color = "#ea580c", width = 2),
          marker = list(color = "#ea580c", size = 4),
          hovertemplate = "%{y:.2f} °C"
        )

      # Destacar el año seleccionado con marcador para cada variable
      if (nrow(df_sel) > 0) {
        if (!is.na(df_sel$P_mm[1])) {
          p <- p |>
            plotly::add_markers(
              data = df_sel,
              x = ~Year,
              y = ~P_mm,
              marker = list(color = "#0284c7", size = 8, line = list(color = "#ffffff", width = 1.5)),
              showlegend = FALSE,
              hoverinfo = "skip"
            )
        }
        if (!is.na(df_sel$T_c[1])) {
          p <- p |>
            plotly::add_markers(
              data = df_sel,
              x = ~Year,
              y = ~T_c,
              yaxis = "y2",
              marker = list(color = "#ea580c", size = 8, line = list(color = "#ffffff", width = 1.5)),
              showlegend = FALSE,
              hoverinfo = "skip"
            )
        }
      }

      # Configuración de layout con doble eje Y (izq: mm, der: °C)
      p |>
        plotly::layout(
          hovermode = "x unified",
          shapes = list(
            list(
              type = "line",
              x0 = yr_sel,
              x1 = yr_sel,
              y0 = 0,
              y1 = 1,
              yref = "paper",
              line = list(color = "#cbd5e1", width = 1.5, dash = "dot")
            )
          ),
          xaxis = list(
            title = "",
            dtick = 4,
            gridcolor = "#f1f5f9",
            tickfont = list(family = "Inter, sans-serif", size = 8)
          ),
          yaxis = list(
            title = list(text = "mm", font = list(family = "Inter, sans-serif", size = 8.5, color = "#0284c7")),
            tickfont = list(family = "Inter, sans-serif", size = 8, color = "#0284c7"),
            gridcolor = "#f1f5f9",
            zeroline = FALSE
          ),
          yaxis2 = list(
            title = list(text = "°C", font = list(family = "Inter, sans-serif", size = 8.5, color = "#ea580c")),
            tickfont = list(family = "Inter, sans-serif", size = 8, color = "#ea580c"),
            overlaying = "y",
            side = "right",
            showgrid = FALSE,
            zeroline = FALSE
          ),
          legend = list(
            orientation = "h",
            x = 0.5,
            xanchor = "center",
            y = 1.22,
            font = list(family = "Inter, sans-serif", size = 8.5),
            bgcolor = "rgba(0,0,0,0)"
          ),
          margin = list(l = 38, r = 38, t = 30, b = 25),
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor = "rgba(0,0,0,0)",
          font = list(family = "Inter, sans-serif", size = 9)
        ) |>
        plotly::config(displayModeBar = FALSE)
    })

    # Inicializar mapa del inspector
    output$mapa_inspector <- leaflet::renderLeaflet({
      leaflet::leaflet() |>
        leaflet::addProviderTiles(leaflet::providers$OpenStreetMap, group = "OpenStreetMap") |>
        leaflet::addProviderTiles(leaflet::providers$Esri.WorldImagery, group = "Satélite") |>
        leaflet::fitBounds(lng1 = -73.01, lat1 = -13.73, lng2 = -71.99, lat2 = -13.20) |>
        leaflet::addLayersControl(
          baseGroups = c("OpenStreetMap", "Satélite"),
          options = leaflet::layersControlOptions(collapsed = TRUE)
        )
    })

    mapa_listo <- reactiveVal(FALSE)
    session$onFlushed(function() mapa_listo(TRUE), once = TRUE)

    # Actualizar marcador del punto consultado y polígonos
    observe({
      req(mapa_listo())
      px   <- pixel_data()
      sf_d <- sf_distritos_wgs84()
      r_d  <- r_disp_wgs84()
      req(px, sf_d, r_d)

      wsi_raster <- r_d[["Prob_Estres_Hidrico_pct"]]
      wsi_vals <- terra::values(wsi_raster, na.rm = TRUE)
      wsi_vals <- wsi_vals[is.finite(wsi_vals)]
      req(length(wsi_vals) > 0)

      pal_wsi <- leaflet::colorNumeric(
        palette = c("#10b981", "#fef08a", "#f97316", "#ef4444"),
        domain = range(c(0, 90, wsi_vals)),
        na.color = "transparent"
      )

      output$mapa_inspector <- leaflet::renderLeaflet({
        leaflet::leaflet() |>
        leaflet::addProviderTiles(leaflet::providers$OpenStreetMap, group = "OpenStreetMap") |>
        leaflet::addProviderTiles(leaflet::providers$Esri.WorldImagery, group = "Satélite") |>
        leaflet::fitBounds(lng1 = -73.01, lat1 = -13.73, lng2 = -71.99, lat2 = -13.20) |>
        leaflet::addLayersControl(
          baseGroups = c("OpenStreetMap", "Satélite"),
          options = leaflet::layersControlOptions(collapsed = TRUE)
        ) |>
        leaflet::addRasterImage(
          wsi_raster,
          colors = pal_wsi,
          opacity = 0.65,
          project = FALSE
        ) |>
        leaflet::addPolygons(
          data = sf_d,
          fillColor = "transparent",
          color = "#072238",
          weight = 1.5,
          opacity = 0.8,
          label = ~NOMBDIST
        ) |>
        leaflet::addCircleMarkers(
          lng = px$lon,
          lat = px$lat,
          radius = 7,
          color = "#ffffff",
          weight = 2,
          fillColor = "#ef4444",
          fillOpacity = 1,
          popup = paste0("<b>Punto Seleccionado</b><br>Distrito: ", px$distrito, "<br>Lluvia: ", fmt_dec(px$p_yr, 1), " mm<br>Temp.: ", fmt_dec(px$t_yr, 1), " °C")
        )
      })
    })
  })
}
