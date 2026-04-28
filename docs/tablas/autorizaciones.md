# Tabla: autorizaciones

## Descripción

Tabla maestra de autorizaciones emitidas. Contiene información de la orden, prestador, solicitante, afiliado, prestación, fechas y estado, junto con los tipos enriquecidos desde catálogos externos (tipo de afiliado, modalidad y estado).

Permite analizar la actividad de autorizaciones por efector / solicitante, hacer seguimiento por afiliado y separar por modalidad o tipo de prestación.

---

## Tipo

Hecho transaccional / maestro de autorizaciones.

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

- numero_autorizacion
- nro_prestacion

---

## Fuente origen

### Tablas transaccionales

- `autorizacion`
- `afiliado`
- `proveedorprestador` (alias `solicitante`)

### Lookup externo

- `tipo_afiliado.xlsx`
- `modalidad_prestacion.xlsx`
- `estados.xlsx`

---

## Proceso que la genera

### Script principal

- `E:/DataWarehouse/autorizaciones/autorizaciones.R`

### Helper

- `E:/DataWarehouse/autorizaciones/Funciones_Helper.R`

### Tabla destino

- `public.autorizaciones` (base SIF)

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | numero_autorizacion | varchar | Sí | Número de orden de autorización (`autorizacionnroorden`) |
| 2 | prestador | varchar | Sí | ID del efector (`autorizacionprestador`) |
| 3 | solicitante | varchar | Sí | Nombre del proveedor solicitante |
| 4 | nro_prestacion | int | Sí | Número de prestación dentro de la autorización |
| 5 | fecha_realizacion | timestamp | Sí | Fecha del estudio / realización |
| 6 | fecha_facturacion | date | Sí | Fecha en que se facturó la autorización |
| 7 | nro_internacion | varchar | Sí | Número de internación asociada (si aplica) |
| 8 | es_salud_mental | bool | Sí | Indica si la autorización corresponde a salud mental |
| 9 | es_rehabilitacion | bool | Sí | Indica si la autorización corresponde a rehabilitación |
| 10 | numero_beneficiario | varchar | Sí | Número de beneficiario PAMI |
| 11 | afiliado | varchar | Sí | Apellido y nombre del afiliado |
| 12 | dni | int | Sí | DNI del afiliado |
| 13 | descripcion | varchar | Sí | Observación de la autorización |
| 14 | op | int | Sí | Número de orden de prestación (mismo origen que `nro_prestacion`) |
| 15 | usuario_alta | varchar | Sí | Usuario que dio de alta la autorización |
| 16 | fecha_alta | timestamp | Sí | Fecha de alta interna |
| 17 | usuario_carga_afip | varchar | Sí | Usuario que la cargó en PAMI/AFIP |
| 18 | fecha_carga_afip | timestamp | Sí | Fecha de carga en PAMI/AFIP |
| 19 | fecha | date | Sí | Fecha funcional de la autorización (NULL si era `0001-01-01`) |
| 20 | tipo_afiliado | varchar | Sí | Tipo de afiliado (enriquecido desde `tipo_afiliado.xlsx`) |
| 21 | tipo_modalidad | varchar | Sí | Modalidad de la prestación (enriquecida desde `modalidad_prestacion.xlsx`) |
| 22 | estado | varchar | Sí | Estado de la autorización (enriquecido desde `estados.xlsx`) |

---

## Reglas de negocio

### Filtro principal

Solo se procesan autorizaciones donde `autorizacionbaja = false`.

### Construcción del solicitante

Se trae el nombre del proveedor solicitante haciendo `LEFT JOIN proveedorprestador AS solicitante ON au.autorizacionsolicitante = solicitante.pprid` y aplicando `TRIM`.

### Vinculación con afiliado

El join con `afiliado` usa la combinación `(afinumbeneficio, afinumbenid, afitpamiprofe)` para garantizar correspondencia exacta.

### Limpieza de fecha

`autorizacionfecha` se castea a `date` y se reemplaza por NULL cuando es `0001-01-01`.

### Enriquecimiento por catálogos Excel

| Campo origen | Lookup | Resultado |
|---|---|---|
| id_tipo_afiliado | tipo_afiliado.xlsx | tipo_afiliado |
| id_modalidad | modalidad_prestacion.xlsx | tipo_modalidad |
| id_estado | estados.xlsx | estado |

Los identificadores técnicos se eliminan del DataFrame final.

---

## Estrategia de carga

`overwrite = TRUE`, `append = FALSE`. La tabla se reemplaza completa en cada corrida.

---

## Ventana operativa

El script verifica la hora de ejecución (rango operativo informativo entre `00:00` y `11:00`), pero no condiciona la ejecución a este rango.

---

## Relaciones principales

| Campo destino | Tabla relacionada |
|---|---|
| numero_autorizacion + nro_prestacion | autorizaciones_practicas |
| numero_beneficiario | afiliado |
| prestador | proveedorprestador |
| nro_internacion | informes_hospitalizacion |

---

## Uso funcional

Permite:

- Seguimiento de autorizaciones por afiliado, efector o solicitante.
- Detección de autorizaciones de salud mental y rehabilitación.
- Cruce con prácticas autorizadas (`autorizaciones_practicas`).
- Auditoría de carga interna vs. carga PAMI/AFIP.

---

## Owner

DBA

---

## Script generador

`E:/DataWarehouse/autorizaciones/autorizaciones.R`
