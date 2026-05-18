# Reporte: Monitoreo CRGs

## Descripción

Reporte PowerBI orientado al **monitoreo del ciclo de vida de los CRGs**: universo total, distribución por estado, detalle de CRGs y seguimiento puntual de la facturación de prestaciones específicas (set "Nancy" — IAC.01, IAC.02, IAC.03, COV.16, COV.17). Cubre múltiples solapas con scripts independientes, pensado para auditoría operativa diaria.

Existen **dos generaciones del proceso** que alimentan este reporte:

- **Legacy:** scripts R que consultan directamente Producción (`facoep` en `10.22.0.142` / `10.22.1.61`). Cada solapa hace su query en vivo.
- **Migrado (vigente):** script R que consume las tablas del **DataWarehouse SIF** y materializa el output en `DBA.monitoreocrg_facturacion`. Es la versión actual; el `.pbix` apunta a esa tabla.

---

## Tipo

Reporte / dashboard de monitoreo operativo (multi-solapa) + materialización de tabla destino para la solapa de Facturación.

---

## Frecuencia

Diaria. La versión migrada procesa un rango móvil de **180 días** sobre `fecha_emision` del comprobante.

---

## Primary Key sugerida

### `DBA.monitoreocrg_facturacion`

- factura
- id_crgdet
- nro_crg
- id_efector

---

## Fuente origen

### Versión migrada (vigente) — tablas DataWarehouse (base SIF)

| Tabla | Rol |
|---|---|
| `detallecrg` | Detalle de prestaciones del CRG (reemplaza `crgdet` de Producción) |
| `crg` | Cabecera del CRG (con `estado_actual` ya decodificado) |
| `comprobantecrgdet` | Detalle del CRG con comprobante / factura asociada |
| `wwcomprobantes` | Cabecera del comprobante (para obtener fecha de emisión) |

### Lookup externo

- `Prestaciones Nancy.xlsx` — set de prácticas a monitorear (hoy hardcodeado en el script vigente).
- `Estados Crgs.xlsx` — referencia del catálogo de estados (también se puede consultar en `tablas_lookup.estados_crg`).
- `PrestacionesNoSumar.xlsx`
- `tabla_parametros_comprobantes.xlsx`
- `parametros_servidor.xlsx`

### Versión legacy

- Producción `facoep`: `crg`, `crgdet`, `comprobantecrgdet`, `comprobantes`, `obrassociales`, `proveedorprestador`.

---

## Proceso que la genera

### Archivo PowerBI

- `E:/.../reportes/Monitoreo CRGs/Monitoreo CRGs.pbix`

### Scripts R (versión migrada — vigente)

Script principal de la solapa de Facturación (refactorizado al DW):

```r
library(data.table)
library(tidyverse)
library(RPostgreSQL)
library(glue)

# Ventana temporal: últimos 180 días sobre fecha_emision del comprobante
fecha_desde <- format(Sys.Date() - 180, "%Y-%m-%d")
fecha_hasta <- format(Sys.Date(),       "%Y-%m-%d")

# Set de prácticas Nancy y tipos de factura FACOEP
practicas_nancy <- c("IAC.01", "IAC.02", "IAC.03", "COV.16", "COV.17")
tipos_comp      <- c("FACA2", "FACB2", "FAECA", "FAECB")

nancy_sql <- paste0("'", practicas_nancy, "'", collapse = ", ")
tipos_sql <- paste0("'", tipos_comp,      "'", collapse = ", ")

# Conexión a SIF (DW) — credenciales gestionadas externamente
drv     <- dbDriver("PostgreSQL")
con_sif <- dbConnect(drv, dbname = "SIF", host = "<HOST_SIF>", port = 5432,
                     user = "<USER>", password = "<PASS>")

QueryDW <- glue("
  SELECT
      det.id_proveedor                          AS id_efector,
      crg.id_obra_social                        AS id_obra_social,
      comp.comprobante                          AS factura,
      ww.fecha_emision                          AS emision_factura,
      det.nro_crg                               AS nro_crg,
      crg.fecha_emision                         AS emision_crg,
      TRIM(CAST(det.dph AS VARCHAR))            AS numero_dph,
      det.practica                              AS prestacion,
      det.id                                    AS id_crgdet,
      det.importe_crg                           AS importe_crg,
      det.fecha_prestacion                      AS fecha_prestacion,
      CONCAT(det.id_proveedor, '-', det.nro_crg, '-', det.dph) AS id_test,
      CONCAT(det.id_proveedor, '-', det.nro_crg)               AS id_detalle
  FROM detallecrg det
  INNER JOIN crg
      ON  det.nro_crg      = crg.nro_crg
      AND det.id_proveedor = crg.id_proveedor
      AND crg.estado_actual = 'Facturado'
  INNER JOIN comprobantecrgdet comp
      ON  det.id_proveedor = comp.id_proveedor
      AND det.nro_crg      = comp.nro_crg
      AND det.id           = comp.id
      AND LEFT(comp.comprobante, POSITION('-' IN comp.comprobante) - 1)
              IN ({tipos_sql})
  INNER JOIN wwcomprobantes ww
      ON  comp.comprobante = ww.comprobante
      AND ww.fecha_emision >= DATE '{fecha_desde}'
      AND ww.fecha_emision <  DATE '{fecha_hasta}'::date + INTERVAL '1 day'
  WHERE TRIM(det.practica) IN ({nancy_sql})
")

CRGsFacturados <- dbGetQuery(con_sif, QueryDW)

# Carga incremental en DBA (DELETE + INSERT por rango)
con_dba <- dbConnect(drv, dbname = "DBA", host = "<HOST_DBA>", port = 5432,
                     user = "<USER>", password = "<PASS>")

dbExecute(con_dba, glue("
  DELETE FROM monitoreocrg_facturacion
  WHERE emision_factura >= DATE '{fecha_desde}'
  AND   emision_factura <  DATE '{fecha_hasta}'::date + INTERVAL '1 day'
"))

dbWriteTable(con_dba, "monitoreocrg_facturacion",
             CRGsFacturados, append = TRUE, row.names = FALSE)
```

### Scripts R legacy (solapas restantes que aún consultan Producción)

- `Monitoreo CRGs_Universo.R` → universo total de CRGs.
- `Monitoreo CRGs_CRGPorEstadosSuma.R` → distribución por estado.
- `Monitoreo CRGs_CRGDetalle.R` → detalle CRG.
- `Monitoreo CRGs_FacturacionCRGs.R` → versión legacy de la solapa de Facturación (Nancy).
- `Monitoreo CRGs_TablasAuxiliares.R` → tablas auxiliares.
- `Script Limpieza Tablas.R` → limpieza.
- `Script Nancy Logica.R` → helpers de prestaciones Nancy.

### Tabla destino (versión migrada)

- `DBA.monitoreocrg_facturacion`

### Documentación interna

- `Logica Monitoreo Facturacion CRGs.txt`
- `Requerimiento.txt`
- `README.md`

---

## Campos de `DBA.monitoreocrg_facturacion`

| # | Campo | Tipo | Origen | Descripción |
|---|---|---|---|---|
| 1 | id_efector | int | detallecrg | ID del efector / proveedor |
| 2 | factura | varchar | comprobantecrgdet | Comprobante (`tipo-prefijo-numero`) |
| 3 | emision_factura | timestamp | wwcomprobantes | Fecha de emisión del comprobante |
| 4 | prestacion | varchar | detallecrg | Práctica del set Nancy (IAC / COV) |
| 5 | nro_crg | int | detallecrg | Número de CRG |
| 6 | id_obra_social | int | crg | Código de obra social |
| 7 | id_crgdet | int | detallecrg | ID del detalle de CRG |
| 8 | fecha_prestacion | date | detallecrg | Fecha de la prestación |
| 9 | numero_dph | varchar | detallecrg | Número de DPH (con TRIM y cast a varchar) |
| 10 | emision_crg | date | crg | Fecha de emisión del CRG |
| 11 | importe_crg | decimal | detallecrg | Importe del detalle dentro del CRG |
| 12 | id_test | varchar | derivado | `id_proveedor-nro_crg-dph` |
| 13 | id_detalle | varchar | derivado | `id_proveedor-nro_crg` |

---

## Reglas de negocio

### Set de prácticas "Nancy"

Prácticas hardcodeadas a monitorear:

`IAC.01, IAC.02, IAC.03, COV.16, COV.17`

Se compara con `TRIM(det.practica) IN (...)` para evitar problemas de espacios.

### Tipos de factura considerados

`FACA2, FACB2, FAECA, FAECB` (familia "Facturas FACOEP" del catálogo de `wwcomprobantes`, ver `docs/tablas/wwcomprobantes.md`). Se extrae el tipo del campo `comprobante` con:

```sql
LEFT(comp.comprobante, POSITION('-' IN comp.comprobante) - 1)
```

### Filtro por estado del CRG

```sql
crg.estado_actual = 'Facturado'
```

Equivale a `crgestado = 4` en Producción. Ver catálogo completo en `docs/tablas/crg.md` → "Catálogo de estados del CRG".

### Ventana temporal

Últimos **180 días** sobre `ww.fecha_emision`:

```sql
ww.fecha_emision >= DATE '{fecha_desde}'
AND ww.fecha_emision <  DATE '{fecha_hasta}'::date + INTERVAL '1 day'
```

El `+ INTERVAL '1 day'` garantiza que el día actual entre completo.

### Identificadores derivados

- `id_detalle = id_proveedor + '-' + nro_crg` → identifica unívocamente al CRG.
- `id_test = id_proveedor + '-' + nro_crg + '-' + dph` → identifica unívocamente la prestación dentro del CRG.

### Joins

- `detallecrg ↔ crg` por `(nro_crg, id_proveedor)` — para filtrar por estado.
- `detallecrg ↔ comprobantecrgdet` por `(id_proveedor, nro_crg, id)` — para vincular cada prestación con su factura.
- `comprobantecrgdet ↔ wwcomprobantes` por `comprobante` — para obtener `fecha_emision`.

---

## Estrategia de carga

Antes de insertar, se ejecuta:

```sql
DELETE FROM monitoreocrg_facturacion
WHERE emision_factura >= DATE '{fecha_desde}'
AND   emision_factura <  DATE '{fecha_hasta}'::date + INTERVAL '1 day'
```

Luego se inserta con `append = TRUE`. La carga es incremental por rango móvil de 180 días.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| nro_crg + id_efector | crg / crg_historial / detallecrg |
| factura | wwcomprobantes / comprobantecrgdet |
| id_obra_social | obrassociales |

---

## Uso funcional

Permite:

- Universo total de CRGs y distribución por estado (solapas legacy).
- Detalle CRG por CRG con estado y fechas.
- Seguimiento puntual de prestaciones críticas (set Nancy: IAC, COV) que **ya fueron facturadas**.
- Auditoría operativa diaria.
- Cruce con `comprobantecrgdet` para validar consistencia entre el universo CRG y lo facturado.

---

## Owner

DBA

---

## Archivo PBIX

`E:/.../reportes/Monitoreo CRGs/Monitoreo CRGs.pbix`

---

## Documentación relacionada

- [docs/tablas/detallecrg.md](../tablas/detallecrg.md)
- [docs/tablas/crg.md](../tablas/crg.md) — incluye catálogo de estados
- [docs/tablas/comprobantecrgdet.md](../tablas/comprobantecrgdet.md)
- [docs/tablas/wwcomprobantes.md](../tablas/wwcomprobantes.md)
