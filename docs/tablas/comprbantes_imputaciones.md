# Tabla: comprobantes_imputaciones

## Descripción

Tabla que almacena imputaciones entre comprobantes.

Permite analizar cómo un comprobante se imputa contra otro, identificando el comprobante principal, el comprobante imputado, importes, fechas, entidad asociada, sucursal y razón social.

---

## Tipo

Hecho transaccional / relación de imputación entre comprobantes

---

## Frecuencia

Diaria

---

## Primary Key sugerida

- empcod
- sucursal_codigo
- id_entidad
- comprobante
- comprobante_imputacion

---

## Fuente origen

### Tablas transaccionales

- `comprobantesimputaciones`
- `comprobantes`
- `sucursal`
- `clientes`
- `proveedorprestador`

---

## Proceso que la genera

### Script principal

- `E:/DataWarehouse/comprobantes_imputaciones/Main.R`

### Helper

- `E:/DataWarehouse/comprobantes_imputaciones/Funciones_Helper.R`

### Tabla destino

- `public.comprobantes_imputaciones`

### Tabla histórica

- `SIF_HISTORICAL.public.comprobantes_imputaciones_historical`

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | empcod | text | Sí | Código de empresa |
| 2 | sucursal_codigo | integer | Sí | Código de sucursal |
| 3 | sucursal_nombre | text | Sí | Nombre de la sucursal |
| 4 | id_entidad | integer | Sí | Identificador de la entidad asociada al comprobante |
| 5 | emision_comprobante | date | Sí | Fecha de emisión del comprobante principal |
| 6 | tipo_comprobante | text | Sí | Tipo del comprobante principal |
| 7 | importe_comprobante | double precision | Sí | Importe total del comprobante principal |
| 8 | entidad | text | Sí | Tipo de entidad: Cliente, Proveedor o Ninguno |
| 9 | tipo_imputacion | text | Sí | Tipo del comprobante imputado |
| 10 | importe_imputacion | double precision | Sí | Importe imputado |
| 11 | fecha_imputacion | date | Sí | Fecha de imputación |
| 12 | fecha_emision_imputacion | date | Sí | Fecha de emisión del comprobante imputado |
| 13 | comprobante | text | Sí | Comprobante principal construido como tipo-prefijo-código |
| 14 | comprobante_imputacion | text | Sí | Comprobante imputado construido como tipo-prefijo-código |
| 15 | razon_social | text | Sí | Entidad concatenada como id_entidad - nombre |

---

## Reglas de negocio

### Extracción principal

Se extraen registros desde `comprobantesimputaciones`.

El proceso no aplica filtro incremental por fecha en la query origen.

---

### Enriquecimiento de sucursal

Se cruza:

- `comprobantesimputaciones.sucursalcodigo`

con:

- `sucursal.sucursalcodigo`

Para obtener:

- `sucursal_nombre`

---

### Enriquecimiento de comprobante principal

Se cruza `comprobantesimputaciones` contra `comprobantes` usando los campos del comprobante principal.

Permite obtener:

- `emision_comprobante`
- `importe_comprobante`

---

### Enriquecimiento de comprobante imputado

Se cruza nuevamente contra `comprobantes`, usando los campos del comprobante imputado.

Permite obtener:

- `fecha_emision_imputacion`

---

### Tipo de entidad

La entidad se determina desde `comprobantetipoentidad`.

| Valor origen | Resultado |
|---|---|
| 2 | Cliente |
| 1 | Proveedor |
| 0 | Ninguno |

---

### Construcción comprobante principal

Formato:

`tipo_comprobante-prefijo_comprobante-codigo_comprobante`

---

### Construcción comprobante imputado

Formato:

`tipo_imputacion-prefijo_imputacion-codigo_imputacion`

---

### Enriquecimiento razón social

Se arma una tabla unificada desde:

#### Clientes

- `clienteid`
- `clientenombre`

#### Proveedores

- `pprid`
- `pprnombre`

Luego se matchea por:

- `id_entidad`
- `entidad`

Y se genera:

`razon_social = id_entidad - nombre`

---

### Limpieza previa a insertar

Se eliminan columnas técnicas utilizadas para construir los comprobantes:

- prefijo_comprobante
- codigo_comprobante
- prefijo_imputacion
- codigo_imputacion
- nombre

---

## Estrategia de carga

La tabla `comprobantes_imputaciones` se sobrescribe completa en cada ejecución.

No se realiza delete por rango ni append incremental sobre la tabla principal.

---

## Estrategia histórica

Además de la tabla principal, el proceso genera una foto diaria en:

`comprobantes_imputaciones_historical`

La fecha de imagen se calcula como el día anterior a la ejecución.

Antes de insertar la foto diaria, se elimina si ya existía una imagen para esa fecha.

Luego se inserta la nueva foto.

También se purgan imágenes históricas con más de 360 días.

La tabla historica se usa cuando se necesita consultar el estado de las imputaciones a una fecha especifica. Se encuentran en SIF_HISTORICAL

---

## Relaciones principales

| Campo destino | Tabla relacionada |
|---|---|
| sucursal_codigo | sucursal |
| id_entidad | clientes |
| id_entidad | proveedorprestador |
| comprobante | comprobantes |
| comprobante_imputacion | comprobantes |

---

## Uso funcional

Permite:

- Analizar imputaciones entre comprobantes
- Ver qué comprobantes fueron aplicados contra otros
- Controlar importes imputados
- Analizar saldos aplicados por cliente o proveedor
- Revisar imputaciones por sucursal
- Auditar imputaciones históricas mediante la tabla historical
- Construir snapshots diarios de imputaciones

---