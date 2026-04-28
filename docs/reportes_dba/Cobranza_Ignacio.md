# Reporte: Cobranza Ignacio

## Descripción

Reporte ad-hoc en R que arma un **resumen mensual de cobranzas para los productos Reg-Cov / Turismo / Detectar**. Cruza deuda, mandatarios y recibos consultando bases de respaldo de cierre de mes (snapshots por fecha) y entrega un CSV consolidado.

Está pensado como un proceso manual mes a mes: hay un script base (`Script Extraccion.R`) y "pruebas" por mes (`prueba Octubre.R`, `prueba Noviembre.R`) donde se ajustan las fechas/bases del mes correspondiente.

---

## Tipo

Reporte ad-hoc / extracción mensual.

---

## Frecuencia

Mensual (manual).

---

## Primary Key sugerida

- id (cliente)
- tipo (Reg-Cov / Turismo / Detectar)
- periodo (Año / "Actual" / "A Vencer")

---

## Fuente origen

### Bases de datos

- Snapshots mensuales de Producción del tipo `facoepDDMMYYYY` (host `172.31.24.12`):
  - Ej: `facoep30062022`, `facoep31052022`, `facoep31102022`, `facoep30092022`.

### Tablas consultadas

- `comprobantes`
- `comprobantecrg`
- `comprobanteshistorial`
- `comprobantesimputaciones`
- `enviocompdet`
- `enviocomprobantes`

---

## Proceso que la genera

### Scripts

- `Script Extraccion.R` (base, parametrizable por fechas)
- `prueba Octubre.R`, `prueba Noviembre.R` (clones por mes con fechas/bases ajustadas)
- `FuncionesHelper.R` (utilidades)
- `directorio bases.txt` (referencia de qué bases usar por mes)

### Output

- `Reporte Cobranzas Noviembre.csv` (ejemplo del último output guardado)

---

## Campos relevantes

| Campo | Descripción |
|---|---|
| id | ID de la entidad (cliente) |
| tipo | Reg-Cov / Turismo / Detectar |
| periodo | Año del vencimiento si es viejo, "Actual" si es del mes actual, "A Vencer" si es futuro |
| monto | Suma de `comprobantesaldo` |
| mandatarios | Importes derivados a mandatarios en el mes |
| recibos | Imputaciones por recibos en el mes |

---

## Reglas de negocio

### Clasificación por tipo

| Origen (`comprobantepprid`) | Tipo |
|---|---|
| 3140 | Turismo |
| 3173 | Detectar |
| Otro | Reg-Cov |

### Tipos de comprobante considerados

`FACA2, FACB2, FAECA, FAECB, NDA, NDB, NDECA` (facturas y notas de débito).

### Cálculo de vencimiento

`vencimiento = MAX(comprobantehisfechatramite) + INTERVAL '60 day'` para movimientos en `comprobanteshistorial` con `comprobantehisestado IN (4, 13)`.

### Clasificación de periodo

| Condición | Periodo |
|---|---|
| `vencimiento < fin_mes_anterior` | EXTRACT(YEAR FROM vencimiento) |
| `EXTRACT(MONTH FROM vencimiento) = mes_actual` | "Actual" |
| `vencimiento >= primer_dia_mes_siguiente` | "A Vencer" |

### Filtros principales de deuda

- `comprobantesaldo > 0`
- `comprobantemandatario = 'FALSE'` (los mandatarios se calculan aparte)

### Recibos

Se imputan únicamente comprobantes tipo `RECX2` cruzados contra `comprobantesimputaciones` por la clave compuesta `(empcod, sucursalcodigo, comprobantetipoentidad, comprobanteentidadcodigo, tipocomprobantecodigo, comprobanteprefijo, comprobantecodigo)`.

---

## Estrategia de carga

No carga en DB. Genera un CSV por mes (ej. `Reporte Cobranzas Noviembre.csv`).

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| comprobante | comprobantes / comprobantecrg |
| id | clientes |

---

## Uso funcional

Permite a Ignacio (área de cobranzas) tener un resumen mensual con:

- Deuda dividida por tipo y periodo de vencimiento.
- Importes derivados a mandatarios en el mes.
- Recibos cobrados en el mes.

---

## Owner

DBA / Cobranzas

---

## Script generador

`E:/.../reportes/Cobranza Ignacio/Script Extraccion.R`
