# Reporte: Cobranza por Cabeceras

## Descripción

Reporte PowerBI orientado a la **cobranza vista a nivel de cabecera de comprobante** (factura, nota de débito, nota de crédito, recibo). Cruza facturas con sus notas de crédito asociadas por CRG y proveedor para mostrar saldo, importe original, importe acreditado, anulación e intereses por efector / obra social / centro de costo.

A diferencia de los reportes que abren por prestación, éste trabaja sobre el comprobante completo.

---

## Tipo

Reporte / dashboard de cobranzas a nivel comprobante.

---

## Frecuencia

Diaria (refresco contra Producción).

---

## Primary Key sugerida

N/A.

---

## Fuente origen

### Tablas transaccionales (Producción)

- `comprobantes`
- `comprobantecrg`
- `comprobantesimputaciones`
- `comprobanteshistorial`
- `proveedorprestador`
- `centrocostos`
- `subcentrocostos`
- `obrassociales`

### Lookup externo

- `tabla_parametros_comprobantes.xlsx` (define qué tipos van como factura vs. nota de crédito)
- `parametros_servidor.xlsx` (host, user, password, database)

---

## Proceso que la genera

### Archivo PowerBI

- `E:/.../reportes/Cobranza por Cabeceras/Cobranza por Cabezeras.pbix`

### Scripts R

- `TablaFinal.R` → arma la tabla maestra de cobranza por cabecera (Factura ↔ Nota de Crédito).
- `TablasComprobantes.R` → arma las tablas auxiliares de comprobantes filtrados por tipo.
- `FuncionesHelper.R` → helpers (lectura de parámetros, transformación de listas IN para SQL).

---

## Campos relevantes

| Campo | Descripción |
|---|---|
| CentroCosto / SubcentroCosto | Asignación contable |
| Efector | Nombre del proveedor |
| ObraSocial | Obra social del CRG |
| Factura | Comprobante factura `tipo-prefijo-numero` |
| Saldo | Saldo del comprobante |
| EmisionFactura | Fecha de emisión |
| CrgFactura / PpridFactura | CRG y proveedor de la factura |
| EmisionCrg | Fecha de emisión del CRG |
| ValorCrgFactura | Importe del CRG facturado |
| NotaCredito | Comprobante NC asociada |
| CrgNotaCredito / PpridNotaCredito | CRG y proveedor de la NC |
| ValorCrgNotaCredito | Importe del CRG acreditado |
| Anulada | Indica si la factura está anulada |
| Interes | Interés asociado |

---

## Reglas de negocio

### Identificación de tipos de comprobante

Vienen de `tabla_parametros_comprobantes.xlsx` filtrando por:

- `tipo = "factura"` → facturas y notas de débito.
- `tipo = "test"` → notas de crédito y recibos.

Estas listas se transforman a string IN-SQL para inyectarse en el query.

### Vínculo Factura ↔ Nota de Crédito

Se hace `left_join` entre Facturas (`Fc`) y Notas de Crédito (`Nc`) por:

- `factura = factura`
- `os = os`
- `nrocrgfactura = nrocrgnotacredito`
- `ppridfactura = ppridnotacredito`

Es decir: una NC se considera vinculada a una factura cuando comparten obra social y CRG/proveedor.

### Construcción de comprobante

`comprobante = TRIM(tipocomprobantecodigo) + "-" + comprobanteprefijo + "-" + comprobantecodigo`.

### Lectura de credenciales

Vía `parametros_servidor.xlsx` (parámetros host, user, password, database con flag `Usar`).

---

## Estrategia de carga

El reporte refresca en memoria contra Producción (no persiste tabla destino). Se ejecutan los scripts manualmente o desde PowerBI antes de publicar.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| factura | comprobantes |
| os | obrassociales |
| nrocrgfactura | crg / comprobantecrg |
| centrocosto | centrocostos |

---

## Uso funcional

Permite:

- Ver saldo a cobrar abierto por factura y por efector.
- Cruzar cada factura con sus notas de crédito.
- Identificar facturas anuladas e intereses generados.
- Análisis por centro / subcentro de costo.

---

## Owner

DBA

---

## Archivo PBIX

`E:/.../reportes/Cobranza por Cabeceras/Cobranza por Cabezeras.pbix`
