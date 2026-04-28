# Reporte: detalle_debitos_medicos

## Descripción

Reporte PowerBI de **detalle de débitos médicos**: para cada nota de débito (`NOTADB`) emitida, abre el motivo de débito, categoría, observaciones, importes rechazados/aceptados, prestación, efector, obra social, auditor, y enriquece con el flag de refactura/refacturación y la auditoría compartida.

El script materializa una tabla destino `detalle_debitos_medicos` en la base DBA local que es la que alimenta el `.pbix`.

---

## Tipo

Reporte / dashboard + materialización de tabla destino.

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

- notadb + nro_crg + prestacion

---

## Fuente origen

### Tablas transaccionales (Producción)

- `comprobantes`
- `comprobantecrg`
- `comprobantecrgdet`
- `comprobantesasociados`
- `proveedorprestador`
- `motivodebito`
- `motivodebitocategoria`
- `clientes`
- `crg`
- `auditoriascompartidascomproban`

### Lookup externo

- `parametros_servidor.xlsx`

---

## Proceso que la genera

### Archivo PowerBI

- `E:/.../reportes/detalle_debitos_medicos/Detalle Debitos Medicos.pbix`

### Scripts R

- `Script_Debitos_Logica.R` (proceso principal)
- `Script_debitos_Funciones.R` (helpers)

### Tabla destino

- `DBA.detalle_debitos_medicos` (Postgres `localhost`)

### Documentación interna

- `declaracion de tabla.txt` (DDL)

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | fecha_emision_comprobante | date | Sí | Fecha de emisión de la nota de débito |
| 2 | notadb | varchar | Sí | `tipo-prefijo-codigo` de la nota de débito |
| 3 | ooss | varchar | Sí | `id_entidad - nombre_cliente` de la obra social |
| 4 | efector | varchar | Sí | Nombre del proveedor (con TRIM) |
| 5 | nro_crg | int | Sí | Número de CRG |
| 6 | auditor | varchar | Sí | Usuario que hizo la auditoría médica |
| 7 | tipo_debito | varchar | Sí | Descripción del motivo de débito |
| 8 | categoria | varchar | Sí | Categoría del motivo de débito |
| 9 | observaciones | varchar | Sí | Observaciones libres del detalle |
| 10 | rechazado | decimal | Sí | Importe rechazado |
| 11 | aceptado | decimal | Sí | Importe aceptado |
| 12 | prestacion | varchar | Sí | Código de la práctica |
| 13 | auditoria_compartida | varchar | Sí | "SI" / "NO" según presencia en `auditoriascompartidascomproban` |
| 14 | es_refactura | bool | Sí | TRUE si el detalle de la factura asociada contiene `"REFACTURA"` |
| 15 | es_refacturacion | varchar | Sí | "SI" / "NO" según patrón del detalle de la NOTADB |

---

## Reglas de negocio

### Filtro principal

`nota.tipocomprobantecodigo IN ('NOTADB')`.

### Detección de "refacturación" desde el detalle de la NOTADB

```r
es_refacturacion = "SI"
WHEN nota.comprobantedetalle LIKE '%Comprobante generado automáticamente
                                    por copia de NOTADB por refacturación.(Rechazo)%'
ELSE 'NO'
```

### Detección de auditoría compartida

`EsAuditoriaCompartida = "SI"` cuando hay match en `auditoriascompartidascomproban` por `(tipocomprobantecodigo, comprobanteprefijo, comprobantecodigo)`.

### Detección de refactura desde el detalle de la factura asociada

Se cruza con `comprobantesasociados` para encontrar la factura origen (tipos `FACA2, FACB2, FAECA, FAECB`) y se aplica:

```r
esRefactura = str_detect(detallefactura, "REFACTURA")
```

Si el detalle es NULL se usa `"SIN DETALLE"` (queda FALSE).

### Encoding

Se aplica `enc2utf8` y `Encoding = "UTF-8"` sobre el query (caracteres especiales en español).

---

## Estrategia de carga

`overwrite = TRUE`, `append = FALSE`. La tabla `DBA.detalle_debitos_medicos` se reemplaza completa en cada corrida.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| nro_crg | crg / comprobantecrg |
| notadb | comprobantes / comprobantesasociados |
| ooss | clientes |
| efector | proveedorprestador |
| tipo_debito | motivodebito |

---

## Uso funcional

Permite:

- Auditar cada NOTADB con su motivo y categoría.
- Identificar cuáles vienen por refacturación.
- Cuantificar importes rechazados vs aceptados.
- Ver auditorías compartidas.

---

## Owner

DBA / Auditoría

---

## Archivo PBIX

`E:/.../reportes/detalle_debitos_medicos/Detalle Debitos Medicos.pbix`
