# Reporte: Pagos por Intimaciones

## Descripción

Script R ad-hoc que genera el listado de **pagos recibidos posteriores a una intimación**. Cruza facturas con sus intimaciones y con las imputaciones (recibos) para detectar qué facturas que fueron intimadas terminaron siendo cobradas (y cuándo respecto de la intimación).

Es un reporte operativo de cobranzas, sin tabla destino: arma un DataFrame en memoria (`reporte`) que se exporta o se entrega manualmente.

---

## Tipo

Reporte ad-hoc de cobranzas (script R).

---

## Frecuencia

A demanda.

---

## Primary Key sugerida

- intimacionnro
- factura

---

## Fuente origen

### Tablas transaccionales (Producción `Facoep`)

- `comprobantes`
- `comprobantesimputaciones`
- `intimacionintimaciondet`
- `intimacion`
- `comprobanteshistorial`
- `obrassociales`

---

## Proceso que la genera

### Script principal

- `E:/.../reportes/Pagos por Intimaciones/PagosPorIntimaciones.R`

(No tiene `.pbix` ni helpers asociados.)

---

## Campos

| # | Campo | Descripción |
|---|---|---|
| 1 | Nro Intimacion | Número de intimación |
| 2 | Factura | `tipo-codigo` de la factura |
| 3 | Cliente | `id_entidad - sigla` de la obra social |
| 4 | Emision | Fecha de emisión de la factura |
| 5 | Importe | Importe total de la factura |
| 6 | Vencimiento | `entrega + 30 días` |
| 7 | Fecha Intimacion | Fecha de envío de la intimación |
| 8 | Recepcion Intimacion | Fecha de recepción (NULL si era `0001-01-01`) |
| 9 | Imputacion | Comprobante de imputación (recibo) |
| 10 | Fecha Imputacion | Fecha del recibo |
| 11 | Importe Imputacion | Importe del recibo |
| 12 | Saldo | Saldo del comprobante |

---

## Reglas de negocio

### Filtros principales

- `c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB')`
- `c.comprobantetipoentidad = 2` (cliente)
- `data$intimacionfecha >= '2021-01-01'`
- `data$fechaimputacion > data$intimacionfecharecepcion` (la imputación debe ser **posterior** a la recepción de la intimación, es decir: cobré después de intimar)

### Cálculo de entrega

```sql
MAX(comprobantehisfechatramite) WHERE comprobantehisestado = 4
```

### Cálculo de vencimiento

`vencimiento = entrega + 30 días` (atención: en otros reportes se usan 60 días; aquí son 30).

### Limpieza

- Se reemplaza `intimacionfecharecepcion = '0001-01-01'` por NA.
- Se eliminan espacios en `factura` e `imputacion`.

### Exclusión de obras sociales

Se filtran fuera:

- `1003 - OSPA'A`
- `1 - I.N.S.S.J. y P.`

### Marcado de intimación (no usado en filtro)

`Intimado = "Intimado"` cuando `comprobanteintimacion = TRUE`. Sirve solo como columna informativa.

---

## Estrategia de carga

No persiste en DB. El DataFrame `reporte` queda en memoria para export manual.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| factura | comprobantes |
| imputacion | comprobantes |
| intimacionnro | intimacion |
| comprobanteentidadcodigo | obrassociales |

---

## Uso funcional

Permite:

- Medir efectividad de las intimaciones (cuántas facturas se cobraron post-intimación).
- Calcular tiempos entre recepción de la intimación y el cobro.
- Identificar qué obras sociales pagan después de ser intimadas y cuáles no.

---

## Owner

DBA / Cobranzas

---

## Script generador

`E:/.../reportes/Pagos por Intimaciones/PagosPorIntimaciones.R`
