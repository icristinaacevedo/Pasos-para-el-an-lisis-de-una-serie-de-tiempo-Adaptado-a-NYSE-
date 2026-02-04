# ==============================================================================
# PASO 8: DIAGNÓSTICO DEL MODELO (MEJORADO)
# ==============================================================================

if (!exists("DIR_ROOT")) source("config.R")

# Cargar modelo (intentar modelo_final primero, luego modelo_auto)
if (file.exists(file.path(DIR_MODELOS, "modelo_final.rds"))) {
  modelo <- cargar_modelo("modelo_final.rds")
  cat("✅ Modelo final cargado\n")
} else {
  modelo <- cargar_modelo("modelo_arima_auto.rds")
  cat("✅ Modelo automático cargado\n")
}

library(forecast)
library(tseries)

cat("\n📊 Realizando diagnóstico del modelo...\n\n")

# Extraer residuos
residuos <- residuals(modelo)

# ==============================================================================
# 1. ESTADÍSTICAS DE RESIDUOS
# ==============================================================================

cat("📈 ESTADÍSTICAS DE RESIDUOS:\n")
cat(rep("-", 80), "\n", sep = "")
cat(sprintf("Media:               %12.6f\n", mean(residuos, na.rm = TRUE)))
cat(sprintf("Desv. Estándar:      %12.6f\n", sd(residuos, na.rm = TRUE)))
cat(sprintf("Asimetría:           %12.4f\n", moments::skewness(residuos)))
cat(sprintf("Curtosis:            %12.4f\n", moments::kurtosis(residuos)))
cat("\n")

# ==============================================================================
# 2. TEST DE LJUNG-BOX (AUTOCORRELACIÓN)
# ==============================================================================

cat("🧪 TEST DE LJUNG-BOX (Autocorrelación de residuos):\n")
cat("   H0: No hay autocorrelación en los residuos\n\n")

# Realizar tests para diferentes lags
lags_test <- c(5, 10, 15, 20)
resultados_lb <- data.frame(
  Lag = integer(),
  Estadistico = numeric(),
  P_valor = numeric(),
  Resultado = character()
)

for (lag in lags_test) {
  lb_test <- Box.test(residuos, lag = lag, type = "Ljung-Box", 
                       fitdf = sum(modelo$arma[1:2]))
  
  resultado <- ifelse(lb_test$p.value > 0.05, "✅ Pasa", "❌ No pasa")
  
  resultados_lb <- rbind(resultados_lb, data.frame(
    Lag = lag,
    Estadistico = lb_test$statistic,
    P_valor = lb_test$p.value,
    Resultado = resultado
  ))
  
  cat(sprintf("Lag %2d: Estadístico=%.4f, p-valor=%.4f %s\n", 
              lag, lb_test$statistic, lb_test$p.value, resultado))
}

# Evaluación general
pasa_lb <- sum(resultados_lb$P_valor > 0.05)
cat(sprintf("\n📊 Resumen: %d de %d tests pasados\n", pasa_lb, length(lags_test)))

if (pasa_lb == length(lags_test)) {
  cat("✅ EXCELENTE: No hay autocorrelación en los residuos\n")
  cat("   El modelo captura bien la estructura temporal\n")
} else if (pasa_lb >= length(lags_test)/2) {
  cat("⚠️  ACEPTABLE: Autocorrelación leve en algunos lags\n")
  cat("   El modelo es razonablemente adecuado\n")
} else {
  cat("❌ PROBLEMA: Autocorrelación significativa detectada\n")
  cat("   RECOMENDACIONES:\n")
  cat("   1. Considerar un modelo con orden superior (más p o q)\n")
  cat("   2. Verificar si hay patrones no capturados\n")
  cat("   3. Evaluar modelos alternativos de la lista del Paso 7\n")
  cat("   4. Para series financieras con volatilidad cambiante:\n")
  cat("      → Usar modelos GARCH (ver Paso 11)\n")
}

guardar_tabla(resultados_lb, "08_resultados_ljungbox.csv")

cat("\n")

# ==============================================================================
# 3. TEST DE NORMALIDAD
# ==============================================================================

cat("🧪 TEST DE JARQUE-BERA (Normalidad de residuos):\n")
cat("   H0: Los residuos siguen distribución normal\n\n")

jb_test <- jarque.bera.test(residuos)
cat(sprintf("Estadístico: %.4f\n", jb_test$statistic))
cat(sprintf("P-valor:     %.4f\n", jb_test$p.value))

if (jb_test$p.value > 0.05) {
  cat("\n✅ No se rechaza H0 → Residuos normales\n")
} else {
  cat("\n⚠️  Se rechaza H0 → Residuos no normales\n")
  cat("   NOTA: La no normalidad NO invalida el modelo ARIMA\n")
  cat("   Pero puede afectar los intervalos de confianza\n")
}

# Shapiro-Wilk (si hay menos de 5000 obs)
if (length(na.omit(residuos)) < 5000) {
  cat("\n🧪 TEST DE SHAPIRO-WILK:\n")
  sw_test <- shapiro.test(na.omit(residuos))
  cat(sprintf("Estadístico: %.4f\n", sw_test$statistic))
  cat(sprintf("P-valor:     %.4f\n", sw_test$p.value))
}

cat("\n")

# ==============================================================================
# 4. TEST DE HOMOCEDASTICIDAD
# ==============================================================================

cat("🧪 TEST DE HOMOCEDASTICIDAD (Varianza constante):\n")
cat(rep("-", 80), "\n", sep = "")

# Test ARCH (heteroscedasticidad condicional)
tryCatch({
  # Dividir residuos en dos mitades
  n <- length(na.omit(residuos))
  mitad <- floor(n/2)
  var1 <- var(residuos[1:mitad], na.rm = TRUE)
  var2 <- var(residuos[(mitad+1):n], na.rm = TRUE)
  
  # Test F para igualdad de varianzas
  f_stat <- var2 / var1
  f_pval <- 2 * min(pf(f_stat, n-mitad-1, mitad-1), 
                    1 - pf(f_stat, n-mitad-1, mitad-1))
  
  cat(sprintf("Varianza primera mitad:  %.6f\n", var1))
  cat(sprintf("Varianza segunda mitad:  %.6f\n", var2))
  cat(sprintf("Razón de varianzas:      %.4f\n", f_stat))
  cat(sprintf("P-valor test F:          %.4f\n", f_pval))
  
  if (f_pval > 0.05) {
    cat("\n✅ Varianza constante en el tiempo\n")
  } else {
    cat("\n⚠️  Evidencia de heteroscedasticidad (varianza cambiante)\n")
    cat("   RECOMENDACIÓN: Considerar modelos GARCH (Paso 11)\n")
    cat("   Los modelos GARCH capturan volatilidad cambiante\n")
  }
}, error = function(e) {
  cat("No se pudo realizar test de homocedasticidad\n")
})

cat("\n")

# ==============================================================================
# 5. GRÁFICOS DE DIAGNÓSTICO
# ==============================================================================

cat("📊 Generando gráficos de diagnóstico...\n")

# Gráfico completo
png(file.path(DIR_FIGURES, "08_diagnostico_completo.png"), 
    width = GRAPH_WIDTH, height = GRAPH_HEIGHT*1.2, units = "in", res = GRAPH_DPI)

par(mfrow = c(3, 2))

# 1. Residuos en el tiempo
plot(residuos, main = "Residuos en el Tiempo", ylab = "Residuos", 
     type = "l", col = "gray40")
abline(h = 0, col = "red", lty = 2)
abline(h = c(-2, 2) * sd(residuos, na.rm = TRUE), col = "blue", lty = 3)

# 2. Histograma
hist(residuos, breaks = 30, main = "Distribución de Residuos", 
     xlab = "Residuos", col = "lightblue", border = "white", probability = TRUE)
curve(dnorm(x, mean = mean(residuos, na.rm = TRUE), sd = sd(residuos, na.rm = TRUE)),
      add = TRUE, col = "red", lwd = 2)

# 3. Q-Q plot
qqnorm(residuos, main = "Q-Q Plot", pch = 16, col = rgb(0,0,1,0.5))
qqline(residuos, col = "red", lwd = 2)

# 4. ACF de residuos
acf(residuos, main = "ACF de Residuos", lag.max = 30, na.action = na.pass)

# 5. PACF de residuos
pacf(residuos, main = "PACF de Residuos", lag.max = 30, na.action = na.pass)

# 6. Residuos vs valores ajustados
valores_ajustados <- fitted(modelo)
plot(valores_ajustados, residuos, main = "Residuos vs Valores Ajustados",
     xlab = "Valores Ajustados", ylab = "Residuos", 
     pch = 16, col = rgb(0,0,1,0.3))
abline(h = 0, col = "red", lty = 2)
# Añadir línea de tendencia
lines(lowess(valores_ajustados, residuos), col = "blue", lwd = 2)

par(mfrow = c(1, 1))
dev.off()

# Checkresiduals de forecast
png(file.path(DIR_FIGURES, "08_checkresiduals.png"), 
    width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)
checkresiduals(modelo)
dev.off()

cat("✅ Gráficos guardados\n")

# ==============================================================================
# 6. ANÁLISIS DE OUTLIERS EN RESIDUOS
# ==============================================================================

cat("\n")
cat("🔍 ANÁLISIS DE OUTLIERS EN RESIDUOS\n")
cat(rep("-", 80), "\n", sep = "")

# Definir outliers como |residuo| > 3 * SD
threshold <- 3 * sd(residuos, na.rm = TRUE)
outliers_idx <- which(abs(residuos) > threshold)
n_outliers <- length(outliers_idx)

cat(sprintf("Threshold (3 SD):    %.6f\n", threshold))
cat(sprintf("Outliers detectados: %d (%.2f%%)\n", 
            n_outliers, (n_outliers/length(residuos))*100))

if (n_outliers > 0) {
  cat("\nÍndices con outliers (primeros 10):\n")
  print(head(outliers_idx, 10))
  
  if (n_outliers > length(residuos) * 0.05) {
    cat("\n⚠️  Más del 5% de outliers detectados\n")
    cat("   Considerar si hay eventos extraordinarios en esas fechas\n")
  }
}

cat("\n")

# ==============================================================================
# 7. RESUMEN DE DIAGNÓSTICO
# ==============================================================================

# Tabla resumen
tabla_diagnostico <- data.frame(
  Prueba = c("Ljung-Box (lag 20)", "Jarque-Bera", "Homocedasticidad"),
  Estadistico = c(resultados_lb$Estadistico[resultados_lb$Lag == 20],
                  jb_test$statistic, 
                  ifelse(exists("f_stat"), f_stat, NA)),
  P_valor = c(resultados_lb$P_valor[resultados_lb$Lag == 20],
              jb_test$p.value,
              ifelse(exists("f_pval"), f_pval, NA)),
  Resultado = c(
    ifelse(resultados_lb$P_valor[resultados_lb$Lag == 20] > 0.05, "Pasa", "No pasa"),
    ifelse(jb_test$p.value > 0.05, "Pasa", "No pasa"),
    ifelse(exists("f_pval"), ifelse(f_pval > 0.05, "Pasa", "No pasa"), NA)
  )
)

guardar_tabla(tabla_diagnostico, "08_resultados_diagnostico.csv")

cat("\n")
cat("📊 RESUMEN DE DIAGNÓSTICO\n")
cat(rep("=", 80), "\n", sep = "")

print(tabla_diagnostico, row.names = FALSE)

# Evaluación general
tests_pasados <- sum(tabla_diagnostico$Resultado == "Pasa", na.rm = TRUE)
total_tests <- sum(!is.na(tabla_diagnostico$Resultado))

cat(sprintf("\nTests pasados: %d de %d\n", tests_pasados, total_tests))

if (tests_pasados == total_tests) {
  cat("\nEXCELENTE: El modelo cumple todos los supuestos\n")
} else if (tests_pasados >= total_tests * 0.67) {
  cat("\nBUENO: El modelo es adecuado pero puede mejorarse\n")
} else {
  cat("\nMEJORABLE: Considerar modelos alternativos\n")
}

cat(rep("=", 80), "\n", sep = "")

cat("\nPaso 8 completado: Diagnóstico finalizado\n")
