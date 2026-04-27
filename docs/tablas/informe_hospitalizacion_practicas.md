# Tabla: informes_hospitalizacion_practicas

## Descripción

Detalle de prácticas asociadas a un informe de hospitalización. Cada fila representa una línea (práctica) realizada dentro de una hospitalización, con su nomenclador, cantidad, fechas operativas, OP y estado.

Es el complemento detalle de `informes_hospitalizacion`: un informe puede tener N prácticas asociadas.

---

## Tipo

Hecho transaccional / detalle de prácticas hospitalarias.

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

- numero_informe
- practica

---

## Fuente origen

### Tablas transaccionales

- `informehosplinea`
- `nomencladortipovigencia`
- `nomenclador`

### Lookup externo

- `estados.xlsx` (vive en la propia carpeta `informe_hospitalizacion_practicas`)

---

## Proceso que la genera

### Script principal

- `E:/DataWarehouse/informe_hospitalizacion_practicas/main.R`

### Helper

- `E:/DataWarehouse/informe_hospitalizacion_practicas/Funciones_Helper.R`
- `E:/DataWarehouse/informe_hospitalizacion_practicas/Funciones_Helper_informe_hospitalizacion_practicas.R`

### Tabla destino

- `public.informes_hospitalizacion_practicas` (base SIF)

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | numero_informe | varchar | Sí | Número de informe de hospitalización |
| 2 | practica | int | Sí | Identificador de línea / práctica dentro del informe |
| 3 | fecha_y_hora | timestamp | Sí | Fecha y hora de la práctica |
| 4 | nomenclador_tipo | varchar | Sí | Tipo de nomenclador vigente (`nomencladortipovigenciacod`) |
| 5 | codigo_nomenclador | bigint | Sí | Código del nomenclador |
| 6 | descripcion | varchar | Sí | Nombre largo del nomenclador |
| 7 | cantidad | int | Sí | Cantidad de prácticas realizadas |
| 8 | nro_op | varchar | Sí | Número de OP asociada |
| 9 | fecha_carga_op | date | Sí | Fecha de carga de la OP |
| 10 | fecha_activacion | date | Sí | Fecha de activación de la OP |
| 11 | fecha_emision_op | date | Sí | Fecha de emisión de la OP |
| 12 | estado | varchar | Sí | Estado de la línea (enriquecido desde `estados.xlsx`) |
| 13 | fecha_turno | timestamp | Sí | Fecha de turno asignada |
| 14 | usuario_carga_cdetac | varchar | Sí | Usuario que cargó la conformidad de detalle |
| 15 | fecha_realizacion | timestamp | Sí | Fecha de realización efectiva |

---

## Reglas de negocio

### Rango de extracción

Se procesan los últimos **1800 días** (~5 años) filtrando por `informehosplineafecha BETWEEN fechaInicio AND fechaFin`.

### Enriquecimiento de nomenclador

Se hace `LEFT JOIN nomenclador` para traer `nomencladornombrelargo` y `LEFT JOIN nomencladortipovigencia` para traer `nomencladortipovigenciacod`.

### Decodificación de estado

Se cruza `id_estado` contra `estados.xlsx` para obtener la descripción legible.

---

## Estrategia de carga

Antes de insertar, se ejecuta:

```sql
DELETE FROM informes_hospitalizacion_practicas
WHERE fecha_y_hora BETWEEN fechaInicio AND fechaFin
```

Luego se inserta con `append = TRUE`. La carga es incremental por rango móvil de 1800 días.

---

## Relaciones principales

| Campo destino | Tabla relacionada |
|---|---|
| numero_informe | informes_hospitalizacion |
| nro_op | autorizaciones_practicas |
| codigo_nomenclador | nomenclador |

---

## Uso funcional

Permite:

- Ver todas las prácticas asociadas a un informe de hospitalización.
- Análisis de prácticas por nomenclador.
- Cruce con OP de autorización.
- Auditoría de prácticas realizadas vs autorizadas.

---

## Owner

DBA

---

## Script generador

`E:/DataWarehouse/informe_hospitalizacion_practicas/main.R`
