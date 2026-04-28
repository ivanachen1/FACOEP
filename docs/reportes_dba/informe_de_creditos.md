# Reporte: informe_de_creditos

## Descripción

Reporte mensual de **clasificación de créditos abiertos** (facturas con saldo). Toma una imagen mensual del DW (`SIF_HISTORICAL`) y clasifica cada crédito en uno de 8 "casos" según su estado de juicio, intimación, vencimiento y año de emisión:

| Caso | Definición |
|---|---|
| 1 | Vencido + en mandatarios (juicio) |
| 2 | Vencido + intimado + no en mandatarios |
| 3 | Vencido + sin intimar + no en mandatarios |
| 4 | Vencido en el mes anterior al de análisis |
| 5 | A vencer (vencimientos posteriores al fin del mes de análisis) |
| 6 | Sin fecha de recepción + emisión en años anteriores al análisis |
| 7 | Sin fecha de recepción + emisión en el año de análisis |
| 8 | Otros |

El resultado se persiste en `DBA.informe_creditos` con columna `fecha_analisis`. Adicionalmente, hay una subcarpeta `desglose_cobrado/` que genera Excel mensuales (`reporte al YYYY-M.xlsx`) y los envía por mail. Tiene además un `try/catch` que dispara mail de error si falla el proceso.

---

## Tipo

Reporte mensual / proceso de clasificación + envío de mail.

---

## Frecuencia

Mensual.

---

## Primary Key sugerida

- comprobante + fecha_analisis + caso

---

## Fuente origen

### Bases consultadas

- SIF_HISTORICAL (`10.22.1.44 / SIF_HISTORICAL`) — para la imagen mensual.
- DBA (`10.22.1.44 / DBA`) — destino.

### Tablas

- Imagen histórica de wwcomprobantes / comprobantes con saldo.

### Lookup externo

- `clientes_custom.xlsx` (mapeo `id_entidad` → `grupo_clientes`)
- `tipo_comprobante.xlsx`
- `caso_dos.xlsx`, `mesTestigo.xlsx`, `mesTestigoMarzo.xlsx`, `revisar.xlsx`, `saldos.xlsx`
- `destinatarios.xlsx`

---

## Proceso que la genera

### Archivo PowerBI

- `informe de creditos.pbix`

### Scripts R (raíz)

- `Main.R` (proceso principal)
- `HelperFunctions.R` (helpers `CreateCasoUno..Ocho`, `CreateFechas`, etc.)
- `SendMail.R` (envío de mail Gmail)

### Subcarpeta `desglose_cobrado/`

- `Main.R` + `FuncionesHelper.R` + `SaveExcel.R` + `SendMail.R`
- Genera Excel mensual `reporte al YYYY-M.xlsx`
- Envía por mail con `destinatarios.xlsx`

### Tabla destino

- `DBA.informe_creditos`

### Documentación interna

- `Roadmap.txt` (definición de los 8 casos)
- `query de creacion.txt`

---

## Campos

| # | Campo | Descripción |
|---|---|---|
| 1 | id_entidad | ID de la obra social / cliente |
| 2 | grupo_clientes | Grupo según `clientes_custom.xlsx` ("Otros" si no mapea) |
| 3 | tipo | Tipo de comprobante |
| 4 | comprobante | Identificador del comprobante |
| 5 | saldo | Saldo numérico |
| 6 | fecha_emision | Fecha de emisión |
| 7 | fecha_entrega | Fecha de entrega/recepción |
| 8 | fecha_vencimiento | Fecha de vencimiento calculada |
| 9 | caso | Caso de clasificación (1..8) |
| 10 | fecha_analisis | Fecha del análisis (inicio del mes anterior al de la imagen) |

---

## Reglas de negocio

### Cálculo de fechas de análisis

- `fecha_fin_analisis = CreateFechaFinAnalisis()` (último día del mes anterior).
- `fecha_inicio_analisis`, `vencimiento`, `inicio_mes_vencimiento` se derivan a partir de `fecha_fin_analisis` con `CreateFechas`.

### Tipos de comprobante considerados

(Definidos en `Roadmap.txt`):
`FACASIB, FACASIA, FACA2, FACB2, FAECA, NDAASI, NDBASI, NDA, NDB, NDECA`.

### Cálculo de fecha de vencimiento

`CreateFechaVencimiento(df)` usa la fecha de entrega como punto de partida.

### Clasificación en casos

Cada función `CreateCasoX` arma un subset del DataFrame:

- **Caso 1**: vencido + mandatarios = juicio.
- **Caso 2**: vencido + intimado + sin mandatarios.
- **Caso 3**: vencido + sin intimar + sin mandatarios.
- **Caso 4**: vencido en el mes anterior al de análisis (entre `fecha_inicio_analisis` y `fecha_fin_analisis`).
- **Caso 5**: A vencer (`fecha_vencimiento > fecha_fin_analisis`).
- **Caso 6**: sin recepción + emisión en años anteriores al análisis.
- **Caso 7**: sin recepción + emisión en el año de análisis.
- **Caso 8**: resto / "Otros".

### Marcado de grupo_clientes

Si no encuentra match en `clientes_custom.xlsx`, queda `"Otros"`.

### Manejo de errores

Si el query o el procesamiento falla, se envía mail "Informe Creditos Fallido" a la lista de `destinatarios.xlsx` (de `datawarehouse_alerts`).

---

## Estrategia de carga

Antes de insertar, se ejecuta el delete del rango de la imagen actual:

```sql
DELETE FROM informe_creditos WHERE fecha_analisis = '{fecha_inicio_analisis}'
```

Luego se inserta con `append = TRUE`.

### Subcarpeta desglose_cobrado

Genera Excel mensual `reporte al YYYY-M.xlsx` y lo envía por mail. El histórico se mantiene como archivos sueltos.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| comprobante | comprobantes / wwcomprobantes |
| id_entidad | clientes / clientes_custom.xlsx |
| tipo | tipo_comprobante.xlsx |

---

## Uso funcional

Permite:

- Distribuir mensualmente la cartera de créditos abiertos en categorías accionables.
- Identificar volumen "en juicio" vs "intimado" vs "a vencer".
- Trackear créditos sin recepción.
- Generar reporte mensual en Excel para distribución por mail.

---

## Owner

DBA / Cobranzas

---

## Archivo PBIX

`E:/.../reportes/informe_de_creditos/informe de creditos.pbix`
