# Tabla: auditoria_medica

## Descripción

Conjunto de tres tablas relacionadas a la auditoría médica de CRGs. Permite analizar la actividad de los auditores, los importes auditados, agregados o debitados, y enriquecer la información con datos de centros de costo.

Las tres tablas son:

- `auditoria_medica_importe`: Histórico clasificado de importes auditados por CRG y tipo de auditoría (Auditado / Auditado Médico).
- `auditoria_medica_usuarios`: Actividad por auditor para el año en curso, con apertura por centro de costo.
- `auditoria_medica_centros`: Catálogo de centros de costo y subcentros utilizado para enriquecer los demás procesos.

---

## Tipo

Hechos transaccionales (importe / usuarios) + dimensión (centros de costo).

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

### auditoria_medica_importe

- id (concatenación de fecha + tipo_auditoria + crg)

### auditoria_medica_usuarios

- fecha_auditoria_medica
- auditor
- centro_costo
- sub_centro_costo
- anio_emision_crg
- mes_emision_crg

### auditoria_medica_centros

- id (id_centro_costos-id_sub_centro_costo)

---

## Fuente origen

### Tablas transaccionales (Producción)

- `crg`
- `crgdet`
- `crghistorial`
- `centrocostos`
- `subcentrocostos`

### Lookup externo

- `medicos.xlsx` (lista de auditores categorizados como "Auditor Médico")

---

## Proceso que la genera

### Scripts

- `E:/DataWarehouse/auditoria_medica/ImportesAuditoriaMedica.R` → genera `auditoria_medica_importe`
- `E:/DataWarehouse/auditoria_medica/UsuariosAuditoriaMedica.R` → genera `auditoria_medica_usuarios`
- `E:/DataWarehouse/auditoria_medica/TablaCentroCostos.R` → genera `auditoria_medica_centros`

### Helpers

- `Script_AuditoriaMedica_Funciones.R`

### Tablas destino

- `public.auditoria_medica_importe`
- `public.auditoria_medica_usuarios`
- `public.auditoria_medica_centros`

---

## Campos

### auditoria_medica_importe

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | fecha | timestamp | Sí | Fecha de auditoría (última fecha de `crghistorial` con estado 3 y código >= 2) |
| 2 | tipo_auditoria | varchar | Sí | "Auditado Médico" si el usuario figura en `medicos.xlsx`, "Auditado" en caso contrario |
| 3 | crg | int | Sí | Número de CRG |
| 4 | cantidad_dph | int | Sí | Cantidad de DPH agrupados (1 por CRG en filas Original; 0 en filas Agregado) |
| 5 | clasifica | varchar | Sí | Tramo de importe: `>$200k`, `>$100k`, `>$50k`, `<$50k` |
| 6 | importe | decimal | Sí | Importe del CRG (Original o Agregado según `tipo_importe`) |
| 7 | tipo_importe | varchar | Sí | "Original" o "Agregado" |
| 8 | id | varchar | Sí | Concatenación `fecha + tipo_auditoria + crg` |

### auditoria_medica_usuarios

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | fecha_auditoria_medica | date | Sí | Fecha en que el auditor médico realizó la auditoría |
| 2 | anio_emision_crg | int | Sí | Año de emisión del CRG |
| 3 | mes_emision_crg | int | Sí | Mes de emisión del CRG |
| 4 | auditor | varchar | Sí | Usuario auditor (sin espacios) |
| 5 | cantidad_crg | int | Sí | Cantidad de CRG auditados |
| 6 | cantidad_dph | int | Sí | Cantidad de DPH auditados |
| 7 | importe_original | decimal | Sí | Importe original (final - agregado) |
| 8 | agregado_importe | decimal | Sí | Importe agregado por motivo 42 |
| 9 | importe_final | decimal | Sí | Importe bruto del CRG |
| 10 | centro_costo | int | Sí | Código de centro de costo |
| 11 | sub_centro_costo | int | Sí | Código de subcentro de costo |
| 12 | id_centros_costos | varchar | Sí | Concatenación `centro_costo-sub_centro_costo` |

### auditoria_medica_centros

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | id_centro_costos | int | Sí | Código de centro de costo |
| 2 | nombre_centro_costo | varchar | Sí | Abreviatura del centro de costo |
| 3 | id_sub_centro_costo | int | Sí | Código de subcentro |
| 4 | nombre_sub_centro_costo | varchar | Sí | Descripción del subcentro |
| 5 | id | varchar | Sí | Concatenación `id_centro_costos-id_sub_centro_costo` |

---

## Reglas de negocio

### Filtro de auditoría real

Solo se consideran CRGs que tengan al menos un movimiento en `crghistorial` con `crghistorialestado = 3` y `crghistorialcod >= 2`. La fecha de auditoría se toma como el `MAX(crghistorialfecha)` que cumpla esa condición.

### Determinación de "Auditor Médico"

Se considera "Auditado Médico" cuando el usuario que cerró la auditoría está incluido en la lista del Excel `medicos.xlsx`. Caso contrario se etiqueta como "Auditado".

### Clasificación por tramo de importe (auditoria_medica_importe)

| Tramo | Condición |
|---|---|
| `>$200k` | importe_original > 200.000 |
| `>$100k` | importe_original > 100.000 |
| `>$50k`  | importe_original > 50.000 |
| `<$50k`  | resto |

### Apertura Original / Agregado

Cada CRG se desdobla en dos filas:

- **Original**: importe original del CRG (final - agregado).
- **Agregado**: importe agregado únicamente cuando `crgdetmotivodebcred = 42`. Si es 0 no se inserta.

### Rango temporal

- `auditoria_medica_importe` se genera para el rango fijo `2021-01-01` a `2021-06-30` (histórico cerrado, no se reprocesa).
- `auditoria_medica_usuarios` se genera para el año en curso (`max_year`).

### Ajuste de fecha de auditoría médica

Para `auditoria_medica_usuarios`, si la `crgauditoriamedicafecha` es `0001-01-01`, nula, o anterior al 2021-01-01, se reemplaza por la fecha real de auditoría obtenida de `crghistorial`.

---

## Estrategia de carga

### auditoria_medica_importe

- `overwrite = TRUE`, `append = FALSE` → reemplaza la tabla completa.

### auditoria_medica_usuarios

- Se borra previamente todo el rango con `DELETE FROM auditoria_medica_usuarios WHERE anio_emision_crg = {max_year}`.
- Luego se inserta con `append = TRUE`.

### auditoria_medica_centros

- `overwrite = TRUE`, `append = FALSE` → reemplaza la tabla completa.

---

## Relaciones principales

| Campo destino | Tabla relacionada |
|---|---|
| crg | crg |
| centro_costo / sub_centro_costo | auditoria_medica_centros |

---

## Uso funcional

Permite:

- Medir productividad y carga de auditores médicos.
- Auditar importes agregados / debitados por motivo.
- Clasificar CRGs por tramo de importe.
- Analizar volumen de auditoría por centro de costo.
- Alimentar el tablero PowerBI `AuditoriaMedica.pbix`.

---

## Owner

DBA

---

## Scripts generadores

- `E:/DataWarehouse/auditoria_medica/ImportesAuditoriaMedica.R`
- `E:/DataWarehouse/auditoria_medica/UsuariosAuditoriaMedica.R`
- `E:/DataWarehouse/auditoria_medica/TablaCentroCostos.R`
