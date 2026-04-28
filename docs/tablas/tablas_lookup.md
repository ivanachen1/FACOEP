# Proceso: tablas_lookup

## Descripción

Proceso transversal que materializa en la base SIF un conjunto de **tablas lookup / dimensiones** que se utilizan como catálogos en el resto del DW. Algunas se generan a partir de Excel mantenidos manualmente y otras se construyen a partir de queries directas a la base de Producción.

No es una tabla única: es un proceso que carga (en una sola corrida) las siguientes tablas destino:

| Tabla destino | Origen | Estrategia |
|---|---|---|
| `estados_crg` | `crg_estados.xlsx` | overwrite |
| `financiadores` | `Financiadores.xlsx` (con regla de negocio) | overwrite |
| `tipos_comprobantes` | `tipos_comprobantes.xlsx` | overwrite |
| `efectores` | Query a `proveedorprestador` | upsert via staging + delete missing |
| `clientes` | Query a `clientes` | overwrite |
| `centro_costos` | Query a `centrocostos` | overwrite |
| `grupos_prestaciones` | `grupo_prestaciones.xlsx` | overwrite |
| `nomenclador` | Query a `nomenclador` + cruce con `tipo_nomenclador.xlsx` | overwrite |
| `origenes` | `Origen.xlsx` | overwrite |

---

## Tipo

Proceso de mantenimiento de dimensiones / catálogos.

---

## Frecuencia

Diaria.

---

## Fuente origen

### Tablas transaccionales (Producción)

- `proveedorprestador`
- `clientes`
- `centrocostos`
- `nomenclador`

### Lookup externo (Excel en `E:/DataWarehouse/tablas_lookup/files`)

- `crg_estados.xlsx`
- `crg_estados_tabla_historial.xlsx` (consumido por `crg_historial`)
- `Financiadores.xlsx`
- `tipos_comprobantes.xlsx`
- `grupo_prestaciones.xlsx`
- `tipo_nomenclador.xlsx`
- `tipo_prestacion.xlsx`
- `tabla_apertura.xlsx`
- `Origen.xlsx`

### Archivos de control

En `E:/DataWarehouse/tablas_lookup/control_files`:

- `centrocostos_control.csv`
- `clientes_control.csv`
- `efectores_control.csv`

---

## Proceso que la genera

### Script principal

- `E:/DataWarehouse/tablas_lookup/main.R`

### Helper

- `E:/DataWarehouse/tablas_lookup/Funciones_Helper.R`
- `E:/DataWarehouse/tablas_lookup/Funciones_Helper_tablas_lookup.R`

### Tablas destino

Todas en la base SIF (`10.22.1.44 / SIF`).

---

## Esquema de cada tabla

### estados_crg

Lectura directa del Excel `crg_estados.xlsx`. Se usa en `crg.estado_actual`.

### financiadores

| Campo | Descripción |
|---|---|
| financiador | Nombre del financiador |
| tipo_cobertura | Tipo de cobertura (con regla: si el nombre contiene "OBRA SOCIAL" se sobreescribe a "OOSS y Prepagas") |
| fecha_ejecucion | Fecha de la corrida |

### tipos_comprobantes

Lectura directa del Excel `tipos_comprobantes.xlsx`.

### efectores

| Campo | Descripción |
|---|---|
| id_proveedor | `pprid` |
| nombre_proveedor | `pprnombre` con TRIM |
| efector | `id_proveedor-nombre_proveedor` |
| id_sigehos | `pprcodsigehos` |
| fecha_ejecucion | Fecha de la corrida |

### clientes

| Campo | Descripción |
|---|---|
| id | `clienteid` |
| nombre_cliente | `clientenombre` con TRIM |
| cuit | `clientecuit` |
| financiador | `id-nombre_cliente` |

### centro_costos

| Campo | Descripción |
|---|---|
| id | `ccostocodigo` |
| nombre_centro | `ccostoabreviatura` |
| fecha_ejecucion | Fecha de la corrida |

### grupos_prestaciones

Lectura directa de `grupo_prestaciones.xlsx`.

### nomenclador

| Campo | Descripción |
|---|---|
| id | `nomencladortipo` |
| codigo | `nomencladorcodigo` con TRIM |
| prestacion | `nomencladorprestacion` con TRIM |
| fecha_alta | `nomencladorfechaalta` |
| descripcion | `nomencladornombrelargo` |
| importe | `nomencladorimporte` |
| nomenclador_totales | `nomencladortotales` |
| (campos enriquecidos desde `tipo_nomenclador.xlsx`) | descripción del tipo |
| fecha_ejecucion | Fecha de la corrida |

### origenes

Lectura directa del Excel `Origen.xlsx`.

---

## Reglas de negocio

### Estrategia general

- Por defecto, las tablas se reemplazan completas (`overwrite = TRUE`) usando la función `PostgresProcess`.
- `efectores` es la excepción: tiene **upsert por id_proveedor** mediante una tabla staging.

### Upsert de efectores

```sql
DROP TABLE IF EXISTS efectores_staging;
CREATE TABLE efectores_staging (LIKE efectores INCLUDING DEFAULTS);
-- carga del DF a staging
INSERT INTO efectores (...)
SELECT ... FROM efectores_staging
ON CONFLICT (id_proveedor) DO UPDATE
SET nombre_proveedor = EXCLUDED.nombre_proveedor,
    efector          = EXCLUDED.efector,
    fecha_ejecucion  = EXCLUDED.fecha_ejecucion,
    id_sigehos       = EXCLUDED.id_sigehos;

-- delete missing
DELETE FROM efectores e
WHERE NOT EXISTS (
    SELECT 1 FROM efectores_staging s
    WHERE s.id_proveedor = e.id_proveedor
);
```

Esto deja `efectores` exactamente igual al DataFrame, sin tirar la tabla.

### Regla específica de financiadores

```r
verificador <- str_detect(Financiadores$Financiador, "OBRA SOCIAL")
Tipo.Cobertura <- ifelse(verificador, "OOSS y Prepagas", Tipo.Cobertura)
```

### Validación de longitud (centro_costos)

Antes de cargar `centro_costos`, se compara el conteo del query contra el archivo de control `centrocostos_control.csv` con `isCorrectLen`.

### Marcado de fecha_ejecucion

Las tablas `efectores`, `centro_costos`, `nomenclador` y `financiadores` reciben un campo `fecha_ejecucion = Sys.Date()` para auditoría.

---

## Estrategia de carga

| Tabla | Estrategia |
|---|---|
| estados_crg | overwrite |
| financiadores | overwrite |
| tipos_comprobantes | overwrite |
| efectores | upsert via staging + delete missing |
| clientes | overwrite |
| centro_costos | overwrite (con validación previa) |
| grupos_prestaciones | overwrite |
| nomenclador | overwrite (`dbWriteTable` directo) |
| origenes | overwrite |

---

## Uso funcional

Estas tablas funcionan como **dimensiones del DW** y son consumidas por casi todos los procesos:

- `crg`, `crg_historial` → `estados_crg`, `crg_estados_tabla_historial`
- `comprobantecrg`, `comprobantecrgdet`, `wwcomprobantes` → `tipos_comprobantes`, `clientes`, `efectores`, `origenes`
- `recupero_gastos`, `comprobantes_asociados` → `tabla_apertura`
- `informes_hospitalizacion`, `autorizaciones` → catálogos compartidos

---

## Owner

DBA

---

## Script generador

`E:/DataWarehouse/tablas_lookup/main.R`
