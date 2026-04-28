# Reporte: Comprobantes Asociados

## Descripción

Carpeta de **trabajo / desarrollo** orientada a explorar la relación entre comprobantes asociados (factura ↔ NC, recibo ↔ comprobante de origen) y el detalle de comprobantes. Contiene el esqueleto de un script R que se conecta a Producción y notas de exploración (CSVs con listados de columnas) para diseñar el query final.

A diferencia del proceso DW `comprobantes_asociados` (que sí materializa una tabla), este es un script analítico/exploratorio: sirvió como base para diseñar el reporte y no carga en DB.

---

## Tipo

Workspace de exploración / scripting analítico.

---

## Frecuencia

A demanda (no automatizada).

---

## Primary Key sugerida

N/A.

---

## Fuente origen

### Tablas transaccionales (Producción)

- `comprobantes`
- `comprobantesasociados`

### Lookup externo

- `tipo_comprobante.xlsx`
- `parametros_servidor.xlsx` (host, user, password, database)

---

## Proceso que la genera

### Scripts

- `Solapa CRG SIF-SIGEHOS.R` (esqueleto de conexión, query pendiente de armar).
- `Script_Facturacion_Funciones.R` (helpers compartidos con otros reportes).

### Insumos de exploración

- `Data Comprobantes Asociados.csv` → listado de columnas de `comprobantesasociados` con notas (ej. "tengo que obtener su fecha de emisión").
- `Data Comprobantes.csv` → listado de columnas de `comprobantes`.

---

## Reglas de negocio

### Conexión

Lee credenciales de `parametros_servidor.xlsx` y aplica `SET client_encoding = 'windows-1252'` por compatibilidad de caracteres con la base original.

---

## Estrategia de carga

No persiste tablas. Es un sandbox de exploración para diseñar reportes/consultas que luego se trasladan al DW (`comprobantes_asociados`) o a otros reportes.

---

## Relaciones principales

| Campo destino | Tabla relacionada |
|---|---|
| comprobante | comprobantes |
| comprobante asociado | comprobantesasociados |

---

## Uso funcional

Material de apoyo para entender el modelo de comprobantes asociados antes de migrar la lógica a un proceso productivo. Hoy reemplazado en producción por `docs/tablas/comprobantes_asociados.md`.

---

## Owner

DBA

---

## Script generador

`E:/.../reportes/Comprobantes Asociados/Solapa CRG SIF-SIGEHOS.R`
