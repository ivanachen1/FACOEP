# Reporte: CRG SIF - SIGEHOS

## Descripción

Reporte PowerBI que **compara la información de CRGs entre el sistema SIF y el sistema Sigehos**. Sirve para detectar diferencias entre ambos sistemas (CRGs presentes en uno y no en el otro, importes desalineados, estados distintos), facilitar conciliaciones y validar la integridad del flujo SIF ↔ Sigehos.

---

## Tipo

Reporte / dashboard de conciliación entre sistemas.

---

## Frecuencia

Diaria (refresco contra las tablas DW).

---

## Primary Key sugerida

N/A.

---

## Fuente origen

### Tablas (base SIF)

- `crg`
- `crg_historial`
- `comprobantecrg`
- `comprobantecrgdet`

### Sistema externo

- Bases SIGEHOS (origen Sigehos consultadas mediante el proceso `Conexion CRGs`).

---

## Proceso que la genera

### Archivo PowerBI

- `E:/.../reportes/CRG SIF-Sigehos/CRG SIF - SIGEHOS.pbix`

### Insumos visuales

- `filtrar.png` (instrucción gráfica de cómo aplicar filtros).

### Versiones

- Se mantiene una segunda versión en `V2/CRG SIF - SIGEHOS.pbix` (en evaluación / refactor).

---

## Campos relevantes

Las visualizaciones se basan en los campos de `crg` (nro_crg, id_proveedor, importe, estado, fecha_emision) y los espejos provenientes de Sigehos.

---

## Reglas de negocio

### Comparación

Se cruza por `nro_crg + id_proveedor`. Las diferencias se segmentan por:

- CRGs presentes en SIF y faltantes en Sigehos.
- CRGs presentes en Sigehos y faltantes en SIF.
- CRGs en ambos pero con diferencias de importe / estado.

### Insumo de conexión

La conexión a Sigehos se mantiene por el proceso `Conexion CRGs` (ver `docs/reportes_dba/Conexion_CRGs.md`).

---

## Estrategia de carga

Refresco directo contra las tablas DW. No tiene tabla destino propia (es un reporte de comparación que opera en memoria).

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| nro_crg + id_proveedor | crg, crg_historial, comprobantecrgdet |

---

## Uso funcional

Permite:

- Detectar CRGs perdidos entre ambos sistemas.
- Conciliar importes y estados.
- Auditoría de la integración SIF ↔ Sigehos.

---

## Owner

DBA

---

## Archivo PBIX

`E:/.../reportes/CRG SIF-Sigehos/CRG SIF - SIGEHOS.pbix`
