# ==============================================================================
# PASO 7: IDENTIFICACIÓN Y SELECCIÓN DEL MODELO ARIMA
# ==============================================================================
#
# Este script identifica modelos ARIMA candidatos usando:
#  - selección automática (auto.arima)
#  - modelos manuales basados en ACF/PACF
#
# La selección final puede ser automática o manual,
# debidamente justificada por parsimonia y análisis visual.
#

if (!exists("DIR_ROOT")) source("config.R")
if (!exists("df_nyse")) df_nyse <- cargar_modelo("df_nyse.rds")

library(forecast)

cat("📊 Identificando el mejor modelo ARIMA...\n\n")

# ==============================================================================
# 0. PREPARACIÓN DE LA SERIE
# ==============================================================================

# Serie temporal (NYSE)
NYSE <- ts(df_nyse$Valor, frequency = 252)

# Configuración: usar o no log (definido en config.R)
if (!exists("USAR_LOG_ARIMA")) USAR_LOG_ARIMA <- FALSE

if (USAR_LOG_ARIMA) {
  NYSE_modelo <- suppressWarnings(log(NYSE))
  cat("✅ Usando transformación logarítmica\n\n")
} else {
  NYSE_modelo <- NYSE
  cat("✅ Usando serie original\n\n")
}

# ==============================================================================
# 1. MODELO AUTOMÁTICO (AUTO.ARIMA)
# ==============================================================================

cat("🤖 1. SELECCIÓN AUTOMÁTICA CON AUTO.ARIMA\n")
cat(rep("-", 80), "\n", sep = "")
cat("   (Puede tomar algunos minutos)\n\n")

modelo_auto <- auto.arima(
  NYSE_modelo,
  seasonal = FALSE,
  stepwise = FALSE,
  approximation = FALSE,
  trace = TRUE,
  ic = CRITERIO_SELECCION,
  max.p = MAX_P,
  max.q = MAX_Q,
  max.d = 2
)

cat("\n✅ Mejor modelo automático:\n")
print(summary(modelo_auto))

order_auto <- arimaorder(modelo_auto)
cat(sprintf("\n📋 Orden: ARIMA(%d,%d,%d)\n",
            order_auto[1], order_auto[2], order_auto[3]))

guardar_modelo(modelo_auto, "modelo_arima_auto.rds")

# ==============================================================================
# 2. MODELOS MANUALES ALTERNATIVOS
# ==============================================================================

cat("\n🔧 2. AJUSTE DE MODELOS MANUALES\n")
cat(rep("-", 80), "\n", sep = "")

modelos_lista <- list()
modelos_info <- data.frame(
  Modelo = character(),
  Orden = character(),
  AIC = numeric(),
  BIC = numeric(),
  RMSE = numeric(),
  stringsAsFactors = FALSE
)

ajustar_evaluar_modelo <- function(nombre, p, d, q) {
  tryCatch({
    cat(sprintf("  Ajustando %s: ARIMA(%d,%d,%d)... ", nombre, p, d, q))
    
    modelo <- Arima(NYSE_modelo, order = c(p, d, q))
    
    aic_val  <- AIC(modelo)
    bic_val  <- BIC(modelo)
    rmse_val <- accuracy(modelo)[1, "RMSE"]
    
    cat(sprintf("AIC=%.2f, BIC=%.2f ✓\n", aic_val, bic_val))
    
    modelos_lista[[nombre]] <<- modelo
    modelos_info <<- rbind(
      modelos_info,
      data.frame(
        Modelo = nombre,
        Orden = sprintf("(%d,%d,%d)", p, d, q),
        AIC = aic_val,
        BIC = bic_val,
        RMSE = rmse_val
      )
    )
  }, error = function(e) {
    cat("❌ Error\n")
  })
}

# Agregar modelo automático
modelos_lista[["Auto"]] <- modelo_auto
modelos_info <- rbind(
  modelos_info,
  data.frame(
    Modelo = "Auto",
    Orden = sprintf("(%d,%d,%d)", order_auto[1], order_auto[2], order_auto[3]),
    AIC = AIC(modelo_auto),
    BIC = BIC(modelo_auto),
    RMSE = accuracy(modelo_auto)[1, "RMSE"]
  )
)

# Modelos candidatos
cat("\n📊 Modelos ARMA / ARIMA candidatos:\n")

ajustar_evaluar_modelo("AR1", 1, 0, 0)
ajustar_evaluar_modelo("AR2", 2, 0, 0)
ajustar_evaluar_modelo("MA1", 0, 0, 1)
ajustar_evaluar_modelo("ARMA(1,1)", 1, 0, 1)
ajustar_evaluar_modelo("ARIMA(1,1,0)", 1, 1, 0)
ajustar_evaluar_modelo("ARIMA(0,1,1)", 0, 1, 1)
ajustar_evaluar_modelo("ARIMA(1,1,1)", 1, 1, 1)
ajustar_evaluar_modelo("ARIMA(0,0,0)", 0, 0, 0)

# ==============================================================================
# 3. COMPARACIÓN DE MODELOS
# ==============================================================================

cat("\n📊 TABLA COMPARATIVA DE MODELOS\n")
cat(rep("=", 80), "\n", sep = "")

modelos_info <- modelos_info[order(modelos_info$AIC), ]
print(modelos_info, row.names = FALSE)

guardar_tabla(modelos_info, "07_comparacion_modelos.csv")

# ==============================================================================
# 4. SELECCIÓN FINAL DEL MODELO
# ==============================================================================

cat("\n🎯 SELECCIÓN DEL MODELO FINAL\n")
cat(rep("=", 80), "\n", sep = "")

# ------------------------------------------------------------------
# Selección manual justificada por parsimonia y análisis visual
# ------------------------------------------------------------------

# NOTA METODOLÓGICA:
# Aunque otros modelos presentan AIC ligeramente menores,
# se selecciona ARIMA(0,0,0) por evidencia de ruido blanco en la media.
# Esto justifica posteriormente el uso de modelos GARCH.

nombre_final <- "ARIMA(0,0,0)"
modelo_final <- modelos_lista[[nombre_final]]

# Métricas del modelo seleccionado
aic_final  <- AIC(modelo_final)
bic_final  <- BIC(modelo_final)
rmse_final <- accuracy(modelo_final)[1, "RMSE"]
orden_final <- paste0("(", paste(arimaorder(modelo_final), collapse = ","), ")")

cat(sprintf("\nModelo seleccionado: %s %s\n", nombre_final, orden_final))
print(summary(modelo_final))

# Guardar modelo final
guardar_modelo(modelo_final, "modelo_final.rds")

info_modelo_final <- list(
  nombre = nombre_final,
  orden = orden_final,
  aic = aic_final,
  bic = bic_final,
  rmse = rmse_final,
  transformacion = ifelse(USAR_LOG_ARIMA, "log", "ninguna"),
  metodo_seleccion = "manual (parsimonia + análisis visual)"
)

guardar_modelo(info_modelo_final, "info_modelo_final.rds")

# ==============================================================================
# 5. ANÁLISIS DE COEFICIENTES
# ==============================================================================

cat("\n📊 ANÁLISIS DE COEFICIENTES\n")
cat(rep("-", 80), "\n", sep = "")

coefs <- coef(modelo_final)

if (length(coefs) == 0) {
  cat("El modelo ARIMA(0,0,0) no contiene coeficientes AR/MA.\n")
  cat("La media se comporta como ruido blanco.\n")
} else {
  print(coefs)
}

# ==============================================================================
# 6. GRÁFICO COMPARATIVO
# ==============================================================================

cat("\n📊 Generando gráfico comparativo...\n")

library(ggplot2)

modelos_info$AIC_norm <- (modelos_info$AIC - min(modelos_info$AIC)) /
                          (max(modelos_info$AIC) - min(modelos_info$AIC))

p <- ggplot(head(modelos_info, 10),
            aes(x = reorder(Modelo, AIC), y = AIC_norm)) +
  geom_point(color = COLOR_PRIMARY, size = 3) +
  geom_line(group = 1, color = COLOR_PRIMARY) +
  labs(
    title = "Comparación de Modelos ARIMA",
    subtitle = "Criterio AIC normalizado",
    x = "Modelo",
    y = "AIC normalizado"
  ) +
  THEME_CUSTOM +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(
  file.path(DIR_FIGURES, "07_comparacion_modelos.png"),
  p,
  width = GRAPH_WIDTH,
  height = GRAPH_HEIGHT,
  dpi = GRAPH_DPI
)

cat("✅ Gráfico guardado\n")
cat("\nPaso 7 completado: modelo identificado y seleccionado correctamente\n")
