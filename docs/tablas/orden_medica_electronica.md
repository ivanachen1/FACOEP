# Tabla: orden_medica_electronica

## Descripción

Tabla de órdenes médicas electrónicas (OME). Contiene información de la orden, efector, afiliado, práctica, periodo, turno, y todo el ciclo administrativo: aceptación, transmisión a PAMI, validación.

Permite analizar la actividad de OMEs por efector / afiliado, su estado de transmisión y validación, y el cumplimiento del flujo electrónico.

---

## Tipo

Hecho transaccional / maestro de órdenes médicas electrónicas.

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

- numero_orden
- practica

---

## Fuente origen

### Tablas transaccionales

- `ordenmedicaelectronica`

### Lookup externo

- (No utiliza catálogos Excel — todas las decodificaciones están en la query)

---

## Proceso que la genera

### Script principal

- `E:/DataWarehouse/orden_medica_electronica/main.R`

### Helper

- `E:/DataWarehouse/orden_medica_electronica/Funciones_Helper.R`

### Tabla destino

- `public.orden_medica_electronica` (base SIF)

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | numero_orden | varchar | Sí | Número de orden (casteado a varchar) |
| 2 | id_efector | int | Sí | Identificador del efector |
| 3 | fecha_emision | date | Sí | Fecha de emisión de la OME |
| 4 | nro_beneficio | varchar | Sí | Número de beneficio del afiliado (casteado a varchar) |
| 5 | nombre | varchar | Sí | Apellido y nombre del afiliado |
| 6 | practica | varchar | Sí | Código o descripción de la práctica |
| 7 | descripcion | varchar | Sí | Descripción libre de la OME |
| 8 | periodo | varchar | Sí | Periodo asociado |
| 9 | turno | varchar | Sí | Turno como string (formato `DD/MM/YYYY - HH24:MI`) |
| 10 | turno_casteado | timestamp | Sí | Turno parseado a timestamp |
| 11 | usuario_acepto | varchar | Sí | Usuario que aceptó la orden |
| 12 | fecha_acepto | date | Sí | Fecha de aceptación |
| 13 | transmitida | varchar | Sí | "SI" / "NO" según `ordenmedicaelectronicatrasmiti = 'S'` |
| 14 | fecha_transmision | date | Sí | Fecha de transmisión |
| 15 | usuario_transmision | varchar | Sí | Usuario que la transmitió |
| 16 | validacion | varchar | Sí | "SI" / "NO" según `ordenmedicaelectronicavalidada = 'S'` |
| 17 | fecha_validacion | date | Sí | Fecha de validación |
| 18 | usuario_validacion | varchar | Sí | Usuario que validó |

---

## Reglas de negocio

### Rango de extracción

Se procesan los últimos **360 días** filtrando por:

```sql
WHERE TO_TIMESTAMP(ordenmedicaelectronicaturno, 'DD/MM/YYYY - HH24:MI')
      BETWEEN '{fechaInicio}' AND '{fechaFin}'
```

### Casteos

- `numero_orden` y `nro_beneficio` se castean a `VARCHAR`.
- `turno` se castea a `timestamp` con el formato `DD/MM/YYYY - HH24:MI` y se persiste como `turno_casteado`.

### Decodificación de transmitida

| Origen (`ordenmedicaelectronicatrasmiti`) | Resultado |
|---|---|
| 'S' | SI |
| Otro | NO |

### Decodificación de validacion

| Origen (`ordenmedicaelectronicavalidada`) | Resultado |
|---|---|
| 'S' | SI |
| Otro | NO |

---

## Estrategia de carga

Antes de insertar, se ejecuta:

```sql
DELETE FROM orden_medica_electronica
WHERE turno_casteado BETWEEN fechaInicio AND fechaFin
```

Luego se inserta con `append = TRUE`. La carga es incremental por rango móvil de 360 días.

---

## Relaciones principales

| Campo destino | Tabla relacionada |
|---|---|
| numero_orden | autorizaciones |
| id_efector | proveedorprestador |
| nro_beneficio | afiliado |

---

## Uso funcional

Permite:

- Seguimiento de OMEs por efector y afiliado.
- Detección de OMEs no transmitidas o no validadas (control de cumplimiento PAMI).
- Análisis de tiempos entre aceptación, transmisión y validación.
- Cruce con autorizaciones para conciliar el flujo completo.

---

## Owner

DBA

---

## Script generador

`E:/DataWarehouse/orden_medica_electronica/main.R`
