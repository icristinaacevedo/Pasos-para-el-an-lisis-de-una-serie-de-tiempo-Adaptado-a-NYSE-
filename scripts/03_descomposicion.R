# ==============================================================================
# PASO 3: DESCOMPOSICIÓN DE LA SERIE TEMPORAL
# ==============================================================================

if (!exists("DIR_ROOT")) source("config.R")
if (!exists("nyse")) nyse <- cargar_modelo("nyse_original.rds")

cat("📊 Evaluando posibilidad de descomposición...\n\n")

# Verificar frecuencia de la serie
freq <- frequency(nyse)

cat(sprintf("Frecuencia de la serie: %d\n", freq))

if (freq <= 1) {
  cat("\n⚠️  SERIE NO ESTACIONAL\n")
  cat(rep("=", 80), "\n", sep = "")
  cat("La serie tiene frecuencia = 1 (datos diarios sin estacionalidad definida)\n")
  cat("La descomposición estacional NO es aplicable.\n\n")
  
  cat("💡 Alternativas para datos diarios:\n")
  cat("  1. Análisis de tendencia con medias móviles (ya realizado en Paso 2)\n")
  cat("  2. Modelos GARCH para volatilidad (Paso 11)\n")
  cat("  3. Si hay patrones semanales/mensuales, convertir a serie agregada\n\n")
  
  cat("⏭️  Paso 3 OMITIDO: Descomposición no aplicable a datos diarios\n\n")
  
} else {
  cat(sprintf("\n✅ Serie tiene estacionalidad (frecuencia = %d)\n", freq))
  cat("Procediendo con descomposición...\n\n")
  
  # Descomposición aditiva
  cat("🔄 Descomposición aditiva...\n")
  descomp_aditiva <- decompose(nyse, type = "additive")
  
  # Descomposición multiplicativa
  cat("🔄 Descomposición multiplicativa...\n")
  descomp_multiplicativa <- decompose(nyse, type = "multiplicative")
  
  # Guardar modelos
  guardar_modelo(descomp_aditiva, "descomposicion_aditiva.rds")
  guardar_modelo(descomp_multiplicativa, "descomposicion_multiplicativa.rds")
  
  # Gráfico de descomposición aditiva
  png(file.path(DIR_FIGURES, "03_descomposicion_aditiva.png"), 
      width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)
  plot(descomp_aditiva, col = COLOR_PRIMARY)
  title(main = "Descomposición Aditiva - NYSE", outer = TRUE, line = -1)
  dev.off()
  
  # Gráfico de descomposición multiplicativa
  png(file.path(DIR_FIGURES, "03_descomposicion_multiplicativa.png"), 
      width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)
  plot(descomp_multiplicativa, col = COLOR_PRIMARY)
  title(main = "Descomposición Multiplicativa - NYSE", outer = TRUE, line = -1)
  dev.off()
  
  # Estadísticas de componentes
  cat("\n📊 Estadísticas de Componentes (Modelo Aditivo):\n")
  cat(sprintf("  Tendencia - Rango: %.4f\n", 
              max(descomp_aditiva$trend, na.rm=TRUE) - min(descomp_aditiva$trend, na.rm=TRUE)))
  cat(sprintf("  Estacionalidad - Amplitud: %.4f\n", 
              max(descomp_aditiva$seasonal) - min(descomp_aditiva$seasonal)))
  cat(sprintf("  Residuos - SD: %.4f\n", sd(descomp_aditiva$random, na.rm=TRUE)))
  
  cat("\n✅ Paso 3 completado: Descomposición finalizada\n")
}