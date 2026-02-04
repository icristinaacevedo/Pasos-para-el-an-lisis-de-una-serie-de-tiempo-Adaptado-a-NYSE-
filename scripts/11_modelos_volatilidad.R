# ==============================================================================
# PASO 11: MODELOS DE VOLATILIDAD (GARCH)
# ==============================================================================
#
# Este script ajusta modelos GARCH para capturar la volatilidad cambiante
# en los retornos de la serie NYSE.
#

if (!exists("DIR_ROOT")) source("config.R")
if (!exists("df_nyse")) df_nyse <- cargar_modelo("df_nyse.rds")

library(rugarch)
library(forecast)

cat("📊 Modelando volatilidad con modelos GARCH...\n\n")

# ==============================================================================
# 1. PREPARACIÓN DE DATOS
# ==============================================================================

cat("📋 PREPARACIÓN DE DATOS\n")
cat(rep("-", 80), "\n", sep = "")

# Calcular retornos logarítmicos
retornos <- diff(log(df_nyse$Valor)) * 100  # En porcentaje
retornos <- na.omit(retornos)

cat(sprintf("Número de observaciones: %d\n", length(retornos)))
cat(sprintf("Media de retornos:       %.4f%%\n", mean(retornos)))
cat(sprintf("SD de retornos:          %.4f%%\n", sd(retornos)))
cat(sprintf("Asimetría:               %.4f\n", moments::skewness(retornos)))
cat(sprintf("Curtosis:                %.4f\n", moments::kurtosis(retornos)))

if (moments::kurtosis(retornos) > 3) {
  cat("\n✅ Curtosis > 3 → Justifica uso de modelos GARCH\n")
}

# ==============================================================================
# 2. MODELO GARCH(1,1) BÁSICO
# ==============================================================================

cat("\n")
cat("🔧 2. MODELO GARCH(1,1) BÁSICO\n")
cat(rep("-", 80), "\n", sep = "")

# Especificación del modelo
spec_garch11 <- ugarchspec(
  variance.model = list(model = "sGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(0, 0), include.mean = TRUE),
  distribution.model = "norm"
)

# Ajustar modelo
cat("Ajustando GARCH(1,1)...\n")
fit_garch11 <- ugarchfit(spec = spec_garch11, data = retornos)

cat("\nResultados GARCH(1,1):\n")
print(fit_garch11)

# Guardar
guardar_modelo(fit_garch11, "garch_11_normal.rds")

# ==============================================================================
# 3. GARCH(1,1) CON DISTRIBUCIÓN t-STUDENT
# ==============================================================================

cat("\n")
cat("🔧 3. GARCH(1,1) CON DISTRIBUCIÓN t-STUDENT\n")
cat(rep("-", 80), "\n", sep = "")

spec_garch11_t <- ugarchspec(
  variance.model = list(model = "sGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(0, 0), include.mean = TRUE),
  distribution.model = "std"  # t-student
)

cat("Ajustando GARCH(1,1) con t-student...\n")
fit_garch11_t <- ugarchfit(spec = spec_garch11_t, data = retornos)

cat("\nResultados GARCH(1,1) t-student:\n")
print(fit_garch11_t)

guardar_modelo(fit_garch11_t, "garch_11_tstudent.rds")

# ==============================================================================
# 4. MODELO EGARCH(1,1)
# ==============================================================================

cat("\n")
cat("🔧 4. MODELO EGARCH(1,1) (Captura asimetría)\n")
cat(rep("-", 80), "\n", sep = "")

spec_egarch11 <- ugarchspec(
  variance.model = list(model = "eGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(0, 0), include.mean = TRUE),
  distribution.model = "std"
)

cat("Ajustando EGARCH(1,1)...\n")
fit_egarch11 <- ugarchfit(spec = spec_egarch11, data = retornos)

cat("\nResultados EGARCH(1,1):\n")
print(fit_egarch11)

guardar_modelo(fit_egarch11, "egarch_11.rds")

# ==============================================================================
# 5. MODELO GJR-GARCH(1,1)
# ==============================================================================

cat("\n")
cat("🔧 5. MODELO GJR-GARCH(1,1) (Captura efecto leverage)\n")
cat(rep("-", 80), "\n", sep = "")

spec_gjrgarch11 <- ugarchspec(
  variance.model = list(model = "gjrGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(0, 0), include.mean = TRUE),
  distribution.model = "std"
)

cat("Ajustando GJR-GARCH(1,1)...\n")
fit_gjrgarch11 <- ugarchfit(spec = spec_gjrgarch11, data = retornos)

cat("\nResultados GJR-GARCH(1,1):\n")
print(fit_gjrgarch11)

guardar_modelo(fit_gjrgarch11, "gjrgarch_11.rds")

# ==============================================================================
# 6. ARMA(1,1)-GARCH(1,1)
# ==============================================================================

cat("\n")
cat("🔧 6. MODELO ARMA(1,1)-GARCH(1,1)\n")
cat(rep("-", 80), "\n", sep = "")

spec_armagarch <- ugarchspec(
  variance.model = list(model = "sGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(1, 1), include.mean = TRUE),
  distribution.model = "std"
)

cat("Ajustando ARMA(1,1)-GARCH(1,1)...\n")
fit_armagarch <- ugarchfit(spec = spec_armagarch, data = retornos)

cat("\nResultados ARMA(1,1)-GARCH(1,1):\n")
print(fit_armagarch)

guardar_modelo(fit_armagarch, "arma_garch_11.rds")

# ==============================================================================
# 7. COMPARACIÓN DE MODELOS
# ==============================================================================

cat("\n")
cat("📊 COMPARACIÓN DE MODELOS GARCH\n")
cat(rep("=", 80), "\n", sep = "")

# Extraer criterios de información
comparacion <- data.frame(
  Modelo = c("GARCH(1,1) Normal", "GARCH(1,1) t-Student", "EGARCH(1,1)", 
             "GJR-GARCH(1,1)", "ARMA(1,1)-GARCH(1,1)"),
  AIC = c(
    infocriteria(fit_garch11)[1],
    infocriteria(fit_garch11_t)[1],
    infocriteria(fit_egarch11)[1],
    infocriteria(fit_gjrgarch11)[1],
    infocriteria(fit_armagarch)[1]
  ),
  BIC = c(
    infocriteria(fit_garch11)[2],
    infocriteria(fit_garch11_t)[2],
    infocriteria(fit_egarch11)[2],
    infocriteria(fit_gjrgarch11)[2],
    infocriteria(fit_armagarch)[2]
  )
)

# Ordenar por AIC
comparacion <- comparacion[order(comparacion$AIC), ]

cat("\nTabla comparativa:\n")
print(comparacion, row.names = FALSE)

# Guardar tabla
guardar_tabla(comparacion, "11_comparacion_modelos_garch.csv")

# Mejor modelo
mejor_modelo <- comparacion$Modelo[1]
cat(sprintf("\n🏆 Mejor modelo según AIC: %s\n", mejor_modelo))

# ==============================================================================
# 8. DIAGNÓSTICO DEL MEJOR MODELO
# ==============================================================================

cat("\n")
cat("🔬 DIAGNÓSTICO DEL MEJOR MODELO\n")
cat(rep("-", 80), "\n", sep = "")

# Seleccionar mejor modelo
if (mejor_modelo == "GARCH(1,1) Normal") {
  mejor_fit <- fit_garch11
} else if (mejor_modelo == "GARCH(1,1) t-Student") {
  mejor_fit <- fit_garch11_t
} else if (mejor_modelo == "EGARCH(1,1)") {
  mejor_fit <- fit_egarch11
} else if (mejor_modelo == "GJR-GARCH(1,1)") {
  mejor_fit <- fit_gjrgarch11
} else {
  mejor_fit <- fit_armagarch
}

# Residuos estandarizados
std_resid <- residuals(mejor_fit, standardize = TRUE)

# Pruebas de diagnóstico
cat("\nPruebas de diagnóstico:\n")

# Test de Ljung-Box en residuos estandarizados
lb_test <- Box.test(std_resid, lag = 20, type = "Ljung-Box")
cat(sprintf("Ljung-Box (residuos):     p-valor = %.4f\n", lb_test$p.value))

# Test de Ljung-Box en residuos al cuadrado
lb_test_sq <- Box.test(std_resid^2, lag = 20, type = "Ljung-Box")
cat(sprintf("Ljung-Box (residuos²):    p-valor = %.4f\n", lb_test_sq$p.value))

# Test ARCH
arch_test <- ArchTest(std_resid, lags = 12)
cat(sprintf("Test ARCH:                p-valor = %.4f\n", arch_test$p.value))

if (lb_test$p.value > 0.05 && lb_test_sq$p.value > 0.05) {
  cat("\n✅ No hay autocorrelación residual → Modelo bien especificado\n")
} else {
  cat("\n⚠️  Hay evidencia de autocorrelación → Considerar modelo más complejo\n")
}

# ==============================================================================
# 9. VISUALIZACIONES
# ==============================================================================

cat("\n📊 Generando visualizaciones...\n")

# Gráfico 1: Serie de retornos y volatilidad condicional
png(file.path(DIR_FIGURES, "11_volatilidad_condicional.png"), 
    width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)

par(mfrow = c(2, 1))

# Retornos
plot(retornos, type = "l", main = "Retornos NYSE", 
     ylab = "Retorno (%)", col = "gray40")
abline(h = 0, col = "red", lty = 2)

# Volatilidad condicional
sigma_t <- sigma(mejor_fit)
plot(sigma_t, type = "l", main = "Volatilidad Condicional (Desv. Std.)",
     ylab = "Volatilidad", col = COLOR_ACCENT, lwd = 1.5)

par(mfrow = c(1, 1))
dev.off()

# Gráfico 2: Diagnóstico de residuos
png(file.path(DIR_FIGURES, "11_diagnostico_residuos_garch.png"), 
    width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)

plot(mejor_fit, which = 9)  # Gráfico de diagnóstico estándar

dev.off()

# Gráfico 3: ACF de residuos y residuos al cuadrado
png(file.path(DIR_FIGURES, "11_acf_residuos_garch.png"), 
    width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)

par(mfrow = c(2, 2))

# ACF residuos estandarizados
acf(std_resid, main = "ACF - Residuos Estandarizados", lag.max = 30)

# PACF residuos estandarizados
pacf(std_resid, main = "PACF - Residuos Estandarizados", lag.max = 30)

# ACF residuos al cuadrado
acf(std_resid^2, main = "ACF - Residuos² Estandarizados", lag.max = 30)

# Q-Q plot
qqnorm(std_resid, main = "Q-Q Plot - Residuos Estandarizados")
qqline(std_resid, col = "red", lwd = 2)

par(mfrow = c(1, 1))
dev.off()

cat("✅ Gráficos guardados\n")

# ==============================================================================
# 10. PRONÓSTICO DE VOLATILIDAD
# ==============================================================================

cat("\n")
cat("🔮 PRONÓSTICO DE VOLATILIDAD\n")
cat(rep("-", 80), "\n", sep = "")

# Pronóstico para 20 días
n_ahead <- 20
forecast_vol <- ugarchforecast(mejor_fit, n.ahead = n_ahead)

cat(sprintf("\nPronóstico de volatilidad para próximos %d días:\n", n_ahead))
print(sigma(forecast_vol))

# Guardar pronóstico
guardar_modelo(forecast_vol, "pronostico_volatilidad.rds")

# Gráfico de pronóstico
png(file.path(DIR_FIGURES, "11_pronostico_volatilidad.png"), 
    width = GRAPH_WIDTH, height = GRAPH_HEIGHT/1.5, units = "in", res = GRAPH_DPI)

plot(forecast_vol, which = 3)

dev.off()

# ==============================================================================
# RESUMEN FINAL
# ==============================================================================

cat("\n")
cat("📊 RESUMEN PASO 11\n")
cat(rep("=", 80), "\n", sep = "")
cat(sprintf("• Modelo seleccionado: %s\n", mejor_modelo))
cat(sprintf("• AIC: %.4f\n", comparacion$AIC[1]))
cat(sprintf("• BIC: %.4f\n", comparacion$BIC[1]))
cat(sprintf("• Test Ljung-Box residuos: p=%.4f\n", lb_test$p.value))
cat(sprintf("• Test Ljung-Box residuos²: p=%.4f\n", lb_test_sq$p.value))
cat(rep("=", 80), "\n", sep = "")

cat("\n💡 INTERPRETACIÓN:\n")
cat("  • GARCH captura clusters de volatilidad (períodos de alta/baja volatilidad)\n")
cat("  • EGARCH permite efectos asimétricos (shocks negativos ≠ positivos)\n")
cat("  • GJR-GARCH captura el 'efecto leverage' en mercados financieros\n")
cat("  • La volatilidad pronosticada es útil para gestión de riesgo\n")

cat("\n✅ Paso 11 completado: Modelos de volatilidad ajustados\n")
