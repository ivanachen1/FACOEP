# Tabla: detallecrg

## Descripción

Detalle de prestaciones del CRG. Contiene cada práctica que conforma un CRG, con datos del afiliado, fechas (ingreso, egreso, prestación), precio unitario, importes (CRG, a facturar, a acreditar, a debitar), nomenclador, tipo de práctica y tipo de prestación.

Es el detalle operativo del CRG visto desde el origen (`crgdet`), antes de cualquier conversión a comprobante. Se complementa con `crg` (cabecera) y se enriquece con `comprobantecrgdet` (cuando ya hay comprobante asociado). La tabla comprobantecrgdet asocia el crg con una factura y prestaciones dadas

---

## Tipo

Hecho transaccional / detalle de prestaciones por CRG.

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

- id
- id_proveedor
- nro_crg

---

## Fuente origen

### Tablas transaccionales

- `crgdet`
- `proveedorprestador`

### Lookup externo

- `tipo_practica.xlsx`
- `tipo_prestacion.xlsx`

---

## Proceso que la genera

### Script principal

- `E:/DataWarehouse/detallecrg/main.R`

### Helper

- `E:/DataWarehouse/detallecrg/Funciones_Helper.R`
- `E:/DataWarehouse/detallecrg/Funciones_Helper_detalle_crg.R`

### Tabla destino

- `public.detallecrg` (base SIF)

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | id | int | Sí | Identificador del detalle (`crgdetid`) |
| 2 | id_proveedor | int | Sí | Identificador del proveedor / efector |
| 3 | nombre_proveedor | varchar | Sí | Nombre del proveedor (con TRIM) |
| 4 | nro_crg | int | Sí | Número de CRG |
| 5 | tipo_documento | varchar | Sí | Tipo de documento del afiliado |
| 6 | numero_documento | varchar | Sí | Número de documento del afiliado |
| 7 | numero_afiliado | varchar | Sí | Número de afiliado |
| 8 | nombre | varchar | Sí | Apellido y nombre del afiliado |
| 9 | fecha_ingreso | date | Sí | Fecha de ingreso del paciente |
| 10 | fecha_egreso | date | Sí | Fecha de egreso |
| 11 | fecha_prestacion | date | Sí | Fecha de la prestación |
| 12 | precio_unitario | decimal | Sí | Precio unitario de la práctica |
| 13 | importe_crg | decimal | Sí | Importe del detalle dentro del CRG (`crgdetimportecrg`) |
| 14 | practica | varchar | Sí | Código o descripción de la práctica |
| 15 | dph | int | Sí | Número de DPH (`crgdetnumerocph`) |
| 16 | id_tipo_nomenclador | int | Sí | Tipo de nomenclador |
| 17 | codigo_nomenclador | varchar | Sí | Código del nomenclador |
| 18 | cantidad_practica | numeric | Sí | Cantidad de prácticas del detalle |
| 19 | motivo_credito_debito | varchar | Sí | Observación de débito / crédito |
| 20 | motivo_descripcion | varchar | Sí | Descripción del motivo |
| 21 | a_facturar | decimal | Sí | Importe a facturar |
| 22 | a_acreditar | decimal | Sí | Importe a acreditar |
| 23 | a_debitar | decimal | Sí | Importe a debitar |
| 24 | tipo_practica | varchar | Sí | Tipo de práctica (enriquecido desde `tipo_practica.xlsx`) |
| 25 | tipo_prestacion | varchar | Sí | Tipo de prestación (enriquecido desde `tipo_prestacion.xlsx`) |
| 26 | hospital | varchar | Sí | Concatenación `id_proveedor - nombre_proveedor` |
| 27 | fecha_ejecucion | date | Sí | Fecha en que el script ejecutó la carga |

---

## Reglas de negocio

### Rango de extracción

Se procesan los últimos **180 días** filtrando por `crgdetfechaingreso BETWEEN fechaInicio AND fechaFin`.

### Construcción del campo hospital

`hospital = id_proveedor + " - " + nombre_proveedor`.

### Enriquecimiento por catálogos Excel

| Campo origen | Lookup | Resultado |
|---|---|---|
| id_tipo_practica | tipo_practica.xlsx | tipo_practica |
| id_tipo_prestacion | tipo_prestacion.xlsx | tipo_prestacion |

Los identificadores técnicos se eliminan del DataFrame final.

### Limpieza

`nombre_proveedor` se aplica `str_trim`.

### Marca de ejecución

Se agrega `fecha_ejecucion = Sys.Date()` para identificar cuándo se cargó cada lote.

---

## Estrategia de carga

Antes de insertar, se ejecuta:

```sql
DELETE FROM detallecrg
WHERE fecha_ingreso BETWEEN fechaInicio AND fechaFin
```

Luego se inserta con `append = TRUE`. La carga es incremental por rango móvil de 180 días.

Se escribe un archivo de control `control.csv` con la cantidad de registros insertados.

---

## Relaciones principales

| Campo destino | Tabla relacionada |
|---|---|
| nro_crg + id_proveedor | crg |
| nro_crg + id_proveedor | crg_historial |
| nro_crg + id | comprobantecrgdet |
| codigo_nomenclador | nomenclador |

---

## Uso funcional

Permite:

- Análisis de prestaciones por afiliado, fecha o efector.
- Cálculo de importes a facturar / acreditar / debitar antes del comprobante.
- Cruce con `comprobantecrgdet` para ver qué se llevó a comprobante y qué no.
- Auditoría temprana sobre el contenido del CRG.

---

## Owner

DBA

---

## Script generador

`E:/DataWarehouse/detallecrg/main.R`
