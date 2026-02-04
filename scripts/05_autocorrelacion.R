# ==============================================================================
# PASO 5: ANÁLISIS DE AUTOCORRELACIÓN (ACF Y PACF)
# ==============================================================================

if (!exists("DIR_ROOT")) source("config.R")
if (!exists("nyse")) nyse <- cargar_modelo("nyse_original.rds")

cat("📊 Analizando autocorrelación de la serie...\n\n")

# ACF y PACF
png(file.path(DIR_FIGURES, "05_acf_pacf.png"), 
    width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)

par(mfrow = c(2, 1))
acf(nyse, lag.max = MAX_LAGS_ACF, main = "Función de Autocorrelación (ACF)")
pacf(nyse, lag.max = MAX_LAGS_ACF, main = "Función de Autocorrelación Parcial (PACF)")
par(mfrow = c(1, 1))

dev.off()

# Valores numéricos
acf_valores <- acf(nyse, lag.max = MAX_LAGS_ACF, plot = FALSE)
pacf_valores <- pacf(nyse, lag.max = MAX_LAGS_ACF, plot = FALSE)

# Tabla con valores
tabla_acf <- data.frame(
  Lag = 1:min(20, length(acf_valores$acf)-1),
  ACF = acf_valores$acf[2:min(21, length(acf_valores$acf))],
  PACF = pacf_valores$acf[1:min(20, length(pacf_valores$acf))]
)

guardar_tabla(tabla_acf, "05_valores_acf_pacf.csv")

cat("\n💡 Interpretación:\n")
cat("  • ACF decae gradualmente → Posible componente AR\n")
cat("  • Picos significativos en múltiplos de 12 → Estacionalidad\n")
cat("  • PACF ayuda a identificar el orden p del componente AR\n")

cat("\n✅ Paso 5 completado: Análisis de autocorrelación finalizado\n")
