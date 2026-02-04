# ==============================================================================
# PASO 4: ANÁLISIS DE ESTACIONARIEDAD
# ==============================================================================

if (!exists("DIR_ROOT")) source("config.R")
if (!exists("NYSE")) NYSE <- cargar_modelo("nyse_original.rds")

library(tseries)

cat("📊 Analizando estacionariedad de la serie...\n\n")

# Prueba ADF
cat("🧪 Prueba de Dickey-Fuller Aumentada (ADF):\n")
cat("   H0: La serie NO es estacionaria (tiene raíz unitaria)\n")
cat("   H1: La serie ES estacionaria\n\n")

adf_resultado <- adf.test(NYSE)
print(adf_resultado)

if (adf_resultado$p.value < 0.05) {
  cat("\n✅ Resultado: La serie ES ESTACIONARIA (p < 0.05)\n")
} else {
  cat("\n❌ Resultado: La serie NO ES ESTACIONARIA (p >= 0.05)\n")
}

# Prueba KPSS
cat("\n🧪 Prueba KPSS:\n")
cat("   H0: La serie ES estacionaria\n")
cat("   H1: La serie NO es estacionaria\n\n")

kpss_resultado <- kpss.test(NYSE)
print(kpss_resultado)

if (kpss_resultado$p.value > 0.05) {
  cat("\n✅ Resultado: La serie ES ESTACIONARIA (p > 0.05)\n")
} else {
  cat("\n❌ Resultado: La serie NO ES ESTACIONARIA (p <= 0.05)\n")
}

# Crear tabla de resultados
tabla_estacionariedad <- data.frame(
  Prueba = c("ADF", "KPSS"),
  Estadistico = c(adf_resultado$statistic, kpss_resultado$statistic),
  P_valor = c(adf_resultado$p.value, kpss_resultado$p.value),
  Resultado = c(
    ifelse(adf_resultado$p.value < 0.05, "Estacionaria", "No estacionaria"),
    ifelse(kpss_resultado$p.value > 0.05, "Estacionaria", "No estacionaria")
  )
)

guardar_tabla(tabla_estacionariedad, "04_pruebas_estacionariedad.csv")

# Gráfico de media y varianza móvil
# Gráfico de media y varianza móvil
library(zoo)
ventana <- 21  # 21 días de trading ≈ 1 mes
media_movil <- rollmean(nyse, k = ventana, fill = NA)
sd_movil <- rollapply(nyse, width = ventana, FUN = sd, fill = NA)

png(file.path(DIR_FIGURES, "04_estacionariedad.png"), 
    width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)

par(mfrow = c(2, 1))
plot(nyse, main = "Serie Original vs Media Móvil (21 días)", ylab = "Valor", col = "gray60")
lines(media_movil, col = "red", lwd = 2)
legend("topleft", c("Original", "Media Móvil (21 días)"), col = c("gray60", "red"), lty = 1)

plot(sd_movil, main = "Desviación Estándar Móvil (21 días)", ylab = "SD", col = "blue", lwd = 2)

par(mfrow = c(1, 1))
dev.off()
