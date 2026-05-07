# Reporte: datawarehouse_alerts

## Descripción

Proceso de **monitoreo de frescura del DataWarehouse**. Cada día se consulta la fecha máxima (`actualizado_al`) de un set de tablas críticas. Si **alguna** está atrasada más de 5 días respecto a hoy, se dispara un mail de alerta con el Excel `TablasDesactualizadas.xlsx`. Los **viernes**, si todo está en orden, se envía un mail de OK con `TablasActualizadas.xlsx`.

Es la pieza de monitoring del DW (complementaria al proceso `conteo_tablas` que sí mide volumen).

---

## Tipo

Proceso de monitoreo / alertas por mail. No persiste tabla destino.

---

## Frecuencia

Diaria. Mail solo cuando hay alerta o el día viernes (resumen semanal OK).

---

## Primary Key sugerida

N/A.

---

## Fuente origen

### Bases consultadas

- SIF (`10.22.1.44 / SIF`)
- SIF_HISTORICAL (`10.22.1.44 / SIF_HISTORICAL`)

### Tablas monitoreadas

| Tabla | Campo de fecha |
|---|---|
| comprobantes_imputaciones | fecha_imputacion |
| wwcomprobantes | fecha_emision |
| comprobantecrg | fecha_emision |
| comprobantecrgdet | fecha_emision_comprobante |
| comprobantes_asociados | fecha_emision_asociado |
| comprobantes_historial | fecha_tramite |
| os_ticket | creacion |
| crg | fecha_carga |
| crg_historial | fecha |
| recupero_gastos | fecha_carga_crg |
| sigehos_anexos_recupero | fecha |
| sigehos_crg_recupero | fecha |
| sigehos_dph_recupero | fecha |
| wwcomprobantes_historial (en SIF_HISTORICAL) | fecha_imagen |

### Lookup externo

- `destinatarios.xlsx`

---

## Proceso que la genera

### Scripts

- `Main.R` (proceso principal)
- `SendMail.R` (helper de envío Gmail SMTP)

### Outputs (Excel)

- `TablasDesactualizadas.xlsx` (cuando hay alerta)
- `TablasActualizadas.xlsx` (los viernes, si todo OK)

---

## Campos del output

| # | Campo | Descripción |
|---|---|---|
| 1 | actualizado_al | Fecha máxima encontrada en la tabla |
| 2 | reporte | Nombre lógico de la tabla / reporte |

---

## Reglas de negocio

### Cálculo de actualizado_al

Para cada tabla se ejecuta un `SELECT MAX(<campo_fecha>)` filtrando por `< CURRENT_DATE` (para excluir cargas del día).

### Umbral de alerta

Se consideran desactualizadas las tablas con `actualizado_al < CURRENT_DATE - 5`.

### Disparadores de mail

| Condición | Acción |
|---|---|
| `nrow(desactualizadas) > 0` | Mail "Tablas Desactualizadas" + `TablasDesactualizadas.xlsx` |
| Resto + `weekday = "viernes"` | Mail "Tablas Actualizadas" + `TablasActualizadas.xlsx` |
| Resto cualquier otro día | No envía nada |

### Envío de mail

`SendEmail` usa Gmail SMTP (`dbafacoep@gmail.com`) con TLS port 465. La lista de destinatarios viene de `destinatarios.xlsx` (columna `emails`).

---

## Estrategia de carga

No persiste en DB. Solo escribe Excels y envía mail.

---

## Relaciones principales

Cada tabla monitoreada tiene su propia documentación en `docs/tablas/`.

---

## Uso funcional

Permite:

- Detectar caídas / atrasos en cualquier proceso del DW.
- Confirmar semanalmente (viernes) que todas las tablas están al día.
- Notificar al equipo DBA por mail con el Excel adjunto.

---

## Owner

DBA

---

## Script generador

`E:/.../reportes/datawarehouse_alerts/Main.R`
