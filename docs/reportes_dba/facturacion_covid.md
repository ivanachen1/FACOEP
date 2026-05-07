# Reporte: facturacion_covid

## Descripción

Reporte PowerBI sobre la **facturación y cobranza de prestaciones COVID** (códigos `60.x` y prácticas que contengan `COV`). Cruza facturas con sus recibos asociados para mostrar lo facturado y lo cobrado por efector / prestación / factura, con flag de anulación.

Contiene dos scripts:

- `Query Facturado.R`: solo lo facturado (rango fijo año 2020).
- `query_cobrado.R`: facturado + cobrado (rango móvil de 365 días).

---

## Tipo

Reporte / dashboard de facturación y cobranza COVID.

---

## Frecuencia

- `Query Facturado.R`: ad-hoc (rango histórico fijo).
- `query_cobrado.R`: diaria (últimos 365 días).

---

## Primary Key sugerida

- factura + prestacion + recibo

---

## Fuente origen

### Tablas transaccionales (Producción)

- `comprobantes`
- `comprobantecrgdet`
- `comprobantesasociados`
- `proveedorprestador`
- `obrassociales`

---

## Proceso que la genera

### Archivo PowerBI

- `E:/.../reportes/facturacion_covid/FacturadoCobradoCovid.pbix`

### Scripts R

- `Query Facturado.R` (facturado año 2020)
- `query_cobrado.R` (facturado + cobrado, rango móvil 365 días)

---

## Campos relevantes

### Facturado

| Campo | Descripción |
|---|---|
| efector | Nombre del proveedor (con TRIM) |
| emision | Fecha de emisión de la factura |
| factura | `tipo - codigo` |
| prestacion | Código de la práctica |
| cantidad | Cantidad agrupada |
| facturado | `comprobantecrgdetimportefactur` |
| anulado | "Si" / "No" |

### Facturado + Cobrado

| Campo | Descripción |
|---|---|
| pprnombre | Efector |
| tipofact / factura | Tipo y código de factura |
| emision | Emisión factura |
| prestacion | Práctica |
| importecrg | Importe del CRG |
| importepostrec | Importe a facturar |
| emisionrecibo | Emisión del recibo |
| tiporec / recibo | Tipo y código del recibo (RECX2) |
| anulado | "Si" / "No" |

---

## Reglas de negocio

### Filtros comunes

- `comprobantetipoentidad = 2` (cliente).
- `tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB')`.
- Práctica filtrada: `comprobantecrgdetpractica LIKE '60.%' OR comprobantecrgdetpractica LIKE '%COV%'`.

### Filtros adicionales (Query Facturado.R)

- Rango fijo: `2020-01-01` a `2020-12-31`.
- Exclusión manual de comprobantes específicos:
  `553, 687, 953, 955, 4516, 4901, 4934, 13295, 13316, 13916, 13941, 14061, 14152, 14754, 15144, 15557, 15817`.

### Filtros adicionales (query_cobrado.R)

- Rango móvil: últimos 365 días.
- Exclusión de obras sociales: `90001199, 90001003, 90001162, 90000172, 90001226`.
- `a.comprobanteasoctipo IS NULL OR a.comprobanteasoctipo = 'RECX2'` (factura sin recibo o con recibo del tipo correcto).

### Cálculo de anulado

`anulado = "Si"` cuando `comprobantedetalle LIKE '%ANULA%'`.

### Concatenación de factura

`factura = tipo + "-" + codigo`.

### Limpieza

`str_squish` sobre `tipofact` y `tiporec` para quitar espacios.

### Encoding (Query Facturado.R)

`SET client_encoding = 'windows-1252'`.

---

## Estrategia de carga

No persiste tabla destino propia. Los scripts trabajan en memoria y alimentan el `.pbix` por refresh manual.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| factura | comprobantes |
| recibo | comprobantesasociados / comprobantes |
| prestacion | nomenclador |
| efector | proveedorprestador |

---

## Uso funcional

Permite:

- Ver lo facturado y cobrado de prestaciones COVID.
- Detectar facturas COVID anuladas.
- Comparar año 2020 (cierre) vs últimos 365 días.

---

## Owner

DBA

---

## Archivo PBIX

`E:/.../reportes/facturacion_covid/FacturadoCobradoCovid.pbix`
