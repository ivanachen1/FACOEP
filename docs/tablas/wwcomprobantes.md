# Tabla: wwcomprobantes

## Descripción
Es la tabla que contiene todos los comprobantes de Facoep.


## Tipo
Hecho transaccional.

## Fuente origen
- Tabla `comprobantes`
- Tabla `comprobanteshistorial`
- Tabla `clientes`
- Tabla `proveedorprestador`
- Tabla `centrocostos`
- Tabla `subcentrocostos`
- Tabla `provincia`
- Tabla `actividadafip`
- Tabla `tipoiva`
- Tabla `tipoliquidacion`
- Tabla `comprobantecrg`
- Proceso R `main.R` + helpers :contentReference[oaicite:0]{index=0}

## Frecuencia
Diaria

## Primary Key
id_entidad
comprobante

## Diccionario de campos

| # | Campo | Tipo | Nullable | Descripción |
|---|------|------|----------|-------------|
| 1 | id_entidad | integer | Sí | Id de la entidad asociada pudiendo ser cliente o proveedor |
| 2 | fecha_emision | date | Sí | Fecha de emisión del comprobante |
| 3 | fecha_entrega | date | Sí | Fecha de entrega del comprobante |
| 4 | nro_cae | text | Sí | Número CAE del comprobante |
| 5 | vencimiento_cae | date | Sí | Fecha de vencimiento del CAE |
| 6 | provincia | text | Sí | Provincia emision del comprobante|
| 7 | actividad_afip | text | Sí | Actividad AFIP |
| 8 | condicion_iva | text | Sí | Condición frente al IVA |
| 9 | tipo | text | Sí | Tipo de comprobante emitido o recibido |
| 10 | importe_total | double precision | Sí | Importe total |
| 11 | detalle | text | Sí | Detalle / descripción del comprobante |
| 12 | periodo | text | Sí | Período contable |
| 13 | entidad | text | Sí | Nombre de entidad |
| 14 | centro_costo | text | Sí | Centro de costo |
| 15 | subcentro_costo | text | Sí | Subcentro de costo |
| 16 | tipo_liquidacion | text | Sí | Tipo de liquidación |
| 17 | asiento | integer | Sí | Número de asiento |
| 18 | numero_proforma | integer | Sí | Número proforma |
| 19 | saldo | double precision | Sí | Saldo pendiente / actual |
| 20 | retencion_ingresos_brutos | double precision | Sí | Retención Ingresos Brutos |
| 21 | importe_percepcion_ingresos_brutos | double precision | Sí | Percepción Ingresos Brutos |
| 22 | importe_percepcion_iva | double precision | Sí | Percepción IVA |
| 23 | importe_percepcion_ganancias | double precision | Sí | Percepción Ganancias |
| 24 | importe_sobretasa_iva | double precision | Sí | Sobretasa IVA |
| 25 | importe_exento | double precision | Sí | Importe exento |
| 26 | comprobante_mandatario | text | Sí | Indicador comprobante mandatario |
| 27 | fue_impreso | text | Sí | Indicador si fue impreso |
| 28 | es_covid | text | Sí | Indicador comprobante COVID |
| 29 | es_intimacion | text | Sí | Indicador intimación |
| 30 | comprobante_importado_de_asi | text | Sí | Indicador importado desde ASI |
| 31 | comprobante_asi | text | Sí | Código / referencia ASI |
| 32 | digital | text | Sí | Indicador digital |
| 33 | es_refacturacion | text | Sí | Indicador refacturación |
| 34 | es_prestacion | text | Sí | Indicador prestación |
| 35 | comprobante_convenio | text | Sí | Indicador convenio |
| 36 | es_anulado | text | Sí | Indicador anulado |
| 37 | id_apertura | double precision | Sí | Identificador apertura |
| 38 | origen | text | Sí | Origen del registro |
| 39 | comprobante | text | Sí | Número / código comprobante |
| 40 | razon_social | text | Sí | Razón social |
| 41 | apertura | text | Sí | Apertura / categoría |
| 42 | fecha_vencimiento | date | Sí | Fecha de vencimiento |
| 43 | es_turismo | text | Sí | Indicador turismo |
| 44 | es_detectar | text | Sí | Indicador detectar |

## Reglas de negocio principales

### Exclusión base
- No incluir registros con `comprobanteentidadcodigo = -1`

### Construcción comprobante
- `comprobante = tipo + "-" + prefijo + "-" + numero`

### Conversión booleanos
Todos estos campos pasan a `SI / NO`:

- fue_impreso
- es_covid
- es_intimacion
- comprobante_importado_de_asi
- comprobante_asi
- digital
- es_refacturacion
- es_prestacion
- comprobante_convenio
- comprobante_mandatario (según lógica especial)

### Anulados
- Si `detalle` contiene texto `ANULADO` → `es_anulado = SI`

### Fecha vencimiento
Si tipo en:

- NDB
- NDA
- NDECA
- NDAASI
- NDBASI

y origen = Intimacion:

→ fecha_emision

Caso contrario:

- sin fecha_entrega → `1999-01-01`
- emisión anterior a fecha parámetro → fecha_entrega + 60 días
- resto → fecha_entrega + 90 días

### Turismo
Marca SI cuando comprobante pertenece a proveedor 3140.

### Detectar
Marca SI cuando comprobante pertenece a proveedores 3173 o 3186.

## Familia de comprobante

Los comprobantes se agrupan en familias funcionales que permiten distinguir su circuito operativo, emisor lógico y tratamiento contable.

Las familias actualmente identificadas son:

- Facturas FACOEP
- Recibos FACOEP
- Facturas ASI
- Recibos ASI (si aplica)
- Otros comprobantes

Esta clasificación facilita:

- reporting separado por unidad de negocio
- análisis de cobranzas
- seguimiento operativo
- reglas específicas por circuito
- control de volumen por familia

### Catálogo de familias

| Tipo comprobante | Familia comprobante | Subfamilia | Unidad de negocio |
|---|---|---|---|
| FACB2 | Facturas FACOEP | Factura | FACOEP |
| FACA2 | Facturas FACOEP | Factura | FACOEP |
| FAECA | Facturas FACOEP | Factura | FACOEP |
| FAECB | Facturas FACOEP | Factura | FACOEP |
| NCA | Créditos FACOEP | Nota de Crédito | FACOEP |
| NCB | Créditos FACOEP | Nota de Crédito | FACOEP |
| NCECA | Créditos FACOEP | Nota de Crédito | FACOEP |
| NDA | Débitos FACOEP | Nota de Débito | FACOEP |
| NDB | Débitos FACOEP | Nota de Débito | FACOEP |
| FACASIA | Facturas ASI | Factura | ASI |
| FACASIB | Facturas ASI | Factura | ASI |
| NCAASI | Créditos ASI | Nota de Crédito | ASI |
| NCBASI | Créditos ASI | Nota de Crédito | ASI |
| NDAASI | Débitos ASI | Nota de Débito | ASI |
| NDASIB | Débitos ASI | Nota de Débito | ASI |
| NOTADB | Comprobante interno Impugnaciones Facoep | Impugnaciones FACOEP | FACOEP |

Nota: las NOTADB son los unicos tipos de comprobantes que reflejan las imnpugnaciones de las obras sociales o clientes. Si una impugnacion es aceptada, se crea una Nota de Credito de Facoep para descontarle saldo de deuda al cliente


## Owner
DBA

## Script generador
jobs/wwcomprobantes/main.R