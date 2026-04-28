# Reporte: cobranza_por_prestaciones

## Descripción

Reporte PowerBI que **abre los recibos de cobranza al detalle de prestación**: para cada recibo (`RECX2` / `RECM`) se identifica la factura de origen, el CRG y las prácticas asociadas, asignando además un tipo de apertura por grupo de prestación. Permite ver no solo cuánto entró sino qué prestaciones/CRG se cobraron.

El script materializa dos tablas en la base DBA: `cobranza_prestaciones_data` (detalle por prestación) y `cobranza_prestaciones_recibos_consin_apertura` (recibos con/sin apertura asignada).

---

## Tipo

Reporte / dashboard + materialización de tabla destino.

---

## Frecuencia

Diaria (rango móvil de 180 días).

---

## Primary Key sugerida

### cobranza_prestaciones_data

- recibo + emision + comprobantecrgnro + Prestacion + id_row

### cobranza_prestaciones_recibos_consin_apertura

- recibo

---

## Fuente origen

### Tablas transaccionales (Producción)

- `comprobantes`
- `comprobantecrg`
- `comprobantecrgdet`
- `clientes`
- `proveedorprestador`

### Lookup externo

- `Grupo Prestaciones.xlsx` (mapeo prestación → tipo de apertura)
- `Origen.xlsx`
- `parametros_servidor.xlsx`

---

## Proceso que la genera

### Archivo PowerBI

- `E:/.../reportes/cobranza_por_prestaciones/Cobranza por Prestaciones.pbix`

### Scripts R

- `Main.R` (proceso principal: extract + transform + insert)
- `Funciones_Helper.R` (helpers)
- `Dataframes_Auxiliares.R` (auxiliares)
- `insert_postgresql.R` (función de inserción)
- `Query Data.txt` (query base de referencia)

### Tablas destino (base DBA, host `10.22.1.44`)

- `cobranza_prestaciones_data`
- `cobranza_prestaciones_recibos_consin_apertura`

---

## Campos

### cobranza_prestaciones_data

| # | Campo | Descripción |
|---|---|---|
| 1 | Efector | Nombre del proveedor |
| 2 | OS / obra_social | `clienteid - clientenombre` |
| 3 | recibo | `tipo-prefijo-codigo` |
| 4 | emision | Fecha de emisión del recibo |
| 5 | comprobantecrgnro | CRG vinculado vía `comprobantecrg` |
| 6 | Prestacion | Práctica del CRG |
| 7 | ImportePrestacion | Importe a facturar de la prestación |
| 8 | CentroCosto | Centro de costo del comprobante |
| 9 | origen | Origen del comprobante |
| 10 | tipo_apertura | Tipo de apertura aplicado (desde `Grupo Prestaciones.xlsx`) |
| 11 | id_row | Identificador de fila (deduplicación) |

### cobranza_prestaciones_recibos_consin_apertura

| # | Campo | Descripción |
|---|---|---|
| 1 | recibo | Número de recibo |
| 2 | tipo_apertura | Apertura asignada |
| 3 | emision_recibo | Fecha de emisión |
| 4 | obra_social | OS (Sin Asignar si NULL) |
| 5 | origen | Origen |

---

## Reglas de negocio

### Rango temporal

Últimos **180 días** (`hasta = Sys.Date()`, `desde = hasta - 180`).

### Filtros de comprobante

- `tipocomprobantecodigo IN ('RECX2', 'RECM')` (recibos)
- `comprobantefechaemision BETWEEN desde AND hasta`
- `comprobanteentidadcodigo <> -1`

### Vinculación recibo → CRG → prestación

```sql
LEFT JOIN comprobantecrg cc
  ON c.tipocomprobantecodigo = cc.tipocomprobantecodigo
 AND c.comprobanteprefijo    = cc.comprobanteprefijo
 AND c.comprobantecodigo     = cc.comprobantecodigo

LEFT JOIN comprobantecrgdet cd
  ON cd.tipocomprobantecodigo = cc.tipocomprobantecodigo
 AND cd.comprobanteprefijo    = cc.comprobanteprefijo
 AND cd.comprobantecodigo     = cc.comprobantecodigo
 AND cd.comprobantecrgnro     = cc.comprobantecrgnro
 AND cd.comprobantepprid      = cc.comprobantepprid
```

### Asignación de tipo_apertura

Vía `Grupo Prestaciones.xlsx` (mapeo prestación → grupo).

### Marcado de obra social vacía

Si `ObraSocial` queda NULL en el dataset de recibos, se rellena con `"Sin Asignar"`.

---

## Estrategia de carga

Para cada tabla destino, antes de insertar:

```sql
DELETE FROM cobranza_prestaciones_data
WHERE emision BETWEEN '{desde}' AND '{hasta}'

DELETE FROM cobranza_prestaciones_recibos_consin_apertura
WHERE emision_recibo BETWEEN '{desde}' AND '{hasta}'
```

Luego se inserta con `append = TRUE`. La carga es incremental por rango móvil de 180 días.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| recibo | comprobantes |
| comprobantecrgnro | comprobantecrg / crg |
| Prestacion | nomenclador / Grupo Prestaciones.xlsx |
| Efector | proveedorprestador |

---

## Uso funcional

Permite:

- Ver qué prestaciones/CRG fueron cobrados por cada recibo.
- Analizar cobranza por grupo de prestación / centro de costo.
- Identificar recibos sin apertura asignada (señal de práctica nueva o sin mapear).

---

## Owner

DBA / Cobranzas

---

## Archivo PBIX

`E:/.../reportes/cobranza_por_prestaciones/Cobranza por Prestaciones.pbix`
