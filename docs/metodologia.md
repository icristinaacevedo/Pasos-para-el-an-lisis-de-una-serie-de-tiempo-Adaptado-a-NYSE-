# Metodología de Análisis de Series Temporales

## Introducción

Este documento describe la metodología completa utilizada para el análisis de series temporales en este proyecto. La metodología sigue las mejores prácticas establecidas en econometría y estadística aplicada.

## Marco Teórico

### Definición de Serie Temporal

Una serie temporal es una secuencia de observaciones ordenadas cronológicamente:

Y(t), t = 1, 2, ..., n

donde t representa el tiempo y Y(t) es el valor observado en el tiempo t.

### Componentes de una Serie Temporal

Toda serie temporal puede descomponerse en:

1. **Tendencia (T):** Movimiento a largo plazo
2. **Estacionalidad (S):** Patrones que se repiten en períodos fijos
3. **Ciclo (C):** Fluctuaciones de largo plazo sin periodicidad fija
4. **Componente Irregular (I):** Variaciones aleatorias

**Modelos de descomposición:**

- Aditivo: Y(t) = T(t) + S(t) + I(t)
- Multiplicativo: Y(t) = T(t) × S(t) × I(t)

## Proceso de Análisis

### 1. Exploración Inicial

**Objetivo:** Comprender la naturaleza de los datos

**Actividades:**
- Cálculo de estadísticas descriptivas
- Identificación de valores atípicos
- Detección de valores faltantes
- Análisis de distribución

**Herramientas:**
- Media, mediana, desviación estándar
- Método de Tukey (IQR) para outliers
- Gráficos de caja (boxplots)

### 2. Visualización

**Objetivo:** Identificar patrones visuales

**Gráficos clave:**
- Serie temporal: identificar tendencia y estacionalidad
- Histograma: evaluar distribución
- Boxplot por período: detectar estacionalidad
- Q-Q plot: verificar normalidad
- Lag plot: explorar autocorrelación

### 3. Descomposición

**Objetivo:** Separar componentes de la serie

**Métodos:**
- Descomposición clásica (aditiva/multiplicativa)
- STL (Seasonal and Trend decomposition using Loess)
- X-13ARIMA-SEATS (para series oficiales)

**Interpretación:**
- Tendencia: dirección general de la serie
- Estacionalidad: magnitud y patrón de repetición
- Residuos: variabilidad no explicada

### 4. Estacionariedad

**Definición:** Una serie es estacionaria si:
- E[Y(t)] = μ (media constante)
- Var[Y(t)] = σ² (varianza constante)
- Cov[Y(t), Y(t+k)] = γ(k) (autocovarianza depende solo del rezago)

**Pruebas estadísticas:**

**Prueba ADF (Augmented Dickey-Fuller):**
- H0: Serie tiene raíz unitaria (NO estacionaria)
- H1: Serie es estacionaria
- Rechazar H0 si p-valor < 0.05

**Prueba KPSS:**
- H0: Serie es estacionaria
- H1: Serie NO es estacionaria
- Rechazar H0 si p-valor < 0.05

**Métodos visuales:**
- Gráfico de media móvil
- Gráfico de varianza móvil

### 5. Autocorrelación

**Función de Autocorrelación (ACF):**

ρ(k) = Cov[Y(t), Y(t-k)] / Var[Y(t)]

Mide correlación entre Y(t) y Y(t-k)

**Interpretación:**
- Decaimiento exponencial → Proceso AR
- Corte abrupto en lag q → Proceso MA(q)
- Decaimiento lento → No estacionariedad

**Función de Autocorrelación Parcial (PACF):**

Correlación entre Y(t) y Y(t-k) eliminando efecto de rezagos intermedios

**Interpretación:**
- Corte abrupto en lag p → Proceso AR(p)
- Decaimiento exponencial → Proceso MA

### 6. Diferenciación

**Objetivo:** Lograr estacionariedad

**Primera diferencia:**
∇Y(t) = Y(t) - Y(t-1)

**Diferencia estacional:**
∇sY(t) = Y(t) - Y(t-s)

donde s es el período estacional

**Diferencia combinada:**
∇∇sY(t) = ∇[Y(t) - Y(t-s)]

**Regla práctica:**
- Si hay tendencia → primera diferencia
- Si hay estacionalidad → diferencia estacional
- Si hay ambas → diferencia combinada

### 7. Modelo ARIMA

**ARIMA(p,d,q):**
- p: orden autoregresivo (AR)
- d: orden de diferenciación (I)
- q: orden de media móvil (MA)

**Componente AR(p):**
Y(t) = φ₁Y(t-1) + φ₂Y(t-2) + ... + φₚY(t-p) + ε(t)

**Componente MA(q):**
Y(t) = ε(t) + θ₁ε(t-1) + θ₂ε(t-2) + ... + θₑε(t-q)

**SARIMA(p,d,q)(P,D,Q)s:**
Incluye componentes estacionales con período s

**Criterios de selección:**
- AIC (Akaike Information Criterion): penaliza complejidad
- BIC (Bayesian Information Criterion): penaliza más que AIC
- AICc (AIC corregido): para muestras pequeñas

Menor valor = mejor modelo

### 8. Diagnóstico de Residuos

**Los residuos deben ser ruido blanco:**

1. Media cercana a cero
2. Varianza constante (homocedasticidad)
3. Sin autocorrelación
4. Distribución normal (opcional)

**Prueba de Ljung-Box:**
- H0: No hay autocorrelación en residuos
- Calcular para varios lags (típicamente 20)
- No rechazar H0 indica buen ajuste

**Prueba de normalidad:**
- Jarque-Bera
- Shapiro-Wilk
- Kolmogorov-Smirnov

**Gráficos de diagnóstico:**
- Residuos vs tiempo
- ACF/PACF de residuos
- Q-Q plot
- Histograma

### 9. Pronóstico

**Generación de pronósticos:**

Ŷ(t+h|t) = E[Y(t+h) | Y(1), ..., Y(t)]

donde h es el horizonte de pronóstico

**Intervalos de confianza:**

IC(α) = Ŷ(t+h) ± z(α/2) × σ̂(h)

donde σ̂(h) es el error estándar del pronóstico

**Consideraciones:**
- Incertidumbre aumenta con h
- IC se amplían para horizontes largos
- Validar contra datos reales cuando sea posible

### 10. Evaluación

**Métricas de error:**

**MAE (Mean Absolute Error):**
MAE = (1/n) Σ|Y(t) - Ŷ(t)|

**RMSE (Root Mean Squared Error):**
RMSE = √[(1/n) Σ(Y(t) - Ŷ(t))²]

**MAPE (Mean Absolute Percentage Error):**
MAPE = (100/n) Σ|[Y(t) - Ŷ(t)]/Y(t)|

**MASE (Mean Absolute Scaled Error):**
Compara con pronóstico naive

**Validación cruzada temporal:**
1. Dividir datos en train/test (típicamente 80/20)
2. Ajustar modelo con train
3. Evaluar en test
4. NO usar validación cruzada k-fold (viola dependencia temporal)

## Supuestos y Limitaciones

### Supuestos de Modelos ARIMA

1. Estacionariedad (después de diferenciación)
2. Linealidad en los parámetros
3. Residuos son ruido blanco
4. No hay cambios estructurales

### Limitaciones

1. **Horizontes largos:** Precisión disminuye
2. **Cambios estructurales:** Modelos pueden fallar
3. **Variables exógenas:** ARIMA no las considera
4. **Volatilidad:** Modelos GARCH para heterocedasticidad
5. **No linealidad:** Considerar modelos no lineales

## Software y Herramientas

### Paquetes de R

- `forecast`: Modelos ARIMA y pronósticos
- `tseries`: Pruebas estadísticas
- `ggplot2`: Visualizaciones
- `zoo`: Manipulación de series

### Funciones Clave

- `auto.arima()`: Selección automática de modelo
- `Arima()`: Ajuste manual de modelo
- `forecast()`: Generación de pronósticos
- `accuracy()`: Cálculo de métricas
- `checkresiduals()`: Diagnóstico automático

## Referencias

1. Box, G. E. P., Jenkins, G. M., Reinsel, G. C., & Ljung, G. M. (2015). Time Series Analysis: Forecasting and Control.
2. Hyndman, R. J., & Athanasopoulos, G. (2021). Forecasting: Principles and Practice.
3. Shumway, R. H., & Stoffer, D. S. (2017). Time Series Analysis and Its Applications.

## Buenas Prácticas

1. **Siempre visualizar primero** antes de modelar
2. **Verificar supuestos** en cada paso
3. **Validar con datos independientes** (conjunto de prueba)
4. **Documentar decisiones** sobre transformaciones y parámetros
5. **Reportar incertidumbre** (intervalos de confianza)
6. **Mantener simplicidad** (parsimonia en modelos)
7. **Actualizar modelos** periódicamente con nuevos datos
8. **Considerar contexto** (conocimiento del dominio)

---

*Este documento es una guía de referencia para el análisis de series temporales en este proyecto.*
