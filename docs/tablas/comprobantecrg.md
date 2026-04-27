# Tabla: comprobantecrg

## Descripción

Cabecera de comprobantes asociados a CRGs. Contiene la información agregada del CRG facturado: sucursal, entidad (cliente / proveedor), proveedor efector, obra social, periodo, importe neto, total, total de débitos y créditos.

Es la cabecera de la cual `comprobantecrgdet` es el detalle. Permite ver el total facturado por CRG sin desglose de prestaciones.

---

## Tipo

Hecho transaccional / cabecera de CRG facturado.

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

- id_entidad
- comprobante
- nro_crg

---

## Fuente origen

### Tablas transaccionales

- `comprobantecrg` (cabecera)
- `sucursal`
- `proveedorprestador`
- `obrassociales`

### Lookup externo

- `crgs_corregidos.xlsx` (correcciones manuales que se agregan al final del proceso)
- `tipo_entidad.xlsx`

---

## Proceso que la genera

### Script principal

- `E:/DataWarehouse/comprobantecrg/main.R`

### Helper

- `E:/DataWarehouse/comprobantecrg/Funciones_Helper.R`
- `E:/DataWarehouse/comprobantecrg/Funciones_Helper_comprobantecrg.R`

### Tabla destino

- `public.comprobantecrg` (base SIF)

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | sucursal_nombre | varchar | Sí | Descripción de la sucursal |
| 2 | tipo_entidad | varchar | Sí | Cliente / Proveedor / Ninguno |
| 3 | id_entidad | int | Sí | Identificador de la entidad asociada |
| 4 | id_proveedor | int | Sí | Identificador del proveedor efector |
| 5 | nombre_proveedor | varchar | Sí | Nombre del proveedor efector (con TRIM) |
| 6 | nro_crg | int | Sí | Número de CRG |
| 7 | id_obra_social | varchar | Sí | Código de obra social |
| 8 | obra_social_nombre | varchar | Sí | Descripción de la obra social |
| 9 | periodo | varchar | Sí | Periodo del CRG |
| 10 | hosp_gob | int | Sí | Indicador hospital de gobierno (campo `comprobantecrghospgob`) |
| 11 | fecha_emision | date | Sí | Fecha de emisión del CRG |
| 12 | importe_neto | decimal | Sí | Importe neto del CRG |
| 13 | total | decimal | Sí | Importe total del detalle (`comprobantecrgimportetotaldeta`) |
| 14 | total_debitos | decimal | Sí | Total de débitos del CRG |
| 15 | total_creditos | decimal | Sí | Total de créditos del CRG |
| 16 | comprobante | varchar | Sí | Comprobante construido como `tipo-prefijo-numero` |
| 17 | efector | varchar | Sí | Concatenación `id_proveedor - nombre_proveedor` |
| 18 | obra_social | varchar | Sí | Concatenación `id_obra_social - obra_social_nombre` |

---

## Reglas de negocio

### Tipo de entidad

| Valor origen | Resultado |
|---|---|
| 2 | Cliente |
| 1 | Proveedor |
| 0 | Ninguno |

### Construcción de comprobante

`comprobante = tipo + "-" + prefijo + "-" + numero` (función `CreateComprobante`).

### Construcción de efector

`efector = id_proveedor + " - " + nombre_proveedor`.

### Construcción de obra social

`obra_social = id_obra_social + " - " + obra_social_nombre`.

### Limpieza

- `nombre_proveedor` y `tipo` se aplican `str_trim`.
- Se eliminan los campos técnicos `id_sucursal` e `id_tipo_entidad` antes de insertar.

### Exclusión manual

Se excluyen los siguientes comprobantes que se reemplazan por la versión corregida del Excel:

- `FACB2-1-16901`
- `FACA2-1-7581`
- `FACB2-1-27492`

Estos comprobantes tuvieron duplicacion de monto facturado.

### Correcciones desde Excel

Se hace `rbind` con el contenido de `crgs_corregidos.xlsx`, casteando:

- `fecha_emision` → date
- `importe_neto` → numeric
- `importe_facturado` → numeric

---

## Estrategia de carga

`overwrite = TRUE`, `append = FALSE`. La tabla se reemplaza completa en cada corrida.

Se escribe un archivo de control `control.csv` con la cantidad de registros insertados.

---

## Relaciones principales

| Campo destino | Tabla relacionada |
|---|---|
| comprobante | comprobantecrgdet |
| comprobante | wwcomprobantes |
| nro_crg | crg |
| id_obra_social | obrassociales |
| id_proveedor | proveedorprestador |

---

## Uso funcional

Permite:

- Análisis facturación por CRG sin abrir prestaciones.
- Conciliación de totales / débitos / créditos.
- Cruce con `comprobantecrgdet` para abrir el detalle.
- Filtrado por obra social, sucursal o efector.

---

## Owner

DBA

---

## Script generador

`E:/DataWarehouse/comprobantecrg/main.R`
