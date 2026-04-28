# Tabla: conteo_tablas

## Descripción

Proceso de monitoreo que recorre todas las tablas de los esquemas no-sistémicos en las bases PostgreSQL de Producción y Slave, contando la cantidad de filas de cada una. El resultado se persiste como un Excel diario con marca de fecha y entorno (`prd` / `slave`).

No genera una tabla en base de datos: la salida son archivos Excel en la carpeta `resultados`. Su propósito es servir de control de frescura / consistencia entre ambientes y detectar caídas o saltos abruptos de volumen por tabla.

---

## Tipo

Proceso de monitoreo / control. Output a archivo (no inserta en DB).

---

## Frecuencia

Diaria.

---

## Primary Key sugerida (en cada Excel)

- table_name
- date
- env (implícito en el nombre de archivo)

---

## Fuente origen

### Bases consultadas

- Producción: `10.22.1.60 / facoep`
- Slave: `10.22.1.61 / facoep`

### Tabla del catálogo PostgreSQL

- `pg_tables`

---

## Proceso que la genera

### Script principal

- `E:/DataWarehouse/conteo_tablas/main.py`

### Carpeta de salida

- `E:/DataWarehouse/Prd/conteo_tablas/resultados/`

### Nombre de archivo

`conteo_filas_postgres_{dia}_{mes}_{anio}_{env}.xlsx`

Donde `env` es `prd` o `slave`.

---

## Campos del Excel resultante

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | table_name | string | No | `schema.tabla` |
| 2 | row_count | int | Sí | Cantidad de filas (NULL si la consulta falló) |
| 3 | error | string | Sí | Mensaje de error si la consulta falló |
| 4 | date | date | No | Fecha de la corrida |

---

## Reglas de negocio

### Inventario de tablas

Se obtienen todas las tablas filtrando por:

```sql
SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
```

### Conteo por tabla

Para cada par `(schema, tabla)` se ejecuta `SELECT COUNT(*) FROM schema."tabla"`. Si falla, se captura el error y `row_count` queda NULL.

### Identificación del ambiente

Se determina por host:

| Host | env |
|---|---|
| 10.22.1.60 | prd |
| 10.22.1.61 | slave |

### Persistencia

Se guarda un Excel separado por entorno y por día. La ruta de salida se crea automáticamente si no existe.

---

## Estrategia de carga

No carga en base. Genera un archivo Excel por entorno y por día. Histórico acumulativo por archivo.

---

## Uso funcional

Permite:

- Detectar tablas que no crecen (potencial fallo de carga).
- Comparar volúmenes entre Producción y Slave (replicación / consistencia).
- Auditar la evolución diaria de volumen por tabla.
- Servir de input para alertas o tableros de control.

---

## Owner

DBA

---

## Script generador

`E:/DataWarehouse/conteo_tablas/main.py`
