# 🚀 Guía de Inicio Rápido

Esta guía te ayudará a poner en marcha el proyecto en pocos minutos.

## ⚡ Instalación Rápida

### 1. Clonar o Descargar el Repositorio

```bash
# Si usas Git
git clone <url-del-repositorio>
cd time_series_nyse

# O descarga el ZIP y descomprímelo
```

### 2. Abrir en Visual Studio Code

```bash
code .
```

### 3. Instalar Extensión de R

En VS Code, instala:
- **R Extension for Visual Studio Code** (REditorSupport.r)

### 4. Configurar R en VS Code

Presiona `Ctrl+Shift+P` y busca "Preferences: Open Settings (JSON)"

Agrega (ajusta las rutas según tu instalación):

```json
{
    "r.rterm.windows": "C:\\Program Files\\R\\R-4.x.x\\bin\\R.exe",
    "r.rterm.mac": "/usr/local/bin/R",
    "r.rterm.linux": "/usr/bin/R",
    "r.bracketedPaste": true
}
```

## 📦 Instalar Paquetes de R

### Opción 1: Desde VS Code

Abre el terminal integrado (`Ctrl+``) y ejecuta:

```bash
Rscript requirements.txt
```

### Opción 2: Desde R Console

Abre R o RStudio y ejecuta:

```r
source("requirements.txt")
```

## ▶️ Ejecutar el Análisis

### Opción 1: Análisis Completo

Ejecuta todos los pasos automáticamente:

```r
source("main.R")
```

Esto ejecutará los 10 pasos en secuencia y generará todos los gráficos y tablas.

### Opción 2: Pasos Individuales

Para ejecutar un paso específico:

```r
# Cargar configuración primero
source("config.R")

# Ejecutar paso específico (ejemplo: Paso 1)
source("scripts/01_carga_exploracion.R")
```

### Opción 3: Desde Terminal

```bash
# Análisis completo
Rscript main.R

# Paso individual
Rscript scripts/01_carga_exploracion.R
```

## 📂 Dónde Encontrar los Resultados

Después de ejecutar el análisis:

- **Gráficos:** `figures/`
- **Tablas CSV:** `outputs/tablas/`
- **Modelos guardados:** `outputs/modelos/`

## 🎯 Flujo de Trabajo Recomendado

### Para Principiantes

1. Lee el `README.md` principal
2. Revisa `docs/metodologia.md` para entender la teoría
3. Ejecuta `source("main.R")` para ver el análisis completo
4. Explora los gráficos en `figures/`
5. Revisa las tablas en `outputs/tablas/`

### Para Usuarios Avanzados

1. Configura parámetros en `config.R`
2. Ejecuta pasos individuales según necesites
3. Modifica scripts para personalizar análisis
4. Experimenta con diferentes modelos ARIMA

## 🔧 Configuración Avanzada

### Cambiar Parámetros del Análisis

Edita `config.R`:

```r
# Ejemplo: Cambiar horizonte de pronóstico
HORIZONTE_PRONOSTICO <- 36  # 36 meses en lugar de 24

# Cambiar proporción train/test
PROPORCION_TRAIN <- 0.7  # 70% entrenamiento, 30% prueba

# Modificar tamaño de gráficos
GRAPH_WIDTH <- 14
GRAPH_HEIGHT <- 10
```

### Deshabilitar Pasos Específicos

En `main.R`, cambia a `FALSE` los pasos que no quieras ejecutar:

```r
EJECUTAR <- list(
  paso_01 = TRUE,
  paso_02 = TRUE,
  paso_03 = FALSE,  # Omitir descomposición
  paso_04 = TRUE,
  # ... etc
)
```

### Pausar Entre Pasos

Para revisar resultados entre pasos, activa:

```r
PAUSAR_ENTRE_PASOS <- TRUE
```

## 💡 Consejos Útiles

### En Visual Studio Code

- **Ejecutar línea actual:** `Ctrl+Enter`
- **Ejecutar selección:** Selecciona código y presiona `Ctrl+Enter`
- **Ver ayuda de función:** Coloca cursor sobre función y presiona `F1`
- **Terminal R:** `Ctrl+Shift+`` para abrir terminal

### Debugging

Si algo falla:

1. Verifica que R esté instalado: `R --version`
2. Verifica paquetes: `source("requirements.txt")`
3. Lee mensajes de error en la consola
4. Revisa que las rutas en `config.R` sean correctas

### Personalización

Para usar tus propios datos:

1. Modifica `scripts/01_carga_exploracion.R`
2. Carga tu serie temporal en lugar de NYSE
3. Ajusta parámetros según tu frecuencia de datos

## 📚 Próximos Pasos

Una vez que hayas ejecutado el análisis básico:

1. **Experimenta:** Prueba diferentes órdenes ARIMA manualmente
2. **Compara:** Evalúa múltiples modelos con diferentes parámetros
3. **Personaliza:** Modifica gráficos y reportes según tus necesidades
4. **Aprende:** Lee `docs/metodologia.md` para profundizar en la teoría
5. **Contribuye:** Mejora el código y comparte tus mejoras

## ❓ Problemas Comunes

### "Error: paquete 'forecast' no encontrado"

Solución:
```r
install.packages("forecast")
```

### "No se puede abrir el dispositivo gráfico"

Solución: Asegúrate de tener permisos de escritura en la carpeta `figures/`

### "Cannot find NYSE data"

Solución: El dataset NYSE viene con R base. Si no está disponible, asegúrate de tener R actualizado.

## 📞 Ayuda y Soporte

- **Documentación:** Lee los archivos en `docs/`
- **Issues:** Abre un issue en GitHub
- **Recursos:** Revisa las referencias en `README.md`

---

¡Listo! Ahora estás preparado para analizar series temporales como un profesional 🎉
