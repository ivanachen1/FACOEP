# Tabla: crg_historial

## Descripción

Histórico de movimientos de estado de los CRGs. Cada fila representa un cambio de estado de un CRG, con la fecha, el usuario que lo realizó, observación libre y el estado decodificado.

Permite reconstruir la trazabilidad temporal del CRG (quién y cuándo cambió cada estado), medir tiempos entre estados y armar tableros de seguimiento operativo.

---

## Tipo

Hecho transaccional / histórico de cambios de estado.

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

- id_proveedor
- nro_crg
- fecha
- id_estado

---

## Fuente origen

### Tablas transaccionales

- `crghistorial`
- `proveedorprestador`

### Lookup externo

- `crg_estados_tabla_historial.xlsx` (vive en `E:/DataWarehouse/tablas_lookup/files`)

---

## Proceso que la genera

### Script principal

- `E:/DataWarehouse/crg_historial/main.R`

### Helper

- `E:/DataWarehouse/crg_historial/Funciones_Helper.R`
- `E:/DataWarehouse/crg_historial/Funciones_Helper_crg_historial.R`

### Tabla destino

- `public.crg_historial` (base SIF)

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | id_proveedor | int | Sí | Identificador del proveedor / efector |
| 2 | nombre_proveedor | varchar | Sí | Nombre del proveedor (con TRIM) |
| 3 | nro_crg | int | Sí | Número de CRG |
| 4 | fecha | timestamp | Sí | Fecha y hora del movimiento |
| 5 | id_estado | int | Sí | Código numérico del estado |
| 6 | observacion | varchar | Sí | Observación libre del movimiento |
| 7 | usuario | varchar | Sí | Usuario que realizó el cambio |
| 8 | estado | varchar | Sí | Descripción del estado (enriquecida desde lookup) |

---

## Reglas de negocio

### Rango de extracción

Se procesan los últimos **360 días** filtrando por `crghistorialfecha BETWEEN fechaInicio AND fechaFin`.

### Vinculación con proveedor

Se hace `LEFT JOIN proveedorprestador ON pprid` para obtener el nombre del efector.

### Conversión de fecha

`fecha` se castea a character antes de insertar para preservar el formato original sin conversiones de zona horaria.

### Enriquecimiento de estado

Se cruza `id_estado` contra el Excel `crg_estados_tabla_historial.xlsx` para traer la descripción legible del estado.

### Catálogo de estados (mismo set que `estados_crg`)

| id | estado |
|---|---|
| 1 | Ingresado |
| 2 | Remitido |
| 3 | Proforma |
| 4 | Facturado |
| 5 | Remitir Factura |
| 6 | Envio GCBA |
| 7 | Liquido Producto |
| 8 | Comisiones Liquidadas |
| 9 | Auditado |
| 10 | Pendiente Medico |
| 11 | Asignado |
| 12 | Pendiente Administrativo |
| 13 | Pendiente Corrección |
| 14 | Reingresado |
| 15 | Eliminado |
| 16 | Eliminado por el Efector |
| 17 | Pendiente Correccion FACOEP |
| 18 | No Facturable |

> Este catálogo es el mismo que el de `estados_crg` (ver `docs/tablas/tablas_lookup.md`). En `crg_historial` cada fila representa un movimiento de estado, por lo que el `id_estado` puede tomar cualquiera de estos valores en la línea de tiempo del CRG.
>
> **Para queries sobre transiciones de estado:**
> - "Cuándo se ingresó un CRG" → `WHERE id_estado = 1` y tomar `MIN(fecha)`.
> - "Cuándo se facturó" → `WHERE id_estado = 4`.
> - "Cuándo se auditó" → `WHERE id_estado = 9`.

### Limpieza

`nombre_proveedor` se aplica `str_trim`.

---

## Estrategia de carga

Antes de insertar, se ejecuta:

```sql
DELETE FROM crg_historial
WHERE fecha BETWEEN fechaInicio AND fechaFin
```

Luego se inserta con `append = TRUE`. La carga es incremental por rango móvil de 360 días.

---

## Relaciones principales

| Campo destino | Tabla relacionada |
|---|---|
| nro_crg + id_proveedor | crg |
| nro_crg + id_proveedor | detallecrg |
| id_estado | tabla lookup `crg_estados_tabla_historial.xlsx` |

---

## Uso funcional

Permite:

- Reconstruir línea de tiempo de un CRG.
- Medir SLA entre estados (tiempo desde alta hasta auditoría, hasta facturación, etc.).
- Identificar quiénes cambian estados con mayor frecuencia.
- Detectar movimientos anómalos o reversiones.

---

## Owner

DBA

---

## Script generador

`E:/DataWarehouse/crg_historial/main.R`
