# Análisis de Series Temporales - NYSE

Repositorio para el análisis de una serie temporal asociada al New York Stock Exchange (NYSE), utilizando R y siguiendo la metodología Box–Jenkins, con extensión a modelos de volatilidad (GARCH).

## Descripción del Proyecto

Este proyecto implementa un análisis completo de series temporales con fines académicos. 
Se analizan datos de retornos diarios del NYSE desde 2 de febreero de 1984 hasta 31 de   diciembre de 1991.

## Estructura del Repositorio

```
time_series_nyse/
├── README.md                    # Este archivo
├── requirements.txt             # Paquetes de R necesarios
├── config.R                     # Configuración global del proyecto
├── main.R                       # Script principal que ejecuta todo el análisis
├── .gitignore                   # Archivos a ignorar en git
│
├── scripts/                     # Scripts de análisis por pasos
│   ├── 01_carga_exploracion.R
│   ├── 02_visualizacion.R
│   ├── 03_descomposicion.R
│   ├── 04_estacionariedad.R
│   ├── 05_autocorrelacion.R
│   ├── 06_diferenciacion.R
│   ├── 06_5_transformacion.R
│   ├── 07_identificacion_modelo.R
│   ├── 08_diagnostico.R
│   ├── 09_pronostico.R
│   ├── 10_evaluacion.R
│   └── 11_modelos_volatillidad.R
│
├── data/                        # Datos (se cargan desde R)
│   └── README.md
│
├── outputs/                     # Resultados del análisis
│   ├── tablas/
│   └── modelos/
│
├── figures/                     # Gráficos generados
│   └── README.md
│
└── docs/                        # Documentación adicional
    └── metodologia.md
```

## Inicio Rápido

### Prerrequisitos

1. **R** (versión 4.0 o superior)
2. **RStudio** o **Visual Studio Code** con extensión de R
3. **Git** (opcional, para control de versiones)

### Instalación

1. Clona este repositorio:
```bash
git clone https://github.com/icristinaacevedo/Pasos-para-el-an-lisis-de-una-serie-de-tiempo-Adaptado-a-NYSE-
cd time_series_nyse
```

2. Abre R o RStudio y ejecuta:
```r
# Instalar paquetes necesarios
source("requirements.txt")
```

3. Ejecuta el análisis completo:
```r
source("main.R")
```

## Pasos del Análisis

### Paso 1: Carga y Exploración Inicial
- Carga de la serie NYSE
- Estadísticas descriptivas
- Exploración preliminar

**Script:** `scripts/01_carga_exploracion.R`

### Paso 2: Visualización de la Serie
- Gráficos temporales
- Histogramas
- Boxplots por período
- Análisis visual de patrones

**Script:** `scripts/02_visualizacion.R`

### Paso 3: Descomposición
- Descomposición aditiva y multiplicativa
- Separación en tendencia, estacionalidad y residuos
- Visualización de componentes

**Script:** `scripts/03_descomposicion.R`

### Paso 4: Análisis de Estacionariedad
- Prueba de Dickey-Fuller Aumentada (ADF)
- Prueba KPSS
- Análisis visual de media y varianza

**Script:** `scripts/04_estacionariedad.R`

### Paso 5: Autocorrelación (ACF/PACF)
- Función de Autocorrelación (ACF)
- Función de Autocorrelación Parcial (PACF)
- Identificación de patrones

**Script:** `scripts/05_autocorrelacion.R`

### Paso 6: Diferenciación
- Primera diferencia
- Diferencia estacional
- Evaluación de transformaciones

**Script:** `scripts/06_diferenciacion.R`

### Paso 7: Identificación del Modelo
- Selección de parámetros ARIMA(p,d,q)
- Modelos SARIMA para estacionalidad
- Comparación de modelos usando AIC/BIC

**Script:** `scripts/07_identificacion_modelo.R`

### Paso 8: Diagnóstico del Modelo
- Análisis de residuos
- Prueba de Ljung-Box
- Pruebas de normalidad
- Validación de supuestos

**Script:** `scripts/08_diagnostico.R`

### Paso 9: Pronóstico
- Generación de predicciones
- Intervalos de confianza
- Visualización de pronósticos

**Script:** `scripts/09_pronostico.R`

### Paso 10: Evaluación
- Métricas de error (RMSE, MAE, MAPE)
- Validación cruzada temporal
- Comparación de desempeño

**Script:** `scripts/10_evaluacion.R`

## Paquetes de R Utilizados

- `forecast`: Modelos de pronóstico automático
- `tseries`: Pruebas de estacionariedad
- `ggplot2`: Visualización avanzada
- `zoo`: Manipulación de series temporales
- `gridExtra`: Composición de gráficos
- `knitr`: Generación de reportes
- `dplyr`: Manipulación de datos

##  Resultados

Los resultados del análisis se guardan en:
- **Gráficos:** `figures/`
- **Tablas:** `outputs/tablas/`
- **Modelos:** `outputs/modelos/`

## 🔧 Configuración en Visual Studio Code

### Extensiones Recomendadas

1. **R Extension for Visual Studio Code** (REditorSupport.r)
2. **R Debugger** (RDebugger.r-debugger)
3. **R LSP Client** (REditorSupport.r-lsp)

### Configuración de settings.json

```json
{
    "r.rterm.windows": "C:\\Program Files\\R\\R-4.x.x\\bin\\R.exe",
    "r.rterm.mac": "/usr/local/bin/R",
    "r.rterm.linux": "/usr/bin/R",
    "r.bracketedPaste": true,
    "r.plot.useHttpgd": true
}
```

### Ejecutar Scripts en VS Code

1. Abre el terminal integrado (Ctrl + `)
2. Ejecuta: `Rscript scripts/01_carga_exploracion.R`
3. O usa Ctrl+Enter para ejecutar línea por línea

## 📚 Recursos Adicionales

### Libros Recomendados
- Box, G. E. P. et al. (2015). *Time Series Analysis: Forecasting and Control*
- Hyndman, R. J., & Athanasopoulos, G. (2021). *Forecasting: Principles and Practice*

### Tutoriales Online
- [CRAN Time Series Task View](https://cran.r-project.org/web/views/TimeSeries.html)
- [Forecasting: Principles and Practice](https://otexts.com/fpp3/)

##  Contribuciones

Las contribuciones son bienvenidas. Por favor:
1. Haz fork del repositorio
2. Crea una rama para tu feature (`git checkout -b feature/NuevaCaracteristica`)
3. Commit tus cambios (`git commit -m 'Añadir nueva característica'`)
4. Push a la rama (`git push origin feature/NuevaCaracteristica`)
5. Abre un Pull Request

##  Licencia

Este proyecto está bajo licencia MIT. Ver archivo `LICENSE` para más detalles.

## ✉️ Contacto

Para preguntas o sugerencias, abre un issue en el repositorio.

---

**Última actualización:** Febrero 2026
