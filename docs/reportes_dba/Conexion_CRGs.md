# Reporte: Conexion CRGs

## Descripción

Proceso Python que **se conecta a las bases MySQL de Sigehos** (todos los hospitales del GCBA) y extrae diariamente CRGs, DPHs y Anexos de FACOEP-PAMI para consolidarlos en una base PostgreSQL local (`sigehos_recupero`). Es la fuente de datos detrás de los reportes de Recupero de Gastos / Conexión SIF-Sigehos.

Se ejecuta orquestado por un `.bat` y persiste los resultados en 3 tablas Postgres locales.

---

## Tipo

Proceso de integración (ETL) MySQL → PostgreSQL.

---

## Frecuencia

Diaria (vía `Run_Script.bat` programado).

---

## Primary Key sugerida

### crg_recupero
- numero + financiador_sigla + origin

### dph_recupero
- numero + nro_crg + origin

### anexos_recupero
- nro_anexo + origin

---

## Fuente origen

### Bases MySQL Sigehos

- Host: `asi-prod-bbdd-slave.gcba.gob.ar`
- Puerto: `3306`
- Listado de bases en `databases.xlsx` y `Bases de datos Sigehos.csv` (una por hospital, formato `sigehoslgc_<hospital>`).

### Tablas MySQL consultadas

- `CRG`, `tipo_anexo`, `DiccEstado`, `obrasocial` (CRGs).
- `CPH`, `paciente` (DPHs).
- `remito`, `RelRemitoNomenclador`, `especialidad_fact` (Anexos).

---

## Proceso que la genera

### Script principal

- `connection_PHPMyAdmin.py`

### Helper

- `HelperFunctions.py`

### Lanzador

- `Run_Script.bat`

### Tablas destino (Postgres local `sigehos_recupero`)

- `crg_recupero`
- `dph_recupero`
- `anexos_recupero`

---

## Campos

### crg_recupero

| # | Campo | Descripción |
|---|---|---|
| 1 | fecha | Fecha de emisión del CRG |
| 2 | numero | Número de CRG |
| 3 | tipo_anexo | Descripción del tipo de anexo |
| 4 | estado | Descripción del estado |
| 5 | cant_dphs | Cantidad de DPHs asociados |
| 6 | financiador_sigla | Sigla de la obra social |
| 7 | financiador_nombre | Nombre de la obra social |
| 8 | importe_total | Importe total del CRG |
| 9 | origin | Identifica el hospital de origen (nombre de la base MySQL) |

### dph_recupero

| # | Campo | Descripción |
|---|---|---|
| 1 | fecha | Fecha de creación del DPH |
| 2 | numero | Número de DPH |
| 3 | tipo_anexo | Tipo de anexo |
| 4 | estado | Estado |
| 5 | nro_crg | Número del CRG asociado |
| 6 | financiador_sigla | Sigla de la obra social |
| 7 | financiador_nombre | Nombre de la obra social |
| 8 | apellidos | Apellido del paciente |
| 9 | nombres | Nombre del paciente |
| 10 | documento | Documento del paciente |
| 11 | importe_total | Importe total del DPH |
| 12 | origin | Hospital de origen |

### anexos_recupero

| # | Campo | Descripción |
|---|---|---|
| 1 | fecha | Fecha del anexo |
| 2 | nro_anexo | Número de anexo |
| 3 | apellidos | Apellido del paciente |
| 4 | nombres | Nombre del paciente |
| 5 | documento | Documento del paciente |
| 6 | tipo_anexo | Tipo de anexo |
| 7 | financiador_sigla | Sigla de la obra social |
| 8 | financiador_nombre | Nombre de la obra social |
| 9 | especialidad | Especialidad de facturación |
| 10 | importe | Suma de `RelRemitoNomenclador.ImporteTotal` para el remito |
| 11 | origin | Hospital de origen |

---

## Reglas de negocio

### Rangos de extracción

- CRGs y DPHs: últimos **365 días**.
- Anexos: desde el **1 del mes en curso** hasta el día actual.

### Filtro Anexos

Solo se traen anexos con `obrasocial.os_nombre = 'FACOEP PAMI'`.

### Loop por base MySQL

El script itera por todos los hospitales del GCBA listados en `databases.xlsx`, ejecuta el query en cada base en batches (`define_batch = 10`) y consolida en un único DataFrame con la columna `origin` para identificar el hospital.

### Conexión MySQL

Se usa `mysql.connector` y se setea la base activa con `cursor.execute('USE {database};')` antes de cada query.

### Conexión PostgreSQL

Base local `sigehos_recupero` en `localhost:5432` (usuario `postgres`).

---

## Estrategia de carga

Por cada tabla destino:

1. Se obtiene el DataFrame consolidado de todos los hospitales.
2. Se ejecuta `aux.delete_part(conn, table, date1, date2)` para borrar el rango procesado.
3. Se inserta con `aux.Postgres_Insert_values(conn, df, table)`.

Es decir: **delete + insert** por rango, equivalente a un append incremental con limpieza previa.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| numero (CRG) | crg / comprobantecrg (sistema SIF) — usado por reporte `CRG SIF-Sigehos` |
| documento | afiliado |

---

## Uso funcional

Permite:

- Tener una copia local consolidada de los CRGs / DPHs / Anexos que vive en cada hospital.
- Comparar contra el sistema SIF (reporte `CRG SIF-Sigehos`).
- Alimentar reporting de Recupero de Gastos.

---

## Owner

DBA

---

## Script generador

`E:/.../reportes/Conexion CRGs/connection_PHPMyAdmin.py`
