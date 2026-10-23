# ==============================================================================
# MOD_BALANCE_ARIDEZ.R: Balance Hídrico, Aridez y Diagnóstico Multianual (30m)
# ==============================================================================

mod_balance_aridez_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    div(
      class = "row g-3",
      
      # ========================================================================
      # COLUMNA IZQUIERDA: COMPONENTE DE MAPAS Y SELECTOR TEMÁTICO (POLÍGONO VERDE)
      # ========================================================================
      div(
        class = "col-lg-7 col-md-12",
        div(
          class = "content-card p-0 h-100 d-flex flex-column",
          
          # Cabecera integrada con Selector de Capa Temática
          div(
            class = "p-3 pb-2 border-bottom bg-light",
            div(
              class = "d-flex justify-content-between align-items-center mb-2 flex-wrap gap-2",
              div(
                class = "content-card-title m-0",
                icon("tint", class = "text-primary me-1"),
                tags$strong("Explorador Cartográfico Biofísico (mapa ~150 m)")
              ),
              tags$span(class = "temporal-type-badge badge-multianual-synth", icon("cube"), "Síntesis Multianual 2001–2025")
            ),
            div(
              class = "row g-2 align-items-center",
              div(
                class = "col-12",
                selectInput(
                  ns("sel_capa_hidro"),
                  label = tags$span(icon("layer-group"), " Capa Temática de Balance y Estrés:"),
                  choices = c(
                    "Categorías de Estrés Hídrico (Clases 1–4)"  = "clases_estres",
                    "Diferencia climática P − ETo (mm/año)" = "bal_p_pet",
                    "Índice de Aridez UNESCO (P / ETo)"          = "aridez_unesco",
                    "Índice relativo de susceptibilidad hídrica (WSI 0–100)" = "wsi_pct",
                    "ETo climatológica ajustada por temperatura" = "eto_pm",
                    "Índice de Humedad NDMI (Sentinel-2)"        = "ndmi"
                  ),
                  selected = "clases_estres",
                  width = "100%"
                )
              )
            ),
            div(
              class = "d-flex justify-content-between align-items-center mt-1 flex-wrap gap-1",
              tags$span(class = "text-muted small", icon("info-circle"), " ", uiOutput(ns("map_hidro_title"), inline = TRUE)),
              tags$span(class = "badge bg-white text-dark border", "PISCOeo_pm / Sentinel-2 / SRTM · mapa ~150 m")
            )
          ),
          
          # Contenedor del Mapa Leaflet
          div(
            class = "map-container-wrapper flex-grow-1",
            leaflet::leafletOutput(ns("mapa_hidro"), height = "610px")
          )
        )
      ),

      # ========================================================================
      # COLUMNA DERECHA: COMPONENTE DINÁMICO (ROJO) + GRÁFICOS FIJOS (AMARILLO)
      # ========================================================================
      div(
        class = "col-lg-5 col-md-12",
        div(
          class = "d-flex flex-column gap-3",
          
          # 1. COMPONENTE DINÁMICO TERRITORIAL (POLÍGONO ROJO)
          div(
            class = "control-panel mb-0",
            div(
              class = "d-flex justify-content-between align-items-center mb-2",
              div(
                class = "control-panel-title m-0",
                icon("city", class = "text-primary me-1"),
                "Diagnóstico Territorial por Distrito"
              ),
              uiOutput(ns("badge_estres_territorial"))
            ),
            div(
              class = "mb-2",
              selectInput(
                ns("sel_distrito"),
                label = tags$span(icon("map-marker-alt"), " Territorio para Ficha de Detalle:"),
                choices = c("PROVINCIA DE ANTA", "ANCAHUASI", "ANTA", "CACHIMAYO", 
                            "CHINCHAYPUJIO", "HUAROCONDO", "LIMATAMBO", "MOLLEPATA", 
                            "PUCYURA", "ZURITE"),
                selected = "CHINCHAYPUJIO",
                width = "100%"
              )
            ),
            div(
              class = "p-2 bg-light rounded border",
              div(
                class = "d-flex justify-content-around text-center py-1",
                div(
                  tags$span(class = "text-muted small d-block", "Área en Clase 3 y 4"),
                  tags$h5(class = "fw-bold text-danger m-0", uiOutput(ns("val_ha_critica")))
                ),
                div(class = "vr mx-2"),
                div(
                  tags$span(class = "text-muted small d-block", "% en clases 3 y 4"),
                  tags$h5(class = "fw-bold text-danger m-0", uiOutput(ns("val_pct_critica")))
                ),
                div(class = "vr mx-2"),
                div(
                  tags$span(class = "text-muted small d-block", "Diferencia P − ETo"),
                  tags$h5(class = "fw-bold text-primary m-0", uiOutput(ns("val_deficit_neto")))
                )
              )
            )
          ),

          # 2. COMPONENTE DE GRÁFICOS FIJOS COMPARATIVOS PROVINCIALES (POLÍGONO AMARILLO)
          div(
            class = "content-card m-0 p-3",
            div(
              class = "content-card-header pb-2 mb-2",
              div(
                tags$h6(class = "content-card-title", icon("chart-bar"), " Diagnóstico Comparativo Provincial (Fijo)"),
                tags$span(class = "content-card-subtitle", "Evaluación estructural multianual de los 9 distritos")
              ),
              tags$span(class = "badge bg-secondary", "Estructural")
            ),
            navset_pill(
              id = ns("nav_graficos_fijos"),
              nav_panel(
                title = tags$span(icon("layer-group"), " % Superficie en Estrés"),
                div(
                  class = "pt-2",
                  tags$p(class = "text-muted small mb-1", "Descomposición territorial de Clases 1 a 4 por distrito a resolución de 30 m:"),
                  plotly::plotlyOutput(ns("plot_barras_apiladas"), height = "360px")
                )
              ),
              nav_panel(
                title = tags$span(icon("sort-numeric-down"), " Comparación P − ETo"),
                div(
                  class = "pt-2",
                  tags$p(class = "text-muted small mb-1", "Diferencia climática anual (P − ETo, mm/año); no representa disponibilidad de agua:"),
                  plotly::plotlyOutput(ns("plot_ranking_deficit"), height = "360px")
                )
              )
            )
          )
        )
      )
    )
  )
}

mod_balance_aridez_server <- function(id, data_resumen, sf_distritos_wgs84, r_disp_wgs84) {
  moduleServer(id, function(input, output, session) {
    
    # Fila territorial seleccionada
    territorio_sel <- reactive({
      req(data_resumen(), input$sel_distrito)
      dist_sel <- input$sel_distrito
      row_m <- data_resumen() |> filter(NOMBDIST == dist_sel)
      if (nrow(row_m) == 0) row_m <- data_resumen() |> filter(NOMBDIST == "PROVINCIA DE ANTA")
      row_m[1, ]
    })

    output$badge_estres_territorial <- renderUI({
      row <- territorio_sel()
      cls <- switch(row$WSI_Cat,
        "Bajo" = "badge-stress-1",
        "Medio" = "badge-stress-2",
        "Alto" = "badge-stress-3",
        "Muy Alto" = "badge-stress-4",
        "bg-secondary"
      )
      tags$span(class = cls, paste0("WSI: ", row$WSI_Cat))
    })

    output$val_ha_critica <- renderUI({
      row <- territorio_sel()
      paste0(fmt_num(row$Ha_Clase3_4), " ha")
    })

    output$val_pct_critica <- renderUI({
      row <- territorio_sel()
      fmt_pct(row$Pct_Clase3_4, 1)
    })

    output$val_deficit_neto <- renderUI({
      row <- territorio_sel()
      paste0(fmt_dec(row$Balance_Hidrico_P_PET_mm, 1), " mm")
    })

    output$map_hidro_title <- renderUI({
      capa_id <- input$sel_capa_hidro
      switch(capa_id,
        "bal_p_pet"      = "Mapa de Balance Hídrico Climático (P − ETo)",
        "aridez_unesco"  = "Mapa del Índice de Aridez UNESCO (P / ETo)",
        "wsi_pct"        = "Mapa de susceptibilidad hídrica relativa (WSI 0–100)",
        "clases_estres"  = "Mapa de Clases de Estrés Hídrico (1 a 4)",
        "eto_pm"         = "ETo climatológica ajustada por temperatura",
        "ndmi"           = "Índice de Humedad de Superficie NDMI (Sentinel-2)",
        "Diagnóstico Hidroclimático"
      )
    })

    # Capa ráster reactiva para Leaflet
    capa_hidro_raster <- reactive({
      req(r_disp_wgs84(), input$sel_capa_hidro)
      r_disp <- r_disp_wgs84()
      capa_id <- input$sel_capa_hidro

      switch(capa_id,
        "bal_p_pet"     = list(r = r_disp[["Balance_Hidrico_P_PET_mm"]], tipo = "balance", title = "Balance (mm/año)"),
        "aridez_unesco" = list(r = r_disp[["Indice_Aridez_UNESCO"]], tipo = "aridez", title = "Índice Aridez"),
        "wsi_pct"       = list(r = r_disp[["Prob_Estres_Hidrico_pct"]], tipo = "wsi", title = "WSI (0–100)"),
        "clases_estres" = list(r = r_disp[["Clase_Estres_Hidrico"]], tipo = "clases", title = "Clase de Estrés"),
        "eto_pm"        = list(r = r_disp[["ETo_PenmanMonteith_mm"]], tipo = "eto", title = "ETo (mm/año)"),
        "ndmi"          = list(r = r_disp[["ndmi"]], tipo = "ndmi", title = "NDMI")
      )
    })

    # Inicializar mapa base Leaflet
    output$mapa_hidro <- leaflet::renderLeaflet({
      leaflet::leaflet() |>
        leaflet::addProviderTiles(leaflet::providers$OpenStreetMap, group = "OpenStreetMap") |>
        leaflet::addProviderTiles(leaflet::providers$Esri.WorldImagery, group = "Satélite Esri") |>
        leaflet::fitBounds(lng1 = -73.01, lat1 = -13.73, lng2 = -71.99, lat2 = -13.20) |>
        leaflet::addLayersControl(
          baseGroups = c("OpenStreetMap", "Satélite Esri"),
          options = leaflet::layersControlOptions(collapsed = TRUE)
        )
    })

    mapa_listo <- reactiveVal(FALSE)
    session$onFlushed(function() mapa_listo(TRUE), once = TRUE)

    # Actualizar ráster y vectores de balance hídrico
    observe({
      req(mapa_listo())
      capa <- capa_hidro_raster()
      sf_d <- sf_distritos_wgs84()
      res  <- data_resumen()
      req(capa, sf_d, res)

      r_obj <- capa$r
      r_vals <- terra::values(r_obj, na.rm = TRUE)
      r_vals <- r_vals[is.finite(r_vals)]
      req(length(r_vals) > 0)
      r_range <- range(r_vals)

      # Unir datos de resumen con sf para tooltips enriquecidos
      sf_join <- sf_d |>
        left_join(res |> filter(NOMBDIST != "PROVINCIA DE ANTA"), by = "NOMBDIST")

      # Paleta según la naturaleza biofísica de la variable
      if (capa$tipo == "balance") {
        # Cero como umbral central (negativo = rojo/déficit, positivo = azul/superávit)
        pal <- leaflet::colorNumeric(
          palette = c("#b91c1c", "#ea580c", "#fef08a", "#38bdf8", "#0284c7"),
          domain = range(c(-1000, 300, r_range)),
          na.color = "transparent"
        )
        legend_vals <- range(c(-1000, 300, r_range))
      } else if (capa$tipo == "aridez") {
        # Clasificación UNESCO: semiárido (<0.50), subhúmedo seco (0.50-0.65), húmedo (>0.65)
        pal <- leaflet::colorNumeric(
          palette = c("#d97706", "#fef08a", "#a7f3d0", "#059669"),
          domain = range(c(0.25, 1.45, r_range)),
          na.color = "transparent"
        )
        legend_vals <- range(c(0.25, 1.45, r_range))
      } else if (capa$tipo == "clases") {
        # 1 a 4 discreto
        pal <- leaflet::colorFactor(
          palette = c("#10b981", "#f59e0b", "#f97316", "#ef4444"),
          domain = 1:4,
          na.color = "transparent"
        )
        legend_vals <- 1:4
      } else if (capa$tipo == "wsi") {
        pal <- leaflet::colorNumeric(
          palette = c("#10b981", "#fef08a", "#f97316", "#ef4444", "#7f1d1d"),
          domain = range(c(0, 90, r_range)),
          na.color = "transparent"
        )
        legend_vals <- range(c(0, 90, r_range))
      } else if (capa$tipo == "eto") {
        pal <- leaflet::colorNumeric(
          palette = "YlOrRd",
          domain = range(c(650, 1700, r_range)),
          na.color = "transparent"
        )
        legend_vals <- range(c(650, 1700, r_range))
      } else { # ndmi
        pal <- leaflet::colorNumeric(
          palette = "BrBG",
          domain = range(c(-0.12, 0.01, r_range)),
          na.color = "transparent"
        )
        legend_vals <- range(c(-0.12, 0.01, r_range))
      }

      popup_content <- paste0(
        "<div style='font-family:Inter,sans-serif; min-width:190px;'>",
        "<h6 style='font-weight:700; color:#0b3b60; margin-bottom:4px;'>", sf_join$NOMBDIST, "</h6>",
        "<span style='font-size:11px; color:#64748b; font-weight:600;'>Síntesis Multianual (30 m)</span><hr style='margin:4px 0;'>",
        "<div style='font-size:12px; line-height:1.4;'>",
        "<b>Balance Hídrico:</b> ", fmt_dec(sf_join$Balance_Hidrico_P_PET_mm, 1), " mm/año<br>",
        "<b>Índice Aridez:</b> ", fmt_dec(sf_join$Indice_Aridez_UNESCO, 3), " (", sf_join$Aridez_Cat, ")<br>",
        "<b>WSI (0–100):</b> ", fmt_dec(sf_join$Prob_Estres_Hidrico_pct, 1), " (", sf_join$WSI_Cat, ")<br>",
        "<b>Área Crítica (Clases 3-4):</b> ", fmt_pct(sf_join$Pct_Clase3_4, 1), " (", fmt_num(sf_join$Ha_Clase3_4), " ha)",
        "</div></div>"
      )

      output$mapa_hidro <- leaflet::renderLeaflet({
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
          opacity = 0.82,
          project = FALSE,
          group = "Capa Biofísica"
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
          label = paste0(sf_join$NOMBDIST, " — WSI: ", fmt_dec(sf_join$Prob_Estres_Hidrico_pct, 1), " / 100"),
          labelOptions = leaflet::labelOptions(
            style = list("font-weight" = "600", "font-family" = "Inter, sans-serif")
          )
        ) |>
        leaflet::addLegend(
          position = "bottomleft",
          pal = pal,
          values = legend_vals,
          title = capa$title,
          opacity = 0.9
        )
      })
    })

    # Gráfico de Barras Apiladas: % Superficie por Clase de Estrés en los 9 Distritos
    output$plot_barras_apiladas <- plotly::renderPlotly({
      req(data_resumen())
      
      df_stack <- data_resumen() |>
        filter(NOMBDIST != "PROVINCIA DE ANTA") |>
        arrange(Pct_Clase4_MuyAlto + Pct_Clase3_Alto)

      plotly::plot_ly(
        data = df_stack,
        y = ~reorder(NOMBDIST, Pct_Clase4_MuyAlto + Pct_Clase3_Alto),
        x = ~Pct_Clase1_Bajo,
        type = "bar",
        orientation = "h",
        name = "1: Bajo",
        marker = list(color = "#10b981", line = list(color = "#ffffff", width = 0.5)),
        hovertemplate = "<b>%{y}</b><br>Bajo: %{x:.1f}%<extra></extra>"
      ) |>
        plotly::add_trace(
          x = ~Pct_Clase2_Medio,
          name = "2: Medio",
          marker = list(color = "#f59e0b", line = list(color = "#ffffff", width = 0.5)),
          hovertemplate = "<b>%{y}</b><br>Medio: %{x:.1f}%<extra></extra>"
        ) |>
        plotly::add_trace(
          x = ~Pct_Clase3_Alto,
          name = "3: Alto",
          marker = list(color = "#f97316", line = list(color = "#ffffff", width = 0.5)),
          hovertemplate = "<b>%{y}</b><br>Alto: %{x:.1f}%<extra></extra>"
        ) |>
        plotly::add_trace(
          x = ~Pct_Clase4_MuyAlto,
          name = "4: Muy Alto",
          marker = list(color = "#ef4444", line = list(color = "#ffffff", width = 0.5)),
          hovertemplate = "<b>%{y}</b><br>Muy Alto: %{x:.1f}%<extra></extra>"
        ) |>
        plotly::layout(
          barmode = "stack",
          xaxis = list(title = "Proporción Territorial (%)", range = c(0, 100), ticksuffix = "%", gridcolor = "#f1f5f9"),
          yaxis = list(title = ""),
          legend = list(orientation = "h", x = 0, y = 1.15, font = list(size = 10)),
          margin = list(l = 10, r = 20, t = 20, b = 35),
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor = "rgba(0,0,0,0)",
          font = list(family = "Inter, sans-serif")
        ) |> plotly::config(displayModeBar = FALSE)
    })

    # Gráfico de Ranking de Déficit Hídrico Neto (P - ETo)
    output$plot_ranking_deficit <- plotly::renderPlotly({
      req(data_resumen())
      
      df_def <- data_resumen() |>
        filter(NOMBDIST != "PROVINCIA DE ANTA") |>
        arrange(Balance_Hidrico_P_PET_mm)

      plotly::plot_ly(
        data = df_def,
        y = ~reorder(NOMBDIST, -Balance_Hidrico_P_PET_mm),
        x = ~Balance_Hidrico_P_PET_mm,
        type = "bar",
        orientation = "h",
        marker = list(
          color = ~Balance_Hidrico_P_PET_mm,
          colorscale = list(c(0, "#b91c1c"), c(0.7, "#f59e0b"), c(1, "#0284c7")),
          showscale = FALSE,
          line = list(color = "#ffffff", width = 0.5)
        ),
        text = ~paste0(round(Balance_Hidrico_P_PET_mm, 1), " mm"),
        textposition = "auto",
        hovertemplate = "<b>%{y}</b><br>Balance: %{x:.1f} mm/año<extra></extra>"
      ) |>
        plotly::layout(
          xaxis = list(title = "Balance Hídrico (P − ETo mm/año)", gridcolor = "#f1f5f9"),
          yaxis = list(title = ""),
          margin = list(l = 10, r = 20, t = 10, b = 35),
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor = "rgba(0,0,0,0)",
          font = list(family = "Inter, sans-serif")
        ) |> plotly::config(displayModeBar = FALSE)
    })
  })
}
