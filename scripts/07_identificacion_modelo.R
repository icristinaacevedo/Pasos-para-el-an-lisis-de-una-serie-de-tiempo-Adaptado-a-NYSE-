# ==============================================================================
# PASO 7: IDENTIFICACIÓN Y SELECCIÓN DEL MODELO (MEJORADO)
# ==============================================================================
#
# Este script identifica el mejor modelo ARIMA/SARIMA usando tanto
# selección automática como ajuste manual de modelos alternativos.
#

if (!exists("DIR_ROOT")) source("config.R")
if (!exists("df_nyse")) df_nyse <- cargar_modelo("df_nyse.rds")

library(forecast)

cat("📊 Identificando el mejor modelo ARIMA/SARIMA...\n\n")

# Crear serie temporal
NYSE <- ts(df_nyse$Valor, frequency = 252)

# Decidir si usar transformación
usar_transformacion <- readline("¿Usar transformación logarítmica? (s/n): ")
if (tolower(usar_transformacion) == "s") {
  NYSE_modelo <- log(NYSE)
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
cat("   (Esto puede tomar varios minutos...)\n\n")

modelo_auto <- auto.arima(
  NYSE_modelo,
  seasonal = FALSE,  # NYSE es diaria, no hay estacionalidad clara
  stepwise = FALSE,
  approximation = FALSE,
  trace = TRUE,
  ic = CRITERIO_SELECCION,
  max.p = MAX_P,
  max.q = MAX_Q,
  max.d = 2,
  lambda = NULL  # No aplicar transformación automática
)

cat("\n✅ Mejor modelo automático:\n")
print(summary(modelo_auto))

order_auto <- arimaorder(modelo_auto)
cat(sprintf("\n📋 Orden: ARIMA(%d,%d,%d)\n", order_auto[1], order_auto[2], order_auto[3]))

guardar_modelo(modelo_auto, "modelo_arima_auto.rds")

# ==============================================================================
# 2. MODELOS MANUALES ALTERNATIVOS
# ==============================================================================

cat("\n")
cat("🔧 2. AJUSTE DE MODELOS MANUALES\n")
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

# Función auxiliar para ajustar y evaluar modelo
ajustar_evaluar_modelo <- function(nombre, p, d, q) {
  tryCatch({
    cat(sprintf("\n  Ajustando %s: ARIMA(%d,%d,%d)...", nombre, p, d, q))
    modelo <- Arima(NYSE_modelo, order = c(p, d, q))
    
    aic_val <- AIC(modelo)
    bic_val <- BIC(modelo)
    rmse_val <- accuracy(modelo)[1, "RMSE"]
    
    cat(sprintf(" AIC=%.2f, BIC=%.2f ✓\n", aic_val, bic_val))
    
    # Guardar en lista
    modelos_lista[[nombre]] <<- modelo
    
    # Agregar a tabla
    modelos_info <<- rbind(modelos_info, data.frame(
      Modelo = nombre,
      Orden = sprintf("(%d,%d,%d)", p, d, q),
      AIC = aic_val,
      BIC = bic_val,
      RMSE = rmse_val
    ))
    
    return(TRUE)
  }, error = function(e) {
    cat(" ❌ Error\n")
    return(FALSE)
  })
}

# Agregar modelo automático a la lista
modelos_lista[["Auto"]] <- modelo_auto
modelos_info <- rbind(modelos_info, data.frame(
  Modelo = "Auto",
  Orden = sprintf("(%d,%d,%d)", order_auto[1], order_auto[2], order_auto[3]),
  AIC = AIC(modelo_auto),
  BIC = BIC(modelo_auto),
  RMSE = accuracy(modelo_auto)[1, "RMSE"]
))

# Modelos basados en ACF/PACF
cat("\n📊 Modelos basados en análisis ACF/PACF:\n")

ajustar_evaluar_modelo("AR1", 1, 0, 0)
ajustar_evaluar_modelo("AR2", 2, 0, 0)
ajustar_evaluar_modelo("MA1", 0, 0, 1)
ajustar_evaluar_modelo("MA2", 0, 0, 2)
ajustar_evaluar_modelo("ARMA(1,1)", 1, 0, 1)
ajustar_evaluar_modelo("ARMA(2,1)", 2, 0, 1)
ajustar_evaluar_modelo("ARMA(1,2)", 1, 0, 2)
ajustar_evaluar_modelo("ARMA(2,2)", 2, 0, 2)

# Modelos con diferenciación
cat("\n📊 Modelos con diferenciación:\n")

ajustar_evaluar_modelo("ARIMA(1,1,0)", 1, 1, 0)
ajustar_evaluar_modelo("ARIMA(0,1,1)", 0, 1, 1)
ajustar_evaluar_modelo("ARIMA(1,1,1)", 1, 1, 1)
ajustar_evaluar_modelo("ARIMA(2,1,1)", 2, 1, 1)
ajustar_evaluar_modelo("ARIMA(1,1,2)", 1, 1, 2)
ajustar_evaluar_modelo("ARIMA(2,1,2)", 2, 1, 2)

# Modelos adicionales
cat("\n📊 Modelos adicionales:\n")

ajustar_evaluar_modelo("ARIMA(3,1,0)", 3, 1, 0)
ajustar_evaluar_modelo("ARIMA(0,1,3)", 0, 1, 3)
ajustar_evaluar_modelo("ARIMA(3,1,1)", 3, 1, 1)
ajustar_evaluar_modelo("ARIMA(1,1,3)", 1, 1, 3)

# ==============================================================================
# 3. COMPARACIÓN DE MODELOS
# ==============================================================================

cat("\n")
cat("📊 TABLA COMPARATIVA DE MODELOS\n")
cat(rep("=", 80), "\n", sep = "")

# Ordenar por AIC
modelos_info <- modelos_info[order(modelos_info$AIC), ]
print(modelos_info, row.names = FALSE)

# Guardar tabla
guardar_tabla(modelos_info, "07_comparacion_modelos.csv")

# Identificar mejores modelos
mejor_aic <- modelos_info[which.min(modelos_info$AIC), ]
mejor_bic <- modelos_info[which.min(modelos_info$BIC), ]
mejor_rmse <- modelos_info[which.min(modelos_info$RMSE), ]

cat("\n")
cat("🏆 MEJORES MODELOS POR CRITERIO\n")
cat(rep("-", 80), "\n", sep = "")
cat(sprintf("• Mejor AIC:  %s %s (AIC=%.2f)\n", 
            mejor_aic$Modelo, mejor_aic$Orden, mejor_aic$AIC))
cat(sprintf("• Mejor BIC:  %s %s (BIC=%.2f)\n", 
            mejor_bic$Modelo, mejor_bic$Orden, mejor_bic$BIC))
cat(sprintf("• Mejor RMSE: %s %s (RMSE=%.4f)\n", 
            mejor_rmse$Modelo, mejor_rmse$Orden, mejor_rmse$RMSE))

# ==============================================================================
# 4. SELECCIÓN DEL MODELO FINAL
# ==============================================================================

cat("\n")
cat("🎯 SELECCIÓN DEL MODELO FINAL\n")
cat(rep("=", 80), "\n", sep = "")

# Usar el modelo con mejor AIC (criterio estándar)
nombre_final <- mejor_aic$Modelo
modelo_final <- modelos_lista[[nombre_final]]

cat(sprintf("\nModelo seleccionado: %s %s\n", nombre_final, mejor_aic$Orden))
cat("\nResumen del modelo final:\n")
print(summary(modelo_final))

# Guardar modelo final
guardar_modelo(modelo_final, "modelo_final.rds")

# Guardar información del modelo
info_modelo_final <- list(
  nombre = nombre_final,
  orden = mejor_aic$Orden,
  aic = mejor_aic$AIC,
  bic = mejor_aic$BIC,
  rmse = mejor_rmse$RMSE,
  transformacion = ifelse(tolower(usar_transformacion) == "s", "log", "ninguna")
)
guardar_modelo(info_modelo_final, "info_modelo_final.rds")

# ==============================================================================
# 5. ANÁLISIS DE COEFICIENTES
# ==============================================================================

cat("\n")
cat("📊 ANÁLISIS DE COEFICIENTES\n")
cat(rep("-", 80), "\n", sep = "")

coefs <- coef(modelo_final)
cat("\nCoeficientes estimados:\n")
print(coefs)

# Significancia de coeficientes (aproximada)
if (length(coefs) > 0) {
  se_coefs <- sqrt(diag(vcov(modelo_final)))
  t_stats <- coefs / se_coefs
  p_values <- 2 * (1 - pnorm(abs(t_stats)))
  
  tabla_coefs <- data.frame(
    Coeficiente = names(coefs),
    Estimacion = coefs,
    Error_Std = se_coefs,
    Estadistico_t = t_stats,
    P_valor = p_values,
    Significativo = ifelse(p_values < 0.05, "***", 
                          ifelse(p_values < 0.10, "**", 
                                ifelse(p_values < 0.15, "*", "")))
  )
  
  cat("\nTabla de coeficientes:\n")
  print(tabla_coefs, row.names = FALSE)
  
  guardar_tabla(tabla_coefs, "07_coeficientes_modelo_final.csv")
  
  # Verificar si hay coeficientes no significativos
  no_signif <- sum(tabla_coefs$P_valor > 0.05)
  if (no_signif > 0) {
    cat(sprintf("\n⚠️  Hay %d coeficiente(s) no significativo(s) al 5%%\n", no_signif))
    cat("   Considera simplificar el modelo\n")
  } else {
    cat("\n✅ Todos los coeficientes son significativos al 5%\n")
  }
}

# ==============================================================================
# 6. GRÁFICO COMPARATIVO
# ==============================================================================

cat("\n📊 Generando gráfico comparativo de criterios...\n")

library(ggplot2)

# Normalizar valores para comparación visual
modelos_info$AIC_norm <- (modelos_info$AIC - min(modelos_info$AIC)) / 
                          (max(modelos_info$AIC) - min(modelos_info$AIC))
modelos_info$BIC_norm <- (modelos_info$BIC - min(modelos_info$BIC)) / 
                          (max(modelos_info$BIC) - min(modelos_info$BIC))

# Tomar solo top 10 modelos por AIC
top_modelos <- head(modelos_info, 10)

p <- ggplot(top_modelos, aes(x = reorder(Modelo, AIC))) +
  geom_point(aes(y = AIC_norm, color = "AIC"), size = 3) +
  geom_point(aes(y = BIC_norm, color = "BIC"), size = 3) +
  geom_line(aes(y = AIC_norm, group = 1, color = "AIC"), linewidth = 1) +
  geom_line(aes(y = BIC_norm, group = 1, color = "BIC"), linewidth = 1) +
  scale_color_manual(values = c("AIC" = COLOR_PRIMARY, "BIC" = COLOR_SECONDARY)) +
  labs(
    title = "Comparación de Modelos ARIMA - Top 10",
    subtitle = "Valores normalizados (menor es mejor)",
    x = "Modelo",
    y = "Valor Normalizado",
    color = "Criterio"
  ) +
  THEME_CUSTOM +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(DIR_FIGURES, "07_comparacion_criterios.png"),
       p, width = GRAPH_WIDTH, height = GRAPH_HEIGHT, dpi = GRAPH_DPI)

cat("✅ Gráfico guardado\n")

cat("\n✅ Paso 7 completado: Modelo identificado y seleccionado\n")
