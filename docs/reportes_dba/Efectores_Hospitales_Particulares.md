# Reporte: Efectores Hospitales Particulares

## Descripción

Reporte PowerBI standalone (sin scripts ni lookup propios en la carpeta) orientado al **monitoreo de efectores hospitales particulares**: actividad, facturación, débitos y volumen por hospital privado conveniado.

Al no tener scripts asociados, el reporte se alimenta directamente desde las tablas del DW (`crg`, `comprobantecrg`, `comprobantecrgdet`, `efectores`) mediante consultas DirectQuery / Import desde PowerBI.

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

### Tablas (base SIF)

- `crg`
- `comprobantecrg`
- `comprobantecrgdet`
- `efectores` (lookup)

(Consultas embebidas en el `.pbix`; sin scripts R/Python en la carpeta.)

---

## Proceso que la genera

### Archivo PowerBI

- `E:/.../reportes/Efectores Hospitales Particulares/Efectores Hospitales.pbix`

(No hay scripts auxiliares: las consultas viven dentro del `.pbix`.)

---

## Campos relevantes

Los del modelo de las tablas DW que utiliza (ver `docs/tablas/crg.md`, `docs/tablas/comprobantecrg.md`, `docs/tablas/comprobantecrgdet.md`).

---

## Reglas de negocio

Las que viven en cada tabla DW de origen. Este reporte no aplica transformaciones adicionales más allá de los filtros / segmentaciones que ofrezca el `.pbix`.

---

## Estrategia de carga

Refresco contra DW desde PowerBI. No persiste tabla destino propia.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| id_proveedor | efectores |
| nro_crg + id_proveedor | crg / comprobantecrgdet |

---

## Uso funcional

Permite:

- Visualizar actividad de hospitales particulares.
- Comparar facturación entre efectores privados.
- Filtrar por convenio / financiador.

---

## Owner

DBA

---

## Archivo PBIX

`E:/.../reportes/Efectores Hospitales Particulares/Efectores Hospitales.pbix`
