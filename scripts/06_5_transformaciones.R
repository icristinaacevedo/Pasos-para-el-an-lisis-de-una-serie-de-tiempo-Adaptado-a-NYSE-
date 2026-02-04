# ==============================================================================
# PASO 6.5: TRANSFORMACIONES DE LA SERIE
# ==============================================================================
#
# Este script explora diferentes transformaciones para estabilizar
# la varianza y mejorar la normalidad de la serie.
#

if (!exists("DIR_ROOT")) source("config.R")
if (!exists("df_nyse")) df_nyse <- cargar_modelo("df_nyse.rds")

library(MASS)
library(forecast)

cat(" Explorando transformaciones de la serie...\n\n")

# Crear serie temporal si no existe
if (!exists("nyse")) {
  nyse <- ts(df_nyse$Valor, frequency = 252)
}

# ==============================================================================
# 1. TRANSFORMACIÓN LOGARÍTMICA
# ==============================================================================

cat("🔄 1. TRANSFORMACIÓN LOGARÍTMICA\n")
cat(rep("-", 80), "\n", sep = "")

# Inicializar SIEMPRE el objeto (regla clave)
nyse_log_ts <- NULL
nyse_log    <- NULL

valores_no_positivos <- sum(nyse <= 0)

if (valores_no_positivos > 0) {

  cat(sprintf("⚠️  La serie contiene %d valores no positivos\n", valores_no_positivos))
  min_valor <- min(nyse)
  nyse_ajustado <- nyse - min_valor + 0.001

  nyse_log <- suppressWarnings(log(nyse_ajustado))

} else {

  nyse_log <- log(nyse)

}

# Crear SIEMPRE la serie ts
nyse_log_ts <- ts(nyse_log, frequency = 252)

cat(sprintf("Media original: %.6f | Media log: %.6f\n",
            mean(nyse, na.rm = TRUE),
            mean(nyse_log, na.rm = TRUE)))

guardar_modelo(nyse_log_ts, "nyse_log.rds")

# ==============================================================================
# 2. TRANSFORMACIÓN BOX-COX
# ==============================================================================

cat("\n🔄 2. TRANSFORMACIÓN BOX-COX\n")
cat(rep("-", 80), "\n", sep = "")

# Box-Cox requiere valores positivos
if (valores_no_positivos > 0) {
  nyse_boxcox_input <- nyse - min(nyse) + 0.001
  cat("   Serie ajustada para Box-Cox (valores positivos)\n")
} else {
  nyse_boxcox_input <- nyse
}

# Estimar lambda óptimo
lambda_bc <- BoxCox.lambda(nyse_boxcox_input, method = "loglik")
cat(sprintf("Lambda óptimo:       %.4f\n", lambda_bc))

# Aplicar transformación
nyse_boxcox <- BoxCox(nyse_boxcox_input, lambda = lambda_bc)
nyse_boxcox_ts <- ts(nyse_boxcox, frequency = 252)

cat(sprintf("Media Box-Cox:       %.6f\n", mean(nyse_boxcox, na.rm = TRUE)))
cat(sprintf("SD Box-Cox:          %.6f\n", sd(nyse_boxcox, na.rm = TRUE)))

# Guardar
guardar_modelo(nyse_boxcox_ts, "nyse_boxcox.rds")
guardar_modelo(lambda_bc, "lambda_boxcox.rds")

# ==============================================================================
# 3. TRANSFORMACIÓN DE RAÍZ CUADRADA
# ==============================================================================

cat("\n🔄 3. TRANSFORMACIÓN DE RAÍZ CUADRADA\n")
cat(rep("-", 80), "\n", sep = "")

if (valores_no_positivos > 0) {
  cat("⚠️  Serie contiene valores negativos, ajustando...\n")
  nyse_sqrt <- sqrt(nyse - min(nyse) + 0.001)
} else {
  nyse_sqrt <- sqrt(nyse)
}

nyse_sqrt_ts <- ts(nyse_sqrt, frequency = 252)

cat(sprintf("Media sqrt:          %.6f\n", mean(nyse_sqrt, na.rm = TRUE)))
cat(sprintf("SD sqrt:             %.6f\n", sd(nyse_sqrt, na.rm = TRUE)))

guardar_modelo(nyse_sqrt_ts, "nyse_sqrt.rds")

# ==============================================================================
# 4. COMPARACIÓN VISUAL DE TRANSFORMACIONES
# ==============================================================================

cat("\n📊 Generando gráficos de comparación...\n")

png(file.path(DIR_FIGURES, "06_5_transformaciones_comparacion.png"), 
    width = GRAPH_WIDTH, height = GRAPH_HEIGHT * 1.5, units = "in", res = GRAPH_DPI)

par(mfrow = c(4, 2))

# Serie original
plot(nyse, main = "Serie Original", ylab = "Valor", col = COLOR_PRIMARY)
hist(df_nyse$Valor, breaks = 30, main = "Distribución Original", 
     xlab = "Valor", col = "lightblue", border = "white")

# Log
plot(nyse_log_ts, main = "Transformación Logarítmica", ylab = "log(Valor)", col = COLOR_SECONDARY)
hist(nyse_log, breaks = 30, main = "Distribución Log", 
     xlab = "log(Valor)", col = "lightgreen", border = "white")

# Box-Cox (si existe)
if (!is.null(lambda_bc)) {
  plot(nyse_boxcox_ts, main = sprintf("Box-Cox (λ=%.4f)", lambda_bc), 
       ylab = "Valor transformado", col = COLOR_SUCCESS)
  hist(nyse_boxcox, breaks = 30, main = "Distribución Box-Cox", 
       xlab = "Valor transformado", col = "lightyellow", border = "white")
} else {
  plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
  text(1, 1, "Box-Cox no disponible", cex = 1.5)
  plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
}

# Sqrt
plot(nyse_sqrt_ts, main = "Transformación Raíz Cuadrada", 
     ylab = "sqrt(Valor)", col = COLOR_WARNING)
hist(nyse_sqrt, breaks = 30, main = "Distribución Sqrt", 
     xlab = "sqrt(Valor)", col = "lightcoral", border = "white")

par(mfrow = c(1, 1))
dev.off()

cat("✅ Gráfico guardado: 06_5_transformaciones_comparacion.png\n")

# ==============================================================================
# 5. PRUEBAS DE NORMALIDAD COMPARATIVAS
# ==============================================================================

cat("\n🧪 PRUEBAS DE NORMALIDAD\n")
cat(rep("-", 80), "\n", sep = "")

library(tseries)

# Función para realizar test de Jarque-Bera
test_normalidad <- function(datos, nombre) {
  jb_test <- jarque.bera.test(na.omit(datos))
  return(data.frame(
    Transformacion = nombre,
    Estadistico_JB = jb_test$statistic,
    P_valor = jb_test$p.value,
    Normal = ifelse(jb_test$p.value > 0.05, "Sí", "No")
  ))
}

# Realizar pruebas
resultados_normalidad <- rbind(
  test_normalidad(df_nyse$Valor, "Original"),
  test_normalidad(nyse_log, "Logarítmica"),
  test_normalidad(nyse_sqrt, "Raíz Cuadrada")
)

if (!is.null(lambda_bc)) {
  resultados_normalidad <- rbind(
    resultados_normalidad,
    test_normalidad(nyse_boxcox, sprintf("Box-Cox (λ=%.2f)", lambda_bc))
  )
}

print(resultados_normalidad)

# Guardar resultados
guardar_tabla(resultados_normalidad, "06_5_pruebas_normalidad_transformaciones.csv")

# ==============================================================================
# 6. ANÁLISIS DE VARIANZA
# ==============================================================================

cat("\n📊 ANÁLISIS DE VARIANZA\n")
cat(rep("-", 80), "\n", sep = "")

# Calcular varianza móvil para cada transformación
library(zoo)
ventana <- 20

var_original <- rollapply(df_nyse$Valor, width = ventana, FUN = var, fill = NA)
var_log <- rollapply(nyse_log, width = ventana, FUN = var, fill = NA)
var_sqrt <- rollapply(nyse_sqrt, width = ventana, FUN = var, fill = NA)

# Coeficiente de variación de la varianza (indicador de estabilidad)
cv_var_original <- sd(var_original, na.rm = TRUE) / mean(var_original, na.rm = TRUE)
cv_var_log <- sd(var_log, na.rm = TRUE) / mean(var_log, na.rm = TRUE)
cv_var_sqrt <- sd(var_sqrt, na.rm = TRUE) / mean(var_sqrt, na.rm = TRUE)

cat(sprintf("CV varianza original:     %.4f\n", cv_var_original))
cat(sprintf("CV varianza log:          %.4f\n", cv_var_log))
cat(sprintf("CV varianza sqrt:         %.4f\n", cv_var_sqrt))

if (!is.null(lambda_bc)) {
  var_boxcox <- rollapply(nyse_boxcox, width = ventana, FUN = var, fill = NA)
  cv_var_boxcox <- sd(var_boxcox, na.rm = TRUE) / mean(var_boxcox, na.rm = TRUE)
  cat(sprintf("CV varianza Box-Cox:      %.4f\n", cv_var_boxcox))
}

cat("\n💡 Menor CV → Mayor estabilidad de varianza\n")

# ==============================================================================
# 7. RECOMENDACIÓN
# ==============================================================================

cat("\n")
cat("🎯 RECOMENDACIÓN DE TRANSFORMACIÓN\n")
cat(rep("=", 80), "\n", sep = "")

# Determinar mejor transformación basada en normalidad y estabilidad
mejor_normalidad <- resultados_normalidad[which.max(resultados_normalidad$P_valor), ]
mejores_cv <- c(Original = cv_var_original, Log = cv_var_log, Sqrt = cv_var_sqrt)
if (!is.null(lambda_bc)) mejores_cv <- c(mejores_cv, BoxCox = cv_var_boxcox)
mejor_estabilidad <- names(which.min(mejores_cv))

cat(sprintf("\n• Mejor normalidad: %s (p-valor = %.4f)\n", 
            mejor_normalidad$Transformacion, mejor_normalidad$P_valor))
cat(sprintf("• Mayor estabilidad de varianza: %s (CV = %.4f)\n", 
            mejor_estabilidad, min(mejores_cv)))

cat("\n💡 CONSIDERACIONES:\n")
cat("  1. Si lambda Box-Cox ≈ 0 → Usar transformación logarítmica\n")
cat("  2. Si varianza aumenta con el nivel → Considerar log o Box-Cox\n")
cat("  3. Para modelación ARIMA, usar la transformación más estable\n")
cat("  4. Para modelación GARCH, trabajar con retornos logarítmicos\n")

cat("\nPaso 6.5 completado: Transformaciones analizadas\n")
