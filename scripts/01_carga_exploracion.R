# ==============================================================================
# PASO 1: CARGA Y EXPLORACIÓN INICIAL DE LOS DATOS
# ==============================================================================
#
# Este script carga la serie temporal nyse y realiza una exploración inicial
# para comprender la estructura, identificar valores atípicos y obtener
# estadísticas descriptivas básicas.
#

# Cargar configuración si no está cargada
if (!exists("DIR_ROOT")) {
  source("config.R")
}

# ==============================================================================
# CARGA DE DATOS
# ==============================================================================

cat("📊 Cargando serie temporal nyse...\n")
library(astsa)
# Cargar la serie nyse desde el paquete base de R
data(nyse)

# Convertir a serie temporal si no lo es
#if (!is.ts(nyse)) {
 # nyse <- ts(nyse, start = c(1962, 1), frequency = 12)}

# ==============================================================================
# INFORMACIÓN BÁSICA DE LA SERIE
# ==============================================================================

# Información de la serie
cat("\n Información básica de la serie:\n")
cat(sprintf("  • Longitud: %d observaciones\n", length(nyse)))
cat(sprintf("  • Clase: %s\n", class(nyse)[1]))
cat(sprintf("  • Frecuencia: %s\n", frequency(nyse)))

## ==============================================================================
# GENERAR FECHAS HÁBILES DE nyse
# ==============================================================================

cat("\nGenerando fechas hábiles de la nyse...\n")

# Definir período (ajustar según tus datos)
# nyse data es diaria desde 1984-02-02 hasta 1991-12-31
fecha_inicio <- as.Date("1984-02-02")  
fecha_fin <- as.Date("1991-12-31")

# 1. Generar todos los días del periodo
dias_todos <- seq(fecha_inicio, fecha_fin, by = "day")

# 2. Identificar cuáles son fines de semana
es_fin_de_semana <- !isWeekday(dias_todos)

# 3. Identificar festivos específicos de la nyse
years_range <- unique(format(dias_todos, "%Y"))
festivos_nyse <- as.Date(holidayNYSE(as.numeric(years_range)))

# 4. Filtrar: Que NO sea fin de semana Y que NO esté en la lista de festivos
es_habil <- !dias_todos %in% festivos_nyse & !es_fin_de_semana
fechas_habiles <- dias_todos[es_habil]

cat(sprintf("  • Días hábiles identificados: %d\n", length(fechas_habiles)))
cat(sprintf("  • Observaciones en nyse: %d\n", length(nyse)))

# Verificar que tengamos suficientes fechas
if (length(fechas_habiles) < length(nyse)) {
  cat("\n⚠️  ADVERTENCIA: No hay suficientes fechas hábiles.\n")
  cat("    Ajustando fechas...\n")
  # Extender el rango si es necesario
  fecha_fin_ajustada <- fecha_fin + 365
  dias_todos <- seq(fecha_inicio, fecha_fin_ajustada, by = "day")
  es_fin_de_semana <- !isWeekday(dias_todos)
  years_range <- unique(format(dias_todos, "%Y"))
  festivos_nyse <- as.Date(holidaynyse(as.numeric(years_range)))
  es_habil <- !dias_todos %in% festivos_nyse & !es_fin_de_semana
  fechas_habiles <- dias_todos[es_habil]
}

# ==============================================================================
# CREAR DATAFRAME CON FECHAS CORRECTAS
# ==============================================================================

# 5. Crear dataframe final con fechas correctas
df_nyse <- data.frame(
  Fecha = fechas_habiles[1:length(nyse)],
  Valor = as.numeric(nyse)
)

cat("\nDataFrame creado con fechas hábiles de nyse\n")
cat(sprintf("  • Primera fecha: %s\n", df_nyse$Fecha[1]))
cat(sprintf("  • Última fecha: %s\n", df_nyse$Fecha[nrow(df_nyse)]))

# Guardar dataframe
saveRDS(df_nyse, file.path(DIR_MODELOS, "df_nyse.rds"))

# ==============================================================================
# ESTADÍSTICAS DESCRIPTIVAS
# ==============================================================================

cat("\n📈 ESTADÍSTICAS DESCRIPTIVAS\n")
cat(rep("-", 80), "\n", sep = "")

# Resumen básico
cat("\nResumen estadístico:\n")
print(summary(df_nyse$Valor))

# Estadísticas adicionales
media <- mean(df_nyse$Valor, na.rm = TRUE)
mediana <- median(df_nyse$Valor, na.rm = TRUE)
desv_std <- sd(df_nyse$Valor, na.rm = TRUE)
varianza <- var(df_nyse$Valor, na.rm = TRUE)
minimo <- min(df_nyse$Valor, na.rm = TRUE)
maximo <- max(df_nyse$Valor, na.rm = TRUE)
rango <- maximo - minimo
cv <- (desv_std / media) * 100
asimetria <- skewness(df_nyse$Valor)
curtosis <- kurtosis(df_nyse$Valor)

cat("\n")
cat(sprintf("Media:               %12.6f\n", media))
cat(sprintf("Mediana:             %12.6f\n", mediana))
cat(sprintf("Desviación Estándar: %12.6f\n", desv_std))
cat(sprintf("Varianza:            %12.6f\n", varianza))
cat(sprintf("Mínimo:              %12.6f\n", minimo))
cat(sprintf("Máximo:              %12.6f\n", maximo))
cat(sprintf("Rango:               %12.6f\n", rango))
cat(sprintf("Coef. Variación:     %12.2f%%\n", cv))
cat(sprintf("Asimetría:           %12.4f\n", asimetria))
cat(sprintf("Curtosis:            %12.4f\n", curtosis))

cat("\n")

# ==============================================================================
# ANÁLISIS DE RETORNOS
# ==============================================================================

cat("ANÁLISIS DE RETORNOS\n")
cat(rep("-", 80), "\n", sep = "")

# Calcular retornos logarítmicos
df_nyse$Retorno <- c(NA, diff(log(df_nyse$Valor)))

# Estadísticas de retornos
retornos <- na.omit(df_nyse$Retorno)
media_ret <- mean(retornos)
sd_ret <- sd(retornos)
asimetria_ret <- skewness(retornos)
curtosis_ret <- kurtosis(retornos)

cat("\nEstadísticas de retornos logarítmicos:\n")
cat(sprintf("Media:               %12.6f (%.4f%%)\n", media_ret, media_ret * 100))
cat(sprintf("Desviación Estándar: %12.6f\n", sd_ret))
cat(sprintf("Asimetría:           %12.4f\n", asimetria_ret))
cat(sprintf("Curtosis:            %12.4f\n", curtosis_ret))

# Interpretación de curtosis
if (curtosis_ret > 3) {
  cat("\n  • Curtosis > 3 → Distribución leptocúrtica (colas pesadas)\n")
  cat("  • Sugiere presencia de valores extremos y volatilidad cambiante\n")
  cat("  • ⚠️  Considerar modelos GARCH para capturar volatilidad\n")
} else {
  cat("\n  • Curtosis ≈ 3 → Distribución aproximadamente normal\n")
}

cat("\n")

# ==============================================================================
# DETECCIÓN DE VALORES ATÍPICOS
# ==============================================================================

cat(" DETECCIÓN DE VALORES ATÍPICOS\n")
cat(rep("-", 80), "\n", sep = "")

# Método de Tukey (IQR)
Q1 <- quantile(df_nyse$Valor, 0.25, na.rm = TRUE)
Q3 <- quantile(df_nyse$Valor, 0.75, na.rm = TRUE)
IQR_val <- Q3 - Q1

limite_inferior <- Q1 - 1.5 * IQR_val
limite_superior <- Q3 + 1.5 * IQR_val

outliers <- df_nyse$Valor < limite_inferior | df_nyse$Valor > limite_superior
n_outliers <- sum(outliers, na.rm = TRUE)

cat(sprintf("Q1 (25%%):           %12.6f\n", Q1))
cat(sprintf("Q3 (75%%):           %12.6f\n", Q3))
cat(sprintf("IQR:                 %12.6f\n", IQR_val))
cat(sprintf("Límite inferior:     %12.6f\n", limite_inferior))
cat(sprintf("Límite superior:     %12.6f\n", limite_superior))
cat(sprintf("\nValores atípicos:    %12d (%.2f%%)\n", n_outliers, (n_outliers/nrow(df_nyse))*100))

if (n_outliers > 0) {
  cat("\nFechas con valores atípicos (primeros 10):\n")
  outliers_df <- df_nyse[outliers, ]
  print(head(outliers_df[, c("Fecha", "Valor")], 10))
}

cat("\n")

# ==============================================================================
# ANÁLISIS TEMPORAL
# ==============================================================================

cat("ANÁLISIS TEMPORAL\n")
cat(rep("-", 80), "\n", sep = "")

# Agregar variables temporales
df_nyse$Año <- as.numeric(format(df_nyse$Fecha, "%Y"))
df_nyse$Mes <- as.numeric(format(df_nyse$Fecha, "%m"))
df_nyse$DiaSemana <- weekdays(df_nyse$Fecha)

# Estadísticas por año
stats_por_año <- df_nyse %>%
  group_by(Año) %>%
  summarise(
    N_obs = n(),
    Media = mean(Valor, na.rm = TRUE),
    SD = sd(Valor, na.rm = TRUE),
    Min = min(Valor, na.rm = TRUE),
    Max = max(Valor, na.rm = TRUE)
  )

cat("\nEstadísticas por año:\n")
print(stats_por_año)

# Verificar efecto día de la semana
stats_por_dia <- df_nyse %>%
  group_by(DiaSemana) %>%
  summarise(
    N_obs = n(),
    Media_Retorno = mean(Retorno, na.rm = TRUE)
  )

cat("\n\nEstadísticas por día de la semana:\n")
print(stats_por_dia)

# ==============================================================================
# CREAR TABLA RESUMEN
# ==============================================================================

cat("\n💾 Guardando tablas de estadísticas...\n")

# Tabla de estadísticas descriptivas
tabla_estadisticas <- data.frame(
  Estadistica = c("N° Observaciones", "Media", "Mediana", "Desv. Estándar", 
                  "Varianza", "Mínimo", "Máximo", "Rango", "CV (%)", 
                  "Asimetría", "Curtosis", "Q1", "Q3", "IQR", "Outliers"),
  Valor = c(nrow(df_nyse), media, mediana, desv_std, varianza, minimo, maximo, 
            rango, cv, asimetria, curtosis, Q1, Q3, IQR_val, n_outliers)
)

guardar_tabla(tabla_estadisticas, "01_estadisticas_descriptivas.csv")

# Tabla de retornos
tabla_retornos <- data.frame(
  Estadistica = c("Media Retorno", "SD Retorno", "Asimetría Retorno", "Curtosis Retorno"),
  Valor = c(media_ret, sd_ret, asimetria_ret, curtosis_ret)
)

guardar_tabla(tabla_retornos, "01_estadisticas_retornos.csv")
guardar_tabla(stats_por_año, "01_estadisticas_por_año.csv")

# ==============================================================================
# VALORES FALTANTES
# ==============================================================================

cat("\n🔍 Verificando valores faltantes...\n")

n_na <- sum(is.na(df_nyse$Valor))
pct_na <- (n_na / length(df_nyse$Valor)) * 100

cat(sprintf("Valores NA: %d (%.2f%%)\n", n_na, pct_na))

if (n_na > 0) {
  cat(" Hay valores faltantes que deben ser tratados\n")
} else {
  cat("No hay valores faltantes\n")
}

cat("\n")

# ==============================================================================
# GUARDAR SERIES PARA USO POSTERIOR
# ==============================================================================

cat("Guardando series temporales...\n")

# Guardar serie original
guardar_modelo(nyse, "nyse_original.rds")

# Guardar dataframe completo
guardar_modelo(df_nyse, "df_nyse.rds")

# Crear serie de retornos
retornos_ts <- ts(na.omit(df_nyse$Retorno), frequency = 252)  # 252 días hábiles/año
guardar_modelo(retornos_ts, "nyse_retornos.rds")

cat("\nPaso 1 completado: Exploración inicial finalizada\n")

# ==============================================================================
# RESUMEN DEL PASO
# ==============================================================================

cat("\n")
cat("RESUMEN DEL PASO 1\n")
cat(rep("=", 80), "\n", sep = "")
cat(sprintf("• Serie: nyse (%s a %s)\n", df_nyse$Fecha[1], df_nyse$Fecha[nrow(df_nyse)]))
cat(sprintf("• Observaciones: %d días hábiles\n", nrow(df_nyse)))
cat(sprintf("• Media: %.6f\n", media))
cat(sprintf("• Desv. Estándar: %.6f\n", desv_std))
cat(sprintf("• Outliers: %d (%.2f%%)\n", n_outliers, (n_outliers/nrow(df_nyse))*100))
cat(sprintf("• Valores NA: %d\n", n_na))
cat(sprintf("• Curtosis retornos: %.4f ", curtosis_ret))
if (curtosis_ret > 3) {
  cat("( Colas pesadas - considerar GARCH)\n")
} else {
  cat("(Normal)\n")
}
cat(rep("=", 80), "\n", sep = "")
cat("\n")
