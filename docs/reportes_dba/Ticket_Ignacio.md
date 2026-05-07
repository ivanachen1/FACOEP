# Reporte: Ticket Ignacio

## Descripción

Reporte ad-hoc en R generado a pedido de Ignacio (cobranzas) que arma un listado de **recibos (RECX2) con detalle de los valores recibidos** (cheques, transferencias) asociados, incluyendo banco, librador, número de cuenta, fechas y un flag de depósito.

Sirve para conciliar valores recibidos por recibo y trackear depósitos.

---

## Tipo

Reporte ad-hoc (script R sin .pbix).

---

## Frecuencia

A demanda.

---

## Primary Key sugerida

- tipo + prefijo + numerorecibo + numerovalor

---

## Fuente origen

### Tablas transaccionales (Producción `Facoep`)

- `comprobantes`
- `valores`
- `tipovalor`
- `banco`

---

## Proceso que la genera

### Script principal

- `E:/.../reportes/Ticket Ignacio/Script Procesamiento.R`

### Documentación interna

- `infotablas.txt` (notas con explicación de cada campo y query base)

---

## Campos

| # | Campo | Descripción |
|---|---|---|
| 1 | id | ID de la entidad (`comprobanteentidadcodigo`) |
| 2 | emision | Fecha de emisión del recibo |
| 3 | tipo | Tipo de comprobante (`RECX2`) |
| 4 | prefijo | Prefijo del recibo |
| 5 | numerorecibo | Número del recibo |
| 6 | importerecibo | Importe total del recibo |
| 7 | origen | Origen del comprobante |
| 8 | comprobanteenviado246 | Flag de envío RES 246 |
| 9 | tipovalortipo | Código del tipo de valor |
| 10 | tipovalor | Descripción del tipo de valor |
| 11 | serie | Serie del valor |
| 12 | numerovalor | Número del valor |
| 13 | banco | Descripción del banco |
| 14 | numctecorriente | Cuenta corriente del librador |
| 15 | librador | Nombre del librador |
| 16 | emisionvalor | Fecha de emisión del valor |
| 17 | vencimientovalor | Fecha de vencimiento |
| 18 | importevalor | Importe del valor |
| 19 | depositado | Flag "SI" / "NO" según valor depositado |

---

## Reglas de negocio

### Filtro principal

`c.tipocomprobantecodigo IN ('RECX2')` (recibos).

### Vinculación recibo ↔ valor

```sql
LEFT JOIN valores val
  ON val.valortipomoventra   = c.tipocomprobantecodigo
 AND val.valorcmpprefijoentra = c.comprobanteprefijo
 AND val.valormovcodigoentra  = c.comprobantecodigo
```

### Cálculo de Depositado

`Depositado = "SI"` cuando:

- `tipovalortipo IN (5, 6)` (tipos de valor que se depositan)
- Y `valormovcodigosale` no es NULL ni vacío.

Caso contrario `"NO"`.

---

## Estrategia de carga

No persiste en DB. DataFrame en memoria (`data`) para export manual o entrega directa.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| numerorecibo | comprobantes |
| numerovalor | valores |
| banco | banco |

---

## Uso funcional

Permite a Ignacio (cobranzas):

- Ver el detalle de qué valor / cheque / transferencia compone cada recibo.
- Saber si los valores ya fueron depositados.
- Conciliar contra extractos bancarios.

---

## Owner

DBA / Cobranzas

---

## Script generador

`E:/.../reportes/Ticket Ignacio/Script Procesamiento.R`
