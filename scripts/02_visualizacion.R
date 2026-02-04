# ==============================================================================
# PASO 2: VISUALIZACIÓN DE LA SERIE TEMPORAL
# ==============================================================================

if (!exists("DIR_ROOT")) {
  source("config.R")
}

if (!exists("nyse")) {
  nyse <- cargar_modelo("nyse_original.rds")
}

if (!exists("df_nyse")) {
  df_nyse <- cargar_modelo("df_nyse.rds")
}

cat("📊 Generando visualizaciones de la serie nyse...\n\n")

# ==============================================================================
# GRÁFICO 1: SERIE TEMPORAL COMPLETA
# ==============================================================================

cat("🎨 Creando gráfico de serie temporal...\n")

library(timeDate)

# Gráfico principal
p1 <- ggplot(df_nyse, aes(x = Fecha, y = Valor)) +
  geom_line(color = COLOR_PRIMARY, linewidth = 1) +
  geom_smooth(method = "lm", se = TRUE, color = COLOR_ACCENT, 
              linetype = "dashed", linewidth = 0.8) +
  labs(
    title = "Serie Temporal NYSE (1984-1991)",
    subtitle = "Retornos diarios del New York Stock Exchange",
    x = "Tiempo",
    y = "Retornos"
  ) +
  THEME_CUSTOM

ggsave(file.path(DIR_FIGURES, "02_serie_temporal.png"), 
       p1, width = GRAPH_WIDTH, height = GRAPH_HEIGHT/1.5, dpi = GRAPH_DPI)

cat("✅ Gráfico de serie temporal guardado\n\n")

# ==============================================================================
# GRÁFICO 2: PANEL DE VISUALIZACIONES MÚLTIPLES
# ==============================================================================

cat("🎨 Creando panel de visualizaciones múltiples (datos diarios)...\n")

library(gridExtra)

# 2.1 Serie temporal con bandas de confianza
p2_1 <- ggplot(df_nyse, aes(x = Fecha, y = Valor)) +
  geom_line(color = COLOR_PRIMARY, linewidth = 0.8) +
  geom_hline(yintercept = mean(nyse), color = COLOR_ACCENT, 
             linetype = "dashed", linewidth = 0.8) +
  geom_ribbon(aes(ymin = mean(nyse) - sd(nyse), 
                  ymax = mean(nyse) + sd(nyse)),
              alpha = 0.2, fill = COLOR_SECONDARY) +
  labs(title = "Serie Temporal con Media ± 1 SD", x = "Fecha", y = "Valor") +
  THEME_CUSTOM +
  theme(plot.title = element_text(size = 12))

# 2.2 Histograma
p2_2 <- ggplot(df_nyse, aes(x = Valor)) +
  geom_histogram(bins = 30, fill = COLOR_SECONDARY, color = "white", alpha = 0.7) +
  geom_vline(xintercept = mean(nyse), color = COLOR_ACCENT, 
             linetype = "dashed", linewidth = 1) +
  geom_vline(xintercept = median(nyse), color = COLOR_SUCCESS, 
             linetype = "dashed", linewidth = 1) +
  labs(title = "Distribución de Valores", x = "Valor", y = "Frecuencia") +
  THEME_CUSTOM +
  theme(plot.title = element_text(size = 12))

# 2.3 Boxplot por año
df_nyse$Año <- format(df_nyse$Fecha, "%Y")
p2_3 <- ggplot(df_nyse, aes(x = Año, y = Valor, group = Año)) +
  geom_boxplot(fill = COLOR_SECONDARY, alpha = 0.6, outlier.color = COLOR_ACCENT) +
  labs(title = "Distribución por Año", x = "Año", y = "Valor") +
  THEME_CUSTOM +
  theme(
    plot.title = element_text(size = 12),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# 2.4 Boxplot por mes (datos diarios)
df_nyse$Mes <- format(df_nyse$Fecha, "%m")
meses_nombres <- c("Ene", "Feb", "Mar", "Abr", "May", "Jun",
                   "Jul", "Ago", "Sep", "Oct", "Nov", "Dic")
df_nyse$MesNombre <- factor(df_nyse$Mes, levels = sprintf("%02d", 1:12), labels = meses_nombres)

p2_4 <- ggplot(df_nyse, aes(x = MesNombre, y = Valor, group = MesNombre)) +
  geom_boxplot(fill = COLOR_SECONDARY, alpha = 0.6, outlier.color = COLOR_ACCENT) +
  labs(title = "Distribución por Mes (Datos Diarios)", x = "Mes", y = "Valor") +
  THEME_CUSTOM +
  theme(
    plot.title = element_text(size = 12),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# Combinar gráficos
panel <- grid.arrange(p2_1, p2_2, p2_3, p2_4, ncol = 2)

ggsave(file.path(DIR_FIGURES, "02_panel_visualizaciones.png"), 
       panel, width = GRAPH_WIDTH, height = GRAPH_HEIGHT, dpi = GRAPH_DPI)

cat("✅ Panel de visualizaciones guardado\n\n")

# ==============================================================================
# GRÁFICO 3: Q-Q PLOT
# ==============================================================================

cat("🎨 Creando Q-Q plot...\n")

p3 <- ggplot(df_nyse, aes(sample = Valor)) +
  stat_qq(color = COLOR_PRIMARY, size = 2, alpha = 0.6) +
  stat_qq_line(color = COLOR_ACCENT, linewidth = 1, linetype = "dashed") +
  labs(
    title = "Q-Q Plot - Normalidad de la Serie",
    subtitle = "Comparación con distribución normal",
    x = "Cuantiles teóricos",
    y = "Cuantiles de la muestra"
  ) +
  THEME_CUSTOM

ggsave(file.path(DIR_FIGURES, "02_qq_plot.png"), 
       p3, width = GRAPH_WIDTH/1.5, height = GRAPH_HEIGHT/1.5, dpi = GRAPH_DPI)

cat("✅ Q-Q plot guardado\n\n")

# ==============================================================================
# GRÁFICO 4: ANÁLISIS DE TENDENCIA Y VARIANZA (datos diarios)
# ==============================================================================

cat("🎨 Creando análisis de tendencia y varianza para datos diarios...\n")

library(zoo)

# Ventana de media móvil (21 días ≈ 1 mes de trading)
ventana <- 21

df_nyse$Media_Movil <- rollmean(nyse, k = ventana, fill = NA, align = "right")
df_nyse$SD_Movil <- rollapply(nyse, width = ventana, FUN = sd, fill = NA, align = "right")

# Gráfico de media móvil
p4_1 <- ggplot(df_nyse, aes(x = Fecha)) +
  geom_line(aes(y = Valor), color = "gray60", alpha = 0.6, linewidth = 0.5) +
  geom_line(aes(y = Media_Movil), color = COLOR_ACCENT, linewidth = 1.2) +
  labs(
    title = "Serie Original vs Media Móvil (21 días)",
    x = "Fecha",
    y = "Valor"
  ) +
  THEME_CUSTOM +
  theme(plot.title = element_text(size = 12))

# Gráfico de desviación estándar móvil
p4_2 <- ggplot(df_nyse, aes(x = Fecha, y = SD_Movil)) +
  geom_line(color = COLOR_SUCCESS, linewidth = 1) +
  labs(
    title = "Desviación Estándar Móvil (21 días)",
    x = "Fecha",
    y = "Desviación Estándar"
  ) +
  THEME_CUSTOM +
  theme(plot.title = element_text(size = 12))

panel_tendencia <- grid.arrange(p4_1, p4_2, ncol = 1)

ggsave(file.path(DIR_FIGURES, "02_tendencia_varianza.png"), 
       panel_tendencia, width = GRAPH_WIDTH, height = GRAPH_HEIGHT, dpi = GRAPH_DPI)

cat("✅ Gráfico de tendencia y varianza guardado\n\n")

# ==============================================================================
# GRÁFICO 5: LAG PLOT (para datos no estacionales)
# ==============================================================================

cat("🎨 Creando lag plot...\n")

library(forecast)

png(file.path(DIR_FIGURES, "02_lag_plot.png"), 
    width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)

gglagplot(nyse, lags = 9, do.lines = FALSE) +
  labs(title = "Lag Plot - Análisis de Autocorrelación Visual") +
  THEME_CUSTOM

dev.off()

cat("✅ Lag plot guardado\n\n")

# ==============================================================================
# GRÁFICO 6: SUBSERIES PLOT (SOLO SI HAY ESTACIONALIDAD)
# ==============================================================================

cat("🎨 Verificando estacionalidad para subseries plot...\n")

# Verificar si la serie tiene frecuencia estacional definida
if (frequency(nyse) > 1) {
  cat("   Serie tiene estacionalidad definida, creando subseries plot...\n")
  
  png(file.path(DIR_FIGURES, "02_subseries_plot.png"), 
      width = GRAPH_WIDTH, height = GRAPH_HEIGHT, units = "in", res = GRAPH_DPI)
  
  ggsubseriesplot(nyse) +
    labs(
      title = "Subseries Plot - Análisis de Estacionalidad",
      y = "Valor"
    ) +
    THEME_CUSTOM
  
  dev.off()
  
  cat("✅ Subseries plot guardado\n\n")
} else {
  cat("   ⚠️  Serie no tiene estacionalidad definida (frecuencia = 1)\n")
  cat("   Saltando subseries plot (requiere datos estacionales)\n\n")
}

# ==============================================================================
# RESUMEN DE VISUALIZACIONES
# ==============================================================================

cat("\n✅ Paso 2 completado: Visualizaciones generadas\n\n")

cat("📊 RESUMEN DE GRÁFICOS GENERADOS\n")
cat(rep("=", 80), "\n", sep = "")
cat("  1. Serie temporal completa\n")
cat("  2. Panel de visualizaciones múltiples\n")
cat("  3. Q-Q plot para normalidad\n")
cat("  4. Tendencia y varianza móvil\n")
cat("  5. Lag plot\n")
if (frequency(nyse) > 1) {
  cat("  6. Subseries plot\n")
} else {
  cat("  6. Subseries plot (omitido - datos no estacionales)\n")
}
cat(rep("=", 80), "\n", sep = "")
cat("\n")