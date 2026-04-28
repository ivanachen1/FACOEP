# Reporte: Convenio PAMI

## Descripción

Reporte PowerBI que monitorea el **convenio capitado de PAMI**: internaciones programadas y no programadas, separadas por modo (Cápita / ExtraCápita), diagnóstico (CoVid 19 / Otros) y sala (UTI, UCO, NEO, PISO, GUARDIA). Genera tanto un snapshot de internaciones de hoy como una serie histórica diaria por sala/diagnóstico.

Está orientado a seguimiento epidemiológico y operativo del convenio.

---

## Tipo

Reporte / dashboard de seguimiento de convenio capitado.

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

N/A (las salidas son agregadas por fecha / sala / diagnóstico).

---

## Fuente origen

### Tablas transaccionales (Producción `Facoep`)

- `informehosp`
- `informehospunidad`
- `proveedorprestador`
- `diagnosticos`
- `afiliado`

### Lookup externo

- `Efectores considerados.xlsx`
- `salas.xlsx`
- `informehospprestmodo.xlsx`
- `Nueva Internaciones 2020.xlsx`
- `parametros_servidor.xlsx`

---

## Proceso que la genera

### Archivo PowerBI

- `E:/.../reportes/Convenio PAMI/Convenio PAMI.pbix`

### Scripts R

- `Script HistoricoFinal.R` (script principal)
- `script_limpieza_tablas.R`
- `ConvenioPami_Funciones.R` (helpers)

---

## Campos relevantes

### InternacionesHoy / Historico

| Campo | Descripción |
|---|---|
| InformeNro | Número de informe |
| Ingreso | Fecha y hora de ingreso |
| Egreso | Fecha y hora de egreso (NULL si sigue internado) |
| Efector | Hospital |
| Sala | Sala (UTI / UCO / NEO / PISO / GUARDIA) |
| Afiliado | Apellido y nombre |
| Documento | DNI |
| Beneficio | Número de beneficio PAMI |
| Capita | "Capita" o "ExtraCapita" |
| Programada | "Programada" / "No Programada" |
| Diagnostico | "CoVid 19" o "Otros" |
| Estadia | Días desde el ingreso |

### Series históricas (HistCapCov..., HistCapOtr...)

| Campo | Descripción |
|---|---|
| Fecha | Fecha del día |
| Cantidad | Cantidad de pacientes internados ese día |
| Capita | "Capita" |
| Diagnostico | "CoVid 19" / "Otros" |
| Sala | UTI / UCO / NEO / PISO / GUARDIA |

---

## Reglas de negocio

### Filtros del query

- `afitpamiprofe = 1` (afiliado PAMI).
- `InformeHospBajaFecha IS NULL` (informes activos).
- `informehospingresofechahora > '2017-01-01'`.
- `informehospprogramada IS NULL` (no programadas).
- `informehospefectorid IN (lista de Efectores considerados)`.

### Decodificación de modo

| Origen (`informehospprestmodo`) | modo |
|---|---|
| 1 | Capita |
| Otro | ExtraCapita |

### Decodificación de diagnóstico

`diagnostico = "CoVid 19"` cuando la descripción contiene `"CORONAV"`. Caso contrario `"Otros"`.

### Determinación de programado

`programa = "Programada"` cuando `informehospprogramada IS NOT NULL`. Caso contrario `"No Programada"`.

### Resolución de duplicados por informe

Se ordena por `nro` y `informehospunidadid` descendente y se queda con el primer registro por `nro` (la unidad más reciente).

### Cálculo de estadía

`Dias = Sys.Date() - fechaingreso` redondeado.

### Series históricas por sala

Para cada combinación `(Capita, Diagnostico, Sala)` se construye una serie diaria entre `min(Ingreso)` y `max(Egreso)` contando, por día, cuántos pacientes estaban dentro del intervalo `[Ingreso, Egreso]`. Si `Egreso` es NULL se reemplaza por `Sys.time()`.

### Filtro temporal del historial

Se filtra por `Fecha > '2021-01-01'`.

### Salas consideradas

UTI, UCO, NEO, PISO, GUARDIA.

---

## Estrategia de carga

El script trabaja en memoria y alimenta directamente al `.pbix`. No se persiste en tabla destino salvo donde lo haga el script de limpieza (`script_limpieza_tablas.R`).

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| informehospnro | informes_hospitalizacion |
| afinumbeneficio | afiliado |
| informehospefectorid | proveedorprestador |
| informehospunidadinternacion | salas.xlsx |

---

## Uso funcional

Permite:

- Monitorear ocupación CoVid vs. otros diagnósticos por sala.
- Ver internaciones activas hoy.
- Tracking del cumplimiento del convenio capitado PAMI.
- Análisis de estadía media.

---

## Owner

DBA

---

## Archivo PBIX

`E:/.../reportes/Convenio PAMI/Convenio PAMI.pbix`
