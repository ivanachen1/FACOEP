# Tabla: comprobantes_asociados

## Descripción

Tabla que vincula comprobantes principales con comprobantes asociados.

Permite analizar relaciones entre documentos contables, aplicaciones entre comprobantes, vínculos administrativos y trazabilidad documental entre comprobantes emitidos dentro del sistema.

Incluye información del comprobante principal, comprobante asociado, entidad, sucursal, importes y apertura contable. Entrega la relacion entre comprobantes, no se hubo imputacion o no

---

## Tipo

Hecho transaccional / relación documental entre comprobantes

---

## Frecuencia

Diaria

---

## Primary Key sugerida

- empcod  
- sucursal_codigo  
- id_entidad  
- comprobante  
- comprobante_asociado  

---

## Fuente origen

### Tablas transaccionales

- `comprobantesasociados`
- `comprobantes`
- `sucursal`
- `clientes`
- `proveedorprestador`

### Lookup externo

- `tabla_apertura.xlsx`

---

## Proceso que la genera

### Script principal

- `E:/DataWarehouse/comprobantes_asociados/Main.R`

### Helper

- `E:/DataWarehouse/comprobantes_asociados/Funciones_Helper.R`

### Tabla destino

- `public.comprobantes_asociados`

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | empcod | text | Sí | Código de empresa |
| 2 | sucursal_codigo | integer | Sí | Código de sucursal |
| 3 | sucursal_nombre | text | Sí | Nombre de la sucursal |
| 4 | id_entidad | integer | Sí | ID cliente / proveedor |
| 5 | emision_comprobante | date | Sí | Fecha emisión comprobante principal |
| 6 | tipo_comprobante | text | Sí | Tipo comprobante principal |
| 7 | importe_comprobante | numeric | Sí | Importe total comprobante principal |
| 8 | entidad | text | Sí | Cliente / Proveedor / Ninguno |
| 9 | tipo_asociado | text | Sí | Tipo comprobante asociado |
| 10 | importe_asociado | numeric | Sí | Importe comprobante asociado |
| 11 | fecha_emision_asociado | date | Sí | Fecha emisión comprobante asociado |
| 12 | id_apertura | integer | Sí | ID apertura contable |
| 13 | comprobante | text | Sí | Tipo-prefijo-código principal |
| 14 | comprobante_asociado | text | Sí | Tipo-prefijo-código asociado |
| 15 | razon_social | text | Sí | ID entidad + nombre |
| 16 | apertura | text | Sí | Descripción apertura |

---

## Reglas de negocio

### Rango de extracción

Se procesan los últimos **360 días**.

---

### Filtro principal

Solo se consideran comprobantes cuya fecha de emisión esté dentro del rango procesado.

---

### Construcción comprobante principal

Formato:

`tipo_comprobante-prefijo_comprobante-codigo_comprobante`

Ejemplo:

`FAC-A-00012345`

---

### Construcción comprobante asociado

Formato:

`tipo_asociado-prefijo_asociado-codigo_asociado`

---

### Tipo de entidad

| Valor origen | Resultado |
|---|---|
| 2 | Cliente |
| 1 | Proveedor |
| 0 | Ninguno |

---

### Enriquecimiento razón social

Se arma tabla unificada desde:

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

Ejemplo:

`10452 - Hospital Italiano`

---

### Enriquecimiento apertura

El campo `id_apertura` proviene de la tabla de comprobantes asociados.

Si viene nulo:

`id_apertura = 4`

Luego se cruza con:

`tabla_apertura.xlsx`

Para obtener:

- `apertura`

---

### Limpieza previa a insertar

Se eliminan columnas técnicas:

- prefijo_comprobante
- codigo_comprobante
- prefijo_asociado
- codigo_asociado
- nombre

---

## Estrategia de carga

Antes de insertar se elimina el rango reprocesado utilizando `emision_comprobante`.

Luego se inserta nuevamente toda la información.

---

## Relaciones principales

| Campo destino | Tabla relacionada |
|---|---|
| id_entidad | clientes |
| id_entidad | proveedorprestador |
| sucursal_codigo | sucursal |
| id_apertura | tabla_apertura |
| comprobante | comprobantes |
| comprobante_asociado | comprobantes |

---

## Uso funcional

Permite:

- Ver comprobantes relacionados entre sí
- Analizar notas de crédito / débito vinculadas
- Conciliaciones administrativas
- Auditoría documental
- Seguimiento por cliente o proveedor
- Control por sucursal
- Trazabilidad entre comprobantes emitidos

---