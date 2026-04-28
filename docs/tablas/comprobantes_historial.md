# Tabla: comprobantes_historial

## Descripción

Tabla que almacena el historial de estados y trámites asociados a comprobantes.

Permite analizar la trazabilidad administrativa de cada comprobante, incluyendo fecha y hora del evento, fecha de trámite, estado, usuario, expediente y observaciones registradas.

---

## Tipo

Hecho transaccional / historial de eventos de comprobantes

---

## Frecuencia

Diaria

---

## Primary Key sugerida

- empcod
- sucursal_codigo
- id_entidad
- comprobante
- fecha_hora
- id_estado

---

## Fuente origen

### Tablas transaccionales

- `comprobanteshistorial`
- `sucursal`

### Lookup externo

- `estados.xlsx`

---

## Proceso que la genera

### Script principal

- `E:/DataWarehouse/comprobantes_historial/Main.R`

### Helper

- `E:/DataWarehouse/comprobantes_historial/Funciones_Helper.R`

### Tabla destino

- `public.comprobantes_historial`

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | empcod | text | Sí | Código de empresa |
| 2 | sucursal_codigo | integer | Sí | Código de sucursal |
| 3 | sucursal_nombre | text | Sí | Nombre de la sucursal |
| 4 | entidad | text | Sí | Tipo de entidad: Cliente, Proveedor o Ninguno |
| 5 | id_entidad | integer | Sí | Identificador de la entidad asociada al comprobante |
| 6 | tipo | text | Sí | Tipo de comprobante |
| 7 | fecha_hora | timestamp with time zone | Sí | Fecha y hora del evento de historial |
| 8 | fecha_tramite | date | Sí | Fecha de trámite del comprobante |
| 9 | historial_observacion | text | Sí | Observación registrada en el historial |
| 10 | id_estado | double precision | Sí | Identificador del estado del comprobante |
| 11 | usuario | text | Sí | Usuario que registró o intervino el evento |
| 12 | expediente | text | Sí | Expediente asociado al comprobante |
| 13 | estado | text | Sí | Descripción del estado, obtenida desde lookup |
| 14 | tipo_comprobante | text | Sí | Tipo de comprobante normalizado |
| 15 | comprobante | text | Sí | Comprobante construido como tipo-prefijo-número |

---

## Reglas de negocio

### Extracción principal

Se extrae el historial completo desde `comprobanteshistorial`.

El proceso no aplica filtro incremental por fecha en la query origen.

---

### Tipo de entidad

La entidad se determina desde `comprobantetipoentidad`.

| Valor origen | Resultado |
|---|---|
| 2 | Cliente |
| 1 | Proveedor |
| 0 | Ninguno |

---

### Enriquecimiento de sucursal

Se cruza `comprobanteshistorial.sucursalcodigo` con `sucursal.sucursalcodigo`.

Permite obtener:

- `sucursal_nombre`

---

### Enriquecimiento de estado

Se cruza el campo:

- `id_estado`

contra el archivo:

- `estados.xlsx`

para obtener la descripción:

- `estado`

---

### Construcción de comprobante

Se construye el campo `comprobante` concatenando:

`tipo-prefijo-numero`

---

### Normalización de tipo de comprobante

Se genera `tipo_comprobante` a partir de `tipo`, aplicando limpieza de espacios.

---

### Limpieza previa a insertar

Se eliminan columnas técnicas utilizadas para construir el comprobante:

- `prefijo`
- `numero`

---

## Estrategia de carga

La tabla destino se sobrescribe completa en cada ejecución.

No se realiza delete por rango ni append incremental.

---

## Relaciones principales

| Campo destino | Tabla relacionada |
|---|---|
| sucursal_codigo | sucursal |
| id_estado | estados.xlsx |
| comprobante | comprobantes |
| id_entidad | clientes / proveedorprestador |

---

## Uso funcional

Permite:

- Analizar el historial de estados de comprobantes
- Ver trazabilidad administrativa
- Auditar cambios de estado
- Identificar usuarios que intervinieron en cada comprobante
- Relacionar comprobantes con expedientes
- Analizar tiempos de trámite
- Detectar comprobantes con observaciones relevantes

---