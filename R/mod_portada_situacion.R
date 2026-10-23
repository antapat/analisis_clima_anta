# ==============================================================================
# MOD_PORTADA_SITUACION.R: Portada - Situación Climática del Territorio
# ==============================================================================

mod_portada_situacion_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Fila de Filtros y Control Territorial
    div(
      class = "row g-3 mb-3",
      div(
        class = "col-lg-7 col-md-12",
        div(
          class = "control-panel",
          div(
            class = "control-panel-title",
            icon("map-marked-alt"), " Ámbito Territorial y Periodo de Análisis"
          ),
          div(
            class = "row g-2 align-items-center",
            div(
              class = "col-md-7 col-sm-12",
              selectInput(
                ns("sel_distrito"),
                label = tags$span(icon("city"), " Territorio / Distrito:"),
                choices = c("PROVINCIA DE ANTA", "ANCAHUASI", "ANTA", "CACHIMAYO", 
                            "CHINCHAYPUJIO", "HUAROCONDO", "LIMATAMBO", "MOLLEPATA", 
                            "PUCYURA", "ZURITE"),
                selected = "PROVINCIA DE ANTA",
                width = "100%"
              )
            ),
            div(
              class = "col-md-5 col-sm-12",
              sliderInput(
                ns("sel_year"),
                label = tags$span(icon("calendar-alt"), " Año Evaluado:"),
                min = 2001,
                max = 2025,
                value = 2024,
                step = 1,
                sep = "",
                width = "100%"
              )
            )
          )
        )
      ),
      div(
        class = "col-lg-5 col-md-12",
        div(
          class = "control-panel h-100 d-flex flex-column justify-content-center",
          div(
            class = "d-flex align-items-center justify-content-between mb-2",
            tags$span(class = "fw-bold text-muted small", "FICHA TERRITORIAL"),
            uiOutput(ns("badge_capital"))
          ),
          div(
            class = "d-flex justify-content-around text-center py-1",
            div(
              tags$span(class = "text-muted small d-block", "Superficie Total"),
              tags$h5(class = "fw-bold text-dark m-0", uiOutput(ns("val_superficie")))
            ),
            div(class = "vr mx-3"),
            div(
              tags$span(class = "text-muted small d-block", "Altitud Media"),
              tags$h5(class = "fw-bold text-dark m-0", uiOutput(ns("val_altitud")))
            )
          )
        )
      )
    ),

    # Banner Interpretativo Territorial Dinámico
    uiOutput(ns("banner_interpretativo")),

    # Bloque 1: Dinámica Anual (Año Seleccionado)
    div(
      class = "mb-4",
      div(
        class = "d-flex align-items-center justify-content-between mb-2 flex-wrap gap-2",
        div(
          class = "d-flex align-items-center gap-2",
          tags$h5(class = "fw-bold m-0 text-primary", icon("calendar-check"), " 1. Dinámica Climática Anual"),
          uiOutput(ns("badge_tipo_anual"))
        ),
        div(
          class = "d-flex align-items-center gap-2",
          tags$span(class = "text-muted small", "Afectado exclusivamente por el selector de año"),
          tags$a(href = "#seccion-guia-indicadores", class = "badge bg-light text-primary border text-decoration-none py-1 px-2", icon("book-reader"), " Guía de Indicadores")
        )
      ),
      div(
        class = "row g-3",
        # Precipitación Anual
        div(
          class = "col-xl-3 col-md-6 col-sm-12",
          div(
            class = "kpi-card kpi-precip",
            div(
              class = "kpi-header-row",
              tags$span(class = "kpi-title", "Precipitación Anual"),
              div(class = "kpi-icon", icon("cloud-rain"))
            ),
            tags$div(class = "kpi-value", uiOutput(ns("kpi_p_actual"))),
            div(
              class = "kpi-subtitle",
              tags$span("Media Histórica: "),
              tags$strong(uiOutput(ns("kpi_p_media")))
            )
          )
        ),
        # Anomalía de Precipitación
        div(
          class = "col-xl-3 col-md-6 col-sm-12",
          div(
            class = "kpi-card kpi-anom-p",
            div(
              class = "kpi-header-row",
              tags$span(class = "kpi-title", "Anomalía de Precipitación"),
              div(class = "kpi-icon", icon("percentage"))
            ),
            tags$div(class = "kpi-value", uiOutput(ns("kpi_p_anom_pct"))),
            div(
              class = "kpi-subtitle",
              tags$span("Diferencia volumétrica: "),
              tags$strong(uiOutput(ns("kpi_p_anom_mm")))
            )
          )
        ),
        # Temperatura Media Anual
        div(
          class = "col-xl-3 col-md-6 col-sm-12",
          div(
            class = "kpi-card kpi-temp",
            div(
              class = "kpi-header-row",
              tags$span(class = "kpi-title", "Temperatura Media Anual"),
              div(class = "kpi-icon", icon("thermometer-half"))
            ),
            tags$div(class = "kpi-value", uiOutput(ns("kpi_t_actual"))),
            div(
              class = "kpi-subtitle",
              tags$span("Media Histórica: "),
              tags$strong(uiOutput(ns("kpi_t_media")))
            )
          )
        ),
        # Anomalía Térmica
        div(
          class = "col-xl-3 col-md-6 col-sm-12",
          div(
            class = "kpi-card kpi-anom-t",
            div(
              class = "kpi-header-row",
              tags$span(class = "kpi-title", "Anomalía Térmica"),
              div(class = "kpi-icon", icon("fire-alt"))
            ),
            tags$div(class = "kpi-value", uiOutput(ns("kpi_t_anom"))),
            div(
              class = "kpi-subtitle",
              tags$span("Posición Percentil: "),
              tags$strong(uiOutput(ns("kpi_t_percentil")))
            )
          )
        )
      )
    ),

    # Bloque 2: Diagnóstico Hidroclimático Multianual a 30m
    div(
      class = "mb-4",
      div(
        class = "d-flex align-items-center justify-content-between mb-2",
        div(
          class = "d-flex align-items-center gap-2",
          tags$h5(class = "fw-bold m-0 text-success", icon("tint"), " 2. Diagnóstico Hidroclimático Multianual a 30 m"),
          tags$span(class = "temporal-type-badge badge-multianual-synth", icon("cube"), "Síntesis Multianual 2001–2025")
        ),
        tags$span(class = "text-muted small", "Indicadores estructurales independientes del año seleccionado")
      ),
      div(
        class = "row g-3",
        # Estrés Hídrico Territorial (WSI)
        div(
          class = "col-xl-3 col-md-6 col-sm-12",
          div(
            class = "kpi-card kpi-stress",
            div(
              class = "kpi-header-row",
              tags$span(class = "kpi-title", "Estrés Hídrico (WSI)"),
              div(class = "kpi-icon", icon("exclamation-circle"))
            ),
            tags$div(class = "kpi-value", uiOutput(ns("kpi_wsi_pct"))),
            div(
              class = "kpi-subtitle",
              tags$span("Categoría: "),
              uiOutput(ns("kpi_wsi_cat"))
            )
          )
        ),
        # Balance Hídrico Climático
        div(
          class = "col-xl-3 col-md-6 col-sm-12",
          div(
            class = "kpi-card kpi-balance",
            div(
              class = "kpi-header-row",
              tags$span(class = "kpi-title", "Balance Hídrico (P − ETo)"),
              div(class = "kpi-icon", icon("water"))
            ),
            tags$div(class = "kpi-value", uiOutput(ns("kpi_balance"))),
            div(
              class = "kpi-subtitle",
              tags$span("Demanda ETo: "),
              tags$strong(uiOutput(ns("kpi_eto")))
            )
          )
        ),
        # Índice de Aridez UNESCO
        div(
          class = "col-xl-3 col-md-6 col-sm-12",
          div(
            class = "kpi-card kpi-aridity",
            div(
              class = "kpi-header-row",
              tags$span(class = "kpi-title", "Índice de Aridez UNESCO"),
              div(class = "kpi-icon", icon("sun"))
            ),
            tags$div(class = "kpi-value", uiOutput(ns("kpi_aridez"))),
            div(
              class = "kpi-subtitle",
              tags$span("Régimen: "),
              uiOutput(ns("kpi_aridez_cat"))
            )
          )
        ),
        # Tendencias Climáticas Decadales
        div(
          class = "col-xl-3 col-md-6 col-sm-12",
          div(
            class = "kpi-card kpi-temp",
            div(
              class = "kpi-header-row",
              tags$span(class = "kpi-title", "Tendencias Decadales"),
              div(class = "kpi-icon", icon("chart-line"))
            ),
            tags$div(class = "kpi-value kpi-value-sm", uiOutput(ns("kpi_tendencia_t"))),
            div(
              class = "kpi-subtitle",
              tags$span("Precipitación: "),
              tags$strong(uiOutput(ns("kpi_tendencia_p")))
            )
          )
        )
      )
    ),

    # Bloque 3: Visualizaciones Complementarias de la Portada
    div(
      class = "row g-3",
      # Gráfico 1: Evolución 2001-2025 y Punto Seleccionado
      div(
        class = "col-lg-7 col-md-12",
        div(
          class = "content-card",
          div(
            class = "content-card-header",
            div(
              tags$h6(class = "content-card-title", icon("history"), " Trayectoria Interanual y Punto en la Serie"),
              tags$span(class = "content-card-subtitle", "Comparación del territorio con la media provincial y destaque del año evaluado")
            )
          ),
          plotly::plotlyOutput(ns("plot_trayectoria_anual"), height = "320px")
        )
      ),
      # Gráfico 2: Descomposición de Clases de Estrés Hídrico
      div(
        class = "col-lg-5 col-md-12",
        div(
          class = "content-card",
          div(
            class = "content-card-header",
            div(
              tags$h6(class = "content-card-title", icon("chart-pie"), " Distribución de Superficie por Estrés"),
              tags$span(class = "content-card-subtitle", "Proporción de área distrital en Clases 1 a 4 a resolución de 30 m")
            )
          ),
          plotly::plotlyOutput(ns("plot_estres_donas"), height = "320px")
        )
      )
    ),

    # Bloque 4: Módulo de Conceptualización y Guía Técnica de Indicadores Hidroclimáticos
    mod_guia_indicadores_ui(ns("guia_indicadores"))
  )
}

mod_portada_situacion_server <- function(id, data_resumen, data_series, data_distritos_sf) {
  moduleServer(id, function(input, output, session) {
    
    # Invocar módulo de conceptualización y guía de indicadores
    mod_guia_indicadores_server("guia_indicadores")
    
    # Datos reactivos para el territorio seleccionado
    territorio_row <- reactive({
      req(data_resumen(), input$sel_distrito)
      dist_sel <- input$sel_distrito
      row_match <- data_resumen() |> filter(NOMBDIST == dist_sel)
      if (nrow(row_match) == 0) row_match <- data_resumen() |> filter(NOMBDIST == "PROVINCIA DE ANTA")
      row_match[1, ]
    })

    # Datos reactivos para el año seleccionado
    serie_year <- reactive({
      req(data_series(), input$sel_distrito, input$sel_year)
      dist_sel <- input$sel_distrito
      yr_sel   <- as.integer(input$sel_year)
      row_match <- data_series() |> filter(NOMBDIST == dist_sel, Year == yr_sel)
      if (nrow(row_match) == 0) return(NULL)
      row_match[1, ]
    })

    # Ficha Territorial
    output$badge_capital <- renderUI({
      row <- territorio_row()
      tags$span(class = "badge bg-secondary", paste0("Capital: ", row$CAPDIST))
    })

    output$val_superficie <- renderUI({
      row <- territorio_row()
      paste0(fmt_num(row$AREA_KM2, 1), " km² (", fmt_num(row$AREA_HA, 0), " ha)")
    })

    output$val_poblacion <- renderUI({
      row <- territorio_row()
      paste0(fmt_num(row$TOT_POB17, 0), " hab.")
    })

    output$val_altitud <- renderUI({
      row <- territorio_row()
      # Estimación altitudinal según relieve
      alt_est <- if (row$NOMBDIST %in% c("LIMATAMBO", "MOLLEPATA")) "~2,450 m" else if (row$NOMBDIST == "CHINCHAYPUJIO") "~3,780 m" else "~3,345 m"
      alt_est
    })

    output$badge_tipo_anual <- renderUI({
      yr <- input$sel_year
      tags$span(class = "temporal-type-badge badge-anual-dynamic", icon("clock"), paste0("Año Dinámico: ", yr))
    })

    # Banner Interpretativo Territorial Dinámico
    output$banner_interpretativo <- renderUI({
      row <- territorio_row()
      syr <- serie_year()
      req(row, syr)

      diag <- generar_mensaje_interpretativo(
        territorio = row$NOMBDIST,
        yr = input$sel_year,
        p_anom_pct = syr$P_anomalia_pct,
        t_anom_c = syr$T_anomalia_C,
        wsi_pct = row$Prob_Estres_Hidrico_pct,
        wsi_cat = row$WSI_Cat,
        pct_critica = row$Pct_Clase3_4
      )

      div(
        class = paste0("territorial-alert-banner ", diag$tipo),
        div(
          class = "territorial-alert-title",
          icon(diag$icono), diag$titulo
        ),
        p(class = "territorial-alert-text", diag$mensaje)
      )
    })

    # KPIs Dinámica Anual
    output$kpi_p_actual <- renderUI({
      syr <- serie_year()
      if (is.null(syr)) return("--")
      paste0(fmt_dec(syr$Precipitacion_mm, 1), " mm")
    })

    output$kpi_p_media <- renderUI({
      row <- territorio_row()
      paste0(fmt_dec(row$P_media, 1), " mm/año")
    })

    output$kpi_p_anom_pct <- renderUI({
      syr <- serie_year()
      if (is.null(syr)) return("--")
      cls <- if (syr$P_anomalia_pct >= 0) "kpi-badge-positive" else "kpi-badge-negative"
      tagList(
        fmt_sign(syr$P_anomalia_pct, 1, "%"),
        tags$span(class = paste0("kpi-badge ", cls, " ms-2"), syr$P_semaforo)
      )
    })

    output$kpi_p_anom_mm <- renderUI({
      syr <- serie_year()
      if (is.null(syr)) return("--")
      fmt_sign(syr$P_anomalia_mm, 1, "mm")
    })

    output$kpi_t_actual <- renderUI({
      syr <- serie_year()
      if (is.null(syr)) return("--")
      paste0(fmt_dec(syr$Temperatura_C, 1), " °C")
    })

    output$kpi_t_media <- renderUI({
      row <- territorio_row()
      paste0(fmt_dec(row$T_media, 1), " °C")
    })

    output$kpi_t_anom <- renderUI({
      syr <- serie_year()
      if (is.null(syr)) return("--")
      cls <- if (syr$T_anomalia_C > 0) "kpi-badge-negative" else "kpi-badge-positive"
      tagList(
        fmt_sign(syr$T_anomalia_C, 2, "°C"),
        tags$span(class = paste0("kpi-badge ", cls, " ms-2"), syr$T_semaforo)
      )
    })

    output$kpi_t_percentil <- renderUI({
      syr <- serie_year()
      if (is.null(syr)) return("--")
      paste0("P", fmt_num(syr$T_percentil), " (en 25 años)")
    })

    # KPIs Síntesis Multianual (30m)
    output$kpi_wsi_pct <- renderUI({
      row <- territorio_row()
      paste0(fmt_dec(row$Prob_Estres_Hidrico_pct, 1), " / 100")
    })

    output$kpi_wsi_cat <- renderUI({
      row <- territorio_row()
      cat_txt <- row$WSI_Cat
      cls <- switch(cat_txt,
        "Bajo" = "badge-stress-1",
        "Medio" = "badge-stress-2",
        "Alto" = "badge-stress-3",
        "Muy Alto" = "badge-stress-4",
        "bg-secondary"
      )
      tags$span(class = cls, cat_txt)
    })

    output$kpi_balance <- renderUI({
      row <- territorio_row()
      fmt_sign(row$Balance_Hidrico_P_PET_mm, 1, "mm/año")
    })

    output$kpi_eto <- renderUI({
      row <- territorio_row()
      paste0(fmt_dec(row$ETo_PenmanMonteith_mm, 1), " mm/año")
    })

    output$kpi_aridez <- renderUI({
      row <- territorio_row()
      fmt_dec(row$Indice_Aridez_UNESCO, 3)
    })

    output$kpi_aridez_cat <- renderUI({
      row <- territorio_row()
      cat_txt <- row$Aridez_Cat
      cls <- switch(cat_txt,
        "Semiárido" = "badge-aridity-semiarid",
        "Subhúmedo Seco" = "badge-aridity-subhumid",
        "Húmedo" = "badge-aridity-humid",
        "bg-secondary"
      )
      tags$span(class = cls, cat_txt)
    })

    output$kpi_tendencia_t <- renderUI({
      row <- territorio_row()
      paste0(fmt_sign(row$T_trend_decada, 2), " °C / década")
    })

    output$kpi_tendencia_p <- renderUI({
      row <- territorio_row()
      paste0(fmt_sign(row$P_trend_decada, 1), " mm / década")
    })

    # Gráfico 1: Trayectoria Anual y Punto Resaltado
    output$plot_trayectoria_anual <- plotly::renderPlotly({
      req(data_series(), input$sel_distrito, input$sel_year)
      
      dist_sel <- input$sel_distrito
      yr_sel   <- as.integer(input$sel_year)

      df_dist <- data_series() |> filter(NOMBDIST == dist_sel)
      df_prov <- data_series() |> filter(NOMBDIST == "PROVINCIA DE ANTA")
      df_pt   <- df_dist |> filter(Year == yr_sel)

      p <- plotly::plot_ly() |>
        # Serie provincial de fondo
        plotly::add_lines(
          data = df_prov,
          x = ~Year,
          y = ~Precipitacion_mm,
          name = "Provincia (Ref.)",
          line = list(color = "#94a3b8", width = 1.8, dash = "dot"),
          hovertemplate = "<b>Provincia</b><br>Año %{x}: %{y:.1f} mm<extra></extra>"
        ) |>
        # Serie territorial seleccionada
        plotly::add_lines(
          data = df_dist,
          x = ~Year,
          y = ~Precipitacion_mm,
          name = dist_sel,
          line = list(color = "#0284c7", width = 2.8),
          hovertemplate = paste0("<b>", dist_sel, "</b><br>Año %{x}: %{y:.1f} mm<extra></extra>")
        ) |>
        plotly::add_markers(
          data = df_dist,
          x = ~Year,
          y = ~Precipitacion_mm,
          showlegend = FALSE,
          marker = list(color = "#0284c7", size = 6)
        )

      # Punto destacado del año
      if (nrow(df_pt) > 0) {
        p <- p |>
          plotly::add_markers(
            data = df_pt,
            x = ~Year,
            y = ~Precipitacion_mm,
            name = paste0("Año ", yr_sel),
            marker = list(
              color = "#ef4444",
              size = 13,
              line = list(color = "#ffffff", width = 2.5)
            ),
            hovertemplate = paste0("<b>Año Evaluado (", yr_sel, ")</b><br>Lluvia: %{y:.1f} mm<extra></extra>")
          )
      }

      p |> plotly::layout(
        xaxis = list(
          title = "Año",
          tickmode = "linear",
          dtick = 3,
          gridcolor = "#f1f5f9"
        ),
        yaxis = list(
          title = "Precipitación Acumulada Anual (mm)",
          gridcolor = "#f1f5f9"
        ),
        legend = list(orientation = "h", x = 0.05, y = 1.15),
        margin = list(l = 50, r = 20, t = 30, b = 40),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(family = "Inter, sans-serif")
      ) |> plotly::config(displayModeBar = FALSE)
    })

    # Gráfico 2: Descomposición de Clases de Estrés Hídrico (Donut)
    output$plot_estres_donas <- plotly::renderPlotly({
      row <- territorio_row()
      req(row)

      df_pie <- data.frame(
        Clase = c("Clase 1: Bajo", "Clase 2: Medio", "Clase 3: Alto", "Clase 4: Muy Alto"),
        Pct = c(row$Pct_Clase1_Bajo, row$Pct_Clase2_Medio, row$Pct_Clase3_Alto, row$Pct_Clase4_MuyAlto),
        Ha = c(row$Ha_Clase1_Bajo, row$Ha_Clase2_Medio, row$Ha_Clase3_Alto, row$Ha_Clase4_MuyAlto),
        Color = c("#10b981", "#f59e0b", "#f97316", "#ef4444")
      )

      plotly::plot_ly(
        data = df_pie,
        labels = ~Clase,
        values = ~Pct,
        type = "pie",
        hole = 0.65,
        sort = FALSE,
        marker = list(
          colors = ~Color,
          line = list(color = "#ffffff", width = 2)
        ),
        textinfo = "percent",
        textposition = "inside",
        hovertemplate = "<b>%{label}</b><br>Superficie: %{customdata:.1f} ha (%{percent})<extra></extra>",
        customdata = ~Ha
      ) |> plotly::layout(
        showlegend = TRUE,
        legend = list(orientation = "h", x = 0, y = -0.15, font = list(size = 10)),
        margin = list(l = 10, r = 10, t = 10, b = 40),
        paper_bgcolor = "rgba(0,0,0,0)",
        font = list(family = "Inter, sans-serif"),
        annotations = list(
          list(
            text = paste0("<b>", fmt_dec(row$Prob_Estres_Hidrico_pct, 1), " / 100</b><br><span style='font-size:10px; color:#64748b;'>WSI Promedio</span>"),
            x = 0.5, y = 0.5,
            showarrow = FALSE,
            font = list(size = 15, color = "#0b3b60")
          )
        )
      ) |> plotly::config(displayModeBar = FALSE)
    })
  })
}
