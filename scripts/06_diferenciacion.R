# ==============================================================================
# PASO 6: DIFERENCIACIÓN DE LA SERIE
# ==============================================================================

if (!exists("DIR_ROOT")) source("config.R")
if (!exists("nyse")) nyse <- cargar_modelo("nyse_original.rds")

library(forecast)

cat("📊 Aplicando diferenciación a la serie...\n\n")

# Número óptimo de diferencias
n_diff <- ndiffs(nyse)

cat(sprintf("Diferencias regulares sugeridas: %d\n", n_diff))

# Verificar si hay estacionalidad
if (frequency(nyse) > 1) {
  n_sdiff <- nsdiffs(nyse)
  cat(sprintf("Diferencias estacionales sugeridas: %d\n\n", n_sdiff))
} else {
  cat("Serie no estacional (frecuencia = 1), omitiendo diferencia estacional\n\n")
  n_sdiff <- 0
}

# Primera diferencia
nyse_diff1 <- diff(nyse, differences = 1)

# Guardar series diferenciadas
guardar_modelo(nyse_diff1, "nyse_diff1.rds")

# Gráfico de comparación
if (frequency(nyse) > 1) {
  # Si hay estacionalidad
  nyse_diff_seasonal <- diff(nyse, lag = frequency(nyse))
  nyse_diff_completa <- diff(diff(nyse, lag = frequency(nyse)), differences = 1)
  
  guardar_modelo(nyse_diff_seasonal, "nyse_diff_seasonal.rds")
  guardar_modelo(nyse_diff_completa, "nyse_diff_completa.rds")
  
  png(file.path(DIR_FIGURES, "06_diferenciacion.png"), 
      width = GRAPH_WIDTH, height = GRAPH_HEIGHT*1.2, units = "in", res = GRAPH_DPI)
  
  par(mfrow = c(4, 1))
  plot(nyse, main = "Serie Original", ylab = "Valor", col = COLOR_PRIMARY)
  plot(nyse_diff1, main = "Primera Diferencia", ylab = "Valor", col = COLOR_SECONDARY)
  abline(h = 0, col = "red", lty = 2)
  plot(nyse_diff_seasonal, main = sprintf("Diferencia Estacional (lag=%d)", frequency(nyse)), 
       ylab = "Valor", col = COLOR_SUCCESS)
  abline(h = 0, col = "red", lty = 2)
  plot(nyse_diff_completa, main = "Diferencia Combinada", ylab = "Valor", col = COLOR_WARNING)
  abline(h = 0, col = "red", lty = 2)
  par(mfrow = c(1, 1))
  
  dev.off()
  
} else {
  # Solo diferencia regular para datos no estacionales
  png(file.path(DIR_FIGURES, "06_diferenciacion.png"), 
      width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)
  
  par(mfrow = c(2, 1))
  plot(nyse, main = "Serie Original (Datos Diarios)", ylab = "Valor", col = COLOR_PRIMARY)
  plot(nyse_diff1, main = "Primera Diferencia", ylab = "Valor", col = COLOR_SECONDARY)
  abline(h = 0, col = "red", lty = 2)
  par(mfrow = c(1, 1))
  
  dev.off()
}

# Prueba ADF en serie diferenciada
cat("\n🧪 Prueba ADF en serie con primera diferencia:\n")
adf_diff1 <- adf.test(nyse_diff1)
print(adf_diff1)

if (adf_diff1$p.value < 0.05) {
  cat("✅ Serie diferenciada ES estacionaria\n")
} else {
  cat("❌ Serie diferenciada NO es estacionaria\n")
}

# ACF/PACF de serie diferenciada
png(file.path(DIR_FIGURES, "06_acf_pacf_diferenciada.png"), 
    width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)

par(mfrow = c(2, 1))
acf(nyse_diff1, lag.max = 40, main = "ACF - Serie con Primera Diferencia")
pacf(nyse_diff1, lag.max = 40, main = "PACF - Serie con Primera Diferencia")
par(mfrow = c(1, 1))

dev.off()

cat("\n✅ Paso 6 completado: Diferenciación finalizada\n")