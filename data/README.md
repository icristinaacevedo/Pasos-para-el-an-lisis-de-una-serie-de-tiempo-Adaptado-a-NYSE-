# Carpeta de Datos

Esta carpeta contiene los datos utilizados en el análisis.

## Serie NYSE

La serie NYSE se carga directamente desde R usando:

```r
data(nyse)
```

**Descripción:**
- **Variable:** Contribuciones del New York Stock Exchange
- **Frecuencia:** Mensual
- **Período:** Enero 1962 - Diciembre 1975
- **Observaciones:** 168 (14 años × 12 meses)

## Archivos Generados

Durante la ejecución del análisis, se guardan copias de las series procesadas:
- `nyse_original.rds` - Serie original
- `nyse_diff1.rds` - Serie con primera diferencia
- `nyse_diff_seasonal.rds` - Serie con diferencia estacional
- `nyse_diff_completa.rds` - Serie con diferenciación combinada

Estos archivos se guardan en la carpeta `outputs/modelos/`.
