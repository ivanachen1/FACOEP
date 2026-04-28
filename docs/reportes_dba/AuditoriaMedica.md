# Reporte: AuditoriaMedica

## Descripción

Reporte PowerBI orientado al seguimiento de la **auditoría médica** sobre los CRGs. Combina la actividad de los auditores (productividad, importes, clasificación por tramo) con la información de centros de costo. Se alimenta de las tablas materializadas por el proceso DW `auditoria_medica`.

Permite responder preguntas como: cuántos CRGs auditó cada médico, qué importe agregaron por motivo 42, distribución por tramo de importe, evolución mensual por centro de costo.

---

## Tipo

Reporte / dashboard de seguimiento operativo (BI).

---

## Frecuencia

Diaria (refresco posterior a la corrida del proceso DW `auditoria_medica`).

---

## Primary Key sugerida

N/A (reporte basado en tablas con sus propias claves: ver `docs/tablas/auditoria_medica.md`).

---

## Fuente origen

### Tablas (base SIF)

- `auditoria_medica_importe`
- `auditoria_medica_usuarios`
- `auditoria_medica_centros`

### Lookup externo

- `medicos.xlsx` (lista de auditores categorizados como "Auditor Médico")
- `parametros_servidor.xlsx`

---

## Proceso que la genera

### Archivo PowerBI

- `E:/.../reportes/AuditoriaMedica/AuditoriaMedicaV2.pbix`

### Scripts R que alimentan el reporte

- `ImportesAuditoriaMedica.R` → `auditoria_medica_importe`
- `UsuariosAuditoriaMedica.R` → `auditoria_medica_usuarios`
- `TablaCentroCostos.R` → `auditoria_medica_centros`
- `Script_AuditoriaMedica_Funciones.R` (helpers)

### Repositorio histórico

- `Repositorio Auditoria Medica/AuditoriaImportes_2021.csv`

---

## Campos relevantes (visualizaciones)

Las tablas que alimentan el reporte contienen los siguientes campos clave:

- **Importes**: fecha, tipo_auditoria (Auditado / Auditado Médico), crg, cantidad_dph, clasifica (`>$200k` / `>$100k` / `>$50k` / `<$50k`), importe, tipo_importe (Original / Agregado).
- **Usuarios**: fecha_auditoria_medica, anio_emision_crg, mes_emision_crg, auditor, cantidad_crg, cantidad_dph, importe_original, agregado_importe, importe_final, centro_costo, sub_centro_costo.
- **Centros**: id_centro_costos, nombre_centro_costo, id_sub_centro_costo, nombre_sub_centro_costo.

---

## Reglas de negocio

### Filtro de auditoría real

Solo se consideran CRGs con al menos un movimiento en `crghistorial` con `crghistorialestado = 3` y `crghistorialcod >= 2`.

### Tipo de auditoría

| Condición | Resultado |
|---|---|
| Usuario en `medicos.xlsx` | Auditado Médico |
| Otro | Auditado |

### Clasificación por tramo

| Tramo | Condición |
|---|---|
| `>$200k` | importe_original > 200.000 |
| `>$100k` | importe_original > 100.000 |
| `>$50k`  | importe_original > 50.000 |
| `<$50k`  | resto |

### Apertura Original / Agregado

Cada CRG se desdobla en dos filas: importe original (final - agregado) e importe agregado (solo cuando `crgdetmotivodebcred = 42`).

### Lectura de credenciales

Se obtienen vía `parametros_servidor.xlsx` (host, user, password, database) usando la helper `GetArchivoParametros`.

---

## Estrategia de carga

Las tablas se reescriben (overwrite) o se cargan incrementalmente según script (ver `docs/tablas/auditoria_medica.md`). El reporte simplemente refresca contra esas tablas.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| crg | crg, comprobantecrgdet |
| centro_costo / sub_centro_costo | auditoria_medica_centros |
| auditor | medicos.xlsx |

---

## Uso funcional

Permite:

- Medir productividad de auditores médicos.
- Detectar agregados de importe por motivo 42.
- Clasificar CRGs por tramo de importe.
- Analizar volumen por centro de costo.

---

## Owner

DBA

---

## Archivo PBIX

`E:/.../reportes/AuditoriaMedica/AuditoriaMedicaV2.pbix`
