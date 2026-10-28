# ==============================================================================
# APP.R: Sistema de Información y Monitoreo Hidroclimático Territorial de Anta
# Municipalidad Provincial de Anta - Gerencia de Desarrollo Urbano y Rural (GDUR)
# Resolución Espacial: 30 metros (PISCO-SENAMHI / GEE / ERA5-Land / Sentinel-2)
# Periodo de Monitoreo: 2001–2025 (25 Años)
# ==============================================================================

# Si los datos de la edición completa no están presentes, servir la edición
# distrital autónoma. En GitHub los rásteres grandes se guardan por partes.
if (identical(Sys.getenv("ANTA_CLOUD_LITE"), "1") ||
    !file.exists("app_data/resumen_distrital.rds")) {
  shiny::shinyAppDir("cloud_lite")
} else {

# Soporte de bibliotecas locales para Windows. RStudio no siempre propaga
# R_LIBS_USER al iniciar una aplicación; por ello se incorpora la biblioteca
# de usuario de la versión activa cuando exista.
if (dir.exists(".r-library")) {
  .libPaths(c(file.path(getwd(), ".r-library"), .libPaths()))
}
user_r_roots <- unique(c(
  file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library"),
  file.path(Sys.getenv("USERPROFILE"), "AppData", "Local", "R", "win-library")
))
version_parts <- strsplit(R.version$minor, "\\.")[[1]]
user_r_version <- paste(R.version$major, version_parts[1], sep = ".")
for (user_r_root in user_r_roots) {
  if (dir.exists(user_r_root)) {
    user_r_lib <- file.path(user_r_root, user_r_version)
    if (dir.exists(user_r_lib)) {
      .libPaths(c(user_r_lib, .libPaths()))
    }
  }
}

# Normalizar codificación UTF-8 en Windows para caracteres en español
invisible(try(Sys.setlocale("LC_CTYPE", "English_United States.utf8"), silent = TRUE))

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(leaflet)
  library(plotly)
  library(reactable)
  library(dplyr)
  library(sf)
  library(terra)
  library(htmltools)
})

if (!requireNamespace("writexl", quietly = TRUE)) {
  stop("No se encontró el paquete 'writexl', requerido para descargar los datos del punto en formato XLSX.")
}

# Cargar funciones auxiliares y módulos analíticos
source("R/utils_data.R", encoding = "UTF-8")
source("R/github_rasters.R", encoding = "UTF-8")
source("R/mod_guia_indicadores.R", encoding = "UTF-8")
source("R/mod_portada_situacion.R", encoding = "UTF-8")
source("R/mod_clima_anual.R", encoding = "UTF-8")
source("R/mod_evolucion_tendencias.R", encoding = "UTF-8")
source("R/mod_balance_aridez.R", encoding = "UTF-8")
source("R/mod_priorizacion_territorial.R", encoding = "UTF-8")
source("R/mod_consulta_ubicacion.R", encoding = "UTF-8")
source("R/mod_metodologia_datos.R", encoding = "UTF-8")

# Carga de datos optimizados compartidos en memoria (una sola vez por proceso)
ensure_github_rasters()
app_data <- load_app_data()

# ── Interfaz de Usuario (UI) ──────────────────────────────────────────────────
ui <- page_fluid(
  theme = bs_theme(
    version = 5,
    primary = "#0b3b60",
    secondary = "#1e293b",
    success = "#059669",
    warning = "#d97706",
    danger = "#dc2626",
    info = "#0284c7",
    bg = "#f8fafc",
    fg = "#1e293b"
  ),
  
  # Inyección de estilos institucionales
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
    tags$title("Sistema de Información Hidroclimática Territorial — Provincia de Anta (30 m)")
  ),
  
  # Encabezado Institucional
  div(
    class = "institutional-header",
    div(
      class = "container-fluid header-shell",
      div(
        class = "header-topline",
        div(
          class = "header-brand",
          tags$img(src = "logo_anta.jpg", class = "logo-img", alt = "Escudo Institucional Municipalidad Provincial de Anta"),
          div(
            class = "header-institution",
            tags$p("MUNICIPALIDAD PROVINCIAL DE ANTA", class = "institution-name"),
            tags$p("Gerencia de Desarrollo Urbano y Rural — GDUR", class = "institution-unit"),
            tags$p("SUB GERENCIA DE PLANEAMIENTO URBANO Y ACONDICIONAMIENTO TERRITORIAL", class = "institution-subunit")
          )
        ),
        div(
          class = "header-system",
          tags$p("PLATAFORMA DE INFORMACIÓN TERRITORIAL", class = "system-kicker"),
          tags$h1("Sistema de Información y Análisis Hidroclimático Territorial"),
          tags$p("Estimaciones anuales 2001–2025 ajustadas con PISCO; píxeles fuente de 30 m y mapas web generalizados a ~150 m.", class = "system-description")
        ),
        div(
          class = "header-context",
          div(class = "context-location", icon("map-marker-alt"), " Provincia de Anta — Cusco"),
          div(class = "context-meta", "Modelo 30 m · mapa ~150 m | 9 distritos"),
          span(class = "update-badge", "Beta referencial · datos hasta 2025")
        )
      )
    )
  ),
  
  # Banner de contexto técnico y alcance de la plataforma
  div(
    class = "container-fluid px-4 pt-3",
    div(
      class = "platform-context-banner",
      # Columna 1: qué es
      div(
        class = "pcb-block pcb-block-what",
        tags$span(class = "pcb-label", icon("database", class = "me-1"), "BASE DE DATOS"),
        tags$p(class = "pcb-text",
          "Estimaciones de temperatura y precipitación a ",
          tags$strong("30 m de resolución (2001–2025)"),
          " generadas mediante modelado espacial en Google Earth Engine
          (ERA5-Land · CHIRPS · SRTM · Sentinel-2) y ajustadas con las
          mallas oficiales del SENAMHI ",
          tags$strong("(PISCOp v3.0 · PISCOt v1.2 · PISCOeo_pm)"),
          " como referencias regionales. No son lecturas directas ni valores
          de exactitud comprobada para cada punto del territorio."
        )
      ),
      div(class = "pcb-divider"),
      # Columna 2: contraste disponible
      div(
        class = "pcb-block pcb-block-validation",
        tags$span(class = "pcb-label", icon("chart-line", class = "me-1"), "CONTRASTE DISPONIBLE"),
        tags$p(class = "pcb-text",
          "El ajuste usa PISCO como referencia regional, pero no certifica
          la precisión local a 30 m. El contraste con las dos estaciones disponibles
          dentro de Anta detectó sesgos térmicos medios de +1,81 °C en Ancachuro
          y +4,92 °C en Soraypampa. Estas estaciones pudieron contribuir a PISCO;
          el contraste no es una validación independiente."
        )
      ),
      div(class = "pcb-divider"),
      # Columna 3: alcance y límite
      div(
        class = "pcb-block pcb-block-scope",
        tags$span(class = "pcb-label", icon("bullseye", class = "me-1"), "ALCANCE Y LÍMITES"),
        tags$p(class = "pcb-text",
          "Apropiado para análisis de ",
          tags$strong("patrones climáticos a escala distrital y provincial"),
          ", comparación territorial y planificación de primer nivel.
          La temperatura 2021–2025 extiende el periodo con el sesgo histórico calibrado,
          no con datos PISCO nuevos. Vea ",
          tags$a(href = "#", onclick = "Shiny.setInputValue('main_nav', 'Datos & Metodología', {priority: 'event'});",
                 "Datos & Metodología", class = "pcb-link"),
          " para el detalle completo del flujo metodológico."
        )
      )
    )
  ),

  div(
    class = "app-navigation",
    div(
      class = "container-fluid px-4",
      navset_pill(
        id = "main_nav",
        
        nav_panel(
          title = tags$span(icon("home"), " Situación Climática"),
          div(class = "pt-3", mod_portada_situacion_ui("portada"))
        ),
        
        nav_panel(
          title = tags$span(icon("globe-americas"), " Clima Anual"),
          div(class = "pt-3", mod_clima_anual_ui("clima_anual"))
        ),
        
        nav_panel(
          title = tags$span(icon("chart-line"), " Evolución 2001–2025"),
          div(class = "pt-3", mod_evolucion_tendencias_ui("evolucion"))
        ),
        
        nav_panel(
          title = tags$span(icon("tint"), " Balance Hídrico & Aridez"),
          div(class = "pt-3", mod_balance_aridez_ui("balance"))
        ),
        
        nav_panel(
          title = tags$span(icon("bullseye"), " Priorización Territorial"),
          div(class = "pt-3", mod_priorizacion_territorial_ui("priorizacion"))
        ),
        
        nav_panel(
          title = tags$span(icon("crosshairs"), " Consulta por Ubicación (30m)"),
          div(class = "pt-3", mod_consulta_ubicacion_ui("consulta"))
        ),
        
        nav_panel(
          title = tags$span(icon("book-open"), " Datos & Metodología"),
          div(class = "pt-3", mod_metodologia_datos_ui("metodologia"))
        )
      )
    )
  ),
  
  # Footer Institucional
  tags$footer(
    class = "institutional-footer",
    div(
      class = "container footer-shell",
      div(
        class = "footer-identity",
        tags$p(tags$strong("Municipalidad Provincial de Anta"), " — Gerencia de Desarrollo Urbano y Rural (GDUR)"),
        tags$p("Plataforma de Información y Análisis Hidroclimático Territorial — Revisión técnica 2026")
      ),
      div(
        class = "footer-provenance",
        tags$p("Datos Oficiales: SENAMHI (PISCOp v3.0, PISCOt v1.2, PISCOeo_pm)"),
        tags$p("Reanálisis y Teledetección: ERA5-Land · CHIRPS · Sentinel-2 MSI · SRTM DEM (30 m)")
      )
    )
  )
)

# ── Lógica del Servidor (Server) ──────────────────────────────────────────────
server <- function(input, output, session) {
  
  # Exponer reactivos compartidos desde el caché de memoria
  data_resumen <- reactive({
    app_data$resumen
  })
  
  data_series <- reactive({
    app_data$series_anuales
  })
  
  sf_distritos <- reactive({
    app_data$distritos_sf
  })
  
  sf_distritos_wgs84 <- reactive({
    app_data$distritos_wgs84
  })
  
  sf_provincia_wgs84 <- reactive({
    app_data$provincia_wgs84
  })
  
  r_p_wgs84 <- reactive({
    app_data$p_wgs84
  })
  
  r_t_wgs84 <- reactive({
    app_data$t_wgs84
  })
  
  r_disp_wgs84 <- reactive({
    app_data$r_disp_wgs84
  })
  
  p_30m_ref <- reactive({
    app_data$p_30m_ref
  })
  
  t_30m_ref <- reactive({
    app_data$t_30m_ref
  })
  
  estres_30m_ref <- reactive({
    app_data$estres_30m_ref
  })
  
  var_30m_ref <- reactive({
    app_data$var_30m_ref
  })
  
  estres_base_ref <- reactive({
    app_data$estres_base_ref
  })

  # Invocar los 7 módulos funcionales
  mod_portada_situacion_server("portada", data_resumen, data_series, sf_distritos)
  mod_clima_anual_server("clima_anual", data_series, data_resumen, sf_distritos_wgs84, r_p_wgs84, r_t_wgs84, r_disp_wgs84)
  mod_evolucion_tendencias_server("evolucion", data_series, data_resumen)
  mod_balance_aridez_server("balance", data_resumen, sf_distritos_wgs84, r_disp_wgs84)
  mod_priorizacion_territorial_server("priorizacion", data_resumen)
  mod_consulta_ubicacion_server("consulta", sf_distritos, sf_distritos_wgs84, p_30m_ref, t_30m_ref, estres_30m_ref, estres_base_ref, r_disp_wgs84)
  mod_metodologia_datos_server("metodologia", data_series, data_resumen)
}

# Ejecutar la aplicación
shinyApp(ui = ui, server = server)
}
