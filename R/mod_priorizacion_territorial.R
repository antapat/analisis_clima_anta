# ==============================================================================
# MOD_PRIORIZACION_TERRITORIAL.R: Priorización para la Toma de Decisiones
# ==============================================================================

mod_priorizacion_territorial_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    div(
      class = "content-card mb-3",
      div(
        class = "content-card-header mb-2",
        div(
          tags$h6(class = "content-card-title", icon("bullseye"), " Matriz exploratoria de indicadores territoriales"),
          tags$span(class = "content-card-subtitle", "Comparación descriptiva de variables biofísicas, climáticas y censales")
        ),
        tags$span(class = "badge bg-primary", "Uso exploratorio")
      ),
      p(
        class = "text-muted small m-0",
        "Esta matriz compara los 9 distritos mediante indicadores derivados del modelo. ",
        "Las categorías son reglas exploratorias y requieren validación hidrológica, social y de campo antes de decidir intervenciones."
      )
    ),

    # Tabla Maestra Reactable de Priorización Multicriterio
    div(
      class = "content-card mb-4 p-3",
      reactable::reactableOutput(ns("tabla_priorizacion"))
    ),

    # Fila de Perfil de Atención Comparativo y Recomendaciones Estratégicas
    div(
      class = "row g-3",
      # Comparativa Radar de Perfiles de Atención
      div(
        class = "col-lg-6 col-md-12",
        div(
          class = "content-card",
          div(
            class = "content-card-header",
            tags$h6(class = "content-card-title", icon("spider"), " Comparación de Perfiles de Vulnerabilidad (Radar)"),
            tags$span(class = "content-card-subtitle", "Normalización 0–100 de las 6 dimensiones críticas")
          ),
          div(
            class = "row g-2 mb-2",
            div(
              class = "col-6",
              selectInput(
                ns("radar_distrito_1"),
                label = "Distrito A (Línea Azul):",
                choices = c("CACHIMAYO", "PUCYURA", "HUAROCONDO", "ANTA", "ZURITE", "ANCAHUASI", "CHINCHAYPUJIO", "MOLLEPATA", "LIMATAMBO"),
                selected = "CACHIMAYO",
                width = "100%"
              )
            ),
            div(
              class = "col-6",
              selectInput(
                ns("radar_distrito_2"),
                label = "Distrito B (Línea Naranja):",
                choices = c("CACHIMAYO", "PUCYURA", "HUAROCONDO", "ANTA", "ZURITE", "ANCAHUASI", "CHINCHAYPUJIO", "MOLLEPATA", "LIMATAMBO"),
                selected = "LIMATAMBO",
                width = "100%"
              )
            )
          ),
          plotly::plotlyOutput(ns("plot_radar_comparativo"), height = "330px"),
          uiOutput(ns("interpretacion_radar"))
        )
      ),

      # Ficha de Diagnóstico Estratégico Territorial
      div(
        class = "col-lg-6 col-md-12",
        div(
          class = "content-card",
          div(
            class = "content-card-header",
            tags$h6(class = "content-card-title", icon("clipboard-check"), " Ficha de indicadores del distrito"),
            tags$span(class = "content-card-subtitle", "Seleccione un territorio para ver sus estimaciones")
          ),
          selectInput(
            ns("sel_dist_ficha"),
            label = "Distrito Consultado:",
            choices = c("CACHIMAYO", "PUCYURA", "HUAROCONDO", "ANTA", "ZURITE", "ANCAHUASI", "CHINCHAYPUJIO", "MOLLEPATA", "LIMATAMBO"),
            selected = "CACHIMAYO",
            width = "100%"
          ),
          uiOutput(ns("ficha_estrategica_detalle"))
        )
      )
    )
  )
}

mod_priorizacion_territorial_server <- function(id, data_resumen) {
  moduleServer(id, function(input, output, session) {
    
    # Tabla Reactable de Priorización Multicriterio
    output$tabla_priorizacion <- reactable::renderReactable({
      req(data_resumen())
      
      df <- data_resumen() |>
        filter(NOMBDIST != "PROVINCIA DE ANTA") |>
        mutate(
          Nivel_Prioridad = case_when(
            Pct_Clase3_4 >= 70 | Balance_Hidrico_P_PET_mm <= -500 ~ "Atención Crítica",
            Pct_Clase3_4 >= 25 | Balance_Hidrico_P_PET_mm <= -400 ~ "Atención Alta",
            TRUE                                                 ~ "Atención Media"
          )
        ) |>
        select(
          NOMBDIST, TOT_POB17, AREA_KM2, Balance_Hidrico_P_PET_mm, 
          Indice_Aridez_UNESCO, Prob_Estres_Hidrico_pct, Pct_Clase3_4,
          P_CV_pct, T_trend_decada, Nivel_Prioridad
        ) |>
        arrange(desc(Pct_Clase3_4), Balance_Hidrico_P_PET_mm)

      reactable::reactable(
        df,
        striped = TRUE,
        highlight = TRUE,
        compact = TRUE,
        pagination = FALSE,
        columns = list(
          NOMBDIST = reactable::colDef(
            name = "Distrito",
            minWidth = 135,
            style = list(fontWeight = "700", color = "#0b3b60")
          ),
          TOT_POB17 = reactable::colDef(
            name = "Pob. censo 2017",
            align = "right",
            width = 85,
            format = reactable::colFormat(separators = TRUE)
          ),
          AREA_KM2 = reactable::colDef(
            name = "Área (km²)",
            align = "right",
            width = 85,
            format = reactable::colFormat(digits = 1)
          ),
          Balance_Hidrico_P_PET_mm = reactable::colDef(
            name = "Diferencia P−ETo",
            align = "right",
            width = 110,
            cell = function(val) {
              cls <- if (val < -500) "text-danger fw-bold" else if (val < -350) "text-warning fw-bold" else "text-success fw-bold"
              tags$span(class = cls, paste0(round(val, 1), " mm"))
            }
          ),
          Indice_Aridez_UNESCO = reactable::colDef(
            name = "Aridez UNESCO",
            align = "right",
            width = 105,
            cell = function(val) {
              cat_t <- if (val < 0.50) "Semiárido" else if (val < 0.65) "Subhúmedo" else "Húmedo"
              tags$span(title = cat_t, fmt_dec(val, 3))
            }
          ),
          Prob_Estres_Hidrico_pct = reactable::colDef(
            name = "WSI (0–100)",
            align = "right",
            width = 85,
            cell = function(val) {
              tags$span(class = "fw-bold", round(val, 1))
            }
          ),
          Pct_Clase3_4 = reactable::colDef(
            name = "% Área Crítica",
            align = "center",
            width = 125,
            cell = function(val) {
              cls <- if (val >= 70) "badge-stress-4" else if (val >= 25) "badge-stress-3" else "badge-stress-1"
              tags$span(class = cls, paste0(round(val, 1), "%"))
            }
          ),
          P_CV_pct = reactable::colDef(
            name = "CV Lluvia",
            align = "right",
            width = 90,
            cell = function(val) paste0(format(round(val, 1), nsmall = 1), "%")
          ),
          T_trend_decada = reactable::colDef(
            name = "Calentam.",
            align = "right",
            width = 95,
            cell = function(val) {
              tags$span(fmt_sign(val, 2, "°C/déc."))
            }
          ),
          Nivel_Prioridad = reactable::colDef(
            name = "Prioridad",
            align = "center",
            width = 135,
            cell = function(val) {
              cls <- switch(val,
                "Atención Crítica" = "badge bg-danger",
                "Atención Alta"    = "badge bg-warning text-dark",
                "Atención Media"   = "badge bg-info text-dark",
                "badge bg-secondary"
              )
              tags$span(class = cls, val)
            }
          )
        )
      )
    })

    # Radar Comparativo de Vulnerabilidad Multicriterio
    output$plot_radar_comparativo <- plotly::renderPlotly({
      req(data_resumen(), input$radar_distrito_1, input$radar_distrito_2)
      
      df_all <- data_resumen() |> filter(NOMBDIST != "PROVINCIA DE ANTA")
      
      # Función para normalizar variables a escala 0 - 100 donde 100 = máxima limitación
      norm_val <- function(x, reverse = FALSE) {
        rng <- range(x, na.rm = TRUE)
        if (rng[1] == rng[2]) return(rep(50, length(x)))
        res <- (x - rng[1]) / (rng[2] - rng[1]) * 100
        if (reverse) 100 - res else res
      }

      df_norm <- df_all |>
        mutate(
          dim_deficit    = norm_val(Balance_Hidrico_P_PET_mm, reverse = TRUE), # Más negativo = mayor déficit = 100
          dim_aridez     = norm_val(Indice_Aridez_UNESCO, reverse = TRUE),    # Menor índice = mayor aridez = 100
          dim_wsi        = norm_val(Prob_Estres_Hidrico_pct),                 # Mayor WSI = 100
          dim_area_crit  = norm_val(Pct_Clase3_4),                            # Mayor % clases 3-4 = 100
          dim_cv_lluvia  = norm_val(P_CV_pct),                                # Mayor volatilidad = 100
          dim_calentam   = norm_val(T_trend_decada)                           # Mayor calentamiento = 100
        )

      d1 <- df_norm |> filter(NOMBDIST == input$radar_distrito_1)
      d2 <- df_norm |> filter(NOMBDIST == input$radar_distrito_2)

      categorias <- c("Déficit Hídrico", "Aridez Estructural", "Estrés WSI", 
                      "Área Crítica (3-4)", "Inestabilidad Lluvias", "Calentamiento")

      vals_d1 <- c(d1$dim_deficit, d1$dim_aridez, d1$dim_wsi, d1$dim_area_crit, d1$dim_cv_lluvia, d1$dim_calentam)
      vals_d2 <- c(d2$dim_deficit, d2$dim_aridez, d2$dim_wsi, d2$dim_area_crit, d2$dim_cv_lluvia, d2$dim_calentam)

      plotly::plot_ly() |>
        plotly::add_trace(
          type = 'scatterpolar',
          mode = 'lines+markers',
          fill = 'toself',
          r = c(vals_d1, vals_d1[1]),
          theta = c(categorias, categorias[1]),
          name = input$radar_distrito_1,
          line = list(color = "#0284c7", width = 2.5),
          marker = list(color = "#0284c7", size = 6),
          fillcolor = "rgba(2, 132, 199, 0.2)"
        ) |>
        plotly::add_trace(
          type = 'scatterpolar',
          mode = 'lines+markers',
          fill = 'toself',
          r = c(vals_d2, vals_d2[1]),
          theta = c(categorias, categorias[1]),
          name = input$radar_distrito_2,
          line = list(color = "#ea580c", width = 2.5),
          marker = list(color = "#ea580c", size = 6),
          fillcolor = "rgba(234, 88, 12, 0.2)"
        ) |>
        plotly::layout(
          polar = list(
            radialaxis = list(visible = TRUE, range = c(0, 100), tickfont = list(size = 9)),
            angularaxis = list(tickfont = list(size = 10, family = "Inter, sans-serif"))
          ),
          legend = list(orientation = "h", x = 0.1, y = -0.15),
          margin = list(l = 30, r = 30, t = 20, b = 40),
          paper_bgcolor = "rgba(0,0,0,0)",
          font = list(family = "Inter, sans-serif")
        ) |> plotly::config(displayModeBar = FALSE)
    })

    # Interpretación Base Dinámica del Gráfico de Radar
    output$interpretacion_radar <- renderUI({
      req(data_resumen(), input$radar_distrito_1, input$radar_distrito_2)
      
      df_all <- data_resumen() |> filter(NOMBDIST != "PROVINCIA DE ANTA")
      
      norm_val <- function(x, reverse = FALSE) {
        rng <- range(x, na.rm = TRUE)
        if (rng[1] == rng[2]) return(rep(50, length(x)))
        res <- (x - rng[1]) / (rng[2] - rng[1]) * 100
        if (reverse) 100 - res else res
      }
      
      df_norm <- df_all |>
        mutate(
          dim_deficit    = norm_val(Balance_Hidrico_P_PET_mm, reverse = TRUE),
          dim_aridez     = norm_val(Indice_Aridez_UNESCO, reverse = TRUE),
          dim_wsi        = norm_val(Prob_Estres_Hidrico_pct),
          dim_area_crit  = norm_val(Pct_Clase3_4),
          dim_cv_lluvia  = norm_val(P_CV_pct),
          dim_calentam   = norm_val(T_trend_decada)
        )
      
      d1 <- df_norm |> filter(NOMBDIST == input$radar_distrito_1)
      d2 <- df_norm |> filter(NOMBDIST == input$radar_distrito_2)
      req(nrow(d1) > 0, nrow(d2) > 0)
      
      dims_d1 <- c(
        "Déficit Hídrico"       = d1$dim_deficit,
        "Aridez Estructural"    = d1$dim_aridez,
        "Estrés WSI"            = d1$dim_wsi,
        "Área Crítica (3-4)"    = d1$dim_area_crit,
        "Inestabilidad Lluvias" = d1$dim_cv_lluvia,
        "Calentamiento"         = d1$dim_calentam
      )
      dims_d2 <- c(
        "Déficit Hídrico"       = d2$dim_deficit,
        "Aridez Estructural"    = d2$dim_aridez,
        "Estrés WSI"            = d2$dim_wsi,
        "Área Crítica (3-4)"    = d2$dim_area_crit,
        "Inestabilidad Lluvias" = d2$dim_cv_lluvia,
        "Calentamiento"         = d2$dim_calentam
      )
      
      score_d1 <- mean(dims_d1)
      score_d2 <- mean(dims_d2)
      
      top_d1 <- names(dims_d1)[which.max(dims_d1)]
      top_d2 <- names(dims_d2)[which.max(dims_d2)]
      
      dif_dims <- abs(dims_d1 - dims_d2)
      max_gap_dim <- names(dif_dims)[which.max(dif_dims)]
      gap_leader <- if (dims_d1[max_gap_dim] > dims_d2[max_gap_dim]) input$radar_distrito_1 else input$radar_distrito_2
      gap_val <- round(dif_dims[max_gap_dim], 1)
      
      mas_vulnerable <- if (score_d1 > score_d2) input$radar_distrito_1 else input$radar_distrito_2
      dif_score <- abs(score_d1 - score_d2)
      
      div(
        class = "p-2 mt-2 bg-light rounded border",
        div(
          class = "d-flex justify-content-between align-items-center mb-1",
          tags$span(class = "fw-bold small text-primary", icon("lightbulb"), " Interpretación Comparativa de Perfiles:"),
          tags$span(class = "badge bg-secondary", paste0("Brecha: ", round(dif_score, 1), " pts"))
        ),
        p(
          class = "small text-muted mb-1",
          tags$strong(mas_vulnerable), " presenta mayor vulnerabilidad integral relativa (Score: ",
          tags$strong(round(max(score_d1, score_d2), 1), "/100"), "), frente a ",
          tags$strong(if (mas_vulnerable == input$radar_distrito_1) input$radar_distrito_2 else input$radar_distrito_1),
          " (Score: ", tags$strong(round(min(score_d1, score_d2), 1), "/100"), ")."
        ),
        div(
          class = "row g-1 small",
          div(
            class = "col-6",
            tags$span(class = "badge bg-primary text-white me-1", input$radar_distrito_1),
            tags$span(class = "text-muted", "Mayor limitación en "), tags$strong(top_d1), paste0(" (", round(dims_d1[top_d1], 1), "/100).")
          ),
          div(
            class = "col-6",
            tags$span(class = "badge bg-orange text-white me-1", input$radar_distrito_2),
            tags$span(class = "text-muted", "Mayor limitación en "), tags$strong(top_d2), paste0(" (", round(dims_d2[top_d2], 1), "/100).")
          )
        ),
        div(
          class = "mt-1 pt-1 border-top small text-muted",
          icon("arrows-alt-h", class = "me-1 text-danger"),
          "Dimensión con mayor contraste: ", tags$strong(max_gap_dim), " (diferencia de ", tags$strong(paste0(gap_val, " puntos")), " a favor de ", tags$span(class = "text-danger fw-bold", gap_leader), ")."
        )
      )
    })

    # Ficha de Detalle y Tipología de Intervención
    output$ficha_estrategica_detalle <- renderUI({
      req(data_resumen(), input$sel_dist_ficha)
      d_sel <- input$sel_dist_ficha
      row <- data_resumen() |> filter(NOMBDIST == d_sel)
      if (nrow(row) == 0) return(NULL)
      row <- row[1, ]

      div(
        class = "mt-2",
        div(
          class = "p-2 px-3 bg-light rounded border mb-3",
          tags$strong(class = "text-primary small d-block", "RESUMEN DEL MODELO:"),
          tags$span(class = "fw-bold", row$NOMBDIST)
        ),
        tags$p(class = "small text-muted mb-2",
               sprintf("Diferencia P − ETo: %.1f mm/año; WSI: %.1f en escala 0–100; superficie en clases 3 y 4: %.1f %%. Los resultados son estimaciones climáticas y biofísicas, no una medición de disponibilidad de agua ni una recomendación de obra.",
                       row$Balance_Hidrico_P_PET_mm,
                       row$Prob_Estres_Hidrico_pct, row$Pct_Clase3_4))
      )
    })
  })
}
