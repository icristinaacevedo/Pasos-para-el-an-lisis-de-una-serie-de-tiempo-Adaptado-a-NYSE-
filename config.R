# ==============================================================================
# CONFIGURACIÓN GLOBAL DEL PROYECTO
# ==============================================================================
#
# Este archivo contiene todas las configuraciones globales del proyecto
# que se utilizan a lo largo de los diferentes scripts de análisis.
#

# ==============================================================================
# CONFIGURACIÓN DE DIRECTORIOS
# ==============================================================================

# Directorio raíz del proyecto
DIR_ROOT <- getwd()

# Directorios de trabajo
DIR_SCRIPTS <- file.path(DIR_ROOT, "scripts")
DIR_DATA <- file.path(DIR_ROOT, "data")
DIR_OUTPUTS <- file.path(DIR_ROOT, "outputs")
DIR_FIGURES <- file.path(DIR_ROOT, "figures")
DIR_DOCS <- file.path(DIR_ROOT, "docs")
#DIR_NOTEBOOK <- file.path(DIR_ROOT, "notebooks")

# Subdirectorios de outputs
DIR_TABLAS <- file.path(DIR_OUTPUTS, "tablas")
DIR_MODELOS <- file.path(DIR_OUTPUTS, "modelos")

# Crear directorios si no existen
dirs <- c(DIR_SCRIPTS, DIR_DATA, DIR_OUTPUTS, DIR_FIGURES, DIR_DOCS,
          DIR_TABLAS, DIR_MODELOS)

for (dir in dirs) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
}

# ==============================================================================
# CONFIGURACIÓN DE VISUALIZACIÓN
# ==============================================================================

# Configuración de gráficos
GRAPH_WIDTH <- 12
GRAPH_HEIGHT <- 8
GRAPH_DPI <- 300
GRAPH_DEVICE <- "png"  # Opciones: "png", "pdf", "jpeg"

# Colores del tema
COLOR_PRIMARY <- "#1F4788"
COLOR_SECONDARY <- "#2E5C8A"
COLOR_ACCENT <- "#E74C3C"
COLOR_SUCCESS <- "#27AE60"
COLOR_WARNING <- "#F39C12"

# Tema de ggplot2
library(ggplot2)
THEME_CUSTOM <- theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", color = COLOR_PRIMARY),
    plot.subtitle = element_text(size = 12, color = "gray30"),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 10),
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    panel.grid.major = element_line(color = "gray90"),
    panel.grid.minor = element_line(color = "gray95")
  )

# ==============================================================================
# CONFIGURACIÓN DE ANÁLISIS
# ==============================================================================

# Parámetros para análisis de series temporales
PERIODO_ESTACIONAL <- NA  # Frecuencia estacional (12 para datos mensuales) 
NIVEL_CONFIANZA <- 0.95   # Nivel de confianza para intervalos
MAX_LAGS_ACF <- 30        # Número máximo de rezagos en ACF/PACF
VENTANA_MOVIL <- 21       # Ventana para medias móviles

# Horizonte de pronóstico
HORIZONTE_PRONOSTICO <- 20  # Número de períodos a pronosticar

# División train/test
PROPORCION_TRAIN <- 0.8  # 80% para entrenamiento, 20% para prueba

# ==============================================================================
# CONFIGURACIÓN DE MODELOS
# ==============================================================================

# Búsqueda de modelos ARIMA
MAX_P <- 5  # Máximo orden AR
MAX_Q <- 5  # Máximo orden MA
MAX_P_SEASONAL <- 2  # Máximo orden AR estacional
MAX_Q_SEASONAL <- 2  # Máximo orden MA estacional

# Criterio de selección de modelos
CRITERIO_SELECCION <- "aic"  # Opciones: "aic", "bic", "aicc"

# ==============================================================================
# CONFIGURACIÓN DE REPORTES
# ==============================================================================

# Formato de fechas
FORMATO_FECHA <- "%Y-%m-%d"

# Número de decimales en reportes
DECIMALES_ESTADISTICAS <- 4
DECIMALES_PRONOSTICOS <- 2

# ==============================================================================
# FUNCIONES AUXILIARES
# ==============================================================================

# Función para guardar gráficos de forma consistente
guardar_grafico <- function(plot, nombre_archivo, width = GRAPH_WIDTH, 
                           height = GRAPH_HEIGHT, dpi = GRAPH_DPI) {
  ruta_completa <- file.path(DIR_FIGURES, nombre_archivo)
  
  ggsave(
    filename = ruta_completa,
    plot = plot,
    width = width,
    height = height,
    dpi = dpi,
    device = GRAPH_DEVICE
  )
  
  cat(sprintf("✅ Gráfico guardado: %s\n", nombre_archivo))
  return(ruta_completa)
}

# Función para guardar tablas
guardar_tabla <- function(datos, nombre_archivo) {
  ruta_completa <- file.path(DIR_TABLAS, nombre_archivo)
  write.csv(datos, ruta_completa, row.names = FALSE)
  cat(sprintf("✅ Tabla guardada: %s\n", nombre_archivo))
  return(ruta_completa)
}

# Función para guardar modelos
guardar_modelo <- function(modelo, nombre_archivo) {
  ruta_completa <- file.path(DIR_MODELOS, nombre_archivo)
  saveRDS(modelo, ruta_completa)
  cat(sprintf("✅ Modelo guardado: %s\n", nombre_archivo))
  return(ruta_completa)
}

# Función para cargar modelos
cargar_modelo <- function(nombre_archivo) {
  ruta_completa <- file.path(DIR_MODELOS, nombre_archivo)
  modelo <- readRDS(ruta_completa)
  cat(sprintf("✅ Modelo cargado: %s\n", nombre_archivo))
  return(modelo)
}

# Función para imprimir separadores en consola
separador <- function(titulo = NULL, ancho = 80) {
  if (is.null(titulo)) {
    cat(rep("=", ancho), "\n", sep = "")
  } else {
    n_equals <- (ancho - nchar(titulo) - 2) / 2
    cat(rep("=", floor(n_equals)), " ", titulo, " ", 
        rep("=", ceiling(n_equals)), "\n", sep = "")
  }
}

# ==============================================================================
# INFORMACIÓN DEL SISTEMA
# ==============================================================================

# Mostrar información de configuración
mostrar_info_config <- function() {
  separador("CONFIGURACIÓN DEL PROYECTO")
  cat("\n")
  cat("📁 Directorios:\n")
  cat(sprintf("  • Root: %s\n", DIR_ROOT))
  cat(sprintf("  • Scripts: %s\n", DIR_SCRIPTS))
  cat(sprintf("  • Datos: %s\n", DIR_DATA))
  cat(sprintf("  • Outputs: %s\n", DIR_OUTPUTS))
  cat(sprintf("  • Figuras: %s\n", DIR_FIGURES))
  cat("\n")
  cat("🔧 Parámetros de análisis:\n")
  cat(sprintf("  • Período estacional: %d\n", PERIODO_ESTACIONAL))
  cat(sprintf("  • Nivel de confianza: %.2f%%\n", NIVEL_CONFIANZA * 100))
  cat(sprintf("  • Horizonte de pronóstico: %d períodos\n", HORIZONTE_PRONOSTICO))
  cat(sprintf("  • Proporción train/test: %.0f%%/%.0f%%\n", 
              PROPORCION_TRAIN * 100, (1 - PROPORCION_TRAIN) * 100))
  cat("\n")
  cat("📊 Configuración de gráficos:\n")
  cat(sprintf("  • Dimensiones: %d x %d\n", GRAPH_WIDTH, GRAPH_HEIGHT))
  cat(sprintf("  • DPI: %d\n", GRAPH_DPI))
  cat(sprintf("  • Formato: %s\n", GRAPH_DEVICE))
  cat("\n")
  separador()
}

# Mensaje de bienvenida
cat("\n")
separador("ANÁLISIS DE SERIES TEMPORALES - NYSE")
cat("\nConfiguración cargada exitosamente\n\n")
cat(" Usa mostrar_info_config() para ver todos los parámetros\n\n")



