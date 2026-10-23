# ==============================================================================
# MOD_EVOLUCION_TENDENCIAS.R: Evolución Histórica y Cambio Climático (2001–2025)
# ==============================================================================

mod_evolucion_tendencias_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Selector de Territorio y Metadatos
    div(
      class = "row g-3 mb-3",
      div(
        class = "col-lg-6 col-md-12",
        div(
          class = "control-panel",
          div(
            class = "control-panel-title",
            icon("chart-line"), " Ámbito de Análisis Temporal (25 Años: 2001–2025)"
          ),
          selectInput(
            ns("sel_distrito"),
            label = tags$span(icon("map-marker-alt"), " Seleccione Territorio / Distrito:"),
            choices = c("PROVINCIA DE ANTA", "ANCAHUASI", "ANTA", "CACHIMAYO", 
                        "CHINCHAYPUJIO", "HUAROCONDO", "LIMATAMBO", "MOLLEPATA", 
                        "PUCYURA", "ZURITE"),
            selected = "PROVINCIA DE ANTA",
            width = "100%"
          )
        )
      ),
      div(
        class = "col-lg-6 col-md-12",
        div(
          class = "control-panel h-100 d-flex flex-column justify-content-center",
          div(class = "control-panel-title", icon("balance-scale"), " Balance Histórico frente a la Media"),
          div(
            class = "d-flex justify-content-around text-center",
            div(
              tags$span(class = "text-muted small d-block", "Años Sobre Media (Lluvia)"),
              tags$h5(class = "fw-bold text-success m-0", uiOutput(ns("anios_p_sobre")))
            ),
            div(class = "vr mx-2"),
            div(
              tags$span(class = "text-muted small d-block", "Años con lluvia bajo la media"),
              tags$h5(class = "fw-bold text-danger m-0", uiOutput(ns("anios_p_bajo")))
            ),
            div(class = "vr mx-2"),
            div(
              tags$span(class = "text-muted small d-block", "Años Sobre Media (Temp.)"),
              tags$h5(class = "fw-bold text-warning m-0", uiOutput(ns("anios_t_sobre")))
            )
          )
        )
      )
    ),

    # Fila de Indicadores de Variabilidad y Tendencias Decadales
    div(
      class = "mb-4",
      div(
        class = "d-flex align-items-center justify-content-between mb-2",
        tags$h6(class = "fw-bold m-0 text-primary", icon("tachometer-alt"), " Indicadores Físicos de Variabilidad y Cambio Climático (30 m)"),
        tags$span(class = "badge bg-light text-dark border", "Tendencias calculadas con series ajustadas PISCO")
      ),
      div(
        class = "row g-3",
        # Tendencia Temperatura
        div(
          class = "col-xl-2 col-md-4 col-sm-6",
          div(
            class = "kpi-card kpi-temp p-3",
            tags$span(class = "kpi-title", "Tendencia Térmica"),
            tags$div(class = "kpi-value kpi-value-sm", uiOutput(ns("val_t_trend"))),
            tags$span(class = "kpi-subtitle", "Calentamiento decadal")
          )
        ),
        # Tendencia Precipitación
        div(
          class = "col-xl-2 col-md-4 col-sm-6",
          div(
            class = "kpi-card kpi-precip p-3",
            tags$span(class = "kpi-title", "Tendencia Lluvia"),
            tags$div(class = "kpi-value kpi-value-sm", uiOutput(ns("val_p_trend"))),
            tags$span(class = "kpi-subtitle", "Variación decadal")
          )
        ),
        # Coeficiente de Variación de Precipitación
        div(
          class = "col-xl-2 col-md-4 col-sm-6",
          div(
            class = "kpi-card kpi-stress p-3",
            tags$span(class = "kpi-title", "Coef. Variación (CV)"),
            tags$div(class = "kpi-value kpi-value-sm", uiOutput(ns("val_p_cv"))),
            tags$span(class = "kpi-subtitle", "Volatilidad pluvial")
          )
        ),
        # Desviación Estándar Interanual Lluvia
        div(
          class = "col-xl-2 col-md-4 col-sm-6",
          div(
            class = "kpi-card kpi-anom-p p-3",
            tags$span(class = "kpi-title", "Desv. Est. Lluvia"),
            tags$div(class = "kpi-value kpi-value-sm", uiOutput(ns("val_p_std"))),
            tags$span(class = "kpi-subtitle", "Desv. interanual (mm)")
          )
        ),
        # Desviación Estándar Interanual Temperatura
        div(
          class = "col-xl-2 col-md-4 col-sm-6",
          div(
            class = "kpi-card kpi-anom-t p-3",
            tags$span(class = "kpi-title", "Desv. Est. Temp."),
            tags$div(class = "kpi-value kpi-value-sm", uiOutput(ns("val_t_std"))),
            tags$span(class = "kpi-subtitle", "Oscilación interanual (°C)")
          )
        ),
        # Año Extremo
        div(
          class = "col-xl-2 col-md-4 col-sm-6",
          div(
            class = "kpi-card kpi-aridity p-3",
            tags$span(class = "kpi-title", "Años Extremos"),
            tags$div(class = "fw-bold small text-dark mt-1", uiOutput(ns("val_extremos_txt"))),
            tags$span(class = "kpi-subtitle", "Récord 2001–2025")
          )
        )
      )
    ),

    # Fila de Gráficos de Series Temporales (Precipitación y Temperatura)
    div(
      class = "row g-3 mb-4",
      div(
        class = "col-lg-6 col-md-12",
        div(
          class = "content-card",
          div(
            class = "content-card-header",
            tags$h6(class = "content-card-title", icon("cloud-rain"), " Serie Interanual de Precipitación (2001–2025)"),
            tags$span(class = "content-card-subtitle", "Línea sólida = Territorio | Discontinua = Provincia | Roja = Tendencia")
          ),
          plotly::plotlyOutput(ns("plot_serie_precipitacion"), height = "320px")
        )
      ),
      div(
        class = "col-lg-6 col-md-12",
        div(
          class = "content-card",
          div(
            class = "content-card-header",
            tags$h6(class = "content-card-title", icon("thermometer-three-quarters"), " Serie Interanual de Temperatura Media (2001–2025)"),
            tags$span(class = "content-card-subtitle", "Línea naranja = Territorio | Discontinua = Provincia | Roja = Tendencia")
          ),
          plotly::plotlyOutput(ns("plot_serie_temperatura"), height = "320px")
        )
      )
    ),

    # Fila de Gráficos de Anomalías y Comparativa Provincial Boxplot
    div(
      class = "row g-3",
      div(
        class = "col-lg-7 col-md-12",
        div(
          class = "content-card",
          div(
            class = "content-card-header",
            tags$h6(class = "content-card-title", icon("chart-bar"), " Distribución Anual de Anomalías Porcentuales de Lluvia (%)"),
            tags$span(class = "content-card-subtitle", "Barras azules = lluvia sobre la media | barras rojas = lluvia bajo la media")
          ),
          plotly::plotlyOutput(ns("plot_anomalias_barras"), height = "320px")
        )
      ),
      div(
        class = "col-lg-5 col-md-12",
        div(
          class = "content-card",
          div(
            class = "content-card-header",
            tags$h6(class = "content-card-title", icon("box"), " Dispersión Distrital de Precipitación"),
            tags$span(class = "content-card-subtitle", "Boxplot comparativo de los 25 años para los 9 distritos")
          ),
          plotly::plotlyOutput(ns("plot_boxplot_distritos"), height = "320px")
        )
      )
    )
  )
}

mod_evolucion_tendencias_server <- function(id, data_series, data_resumen) {
  moduleServer(id, function(input, output, session) {
    
    # Datos reactivos del territorio
    dist_data <- reactive({
      req(data_series(), input$sel_distrito)
      dist_sel <- input$sel_distrito
      data_series() |> filter(NOMBDIST == dist_sel) |> arrange(Year)
    })

    prov_data <- reactive({
      req(data_series())
      data_series() |> filter(NOMBDIST == "PROVINCIA DE ANTA") |> arrange(Year)
    })

    dist_resumen <- reactive({
      req(data_resumen(), input$sel_distrito)
      dist_sel <- input$sel_distrito
      row_m <- data_resumen() |> filter(NOMBDIST == dist_sel)
      if (nrow(row_m) == 0) row_m <- data_resumen() |> filter(NOMBDIST == "PROVINCIA DE ANTA")
      row_m[1, ]
    })

    # Métricas y Extremos
    output$anios_p_sobre <- renderUI({
      df <- dist_data()
      n_sobre <- sum(df$P_anomalia_mm >= 0, na.rm = TRUE)
      paste0(n_sobre, " años (", round((n_sobre / nrow(df)) * 100), "%)")
    })

    output$anios_p_bajo <- renderUI({
      df <- dist_data()
      n_bajo <- sum(df$P_anomalia_mm < 0, na.rm = TRUE)
      paste0(n_bajo, " años (", round((n_bajo / nrow(df)) * 100), "%)")
    })

    output$anios_t_sobre <- renderUI({
      df <- dist_data()
      n_t_sobre <- sum(df$T_anomalia_C > 0, na.rm = TRUE)
      paste0(n_t_sobre, " años (", round((n_t_sobre / nrow(df)) * 100), "%)")
    })

    output$val_t_trend <- renderUI({
      r <- dist_resumen()
      fmt_sign(r$T_trend_decada, 2, "°C/déc.")
    })

    output$val_p_trend <- renderUI({
      r <- dist_resumen()
      fmt_sign(r$P_trend_decada, 1, "mm/déc.")
    })

    output$val_p_cv <- renderUI({
      r <- dist_resumen()
      fmt_pct(r$P_CV_pct, 1)
    })

    output$val_p_std <- renderUI({
      r <- dist_resumen()
      paste0(fmt_dec(r$P_std_interanual, 1), " mm")
    })

    output$val_t_std <- renderUI({
      r <- dist_resumen()
      paste0(fmt_dec(r$T_std_interanual, 2), " °C")
    })

    output$val_extremos_txt <- renderUI({
      df <- dist_data()
      yr_seco   <- df$Year[which.min(df$Precipitacion_mm)]
      yr_humedo <- df$Year[which.max(df$Precipitacion_mm)]
      yr_calido <- df$Year[which.max(df$Temperatura_C)]
      yr_frio   <- df$Year[which.min(df$Temperatura_C)]

      tagList(
        tags$span(class = "d-block", paste0("Seco: ", yr_seco, " | Húmedo: ", yr_humedo)),
        tags$span(class = "text-muted", paste0("Frío: ", yr_frio, " | Cálido: ", yr_calido))
      )
    })

    # Gráfico 1: Serie Temporal de Precipitación Anual
    output$plot_serie_precipitacion <- plotly::renderPlotly({
      df_d <- dist_data()
      df_p <- prov_data()
      req(df_d, df_p)

      fit_d <- lm(Precipitacion_mm ~ Year, data = df_d)
      df_d$P_trend <- predict(fit_d)
      media_p <- mean(df_d$Precipitacion_mm, na.rm = TRUE)

      plotly::plot_ly() |>
        plotly::add_lines(
          data = df_p,
          x = ~Year,
          y = ~Precipitacion_mm,
          name = "Provincia (Ref.)",
          line = list(color = "#94a3b8", width = 1.6, dash = "dot"),
          hovertemplate = "<b>Provincia</b><br>Año %{x}: %{y:.1f} mm<extra></extra>"
        ) |>
        plotly::add_lines(
          data = df_d,
          x = ~Year,
          y = ~Precipitacion_mm,
          name = input$sel_distrito,
          line = list(color = "#0284c7", width = 2.6),
          hovertemplate = paste0("<b>", input$sel_distrito, "</b><br>Año %{x}: %{y:.1f} mm<extra></extra>")
        ) |>
        plotly::add_markers(
          data = df_d,
          x = ~Year,
          y = ~Precipitacion_mm,
          showlegend = FALSE,
          marker = list(color = "#0284c7", size = 5)
        ) |>
        plotly::add_lines(
          data = df_d,
          x = ~Year,
          y = ~P_trend,
          name = "Tendencia Lineal",
          line = list(color = "#dc2626", width = 2, dash = "dash"),
          hovertemplate = "<b>Tendencia</b><br>Año %{x}: %{y:.1f} mm<extra></extra>"
        ) |>
        plotly::layout(
          xaxis = list(title = "Año", tickmode = "linear", dtick = 3, gridcolor = "#f1f5f9"),
          yaxis = list(title = "Precipitación (mm/año)", gridcolor = "#f1f5f9"),
          legend = list(orientation = "h", x = 0.05, y = 1.15),
          margin = list(l = 50, r = 20, t = 30, b = 40),
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor = "rgba(0,0,0,0)",
          font = list(family = "Inter, sans-serif")
        ) |> plotly::config(displayModeBar = FALSE)
    })

    # Gráfico 2: Serie Temporal de Temperatura Media
    output$plot_serie_temperatura <- plotly::renderPlotly({
      df_d <- dist_data()
      df_p <- prov_data()
      req(df_d, df_p)

      fit_t <- lm(Temperatura_C ~ Year, data = df_d)
      df_d$T_trend <- predict(fit_t)

      plotly::plot_ly() |>
        plotly::add_lines(
          data = df_p,
          x = ~Year,
          y = ~Temperatura_C,
          name = "Provincia (Ref.)",
          line = list(color = "#94a3b8", width = 1.6, dash = "dot"),
          hovertemplate = "<b>Provincia</b><br>Año %{x}: %{y:.2f} °C<extra></extra>"
        ) |>
        plotly::add_lines(
          data = df_d,
          x = ~Year,
          y = ~Temperatura_C,
          name = input$sel_distrito,
          line = list(color = "#ea580c", width = 2.6),
          hovertemplate = paste0("<b>", input$sel_distrito, "</b><br>Año %{x}: %{y:.2f} °C<extra></extra>")
        ) |>
        plotly::add_markers(
          data = df_d,
          x = ~Year,
          y = ~Temperatura_C,
          showlegend = FALSE,
          marker = list(color = "#ea580c", size = 5)
        ) |>
        plotly::add_lines(
          data = df_d,
          x = ~Year,
          y = ~T_trend,
          name = "Tendencia Térmica",
          line = list(color = "#dc2626", width = 2, dash = "dash"),
          hovertemplate = "<b>Tendencia</b><br>Año %{x}: %{y:.2f} °C<extra></extra>"
        ) |>
        plotly::layout(
          xaxis = list(title = "Año", tickmode = "linear", dtick = 3, gridcolor = "#f1f5f9"),
          yaxis = list(title = "Temperatura Media (°C)", gridcolor = "#f1f5f9"),
          legend = list(orientation = "h", x = 0.05, y = 1.15),
          margin = list(l = 50, r = 20, t = 30, b = 40),
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor = "rgba(0,0,0,0)",
          font = list(family = "Inter, sans-serif")
        ) |> plotly::config(displayModeBar = FALSE)
    })

    # Gráfico 3: Barras Divergentes de Anomalías Anuales
    output$plot_anomalias_barras <- plotly::renderPlotly({
      df_d <- dist_data()
      req(df_d)

      df_d$color <- ifelse(df_d$P_anomalia_pct >= 0, "#0284c7", "#ef4444")

      plotly::plot_ly(
        data = df_d,
        x = ~Year,
        y = ~round(P_anomalia_pct, 1),
        type = "bar",
        marker = list(
          color = ~color,
          line = list(color = "#ffffff", width = 0.5)
        ),
        hovertemplate = "<b>Año %{x}</b><br>Anomalía: %{y:+.1f}%<extra></extra>"
      ) |>
        plotly::layout(
          xaxis = list(title = "Año", tickmode = "linear", dtick = 2, gridcolor = "#f1f5f9"),
          yaxis = list(title = "Anomalía de Precipitación (%)", ticksuffix = "%", gridcolor = "#f1f5f9"),
          margin = list(l = 50, r = 20, t = 20, b = 40),
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor = "rgba(0,0,0,0)",
          font = list(family = "Inter, sans-serif")
        ) |> plotly::config(displayModeBar = FALSE)
    })

    # Gráfico 4: Boxplot de Distribución Distrital (2001–2025)
    output$plot_boxplot_distritos <- plotly::renderPlotly({
      req(data_series())
      
      df_distritos <- data_series() |>
        filter(NOMBDIST != "PROVINCIA DE ANTA")

      plotly::plot_ly(
        data = df_distritos,
        y = ~reorder(NOMBDIST, Precipitacion_mm, FUN = median),
        x = ~Precipitacion_mm,
        type = "box",
        orientation = "h",
        color = ~NOMBDIST,
        colors = "Blues",
        boxpoints = "outliers",
        showlegend = FALSE
      ) |>
        plotly::layout(
          xaxis = list(title = "Precipitación Anual (mm)", gridcolor = "#f1f5f9"),
          yaxis = list(title = ""),
          margin = list(l = 10, r = 20, t = 10, b = 40),
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor = "rgba(0,0,0,0)",
          font = list(family = "Inter, sans-serif", size = 10)
        ) |> plotly::config(displayModeBar = FALSE)
    })
  })
}
