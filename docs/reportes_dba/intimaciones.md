# Reporte: intimaciones

## Descripción

Reporte PowerBI standalone (`Reporte intimaciones.pbix`) sin scripts asociados en la carpeta. Refresca directamente desde las tablas del DW (`comprobantes`, `intimacion`, `intimacionintimaciondet`) consultadas embebidamente desde PowerBI.

Está orientado a seguimiento de intimaciones emitidas, su estado, recepción y cobro asociado.

---

## Tipo

Reporte / dashboard standalone (solo `.pbix`).

---

## Frecuencia

Refresco manual o programado desde PowerBI Service.

---

## Primary Key sugerida

N/A.

---

## Fuente origen

### Tablas (Producción / SIF)

- `intimacion`
- `intimacionintimaciondet`
- `comprobantes`
- `comprobantesimputaciones`
- `clientes`

(Consultas embebidas en el `.pbix`; sin scripts R/Python en la carpeta.)

---

## Proceso que la genera

### Archivo PowerBI

- `E:/.../reportes/intimaciones/Reporte intimaciones.pbix`

(No hay scripts auxiliares: las consultas viven dentro del `.pbix`.)

---

## Campos relevantes

Los del modelo de las tablas de intimación que utiliza:

| Campo | Descripción |
|---|---|
| intimacionnro | Número de intimación |
| intimacionfecha | Fecha de envío |
| intimacionfecharecepcion | Fecha de recepción |
| factura | Comprobante intimado |
| importe | Importe del comprobante |
| obra_social | Cliente |

---

## Reglas de negocio

Las que viven en cada tabla origen. Filtros y segmentaciones se aplican dentro del `.pbix`.

Para reglas de negocio detalladas sobre intimaciones y cobranzas asociadas, ver:

- `docs/reportes_dba/Pagos_por_Intimaciones.md`

---

## Estrategia de carga

Refresco contra DW desde PowerBI. No persiste tabla destino propia.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| factura | comprobantes |
| intimacionnro | intimacion |
| obra_social | clientes / obrassociales |

---

## Uso funcional

Permite:

- Ver volumen de intimaciones emitidas.
- Estado de recepción.
- Filtrar por obra social, fecha o tipo de comprobante.

---

## Owner

DBA / Cobranzas

---

## Archivo PBIX

`E:/.../reportes/intimaciones/Reporte intimaciones.pbix`
