# ==============================================================================
# PASO 10: EVALUACIÓN DEL MODELO
# ==============================================================================

if (!exists("DIR_ROOT")) source("config.R")
if (!exists("modelo_auto")) modelo_auto <- cargar_modelo("modelo_arima_auto.rds")
if (!exists("NYSE")) NYSE <- cargar_modelo("nyse_original.rds")

library(forecast)

cat("📊 Evaluando el desempeño del modelo...\n\n")

# Métricas en conjunto completo
cat("📈 MÉTRICAS EN CONJUNTO COMPLETO:\n")
cat(rep("-", 80), "\n", sep = "")

metricas_completo <- accuracy(modelo_auto)
print(metricas_completo)
cat("\n")

# Validación cruzada temporal
cat("🔄 VALIDACIÓN CRUZADA TEMPORAL:\n")
cat(rep("-", 80), "\n", sep = "")

n_total <- length(NYSE)
n_train <- round(PROPORCION_TRAIN * n_total)
n_test <- n_total - n_train

cat(sprintf("Total de observaciones: %d\n", n_total))
cat(sprintf("Conjunto de entrenamiento: %d (%.0f%%)\n", n_train, PROPORCION_TRAIN*100))
cat(sprintf("Conjunto de prueba: %d (%.0f%%)\n\n", n_test, (1-PROPORCION_TRAIN)*100))

# Dividir datos
nyse_train <- window(NYSE, end = time(NYSE)[n_train])
nyse_test <- window(NYSE, start = time(NYSE)[n_train + 1])

# Ajustar modelo con datos de entrenamiento
cat("Entrenando modelo con datos de entrenamiento...\n")
modelo_train <- auto.arima(nyse_train, seasonal = TRUE)

# Pronóstico para período de prueba
cat("Generando pronósticos para período de prueba...\n")
pronostico_test <- forecast(modelo_train, h = n_test)

# Calcular métricas
cat("\n📊 MÉTRICAS EN CONJUNTO DE PRUEBA:\n")
metricas_test <- accuracy(pronostico_test, nyse_test)
print(metricas_test)
cat("\n")

# Gráfico de validación
png(file.path(DIR_FIGURES, "10_validacion.png"), 
    width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)

plot(pronostico_test, main = "Validación: Pronóstico vs Valores Reales",
     xlab = "Tiempo", ylab = "Valor")
lines(nyse_test, col = "red", lwd = 2)
legend("topleft", 
       legend = c("Entrenamiento", "Pronóstico", "Valores Reales"),
       col = c("black", "blue", "red"),
       lty = c(1, 1, 1),
       lwd = c(1, 1, 2))

dev.off()

# Errores de pronóstico
errores <- nyse_test - pronostico_test$mean

png(file.path(DIR_FIGURES, "10_errores_pronostico.png"), 
    width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)

par(mfrow = c(2, 1))
plot(errores, main = "Errores de Pronóstico", ylab = "Error", type = "l", col = "red")
abline(h = 0, lty = 2)
hist(errores, breaks = 20, main = "Distribución de Errores", 
     xlab = "Error", col = "lightblue", border = "white")

par(mfrow = c(1, 1))
dev.off()

# Tabla comparativa de métricas
tabla_metricas <- data.frame(
  Metrica = c("MAE", "RMSE", "MAPE", "MASE"),
  Training_Set = c(
    metricas_completo[1, "MAE"],
    metricas_completo[1, "RMSE"],
    metricas_completo[1, "MAPE"],
    metricas_completo[1, "MASE"]
  ),
  Test_Set = c(
    metricas_test[2, "MAE"],
    metricas_test[2, "RMSE"],
    metricas_test[2, "MAPE"],
    metricas_test[2, "MASE"]
  )
)

guardar_tabla(tabla_metricas, "10_metricas_comparacion.csv")

# Interpretación de resultados
cat("💡 INTERPRETACIÓN DE MÉTRICAS:\n")
cat(rep("-", 80), "\n", sep = "")

mape_test <- metricas_test[2, "MAPE"]
if (mape_test < 10) {
  cat("  • MAPE < 10%: Precisión EXCELENTE\n")
} else if (mape_test < 20) {
  cat("  • MAPE < 20%: Precisión BUENA\n")
} else if (mape_test < 30) {
  cat("  • MAPE < 30%: Precisión ACEPTABLE\n")
} else {
  cat("  • MAPE >= 30%: Precisión BAJA - considerar mejoras\n")
}

rmse_test <- metricas_test[2, "RMSE"]
mae_test <- metricas_test[2, "MAE"]

if (rmse_test / mae_test < 1.5) {
  cat("  • RMSE/MAE < 1.5: Errores consistentes\n")
} else {
  cat("  • RMSE/MAE >= 1.5: Presencia de errores grandes ocasionales\n")
}

cat("\n")

# Resumen final
cat("📋 RESUMEN DE EVALUACIÓN:\n")
cat(rep("=", 80), "\n", sep = "")
cat(sprintf("Modelo: ARIMA%s\n", paste(arimaorder(modelo_auto), collapse = "")))
cat(sprintf("RMSE (test): %.4f\n", rmse_test))
cat(sprintf("MAE (test): %.4f\n", mae_test))
cat(sprintf("MAPE (test): %.2f%%\n", mape_test))
cat(rep("=", 80), "\n", sep = "")

cat("\n✅ Paso 10 completado: Evaluación finalizada\n")
