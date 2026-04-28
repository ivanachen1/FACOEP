# Reporte: Facturacion_por_DNI

## Descripción

Reporte que arma una vista de **facturación por DNI de afiliado** sobre las prestaciones facturadas desde mayo de 2024. Cruza el detalle de comprobantes (`comprobantecrgdet`) con la cabecera de comprobantes (`wwcomprobantes`) para incluir el flag `es_refacturacion`.

El script materializa el resultado en una tabla en la base DBA (`facturacion_por_dni`) y es la fuente del `.pbix`. Tiene además un script de envío por mail (hoy comentado) preparado para distribuir el Excel.

---

## Tipo

Reporte / dashboard + materialización de tabla destino.

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

- numero (DNI)
- nro_crg
- practica
- efector

---

## Fuente origen

### Tablas (base SIF)

- `comprobantecrgdet`
- `wwcomprobantes`

### Lookup externo

- `destinatarios.xlsx` (lista de mails para envío)

---

## Proceso que la genera

### Archivo PowerBI

- `E:/.../reportes/Facturacion_por_DNI/Facturacion por DNI.pbix`

### Scripts R

- `Main.R` (extrae, transforma y persiste en DBA)
- `Adhoc.R` (consultas ad-hoc)
- `SendMail.R` (envío de mail con Gmail SMTP)

### Tabla destino

- `DBA.facturacion_por_dni` (Postgres host `10.22.1.44`)

### Salida adicional

- `Facturacion por DNI.xlsx` (export opcional, hoy comentado)

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | tipo | varchar | Sí | Tipo de documento del afiliado |
| 2 | numero | varchar | Sí | Número de documento |
| 3 | efector | varchar | Sí | Efector (concatenación id - nombre) |
| 4 | financiador | varchar | Sí | Financiador (concatenación id - nombre) |
| 5 | tipo_prestacion | varchar | Sí | Tipo de prestación |
| 6 | fecha_prestacion | date | Sí | Fecha de la prestación |
| 7 | nro_crg | int | Sí | Número de CRG |
| 8 | practica | varchar | Sí | Práctica realizada |
| 9 | es_refacturacion | bool | Sí | Flag de refacturación, viene de `wwcomprobantes` |
| 10 | facturado | decimal | Sí | `SUM(importe_a_facturar)` agrupado |

---

## Reglas de negocio

### Filtros

- `tipo IN ('FACB2', 'FACA2', 'FAECA')` (factura A2, B2 o E factura A).
- `fecha_prestacion > '2024-05-31'`.
- (En el query original adicionalmente: `practica LIKE '%IMA%'` y `tipo_documento_afiliado = 'DNI'`. El `Main.R` los relaja para no acotar por práctica/documento al persistir.)

### Agrupación

`SUM(importe_a_facturar)` agrupado por todas las dimensiones (tipo doc, número, efector, financiador, tipo prestación, fecha, CRG, práctica, es_refacturacion).

### Vinculación `wwcomprobantes`

```sql
LEFT JOIN (
  SELECT comprobante, es_refacturacion
  FROM wwcomprobantes
  WHERE tipo IN ('FACB2', 'FACA2', 'FAECA')
) c
ON det.comprobante = c.comprobante
```

---

## Estrategia de carga

Reemplaza la tabla destino completa:

```r
dbWriteTable(con1, "facturacion_por_dni", df,
             append = FALSE, overwrite = TRUE)
```

### Envío por mail (comentado)

`SendMail.R` está preparado para enviar `Facturacion por DNI.xlsx` por Gmail (`dbafacoep@gmail.com`) a la lista de `destinatarios.xlsx`. Hoy está comentado en `Main.R`.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| nro_crg | crg / comprobantecrg |
| comprobante | wwcomprobantes |
| numero (DNI) | afiliado |

---

## Uso funcional

Permite:

- Ver facturación agregada por afiliado (DNI).
- Detectar prácticas refacturadas.
- Análisis por efector / financiador / tipo de prestación.

---

## Owner

DBA

---

## Archivo PBIX

`E:/.../reportes/Facturacion_por_DNI/Facturacion por DNI.pbix`
