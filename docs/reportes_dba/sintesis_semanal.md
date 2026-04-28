# Reporte: sintesis_semanal

## Descripción

Reporte semanal automatizado que genera un Excel con múltiples solapas (Síntesis, Facturado, CRG por Efector, CRG por Período PAMI/INCLUIR/FACOEP, etc.), con tablas formateadas, totales, gráficos de torta y desgloses por centro de costo. Se envía por mail a la lista de destinatarios.

Es el principal "deliverable" semanal del área DBA: arma una foto consolidada de la situación comercial (Facturado / Cobrado / Pendiente), por ente, efector y centro de costo.

---

## Tipo

Reporte semanal automatizado (Excel + envío por mail).

---

## Frecuencia

Semanal (típicamente lunes; depende del calendario operativo).

---

## Primary Key sugerida

N/A (varias tablas / solapas distintas).

---

## Fuente origen

### Base consultada

- Producción: `10.22.1.61 / facoep`

### Tablas

- `comprobantes`
- `clientes`
- `obrassociales`
- `comprobanteshistorial`
- `crg`
- `crgdet`
- `proveedorprestador`
- `afiliado`

### Lookup externo

- `destinatarios.xlsx`

---

## Proceso que la genera

### Scripts

- `sintesis_semanal_final.R` (proceso principal)
- `SendMail.R` (envío de mail Gmail)

### Output

- `files/FACOEP Sintesis Semanal {DD}-{MM}-{YYYY}.xlsx`

(Histórico acumulado de archivos en `files/`.)

---

## Solapas del Excel

| Solapa | Contenido |
|---|---|
| Sintesis | Estado (Entregado / No Entregado / Facturado / Cobrado / Pendiente) + gráfico de torta + facturado por centro de costo |
| Facturado | Total facturado por ente (cliente, ente, tipo) con cantidad, importe, acumulado y participación |
| Cobrado | Cobranza por cliente con CantPagos, Cobrado, Participación, CobradoTotal y CobradoTotalPor |
| CRG Efectores | Tabla por efector (cantidad, entes, neto) |
| CRG Efectores Periodo | Importe neto pivoteado por efector y periodo |
| CRG Efectores Periodo PAMI | Lo anterior, filtrado por obras sociales PAMI |
| CRG Efectores Periodo INCLUIR | Lo anterior, filtrado por INCLUIR |
| CRG Efectores Periodo FACOEP | Lo anterior, filtrado por FACOEP |

---

## Campos relevantes (Síntesis)

| Estado | Importe | Cobrado | Pendiente |
|---|---|---|---|
| Entregado | suma facturado entregado | cobrado total | importe - cobrado |
| No Entregado | suma facturado no entregado | 0 | importe |
| Facturado | suma total facturado | 0 | 0 |

---

## Reglas de negocio

### Filtros principales

#### Facturado

- `tipocomprobantecodigo IN ('FACB2', 'FACA2', 'FAECA', 'FAECB')`
- `comprobanteentidadcodigo <> -1`
- `obsocialescodigo NOT IN ('90001162', '90001199')` (excluye PAMI / INCLUIR del facturado de la solapa Sintesis)

#### Cobrado

- `tipocomprobantecodigo = 'RECX2'`
- Mismas exclusiones de OOSS.

### Estado de la factura

```sql
fecha_entrega = comprobantehisfechatramite
WHERE comprobantehisestado = 4 (entregada)
```

```r
Estado = ifelse(is.na(fecha_entrega), "No Entregado", "Entregado")
```

### Categorización por Centro

Para las solapas CRG por Efector (segmentadas):

| obsocialescodigo | Centro |
|---|---|
| 90001199, 9000116, 90001003, 90001162 | PAMI |
| 90000172 | INCLUIR |
| Resto | FACOEP |

### Cálculo de participación / acumulado

```r
Participacion       = Cobrado / sum(Cobrado)
CobradoTotal        = cumsum(Cobrado)
CobradoTotalPor     = round(CobradoTotal / sum(Cobrado) * 100, 1)
```

### Estilo Excel

Se aplican estilos manuales (`s.titulos`, `s.totales`, `letraytamanio`, `moneda` formateando como CURRENCY, anchos de columna fijos en 17). Constante `M = 1.000.000` para mostrar millones en el gráfico.

### Generación del nombre del archivo

```r
fileName = "FACOEP Sintesis Semanal {DD}-{MM}-{YYYY}.xlsx"
```

### Envío por mail

`SendMail.R` envía vía Gmail SMTP el Excel adjunto a la lista de `destinatarios.xlsx`.

---

## Estrategia de carga

No persiste en DB. Genera Excel semanal y lo envía por mail. El histórico queda como archivos sueltos en `files/`.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| comprobantecodigo | comprobantes |
| obsocialescodigo | obrassociales |
| pprnombre | proveedorprestador / efectores |

---

## Uso funcional

Permite:

- Vista semanal consolidada de Facturado / Cobrado / Pendiente para dirección.
- Desglose por centro de costo y por ente.
- Análisis de CRG por efector y período (cuántos millones se generaron por hospital cada mes).
- Separación PAMI / INCLUIR / FACOEP.

---

## Owner

DBA

---

## Script generador

`E:/.../reportes/sintesis_semanal/sintesis_semanal_final.R`
