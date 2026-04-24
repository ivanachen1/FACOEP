# Tabla: comprobantecrgdet

## Descripción
Tabla de detalle de comprobantes asociados a CRG. Contiene información de prestaciones, afiliados, prácticas, importes debitados/acreditados/facturados, proveedor efector, financiador, motivos de débito/crédito y datos relacionados al CRG. Es conceptualmente el detalle del CRG facturado. Permite tener lo facturado por DNI y es el corazon de facturacion por prestaciones

## Tipo
Hecho transaccional / detalle operativo de comprobantes CRG.

## Fuente origen
- Tabla `comprobantecrgdet`
- Tabla `comprobantes`
- Tabla `crg`
- Tabla `crgdet`
- Tabla `proveedorprestador`
- Tabla `clientes`
- Tabla `sucursal`
- Tabla `motivodebito`
- Tabla `motivodebitocategoria`
- Excel `tipo_prestacion.xlsx`
- Excel `tabla_motivos.xlsx`
- Proceso Python `main.py` + `funciones.py`

## Frecuencia
Diaria

## Primary Key sugerida
id_entidad  
comprobante  
nro_crg  
id  
practica

## Diccionario de campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | empcod | character varying | Sí | Código de empresa |
| 2 | id_sucursal | integer | Sí | Identificador de sucursal |
| 3 | sucursal_nombre | character varying | Sí | Nombre de la sucursal |
| 4 | tipo_entidad | character varying | Sí | Tipo de entidad asociada: Cliente, Proveedor o Ninguno |
| 5 | id_entidad | integer | Sí | Identificador de la entidad asociada al comprobante |
| 6 | tipo | character varying | Sí | Tipo de comprobante Emitido|
| 7 | fecha_emision_comprobante | date | Sí | Fecha de emisión del comprobante |
| 8 | id_proveedor | integer | Sí | Identificador del proveedor/prestador |
| 9 | nombre_proveedor | character varying | Sí | Nombre del proveedor/prestador |
| 10 | nro_crg | integer | Sí | Número de CRG asociado |
| 11 | id | integer | Sí | Identificador del detalle dentro del CRG |
| 12 | tipo_documento_afiliado | character varying | Sí | Tipo de documento del afiliado |
| 13 | numero_documento_afiliado | character varying | Sí | Número de documento del afiliado |
| 14 | numero_afiliado | character varying | Sí | Número de afiliado |
| 15 | nombre_apellido_afiliado | character varying | Sí | Nombre y apellido del afiliado |
| 16 | motivo | character varying | Sí | Motivo informado en el detalle |
| 17 | forma_egreso | character varying | Sí | Forma de egreso |
| 18 | fecha_egreso | date | Sí | Fecha de egreso |
| 19 | fecha_ingreso | date | Sí | Fecha de ingreso |
| 20 | fecha_prestacion | date | Sí | Fecha de prestación |
| 21 | practica | character varying | Sí | Código o descripción de práctica |
| 22 | precio_unitario | numeric | Sí | Precio unitario de la práctica |
| 23 | tipo_practica | character varying | Sí | Tipo de práctica. Actualmente se marca como Nomenclador cuando corresponde |
| 24 | nro_crg_relacionado | integer | Sí | Número de CRG relacionado |
| 25 | importe_modificado_crg | numeric | Sí | Importe neto/modificado del CRG |
| 26 | importe_a_acreditar | numeric | Sí | Importe a acreditar. Es el que se usa para informar debitos o impugnaciones |
| 27 | importe_a_debitar | numeric | Sí | Importe a debitar. Es el que se usa para informar debitos o impugnaciones |
| 28 | importe_a_facturar | numeric | Sí | Importe a facturar. Es el que se usa cuando se quiere informar facturacion |
| 29 | discrepancia | character varying | Sí | Diferencia o discrepancia informada |
| 30 | comprobante | character varying | Sí | Comprobante construido como tipo-prefijo-numero |
| 31 | efector | character varying | Sí | Proveedor/prestador concatenado como id - nombre |
| 32 | financiador | character varying | Sí | Financiador concatenado como id entidad - nombre cliente |
| 33 | tipo_prestacion | character varying | Sí | Tipo de prestación enriquecido desde catálogo externo |
| 34 | motivo_debito | character varying | Sí | Descripción del motivo de débito |
| 35 | categoria_motivo_debito | character varying | Sí | Categoría del motivo de débito |
| 36 | motivo_debito_credito | character varying | Sí | Motivo de débito/crédito enriquecido desde tabla de motivos |
| 37 | id_nomenclador | integer | Sí | Identificador del nomenclador |
| 38 | id_centro_costo | integer | Sí | Identificador del centro de costo |
| 39 | id_subcentro_costo | integer | Sí | Identificador del subcentro de costo |
| 40 | id_origen | character varying | Sí | Origen del comprobante |
| 41 | importe_original_crg | numeric | Sí | Importe bruto original del CRG |
| 42 | fecha_emision_crg | date | Sí | Fecha de emisión del CRG |
| 43 | fecha_carga_crg | date | Sí | Fecha de carga del CRG |
| 44 | cantidad_practicas | numeric | Sí | Cantidad de prácticas asociadas al detalle |
| 45 | id_tipo_prestacion_desde_sigehos | integer | Sí | Identificador del tipo de prestación proveniente de Sigehos |
| 46 | obra_sociales_codigo | integer | Sí | Código de obra social asociada al CRG |

## Reglas de negocio principales

### Filtro base
- Se toman comprobantes cuya `comprobantefechaemision` esté dentro del rango procesado.
- Se excluyen registros con `comprobanteentidadcodigo = -1`.

### Construcción de comprobante
- `comprobante = tipo + "-" + prefijo + "-" + numero`.

### Construcción de efector
- `efector = id_proveedor + " - " + nombre_proveedor`.

### Construcción de financiador
- `financiador = id_entidad + " - " + nombre_cliente`.

### Tipo de entidad
- `2` → Cliente
- `1` → Proveedor
- `0` → Ninguno

### Tipo de práctica
- Si `comprobantecrgdettipopractica = 1`, se informa `Nomenclador`.

### Importe modificado del CRG
- Se calcula como:
  - `crgimpbruto - crgimpdescuento`

### Enriquecimiento de tipo de prestación
- Se cruza `id_tipo_prestacion` contra el Excel `tipo_prestacion.xlsx`.
- Luego se elimina el identificador técnico y queda el campo descriptivo `tipo_prestacion`.

### Enriquecimiento de motivo débito/crédito
- Se cruza `id_motivo_debito_credito` contra el Excel `tabla_motivos.xlsx`.
- Luego se elimina el identificador técnico.

### Valores por defecto
- `importe_original_crg` se completa con `0` cuando viene nulo.
- `cantidad_practicas` se completa con `1` cuando viene nulo.

### Carga incremental por rango
- El proceso extrae datos por bloques de días.
- Antes de insertar en destino, elimina registros existentes de `comprobantecrgdet` para el rango:
  - `fecha_emision_comprobante BETWEEN fecha_inicio AND fecha_fin`.

Nota: Se relaciona con la tabla wwcomprobantes por el campo comprobante. Permite desglosar la facturacion por Efector y financiador

## Owner
DBA

## Script generador
jobs/comprobantecrgdet/main.py