# ==============================================================================
# SCRIPT PRINCIPAL - ANÁLISIS COMPLETO DE SERIE TEMPORAL NYSE
# ==============================================================================
#
# Este script ejecuta el análisis completo de la serie temporal NYSE
# en orden secuencial, llamando a cada uno de los scripts individuales.
#
# Autor: [Isabel Cristina Acevedo Agudelo]
# Fecha: Enero 2026
#

# Limpiar workspace
rm(list = ls())
gc()

# ==============================================================================
# CONFIGURACIÓN INICIAL
# ==============================================================================

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════════╗\n")
cat("║                  ANÁLISIS DE SERIES TEMPORALES - NYSE                     ║\n")
cat("║                  New York Stock Exchange (1962-1975)                      ║\n")
cat("╚════════════════════════════════════════════════════════════════════════════╝\n")
cat("\n")

# Registrar tiempo de inicio
tiempo_inicio <- Sys.time()

# Cargar configuración global
cat("📋 Cargando configuración...\n")
source("config.R")

# Selecciona un mirror cercano
#chooseCRANmirror(ind = 77)  # Colombia

# Instalar paquetes
paquetes <- c(
  "forecast",      # Modelos de pronóstico y herramientas ARIMA
  "tseries",       # Pruebas de estacionariedad (ADF, KPSS)
  "ggplot2",       # Visualización avanzada de datos
  "zoo",           # Manipulación de series temporales
  "gridExtra",     # Composición de múltiples gráficos
  "dplyr",         # Manipulación de datos
  "tidyr",         # Limpieza y transformación de datos
  "knitr",         # Generación de reportes
  "kableExtra",    # Tablas con formato mejorado
  "scales",        # Escalas y formateo para gráficos
  "lubridate",     # Manejo de fechas
  "ggfortify",      # Extensión de ggplot2 para series temporales
  "timeDate"
)



# Función para instalar paquetes faltantes
instalar_si_falta <- function(paquete) {
  if (!require(paquete, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("  ⬇️  Instalando %s...\n", paquete))
    install.packages(paquete, dependencies = TRUE, quiet = TRUE)
    library(paquete, character.only = TRUE)
    cat(sprintf("  ✅ %s instalado correctamente\n", paquete))
  } else {
    cat(sprintf("  ✓ %s ya está instalado\n", paquete))
  }
}



# Cargar librerías necesarias
cat("\n📦 Cargando librerías...\n")

library(astsa)
library(forecast)
library(tseries)
library(ggplot2)
library(zoo)
library(gridExtra)
library(dplyr)
library(timeDate)
library(moments)

cat("✅ Librerías cargadas exitosamente\n")

# Mostrar información de configuración
mostrar_info_config()

# ==============================================================================
# PARÁMETROS DE EJECUCIÓN
# ==============================================================================

# Opciones de ejecución (cambiar a FALSE para omitir pasos)
EJECUTAR <- list(
  paso_01 = TRUE,   # Carga y exploración inicial
  paso_02 = TRUE,   # Visualización
  paso_03 = FALSE,  # Descomposición (omitir para datos diarios)
  paso_04 = TRUE,   # Estacionariedad
  paso_05 = TRUE,   # Autocorrelación
  paso_06 = TRUE,   # Diferenciación
  paso_6_5 = TRUE,  # Transformaciones ← CAMBIO AQUÍ
  paso_07 = FALSE,   # Identificación del modelo
  paso_08 = TRUE,   # Diagnóstico
  paso_09 = TRUE,   # Pronóstico
  paso_10 = TRUE,   # Evaluación
  paso_11 = TRUE    # Modelos de volatilidad ← CAMBIO AQUÍ (era paaso_11)
)

# Pausar entre pasos (útil para revisión)
PAUSAR_ENTRE_PASOS <- FALSE

# ==============================================================================
# FUNCIÓN AUXILIAR PARA EJECUTAR PASOS
# ==============================================================================

ejecutar_paso <- function(numero, nombre, archivo) {
  # Manejar pasos con decimales (ej: 6.5) ← AGREGAR ESTA SECCIÓN
  if (numero == floor(numero)) {
    # Es entero
    paso_id <- paste0("paso_", sprintf("%02d", numero))
  } else {
    # Tiene decimales, reemplazar punto por guion bajo
    paso_id <- paste0("paso_", gsub("\\.", "_", as.character(numero)))
  }
  
  if (EJECUTAR[[paso_id]]) {
    # Usar %.1f en lugar de %d para soportar decimales ← CAMBIO AQUÍ
    separador(sprintf("PASO %.1f: %s", numero, nombre))
    cat("\n")
    cat(sprintf("📂 Ejecutando: %s\n", archivo))
    cat("\n")
    
    tiempo_paso_inicio <- Sys.time()
    
    tryCatch({
      source(file.path(DIR_SCRIPTS, archivo), encoding = "UTF-8")
      
      tiempo_paso_fin <- Sys.time()
      duracion <- difftime(tiempo_paso_fin, tiempo_paso_inicio, units = "secs")
      
      cat("\n")
      # Usar %.1f aquí también ← CAMBIO AQUÍ
      cat(sprintf("✅ Paso %.1f completado exitosamente (%.2f segundos)\n", 
                  numero, as.numeric(duracion)))
      cat("\n")
      
      # Cambiar condición a 11 ← CAMBIO AQUÍ
      if (PAUSAR_ENTRE_PASOS && numero < 11) {
        cat("⏸️  Presiona ENTER para continuar...")
        readline()
      }
      
    }, error = function(e) {
      cat("\n")
      # Usar %.1f aquí también ← CAMBIO AQUÍ
      cat(sprintf("❌ ERROR en Paso %.1f: %s\n", numero, e$message))
      cat("\n")
      stop(sprintf("Ejecución detenida en Paso %.1f", numero))
    })
    
  } else {
    # Usar %.1f aquí también ← CAMBIO AQUÍ
    cat(sprintf("⏭️  Paso %.1f omitido (deshabilitado en configuración)\n\n", numero))
  }
}

# ==============================================================================
# EJECUCIÓN DE TODOS LOS PASOS
# ==============================================================================

cat("\n")
separador("INICIANDO ANÁLISIS COMPLETO")
cat("\n")

# PASO 1: Carga y Exploración Inicial
ejecutar_paso(
  numero = 1,
  nombre = "Carga y Exploración Inicial",
  archivo = "01_carga_exploracion.R"
)

# PASO 2: Visualización
ejecutar_paso(
  numero = 2,
  nombre = "Visualización de la Serie",
  archivo = "02_visualizacion.R"
)

# PASO 3: Descomposición
ejecutar_paso(
  numero = 3,
  nombre = "Descomposición de la Serie",
  archivo = "03_descomposicion.R"
)

# PASO 4: Estacionariedad
ejecutar_paso(
  numero = 4,
  nombre = "Análisis de Estacionariedad",
  archivo = "04_estacionariedad.R"
)

# PASO 5: Autocorrelación
ejecutar_paso(
  numero = 5,
  nombre = "Análisis de Autocorrelación (ACF/PACF)",
  archivo = "05_autocorrelacion.R"
)

# PASO 6: Diferenciación
ejecutar_paso(
  numero = 6,
  nombre = "Diferenciación de la Serie",
  archivo = "06_diferenciacion.R"
)


#PASO 6_5: transformaciones
ejecutar_paso(
  numero = 6.5,
  nombre = "Transformaciones de la Serie",
  archivo = "06_5_transformaciones.R"  # ← CORREGIR NOMBRE (era transformacioes)
)

# PASO 7: Identificación del Modelo
ejecutar_paso(
  numero = 7,
  nombre = "Identificación y Selección del Modelo",
  archivo = "07_identificacion_modelo.R"
)

# PASO 8: Diagnóstico
ejecutar_paso(
  numero = 8,
  nombre = "Diagnóstico del Modelo",
  archivo = "08_diagnostico.R"
)

# PASO 9: Pronóstico
ejecutar_paso(
  numero = 9,
  nombre = "Generación de Pronósticos",
  archivo = "09_pronostico.R"
)

# PASO 10: Evaluación
ejecutar_paso(
  numero = 10,
  nombre = "Evaluación del Modelo",
  archivo = "10_evaluacion.R"
)

#PASO 11:modelo s volatilidad
ejecutar_paso(
  numero = 11,
  nombre = "Evaluación del Modelo",
  archivo = "11_modelos_volatilidad.R"
)

# ==============================================================================
# FINALIZACIÓN
# ==============================================================================

# Calcular tiempo total
tiempo_fin <- Sys.time()
duracion_total <- difftime(tiempo_fin, tiempo_inicio, units = "mins")

cat("\n")
separador("ANÁLISIS COMPLETADO")
cat("\n")
cat(sprintf("⏱️  Tiempo total de ejecución: %.2f minutos\n", as.numeric(duracion_total)))
cat(sprintf("📅 Fecha de finalización: %s\n", format(tiempo_fin, "%Y-%m-%d %H:%M:%S")))
cat("\n")
cat("📂 Resultados guardados en:\n")
cat(sprintf("   • Gráficos: %s\n", DIR_FIGURES))
cat(sprintf("   • Tablas: %s\n", DIR_TABLAS))
cat(sprintf("   • Modelos: %s\n", DIR_MODELOS))
cat("\n")
cat("✅ Análisis finalizado exitosamente!\n")
cat("\n")
separador()
cat("\n")

# Resumen de archivos generados
cat("📊 Archivos generados:\n\n")
cat("Gráficos:\n")
archivos_figuras <- list.files(DIR_FIGURES, pattern = "\\.(png|pdf|jpeg)$")
if (length(archivos_figuras) > 0) {
  for (archivo in archivos_figuras) {
    cat(sprintf("  • %s\n", archivo))
  }
} else {
  cat("  (ninguno)\n")
}

cat("\nTablas:\n")
archivos_tablas <- list.files(DIR_TABLAS, pattern = "\\.csv$")
if (length(archivos_tablas) > 0) {
  for (archivo in archivos_tablas) {
    cat(sprintf("  • %s\n", archivo))
  }
} else {
  cat("  (ninguno)\n")
}

cat("\nModelos:\n")
archivos_modelos <- list.files(DIR_MODELOS, pattern = "\\.rds$")
if (length(archivos_modelos) > 0) {
  for (archivo in archivos_modelos) {
    cat(sprintf("  • %s\n", archivo))
  }
} else {
  cat("  (ninguno)\n")
}

cat("\n")
cat("💡 Para re-ejecutar pasos individuales, usa:\n")
cat("   source('scripts/XX_nombre_paso.R')\n")
cat("\n")


