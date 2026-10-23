# ==============================================================================
# MOD_CLIMA_ANUAL.R: Mapa Climático Anual, Anomalías y Rankings
# ==============================================================================

mod_clima_anual_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    div(
      class = "row g-3 mb-3",
      # Controles del mapa
      div(
        class = "col-lg-8 col-md-12",
        div(
          class = "control-panel",
          div(
            class = "d-flex justify-content-between align-items-center mb-2",
            div(class = "control-panel-title m-0", icon("globe-americas"), " Dinámica Cartográfica Anual (2001–2025)"),
            tags$span(class = "temporal-type-badge badge-anual-dynamic", icon("sync-alt"), "Selector de Año Exclusivo")
          ),
          div(
            class = "row g-2 align-items-center",
            div(
              class = "col-md-4 col-sm-6",
              sliderInput(
                ns("sel_year"),
                label = "Año de Evaluación:",
                min = 2001, max = 2025, value = 2024, step = 1, sep = "",
                width = "100%"
              )
            ),
            div(
              class = "col-md-5 col-sm-6",
              selectInput(
                ns("sel_indicador"),
                label = "Indicador Cartográfico Anual:",
                choices = c(
                  "Precipitación Anual (mm/año)"          = "p_anual",
                  "Temperatura Media Anual (°C)"         = "t_anual",
                  "Anomalía de Precipitación (mm)"       = "p_anom_mm",
                  "Anomalía Porcentual de Lluvia (%)"    = "p_anom_pct",
                  "Anomalía Térmica (°C)"                = "t_anom_c"
                ),
                selected = "p_anom_pct",
                width = "100%"
              )
            ),
            div(
              class = "col-md-3 col-sm-12",
              sliderInput(
                ns("sel_opacity"),
                label = "Opacidad Capa:",
                min = 0.2, max = 1.0, value = 0.95, step = 0.05,
                width = "100%"
              )
            )
          )
        )
      ),
      # Resumen rápido del año seleccionado
      div(
        class = "col-lg-4 col-md-12",
        div(
          class = "control-panel h-100 d-flex flex-column justify-content-center",
          div(class = "control-panel-title", icon("info-circle"), " Síntesis Provincial del Año"),
          div(
            class = "d-flex justify-content-around text-center mt-1",
            div(
              tags$span(class = "text-muted small d-block", "Lluvia Media"),
              tags$h5(class = "fw-bold text-primary m-0", uiOutput(ns("prov_p_val")))
            ),
            div(class = "vr mx-2"),
            div(
              tags$span(class = "text-muted small d-block", "Temp. Media"),
              tags$h5(class = "fw-bold text-danger m-0", uiOutput(ns("prov_t_val")))
            ),
            div(class = "vr mx-2"),
            div(
              tags$span(class = "text-muted small d-block", "Carácter Anual"),
              tags$h6(class = "fw-bold m-0", uiOutput(ns("prov_caracter")))
            )
          )
        )
      )
    ),

    # Fila Principal: Mapa + Ranking y Semáforo
    div(
      class = "row g-3",
      # Mapa Interactivo Leaflet
      div(
        class = "col-lg-8 col-md-12",
        div(
          class = "content-card p-0",
          div(
            class = "p-3 pb-2 d-flex justify-content-between align-items-center border-bottom",
            div(
              tags$h6(class = "content-card-title", icon("map"), uiOutput(ns("map_title"))),
              tags$span(class = "content-card-subtitle", "Raster corregido con PISCO-SENAMHI (malla agregada para visor web continuo)")
            ),
            tags$span(class = "badge bg-light text-dark border", "EPSG:4326 / 32718")
          ),
          div(
            class = "map-container-wrapper",
            leaflet::leafletOutput(ns("mapa_clima"), height = "560px")
          )
        )
      ),

      # Paneles Analíticos Laterales: Ranking y Semáforo Anual
      div(
        class = "col-lg-4 col-md-12",
        div(
          class = "d-flex flex-column gap-3",
          # Ranking Distrital Anual
          div(
            class = "content-card m-0",
            div(
              class = "content-card-header mb-2",
              tags$h6(class = "content-card-title", icon("sort-amount-down"), " Ranking Distrital del Año"),
              tags$span(class = "content-card-subtitle", "Valores promedios zonales para los 9 distritos")
            ),
            plotly::plotlyOutput(ns("plot_ranking_anual"), height = "280px")
          ),
          # Semáforo y Percentil Anual por Distrito
          div(
            class = "content-card m-0",
            div(
              class = "content-card-header mb-2",
              tags$h6(class = "content-card-title", icon("traffic-light"), " Semáforo Climático del Año"),
              tags$span(class = "content-card-subtitle", "Posición relativa dentro de la serie 2001–2025")
            ),
            div(
              style = "max-height: 220px; overflow-y: auto;",
              uiOutput(ns("lista_semaforos"))
            )
          )
        )
      )
    )
  )
}

mod_clima_anual_server <- function(id, data_series, data_resumen, sf_distritos_wgs84, r_p_wgs84, r_t_wgs84, r_disp_wgs84) {
  moduleServer(id, function(input, output, session) {
    
    # Datos provinciales reactivos para el año seleccionado
    prov_data <- reactive({
      req(data_series(), input$sel_year)
      yr <- as.integer(input$sel_year)
      data_series() |> filter(NOMBDIST == "PROVINCIA DE ANTA", Year == yr)
    })

    output$prov_p_val <- renderUI({
      pd <- prov_data()
      if (nrow(pd) == 0) return("--")
      paste0(fmt_dec(pd$Precipitacion_mm, 1), " mm")
    })

    output$prov_t_val <- renderUI({
      pd <- prov_data()
      if (nrow(pd) == 0) return("--")
      paste0(fmt_dec(pd$Temperatura_C, 1), " °C")
    })

    output$prov_caracter <- renderUI({
      pd <- prov_data()
      if (nrow(pd) == 0) return("--")
      tagList(
        tags$span(class = "badge bg-info text-dark d-block mb-1", pd$P_semaforo),
        tags$span(class = "badge bg-warning text-dark d-block", pd$T_semaforo)
      )
    })

    output$map_title <- renderUI({
      yr <- input$sel_year
      ind <- input$sel_indicador
      ind_txt <- switch(ind,
        "p_anual"    = "Precipitación Acumulada Anual",
        "t_anual"    = "Temperatura Media Anual",
        "p_anom_mm"  = "Anomalía Absoluta de Precipitación (mm)",
        "p_anom_pct" = "Anomalía Porcentual de Lluvia (%)",
        "t_anom_c"   = "Anomalía Térmica (°C)",
        "Indicador Climático"
      )
      paste0(ind_txt, " — Año ", yr)
    })

    # Raster reactivo para el mapa
    capa_raster <- reactive({
      req(r_p_wgs84(), r_t_wgs84(), r_disp_wgs84(), input$sel_year, input$sel_indicador)
      yr <- as.integer(input$sel_year)
      ind <- input$sel_indicador
      
      b_p_name <- paste0("P_", yr)
      b_t_name <- paste0("T_", yr)
      
      r_p_yr   <- r_p_wgs84()[[b_p_name]]
      r_t_yr   <- r_t_wgs84()[[b_t_name]]
      r_p_med  <- r_disp_wgs84()[["P_media"]]
      r_t_med  <- r_disp_wgs84()[["T_media"]]

      switch(ind,
        "p_anual"    = list(raster = r_p_yr, tipo = "seq_p", title = "Precipitación (mm)", unit = "mm"),
        "t_anual"    = list(raster = r_t_yr, tipo = "seq_t", title = "Temperatura (°C)", unit = "°C"),
        "p_anom_mm"  = list(raster = r_p_yr - r_p_med, tipo = "div_p", title = "Anomalía Lluvia (mm)", unit = "mm"),
        "p_anom_pct" = list(raster = ((r_p_yr / r_p_med) - 1) * 100, tipo = "div_p_pct", title = "Anom. Lluvia (%)", unit = "%"),
        "t_anom_c"   = list(raster = r_t_yr - r_t_med, tipo = "div_t", title = "Anom. Térmica (°C)", unit = "°C")
      )
    })

    # Inicializar mapa base Leaflet una sola vez
    output$mapa_clima <- leaflet::renderLeaflet({
      leaflet::leaflet() |>
        leaflet::addProviderTiles(leaflet::providers$OpenStreetMap, group = "OpenStreetMap") |>
        leaflet::addProviderTiles(leaflet::providers$Esri.WorldImagery, group = "Satélite Esri") |>
        leaflet::fitBounds(lng1 = -73.01, lat1 = -13.73, lng2 = -71.99, lat2 = -13.20) |>
        leaflet::addLayersControl(
          baseGroups = c("OpenStreetMap", "Satélite Esri"),
          options = leaflet::layersControlOptions(collapsed = TRUE)
        )
    })

    # La primera carga de los inputs puede ocurrir antes de que el navegador
    # haya creado el objeto Leaflet. Diferimos el proxy al siguiente flush para
    # que las capas iniciales no se pierdan.
    mapa_listo <- reactiveVal(FALSE)
    session$onFlushed(function() mapa_listo(TRUE), once = TRUE)

    # Actualizar capa ráster y geometrías reactivamente
    observe({
      req(mapa_listo())
      capa <- capa_raster()
      sf_d <- sf_distritos_wgs84()
      ser  <- data_series()
      yr   <- as.integer(input$sel_year)
      op   <- input$sel_opacity
      ind  <- input$sel_indicador

      req(capa, sf_d, ser)

      # Vincular valores del año seleccionado a los distritos
      ser_yr <- ser |> filter(Year == yr, NOMBDIST != "PROVINCIA DE ANTA")
      sf_join <- sf_d |>
        left_join(ser_yr |> select(NOMBDIST, Precipitacion_mm, Temperatura_C, P_anomalia_pct, T_anomalia_C, P_semaforo, T_semaforo), by = "NOMBDIST")

      # Configurar paleta de colores según el indicador
      r_obj <- capa$raster
      r_vals <- terra::values(r_obj, na.rm = TRUE)
      r_vals <- r_vals[is.finite(r_vals)]
      req(length(r_vals) > 0)
      r_range <- range(r_vals)
      p_domain <- range(c(350, 1600, r_range))
      t_domain <- range(c(3, 22, r_range))
      # Para anomalías, una escala fija muy amplia vuelve imperceptibles las
      # variaciones anuales locales. Se conserva una amplitud mínima útil y
      # se adapta al rango observado del ráster seleccionado.
      p_anom_limit <- max(75, abs(r_range))
      p_anom_pct_limit <- max(12, abs(r_range))
      t_anom_limit <- max(2, abs(r_range))
      
      pal <- switch(capa$tipo,
        "seq_p" = leaflet::colorNumeric(palette = "YlGnBu", domain = p_domain, na.color = "transparent"),
        "seq_t" = leaflet::colorNumeric(palette = rev(c("#a50026", "#d73027", "#f46d43", "#fdae61", "#fee090", "#e0f3f8", "#abd9e9", "#74add1", "#4575b4", "#313695")), domain = t_domain, na.color = "transparent"),
        "div_p" = leaflet::colorNumeric(palette = c("#b2182b", "#d6604d", "#f4a582", "#fddbc7", "#f7f7f7", "#d1e5f0", "#92c5de", "#4393c3", "#2166ac"), domain = c(-p_anom_limit, p_anom_limit), na.color = "transparent"),
        "div_p_pct" = leaflet::colorNumeric(palette = c("#b2182b", "#d6604d", "#f4a582", "#fddbc7", "#f7f7f7", "#d1e5f0", "#92c5de", "#4393c3", "#2166ac"), domain = c(-p_anom_pct_limit, p_anom_pct_limit), na.color = "transparent"),
        "div_t" = leaflet::colorNumeric(palette = c("#2166ac", "#4393c3", "#92c5de", "#d1e5f0", "#f7f7f7", "#fddbc7", "#f4a582", "#d6604d", "#b2182b"), domain = c(-t_anom_limit, t_anom_limit), na.color = "transparent")
      )

      # Popups y Tooltips vectoriales
      popup_content <- paste0(
        "<div style='font-family:Inter,sans-serif; min-width:180px;'>",
        "<h6 style='font-weight:700; color:#0b3b60; margin-bottom:4px;'>", sf_join$NOMBDIST, "</h6>",
        "<span style='font-size:11px; color:#64748b; font-weight:600;'>Año: ", yr, "</span><hr style='margin:4px 0;'>",
        "<div style='font-size:12px; line-height:1.4;'>",
        "<b>Lluvia:</b> ", fmt_dec(sf_join$Precipitacion_mm, 1), " mm (", fmt_sign(sf_join$P_anomalia_pct, 1, "%"), ")<br>",
        "<b>Temperatura:</b> ", fmt_dec(sf_join$Temperatura_C, 1), " °C (", fmt_sign(sf_join$T_anomalia_C, 2, "°C"), ")<br>",
        "<b>Condición:</b> <span class='badge bg-primary'>", sf_join$P_semaforo, "</span>",
        "</div></div>"
      )

      # Renderizar el mapa completo, no sólo un proxy. Esto incrusta la imagen
      # del ráster en la respuesta del output y evita perderla al abrir pestañas.
      output$mapa_clima <- leaflet::renderLeaflet({
        leaflet::leaflet() |>
        leaflet::addProviderTiles(leaflet::providers$OpenStreetMap, group = "OpenStreetMap") |>
        leaflet::addProviderTiles(leaflet::providers$Esri.WorldImagery, group = "Satélite Esri") |>
        leaflet::fitBounds(lng1 = -73.01, lat1 = -13.73, lng2 = -71.99, lat2 = -13.20) |>
        leaflet::addLayersControl(
          baseGroups = c("OpenStreetMap", "Satélite Esri"),
          options = leaflet::layersControlOptions(collapsed = TRUE)
        ) |>
        leaflet::addRasterImage(
          r_obj,
          colors = pal,
          opacity = op,
          project = FALSE,
          group = "Capa Climática"
        ) |>
        leaflet::addPolygons(
          data = sf_join,
          fillColor = "transparent",
          color = "#072238",
          weight = 1.8,
          opacity = 0.9,
          dashArray = "2",
          highlightOptions = leaflet::highlightOptions(
            weight = 3.5,
            color = "#0284c7",
            fillOpacity = 0.1,
            bringToFront = TRUE
          ),
          popup = popup_content,
          label = paste0(sf_join$NOMBDIST, " (", yr, ")"),
          labelOptions = leaflet::labelOptions(
            style = list("font-weight" = "600", "font-family" = "Inter, sans-serif"),
            direction = "auto"
          )
        ) |>
        leaflet::addLegend(
          position = "bottomleft",
          pal = pal,
          values = switch(capa$tipo,
            "seq_p" = p_domain,
            "seq_t" = t_domain,
            "div_p" = c(-p_anom_limit, p_anom_limit),
            "div_p_pct" = c(-p_anom_pct_limit, p_anom_pct_limit),
            "div_t" = c(-t_anom_limit, t_anom_limit)
          ),
          title = capa$title,
          labFormat = leaflet::labelFormat(suffix = paste0(" ", capa$unit)),
          opacity = 0.9
        )
      })
    })

    # Ranking Distrital Anual con Plotly
    output$plot_ranking_anual <- plotly::renderPlotly({
      req(data_series(), input$sel_year, input$sel_indicador)
      yr <- as.integer(input$sel_year)
      ind <- input$sel_indicador
      
      df_yr <- data_series() |>
        filter(Year == yr, NOMBDIST != "PROVINCIA DE ANTA")

      meta <- switch(ind,
        "p_anual"    = list(col = "Precipitacion_mm", name = "Precipitación Anual (mm)", color = "#0284c7"),
        "t_anual"    = list(col = "Temperatura_C", name = "Temperatura Media (°C)", color = "#ea580c"),
        "p_anom_mm"  = list(col = "P_anomalia_mm", name = "Anomalía Lluvia (mm)", color = "#06b6d4"),
        "p_anom_pct" = list(col = "P_anomalia_pct", name = "Anomalía Lluvia (%)", color = "#0284c7"),
        "t_anom_c"   = list(col = "T_anomalia_C", name = "Anomalía Térmica (°C)", color = "#f97316")
      )

      df_plot <- df_yr |>
        mutate(valor = .data[[meta$col]]) |>
        arrange(valor) |>
        mutate(distrito = factor(NOMBDIST, levels = NOMBDIST))

      plotly::plot_ly(
        data = df_plot,
        y = ~distrito,
        x = ~round(valor, 1),
        type = "bar",
        orientation = "h",
        marker = list(
          color = if (grepl("anom", ind)) {
            ifelse(df_plot[[meta$col]] >= 0, "#0284c7", "#ef4444")
          } else {
            meta$color
          },
          line = list(color = "#ffffff", width = 1)
        ),
        text = ~round(valor, 1),
        textposition = "auto",
        hovertemplate = paste0("<b>%{y}</b><br>", meta$name, ": %{x}<extra></extra>")
      ) |>
        plotly::layout(
          xaxis = list(title = meta$name, gridcolor = "#f1f5f9"),
          yaxis = list(title = ""),
          margin = list(l = 10, r = 20, t = 10, b = 35),
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor = "rgba(0,0,0,0)",
          font = list(family = "Inter, sans-serif", size = 11)
        ) |>
        plotly::config(displayModeBar = FALSE)
    })

    # Lista con Semáforo y Percentiles de los 9 distritos
    output$lista_semaforos <- renderUI({
      req(data_series(), input$sel_year)
      yr <- as.integer(input$sel_year)
      
      df_sem <- data_series() |>
        filter(Year == yr, NOMBDIST != "PROVINCIA DE ANTA") |>
        arrange(desc(P_anomalia_pct))

      tagList(
        lapply(1:nrow(df_sem), function(i) {
          row <- df_sem[i, ]
          cls_p <- if (row$P_anomalia_pct >= 5) "text-success" else if (row$P_anomalia_pct <= -10) "text-danger" else "text-muted"
          div(
            class = "d-flex justify-content-between align-items-center py-1 border-bottom",
            div(
              tags$strong(class = "small", row$NOMBDIST),
              tags$span(class = "text-muted small d-block", paste0("Lluvia: ", fmt_dec(row$Precipitacion_mm, 0), " mm"))
            ),
            div(
              class = "text-end",
              tags$span(class = paste0("fw-bold small ", cls_p), fmt_sign(row$P_anomalia_pct, 1, "%")),
              tags$span(class = "badge bg-light text-dark border d-block mt-1", style = "font-size:0.68rem;", row$P_semaforo)
            )
          )
        })
      )
    })
  })
}
