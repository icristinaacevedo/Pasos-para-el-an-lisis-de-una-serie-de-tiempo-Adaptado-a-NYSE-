# ==============================================================================
# PASO 9: GENERACIÓN DE PRONÓSTICOS
# ==============================================================================

if (!exists("DIR_ROOT")) source("config.R")
if (!exists("modelo_final")) modelo_final <- cargar_modelo("modelo_final.rds")
if (!exists("nyse")) nyse <- cargar_modelo("nyse_original.rds")
if (!exists("df_nyse")) df_nyse <- cargar_modelo("df_nyse.rds")

library(forecast)
library(lubridate)

cat("📊 Generando pronósticos...\n\n")

# Generar pronóstico
cat(sprintf("Horizonte de pronóstico: %d períodos\n\n", HORIZONTE_PRONOSTICO))

pronostico <- forecast(modelo_final, h = HORIZONTE_PRONOSTICO)

# Guardar pronóstico
guardar_modelo(pronostico, "pronostico.rds")

# Mostrar primeros valores
cat("📈 Primeros 12 valores pronosticados:\n")
print(head(pronostico$mean, 12))
cat("\n")

# Crear fechas futuras para datos DIARIOS
ultima_fecha <- max(df_nyse$Fecha)

# Generar fechas de días hábiles futuros (solo lunes a viernes)
fechas_futuras <- c()
fecha_actual <- ultima_fecha

while (length(fechas_futuras) < HORIZONTE_PRONOSTICO) {
  fecha_actual <- fecha_actual + days(1)
  # Solo agregar si es día hábil (lunes=2 a viernes=6)
  if (wday(fecha_actual) >= 2 && wday(fecha_actual) <= 6) {
    fechas_futuras <- c(fechas_futuras, fecha_actual)
  }
}

fechas_futuras <- as.Date(fechas_futuras, origin = "1970-01-01")

# Crear tabla de pronósticos
tabla_pronostico <- data.frame(
  Periodo = 1:HORIZONTE_PRONOSTICO,
  Fecha = format(fechas_futuras, "%Y-%m-%d"),
  Pronostico = as.numeric(pronostico$mean),
  IC_Inferior_80 = as.numeric(pronostico$lower[, 1]),
  IC_Superior_80 = as.numeric(pronostico$upper[, 1]),
  IC_Inferior_95 = as.numeric(pronostico$lower[, 2]),
  IC_Superior_95 = as.numeric(pronostico$upper[, 2])
)

guardar_tabla(tabla_pronostico, "09_tabla_pronosticos.csv")

# Gráfico de pronóstico
png(file.path(DIR_FIGURES, "09_pronostico.png"), 
    width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)

plot(pronostico, 
     main = sprintf("Pronóstico NYSE - %d Períodos (Días Hábiles)", HORIZONTE_PRONOSTICO),
     xlab = "Tiempo",
     ylab = "Retornos",
     shadecols = c("lightblue", "lightyellow"),
     fcol = "blue",
     flwd = 2)

legend("topleft",
       legend = c("Datos históricos", "Pronóstico", "IC 80%", "IC 95%"),
       col = c("black", "blue", "lightblue", "lightyellow"),
       lty = c(1, 1, NA, NA),
       pch = c(NA, NA, 15, 15),
       cex = 0.8)

dev.off()

# Gráfico zoom en últimos datos + pronóstico
png(file.path(DIR_FIGURES, "09_pronostico_zoom.png"), 
    width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)

plot(pronostico, 
     include = 100,  # Últimos 100 días
     main = "Pronóstico NYSE - Últimos 100 Días + Predicción",
     xlab = "Tiempo",
     ylab = "Retornos",
     shadecols = c("lightblue", "lightyellow"),
     fcol = "blue",
     flwd = 2)

dev.off()

# Estadísticas del pronóstico
cat("📊 ESTADÍSTICAS DEL PRONÓSTICO:\n")
cat(rep("-", 80), "\n", sep = "")
cat(sprintf("Media del pronóstico:     %12.6f\n", mean(pronostico$mean)))
cat(sprintf("Mínimo pronosticado:      %12.6f\n", min(pronostico$mean)))
cat(sprintf("Máximo pronosticado:      %12.6f\n", max(pronostico$mean)))
cat(sprintf("Amplitud IC 95%% promedio: %12.6f\n", 
            mean(pronostico$upper[,2] - pronostico$lower[,2])))
cat("\n")

cat("✅ Paso 9 completado: Pronósticos generados\n")