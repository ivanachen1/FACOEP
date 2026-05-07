# Reporte: Monitoreo CRGs

## Descripción

Reporte PowerBI orientado al **monitoreo del ciclo de vida de los CRGs**: universo total, distribución por estado, detalle de CRGs y seguimiento puntual de la facturación de prestaciones específicas (set "Nancy" — IAC.01, IAC.02, IAC.03, COV.16, COV.17). Cubre múltiples solapas con scripts independientes, pensado para auditoría operativa diaria.

---

## Tipo

Reporte / dashboard de monitoreo operativo (multi-solapa).

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

N/A.

---

## Fuente origen

### Tablas transaccionales (Producción)

- `crg`
- `crgdet`
- `crghistorial`
- `comprobantes`
- `comprobantecrg`
- `comprobantecrgdet`
- `proveedorprestador`
- `obrassociales`

### Lookup externo

- `Estados Crgs.xlsx`
- `Prestaciones Nancy.xlsx` (set de prácticas a monitorear)
- `PrestacionesNoSumar.xlsx`
- `tabla_parametros_comprobantes.xlsx`
- `parametros_servidor.xlsx`

---

## Proceso que la genera

### Archivo PowerBI

- `E:/.../reportes/Monitoreo CRGs/Monitoreo CRGs.pbix`

### Scripts R (uno por solapa)

- `Monitoreo CRGs_Universo.R` → universo total de CRGs
- `Monitoreo CRGs_CRGPorEstadosSuma.R` → distribución por estado
- `Monitoreo CRGs_CRGDetalle.R` → detalle CRG
- `Monitoreo CRGs_FacturacionCRGs.R` → facturación del set Nancy
- `Monitoreo CRGs_TablasAuxiliares.R` → tablas auxiliares
- `Script Limpieza Tablas.R` → limpieza
- `Script Nancy Logica.R` → lógica de prestaciones Nancy

### Documentación interna

- `Logica Monitoreo Facturacion CRGs.txt`
- `Requerimiento.txt`
- `README.md`

---

## Campos relevantes

### Solapa Facturación CRGs (set Nancy)

| Campo | Descripción |
|---|---|
| pprid | ID del efector |
| efector | Nombre del proveedor |
| factura | `tipo-prefijo-codigo` |
| EmisionFactura | Fecha de emisión de la factura |
| Nrocrg | Número de CRG |
| emisioncrg | Fecha de emisión del CRG |
| crgdetnumerocph | DPH |
| obsocialesdescripcion | Obra social |
| practica | Práctica realizada |
| idcrgdet | ID del detalle de CRG |
| importecrg | Importe del detalle |
| fechaprestacion | Fecha de la prestación |
| id_test / id_detalle | Concatenaciones para el cruce |

---

## Reglas de negocio

### Set de prácticas "Nancy"

Se monitorean prácticas específicas que vienen de `Prestaciones Nancy.xlsx`:

`IAC.01, IAC.02, IAC.03, COV.16, COV.17` (al momento del último ajuste).

### Tipos de factura considerados

Vienen de `tabla_parametros_comprobantes.xlsx`. Habitualmente: `FACA2, FACB2, FAECA, FAECB`.

### Cálculo de id_test e id_detalle

Para identificar exactamente la prestación dentro del CRG:

```
id_detalle = pprid + '-' + crgnum
id_test    = pprid + '-' + crgnum + '-' + crgdetnumerocph
```

### Vinculación CRG → factura

```sql
LEFT JOIN comprobantecrgdet comp
  ON det.pprid = comp.comprobantepprid
 AND det.crgnum = comp.comprobantecrgnro
 AND det.crgdetid = comp.comprobantecrgdetid
```

### Filtro principal (Logica Monitoreo Facturacion CRGs)

- `det.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB')`
- `aux2.id_test IS NOT NULL` (CRG pertenece al set Nancy)

### Lectura de credenciales

Vía `parametros_servidor.xlsx` (host, user, password, database, workdirectory).

---

## Estrategia de carga

Scripts en memoria → `.pbix`. No persiste tabla destino propia.

Existe una versión "Migrado" en la subcarpeta `Migrado/` (refactor en curso).

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| nro_crg + pprid | crg / crg_historial |
| factura | comprobantes / wwcomprobantes |
| obsocialescodigo | obrassociales |

---

## Uso funcional

Permite:

- Universo total de CRGs y distribución por estado.
- Detalle CRG por CRG con estado y fechas.
- Seguimiento puntual de prestaciones críticas (set Nancy: IAC, COV).
- Auditoría operativa diaria.

---

## Owner

DBA

---

## Archivo PBIX

`E:/.../reportes/Monitoreo CRGs/Monitoreo CRGs.pbix`
