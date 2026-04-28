# Tabla: autorizaciones_practicas

## Descripción

Detalle de líneas de autorización (prácticas autorizadas) por orden de autorización. Contiene cada práctica solicitada / facturada, su nomenclador, cantidad, fechas operativas, estado y origen. Son para las prestaciones ambulatorios

Es el complemento detalle de la tabla `autorizaciones`: una autorización puede tener N líneas (prácticas) asociadas.

---

## Tipo

Hecho transaccional / detalle de prácticas autorizadas.

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

- nro_orden
- linea

---

## Fuente origen

### Tablas transaccionales

- `autorizacionlinea`
- `nomenclador`
- `autorizacion`

### Lookup externo

- `estados.xlsx` (compartido con `informe_hospitalizacion_practicas`)

---

## Proceso que la genera

### Script principal

- `E:/DataWarehouse/autorizaciones_practicas/main.R`

### Helper

- `E:/DataWarehouse/autorizaciones_practicas/Funciones_Helper.R`
- `E:/DataWarehouse/autorizaciones_practicas/Funciones_Helper_autorizaciones_linea.R`

### Tabla destino

- `public.autorizaciones_practicas` (base SIF)

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | nro_orden | varchar | Sí | Número de orden de la autorización |
| 2 | linea | int | Sí | Identificador de línea dentro de la autorización |
| 3 | codigo_nomenclador | varchar | Sí | Código de nomenclador de la práctica |
| 4 | nomenclador_nombre | varchar | Sí | Nombre / descripción del nomenclador |
| 5 | id_tipo_nomenclador | int | Sí | Identificador del tipo de nomenclador |
| 6 | vigente | bool | Sí | Indica si el nomenclador está habilitado |
| 7 | cantidad | numeric | Sí | Cantidad de prácticas autorizadas |
| 8 | op | varchar | Sí | Número de OP asociada |
| 9 | fecha_carga_op | timestamp | Sí | Fecha de carga de la OP |
| 10 | fecha_activacion_op | timestamp | Sí | Fecha de activación de la OP |
| 11 | fecha_emision_op | timestamp | Sí | Fecha de emisión de la OP |
| 12 | fecha_alta_autorizacion | timestamp | Sí | Fecha de alta de la autorización contenedora |
| 13 | estado | varchar | Sí | Estado de la línea (decodificado, ver mapping abajo) |
| 14 | origen | varchar | Sí | Origen de la línea: Solicitada / Facturada / Solicitada Facturada |
| 15 | fecha_turno | timestamp | Sí | Fecha de turno asignada |
| 16 | usuario_carga_cdetac | varchar | Sí | Usuario que cargó la conformidad / detalle activación |
| 17 | fecha_realizacion | timestamp | Sí | Fecha en que se realizó la práctica |
| 18 | fecha_realizacion_autorizacion | timestamp | Sí | Fecha de realización registrada en la autorización |
| 19 | info_prestador | varchar | Sí | Información cargada por el prestador |

---

## Reglas de negocio

### Filtro principal

Se procesa el rango móvil de los últimos **365 días** filtrando por `au.autorizacionfechaalta BETWEEN fechaInicio AND fechaFin`.

### Decodificación de estado

| Origen (`autorizacionlineaestado`) | Resultado |
|---|---|
| 1 | Pendiente |
| 2 | Autorizado |
| 3 | Rechazo Conformado |
| 4 | Rechazado |
| 5 | Pendiente de Documentacion |
| 6 | Autorizado con Observacion |

### Decodificación de origen

| Origen (`autorizacionlineaorigen`) | Resultado |
|---|---|
| 1 | Solicitada |
| 2 | Facturada |
| 3 | Solicitada Facturada |

### Enriquecimiento de nomenclador

El join con `nomenclador` por `autorizacionlineanomenclador = nomencladorcodigo` aporta nombre y vigencia del código.

---

## Estrategia de carga

Antes de insertar, se ejecuta:

```sql
DELETE FROM autorizaciones_practicas
WHERE fecha_realizacion BETWEEN fechaInicio AND fechaFin
```

Luego se inserta con `append = TRUE`. La carga es incremental por rango móvil de 365 días.

---

## Relaciones principales

| Campo destino | Tabla relacionada |
|---|---|
| nro_orden | autorizaciones |
| codigo_nomenclador | nomenclador |
| op | informe_hospitalizacion_practicas |

---

## Uso funcional

Permite:

- Ver todas las prácticas asociadas a una autorización.
- Analizar prácticas por nomenclador, estado y origen.
- Detectar prácticas pendientes, rechazadas o con observación.
- Cruzar con `informe_hospitalizacion_practicas` por OP.

---

## Owner

DBA

---

## Script generador

`E:/DataWarehouse/autorizaciones_practicas/main.R`
