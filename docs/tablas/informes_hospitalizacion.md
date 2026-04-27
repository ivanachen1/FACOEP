# Tabla: informes_hospitalizacion

## Descripción

Tabla maestra de informes de hospitalización. Cada registro corresponde a un informe que documenta la internación de un afiliado, con información del efector, modalidad, médico interviniente, fechas (ingreso, egreso, baja), motivos, tipo de internación, estado de OP y datos del afiliado.

Es la cabecera de `informes_hospitalizacion_practicas` y se complementa con `autorizaciones` cuando aplica.

Adicionalmente, cada corrida persiste una imagen diaria en la tabla `informes_hospitalizacion_historical` para permitir comparaciones día a día (con retención de 60 días).

---

## Tipo

Hecho transaccional / cabecera de internación. Más una tabla histórica (snapshot diario).

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

### informes_hospitalizacion

- numero_informe

### informes_hospitalizacion_historical

- numero_informe
- fecha_imagen

---

## Fuente origen

### Tablas transaccionales

- `informehosp`
- `afiliado`
- `medico`
- `tipogeriatria`

### Lookup externo

- `Modalidad.xlsx`
- `estado_op.xlsx`
- `motivo_egreso.xlsx`
- `tipo_internacion.xlsx`
- `tipo_afiliado.xlsx`

---

## Proceso que la genera

### Script principal

- `E:/DataWarehouse/informes_hospitalizacion/main.R`

### Helper

- `E:/DataWarehouse/informes_hospitalizacion/Funciones_Helper.R`

### Tablas destino

- `public.informes_hospitalizacion` (base SIF, reemplazo total)
- `public.informes_hospitalizacion_historical` (base SIF_HISTORICAL, snapshot diario)

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | numero_informe | varchar | Sí | Número de informe de hospitalización |
| 2 | id_efector | int | Sí | Identificador del efector |
| 3 | afiliado | varchar | Sí | Número de beneficio del afiliado |
| 4 | familiar | varchar | Sí | ID de beneficio familiar |
| 5 | es_geriatria | bool | Sí | Indica si es geriatría |
| 6 | es_rehabilitacion | bool | Sí | Indica si es rehabilitación |
| 7 | afiliado_nombre | varchar | Sí | Apellido y nombre del afiliado |
| 8 | afiliado_motivo_baja | varchar | Sí | Motivo de baja del afiliado (con TRIM) |
| 9 | op | varchar | Sí | Número de OP asociada |
| 10 | importada_sigehos | bool | Sí | Marca si fue importada desde Sigehos |
| 11 | fecha_ingreso | timestamp | Sí | Fecha y hora de ingreso |
| 12 | fecha_egreso | timestamp | Sí | Fecha y hora de egreso |
| 13 | fecha_baja | date | Sí | Fecha de baja del informe |
| 14 | medico_interviniente | varchar | Sí | Apellido y nombre del médico |
| 15 | id_tipo_geriatria | int | Sí | Tipo de geriatría (-1 si no aplica) |
| 16 | tipo_geriatria_descripcion | varchar | Sí | Descripción del tipo de geriatría ("No Posee Geriatria" si NULL) |
| 17 | usuario_alta | varchar | Sí | Usuario que dio de alta el informe |
| 18 | tipo_modalidad | varchar | Sí | Modalidad enriquecida desde `Modalidad.xlsx` |
| 19 | estado_op | varchar | Sí | Estado de la OP (enriquecido desde `estado_op.xlsx`, "Sin OP" si NULL) |
| 20 | op_activada | varchar | Sí | "SI" / "NO" según `informehospprestordenactivacio` |
| 21 | motivo_egreso | varchar | Sí | Motivo de egreso (enriquecido, "No Egresó" si NULL) |
| 22 | tipo_internacion | varchar | Sí | Tipo de internación (enriquecido desde `tipo_internacion.xlsx`) |
| 23 | tiene_op | varchar | Sí | "Con número" / "Sin número" según valor de `op` |
| 24 | tipo_afiliado | varchar | Sí | Tipo de afiliado (enriquecido desde `tipo_afiliado.xlsx`) |
| 25 | fecha_imagen | date | Sí | Solo en `informes_hospitalizacion_historical`: fecha del snapshot (día anterior a la corrida) |

---

## Reglas de negocio

### Vinculación con afiliado

El join con `afiliado` usa la combinación `(afitpamiprofe, afinumbeneficio, afinumbenid)`.

### Vinculación con médico

`hosp.mednromatriculanac = medico.mednromatriculanac` para obtener nombre.

### Cálculo de op_activada

Si `informehospprestordenactivacio` es nulo → `op_activada = "NO"`, caso contrario `"SI"`. El campo `orden_activacion` se elimina luego.

### Cálculo de tiene_op

| Valor de `op` | tiene_op |
|---|---|
| 0 | Con número |
| Otro | Sin número |

### Determinación de salud mental (interna)

`salud_mental = TRUE` cuando `es_geriatria = TRUE` o `id_tipo_geriatria > 0`. (Función `EsSaludMental`, no necesariamente persistida.)

### Reemplazo de nulos

| Campo | Valor por defecto |
|---|---|
| id_tipo_geriatria | -1 |
| tipo_geriatria_descripcion | "No Posee Geriatria" |
| estado_op | "Sin OP" |
| motivo_egreso | "No Egresó" |

### Enriquecimiento por catálogos Excel

| Campo origen | Lookup | Resultado |
|---|---|---|
| id_modalidad | Modalidad.xlsx | tipo_modalidad |
| id_estado_op | estado_op.xlsx | estado_op |
| id_motivo_egreso | motivo_egreso.xlsx | motivo_egreso |
| id_tipo_internacion | tipo_internacion.xlsx | tipo_internacion |
| id_tipo_afiliado | tipo_afiliado.xlsx | tipo_afiliado |

Los identificadores técnicos se eliminan del DataFrame final.

---

## Estrategia de carga

### Tabla viva (`informes_hospitalizacion`)

- `overwrite = TRUE` → reemplazo total en cada corrida.

### Tabla histórica (`informes_hospitalizacion_historical`)

- Se asigna `fecha_imagen = Sys.Date() - 1`.
- Se borra todo el snapshot existente del día con:

```sql
DELETE FROM informes_hospitalizacion_historical
WHERE fecha_imagen = '{dia_anterior}'
```

- Luego se inserta con `append = TRUE`.
- Se purga el histórico mayor a 60 días:

```sql
DELETE FROM informes_hospitalizacion_historical
WHERE fecha_imagen < current_date - 60
```

Se escribe un archivo de control `control.csv` con la cantidad de registros insertados.

---

## Relaciones principales

| Campo destino | Tabla relacionada |
|---|---|
| numero_informe | informes_hospitalizacion_practicas |
| afiliado | afiliado |
| op | autorizaciones |
| id_efector | proveedorprestador |

---

## Uso funcional

Permite:

- Seguimiento de internaciones por afiliado, efector y médico.
- Análisis de motivos de egreso y tipo de internación.
- Cruce con prácticas hospitalarias.
- Comparación día a día sobre `informes_hospitalizacion_historical` (auditoría de cambios en la base operativa).

---

## Owner

DBA

---

## Script generador

`E:/DataWarehouse/informes_hospitalizacion/main.R`
