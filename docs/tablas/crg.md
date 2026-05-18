# Tabla: crg

## Descripción

Tabla maestra de CRGs (Comprobantes de Recupero de Gastos). Contiene la cabecera del CRG con datos del proveedor efector, obra social, tipos, particularidades, importes, fechas operativas y trazabilidad de usuarios (alta, carga, modificación, auditoría médica, documentación pendiente).

Es la fuente principal de información estática del CRG. Se complementa con `crg_historial` (movimientos de estado) y `detallecrg` (detalle de prestaciones).

---

## Tipo

Hecho transaccional / cabecera maestra de CRG.

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

- id_proveedor
- nro_crg

---

## Fuente origen

### Tablas transaccionales

- `crg`
- `crgdet` (subconsulta para `cantidad_practicas`)
- `crghistorial` (para `fecha_carga` y `usuario_carga`)
- `obrassociales`
- `proveedorprestador`
- `estados_crg` (en base SIF)

### Lookup externo

- `tipos.xlsx`
- `tipo_prestacion.xlsx`
- `particularidad.xlsx`
- `tipos_financiador.xlsx`
- `tipos_obras_sociales.xlsx`

---

## Proceso que la genera

### Script principal

- `E:/DataWarehouse/crg/main.R`

### Helper

- `E:/DataWarehouse/crg/Funciones_Helper.R`
- `E:/DataWarehouse/crg/Funciones_Helper_crg.R`

### Tabla destino

- `public.crg` (base SIF)

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | id_proveedor | int | Sí | Identificador del proveedor / efector |
| 2 | nombre_proveedor | varchar | Sí | Nombre del proveedor (con TRIM) |
| 3 | efector | varchar | Sí | Concatenación `id_proveedor - nombre_proveedor` |
| 4 | nro_crg | int | Sí | Número de CRG |
| 5 | tipo | varchar | Sí | Tipo de CRG (enriquecido desde `tipos.xlsx`) |
| 6 | estado_actual | varchar | Sí | Estado actual del CRG (enriquecido desde `estados_crg`) |
| 7 | particularidad | varchar | Sí | Particularidad (enriquecida desde `particularidad.xlsx`) |
| 8 | tipo_prestacion | varchar | Sí | Tipo de prestación (enriquecido desde `tipo_prestacion.xlsx`) |
| 9 | periodo | varchar | Sí | Periodo del CRG (`crgperiodnum`) |
| 10 | fecha_emision | date | Sí | Fecha de emisión |
| 11 | fecha_ingreso | date | Sí | Fecha de ingreso |
| 12 | fecha_carga | timestamp | Sí | Fecha mínima del primer movimiento de estado 1 en `crghistorial` |
| 13 | fecha_modificacion | timestamp | Sí | Fecha de última modificación |
| 14 | usuario_modificacion | varchar | Sí | Usuario que realizó la última modificación |
| 15 | usuario_alta | varchar | Sí | Usuario que dio de alta el CRG (`crgusucarga`) |
| 16 | usuario_carga | varchar | Sí | Usuario asociado al primer movimiento de estado 1 en `crghistorial` |
| 17 | usuario_documentacion_pendiente | varchar | Sí | Usuario que marcó documentación pendiente |
| 18 | numero_remito | int | Sí | Número de remito asociado |
| 19 | numero_proforma | int | Sí | Número de proforma asociado |
| 20 | id_obra_social | int | Sí | Código de obra social |
| 21 | nombre_obra_social | varchar | Sí | Descripción de la obra social |
| 22 | sigla_obra_social | varchar | Sí | Sigla de la obra social |
| 23 | obra_social_facturable | varchar | Sí | "SI" / "NO" — derivado de `obsocialesnofacturable` |
| 24 | usuario_auditoria_medica | varchar | Sí | Usuario que realizó la auditoría médica |
| 25 | visto_por_medico | bool | Sí | Indicador de auditoría médica realizada |
| 26 | importe_bruto | decimal | Sí | Importe bruto del CRG |
| 27 | importe_descuento | decimal | Sí | Importe descontado |
| 28 | importe_neto | decimal | Sí | `importe_bruto - importe_descuento` |
| 29 | crg_prestacional | varchar | Sí | Indicador de CRG prestacional |
| 30 | observaciones | varchar | Sí | Observaciones libres del CRG |
| 31 | tipo_financiador | varchar | Sí | Tipo de financiador (enriquecido desde `tipos_financiador.xlsx`) |
| 32 | cantidad_practicas | int | Sí | Conteo de prácticas asociadas en `crgdet` |

---

## Reglas de negocio

### Cálculo de fecha_carga y usuario_carga

Se obtienen consultando `crghistorial`:

- `fecha_carga = MIN(crghistorialfecha)` para el CRG donde `crghistorialestado = 1`.
- `usuario_carga` es el `crghistorialusuario` correspondiente a esa fecha mínima.

### Cálculo de cantidad_practicas

Subconsulta sobre `crgdet`:

```sql
SELECT pprid, crgnum, COUNT(crgdetpractica) AS cantidad
FROM crgdet
GROUP BY pprid, crgnum
```

### Construcción de efector

`efector = id_proveedor + " - " + nombre_proveedor`.

### Importe neto

`importe_neto = importe_bruto - importe_descuento`.

### Obra social facturable

Si `obsocialesnofacturable` es nulo se asume `FALSE`. Luego:

- `FALSE` → `obra_social_facturable = "SI"`
- `TRUE`  → `obra_social_facturable = "NO"`

### Enriquecimiento por catálogos Excel

| Campo origen | Lookup | Resultado |
|---|---|---|
| id_tipo_crg | tipos.xlsx | tipo |
| id_tipo_prestacion | tipo_prestacion.xlsx | tipo_prestacion |
| id_particularidad | particularidad.xlsx | particularidad |
| id_tipo_financiador | tipos_financiador.xlsx | tipo_financiador |
| id_estado_crg | estados_crg (DB SIF) | estado |

Los identificadores técnicos se eliminan del DataFrame final.

### Catálogo de estados del CRG

El campo `estado_actual` guarda la **descripción** del estado decodificada desde `estados_crg`. Para filtrar / interpretar correctamente:

| id (`crgestado` en origen) | `estado_actual` (en DW SIF) |
|---|---|
| 1 | Ingresado |
| 2 | Remitido |
| 3 | Proforma |
| 4 | Facturado |
| 5 | Remitir Factura |
| 6 | Envio GCBA |
| 7 | Liquido Producto |
| 8 | Comisiones Liquidadas |
| 9 | Auditado |
| 10 | Pendiente Medico |
| 11 | Asignado |
| 12 | Pendiente Administrativo |
| 13 | Pendiente Corrección |
| 14 | Reingresado |
| 15 | Eliminado |
| 16 | Eliminado por el Efector |
| 17 | Pendiente Correccion FACOEP |
| 18 | No Facturable |

> Catálogo mantenido por el proceso `tablas_lookup` (ver `docs/tablas/tablas_lookup.md` → "estados_crg").
> **Importante para queries:** filtrar por `WHERE estado_actual = 'Facturado'` desde el DW. Si se consulta directamente Producción, usar `WHERE crgestado = 4`.

### Limpieza

- `nombre_proveedor` se aplica `str_trim`.

---

## Estrategia de carga

`overwrite = TRUE`, `append = FALSE`. La tabla se reemplaza completa en cada corrida.

---

## Relaciones principales

| Campo destino | Tabla relacionada |
|---|---|
| nro_crg + id_proveedor | detallecrg |
| nro_crg + id_proveedor | crg_historial |
| nro_crg + id_proveedor | comprobantecrg / comprobantecrgdet |
| id_obra_social | obrassociales |
| id_proveedor | proveedorprestador |

---

## Uso funcional

Permite:

- Consulta maestra del CRG (estado, importe, particularidad).
- Auditoría de carga (quién y cuándo dio de alta cada CRG).
- Filtrado por obra social, tipo financiador, estado.
- Cálculo de KPIs por efector.

---

## Owner

DBA

---

## Script generador

`E:/DataWarehouse/crg/main.R`
