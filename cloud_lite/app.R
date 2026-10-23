# Clima de Anta: edición territorial agregada para Posit Connect Cloud.
# Usa solamente las copias públicas incluidas en www/data.

library(shiny)

datos_dir <- file.path("www", "data")
series <- read.csv(file.path(datos_dir, "series_anuales_2001_2025_anta.csv"),
                   fileEncoding = "UTF-8", stringsAsFactors = FALSE)
resumen <- read.csv(file.path(datos_dir, "resumen_hidroclimatico_distrital_anta.csv"),
                    fileEncoding = "UTF-8", stringsAsFactors = FALSE)
contraste <- read.csv(file.path(datos_dir, "validacion_red_estaciones.csv"),
                     fileEncoding = "UTF-8", stringsAsFactors = FALSE)

stopifnot(nrow(series) == 250L, nrow(resumen) == 10L,
          all(c("NOMBDIST", "Year", "Precipitacion_mm", "Temperatura_C") %in% names(series)),
          all(c("NOMBDIST", "P_media", "T_media", "Indice_susceptibilidad_WSI_0_100") %in% names(resumen)))

provincia <- "PROVINCIA DE ANTA"
ambitos <- c(provincia, sort(setdiff(unique(series$NOMBDIST), provincia)))
indicadores <- c(
  "Precipitación media anual (mm)" = "P_media",
  "Temperatura media anual (°C)" = "T_media",
  "Susceptibilidad hídrica relativa (0–100)" = "Indice_susceptibilidad_WSI_0_100",
  "Variación interanual de lluvia (%)" = "P_CV_pct"
)

archivo_descarga <- function(nombre, etiqueta) {
  tags$a(href = paste0("data/", nombre), download = nombre,
         class = "download-link", etiqueta)
}

ui <- fluidPage(
  tags$head(tags$meta(charset = "utf-8"),
            tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
            tags$link(rel = "stylesheet", href = "styles.css")),
  div(class = "hero",
      div(class = "eyebrow", "Provincia de Anta · Cusco · 2001–2025"),
      h1("Clima de Anta"),
      p(class = "hero-subtitle", "Edición territorial agregada · beta referencial"),
      p("Explore estimaciones anuales de lluvia, temperatura e indicadores resumidos para nueve distritos y la provincia.")),
  div(class = "scope-note",
      strong("Alcance de esta edición: "),
      "muestra promedios y series por territorio. No incluye mapas de celdas ni consulta puntual de 30 m. ",
      "Los datos son resultados modelados ajustados con PISCO, no mediciones directas de cada lugar."),
  tabsetPanel(
    id = "seccion",
    tabPanel("Series anuales",
      div(class = "section-wrap",
          fluidRow(
            column(5, selectInput("ambito", "Ámbito territorial", choices = ambitos,
                                  selected = provincia)),
            column(5, selectInput("variable", "Variable", choices = c(
              "Precipitación anual (mm)" = "Precipitacion_mm",
              "Temperatura media anual (°C)" = "Temperatura_C")))
          ),
          fluidRow(
            column(4, div(class = "metric-card", span("Media de lluvia"),
                          strong(textOutput("p_media", inline = TRUE)))),
            column(4, div(class = "metric-card", span("Media de temperatura"),
                          strong(textOutput("t_media", inline = TRUE)))),
            column(4, div(class = "metric-card", span("WSI relativo"),
                          strong(textOutput("wsi", inline = TRUE))))
          ),
          div(class = "chart-card", plotOutput("serie_plot", height = "380px")),
          p(class = "fineprint", "La línea de referencia es la media del ámbito en 2001–2025. ",
            "La serie tiene 25 años y no demuestra por sí sola causas ni evolución futura.")
      )
    ),
    tabPanel("Comparar territorios",
      div(class = "section-wrap",
          selectInput("indicador", "Indicador agregado", choices = indicadores),
          div(class = "chart-card", plotOutput("comparacion_plot", height = "430px")),
          p(class = "fineprint", "El WSI es una escala relativa de 0 a 100, no una probabilidad. ",
            "La diferencia P − ETo no mide disponibilidad de agua. ",
            "Los pesos y umbrales del WSI no cuentan con validación de campo."),
          h3("Resumen territorial"),
          tableOutput("resumen_tabla")
      )
    ),
    tabPanel("Datos y límites",
      div(class = "section-wrap prose",
          h2("Cómo usar estos resultados"),
          p("Esta edición sirve para explorar patrones climáticos generales y comparar ",
            "estimaciones modeladas a escala distrital y provincial. El tamaño de celda ",
            "del modelo original (30 m) no equivale a exactitud instrumental; esta edición ",
            "solo muestra agregados territoriales."),
          p("Solo Ancachuro y Soraypampa están dentro del territorio modelado con datos ",
            "disponibles para el contraste. Pudieron alimentar PISCO, por lo que la ",
            "comparación no constituye validación independiente. El producto final mostró ",
            "sesgos térmicos medios de +1,81 °C y +4,92 °C, respectivamente."),
          p("La temperatura de 2021–2025 se extendió con un sesgo histórico calibrado; ",
            "no procede de PISCOt nuevo. La ETo anual se estimó mediante una fórmula ",
            "empírica dependiente de temperatura, sin recalcular Penman–Monteith completo ",
            "para cada año."),
          div(class = "warning-box", strong("Para decisiones sobre parcelas, obras, ",
              "riego o disponibilidad de agua se requieren observaciones y estudios locales.")),
          h3("Descargar datos públicos"),
          archivo_descarga("series_anuales_2001_2025_anta.csv", "Series anuales · CSV"),
          archivo_descarga("resumen_hidroclimatico_distrital_anta.csv", "Resumen territorial · CSV"),
          archivo_descarga("validacion_red_estaciones.csv", "Contraste con estaciones · CSV"),
          archivo_descarga("distritos_anta.geojson", "Límites distritales · GeoJSON"),
          h3("Contraste de estaciones interiores"),
          tableOutput("contraste_tabla"),
          p(class = "fineprint", "Sesgo = modelo menos estación. Los años válidos son escasos ",
            "y la red puede no ser independiente de PISCO.")
      )
    )
  ),
  div(class = "footer", "Clima de Anta · Beta referencial · Resultados modelados para exploración territorial")
)

server <- function(input, output, session) {
  fila_ambito <- reactive(resumen[resumen$NOMBDIST == input$ambito, , drop = FALSE])
  output$p_media <- renderText(sprintf("%.0f mm/año", fila_ambito()$P_media))
  output$t_media <- renderText(sprintf("%.1f °C", fila_ambito()$T_media))
  output$wsi <- renderText(sprintf("%.1f / 100", fila_ambito()$Indice_susceptibilidad_WSI_0_100))

  output$serie_plot <- renderPlot({
    d <- series[series$NOMBDIST == input$ambito, , drop = FALSE]
    d <- d[order(d$Year), , drop = FALSE]
    y <- d[[input$variable]]
    promedio <- mean(y)
    unidad <- if (input$variable == "Precipitacion_mm") "mm/año" else "°C"
    par(mar = c(4.5, 5, 2, 1))
    plot(d$Year, y, type = "b", pch = 16, lwd = 2, col = "#087e8b",
         xlab = "Año", ylab = unidad, xaxt = "n", cex.lab = 1.1)
    axis(1, at = seq(2001, 2025, by = 4))
    abline(h = promedio, lty = 2, col = "#d97706", lwd = 2)
    grid(col = "#e2e8f0")
    lines(d$Year, y, type = "b", pch = 16, lwd = 2, col = "#087e8b")
    legend("topright", legend = c("Estimación anual", "Media 2001–2025"),
           col = c("#087e8b", "#d97706"), lty = c(1, 2), bty = "n", cex = 0.9)
  }, res = 110)

  output$comparacion_plot <- renderPlot({
    d <- resumen[resumen$NOMBDIST != provincia, , drop = FALSE]
    d <- d[order(d[[input$indicador]]), , drop = FALSE]
    valores <- d[[input$indicador]]
    par(mar = c(4.5, 10, 2, 1))
    barplot(valores, names.arg = d$NOMBDIST, horiz = TRUE, las = 1,
            col = "#087e8b", border = NA,
            xlab = names(indicadores)[match(input$indicador, indicadores)],
            cex.names = 0.85)
    grid(nx = NULL, ny = NA, col = "#e2e8f0")
  }, res = 110)

  output$resumen_tabla <- renderTable({
    d <- resumen[, c("NOMBDIST", "P_media", "T_media", "Indice_susceptibilidad_WSI_0_100")]
    names(d) <- c("Territorio", "Lluvia media (mm/año)", "Temperatura media (°C)", "WSI (0–100)")
    d[-1] <- lapply(d[-1], function(x) round(x, 1))
    d
  }, striped = TRUE, bordered = FALSE, spacing = "s")

  output$contraste_tabla <- renderTable({
    d <- contraste[contraste$producto == "modelo" &
                    contraste$estacion %in% c("ANCACHURO", "SORAYPAMPA"),
                  c("estacion", "variable", "n", "sesgo", "MAE")]
    names(d) <- c("Estación", "Variable", "Años válidos", "Sesgo", "MAE")
    d$Sesgo <- round(d$Sesgo, 2)
    d$MAE <- round(d$MAE, 2)
    d$Variable <- ifelse(d$Variable == "T", "Temperatura (°C)", "Lluvia (mm/año)")
    d
  }, striped = TRUE, bordered = FALSE, spacing = "s")
}

shinyApp(ui, server)
