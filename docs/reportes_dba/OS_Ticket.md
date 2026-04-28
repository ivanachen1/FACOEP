# Reporte: OS-Ticket

## Descripción

Reporte PowerBI sobre la **plataforma de tickets osTicket** que utiliza el área DBA. El proceso ETL extrae los tickets desde la base MySQL de osTicket (`localhost / osticket`), enriquece el campo "Tema" con un diccionario manual y persiste el resultado en la tabla `os_ticket` de la base SIF para alimentar el `.pbix`.

Permite ver tickets abiertos / cerrados, agentes asignados, niveles, tiempos, temas y prioridades.

---

## Tipo

Reporte / dashboard de tickets + ETL MySQL → PostgreSQL.

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

- ticket_id

---

## Fuente origen

### Bases

- MySQL local: `osticket` (host `localhost:3306`, user `root`).
- Postgres SIF: `10.22.1.44 / SIF` (destino).

### Tablas MySQL consultadas

- `ost_ticket`
- `ost_user`
- `ost_staff`
- `ost_help_topic`
- `ost_ticket_status`
- `ost_ticket__cdata`
- `ost_ticket_priority`
- `ost_form_entry` / `ost_form_entry_values`

### Lookup externo

- `diccionario.xlsx` (mapping de `Tema` → `tema2` legible)

---

## Proceso que la genera

### Archivo PowerBI

- `E:/.../reportes/OS-Ticket/Reporte Tickets.pbix`

### Scripts

- `produccion/main.R` (ETL principal MySQL → PG SIF)
- `produccion/InsertSaldos.R` (saldos asociados)
- `script.R` (lectura de la tabla persistida desde DBA)
- `connectionTest.R` (test de conexión)
- `test.py` (test Python)

### Tabla destino

- `SIF.os_ticket` (Postgres `10.22.1.44`)

### Documentación interna

- `Nuevo Realease Tickets.txt`

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | creacion | timestamp | Sí | Fecha de creación del ticket |
| 2 | cerrado | timestamp | Sí | Fecha de cierre |
| 3 | ticket_id | varchar | Sí | Número visible del ticket |
| 4 | usuario | varchar | Sí | Usuario solicitante |
| 5 | descripcion | varchar | Sí | Asunto del ticket |
| 6 | nivel | varchar | Sí | Topic / nivel de soporte |
| 7 | tema | varchar | Sí | Tema enriquecido vía `diccionario.xlsx` |
| 8 | agente | varchar | Sí | Agente asignado |
| 9 | ultima_modificacion | timestamp | Sí | Última actualización |
| 10 | estado | varchar | Sí | Estado actual del ticket |
| 11 | prioridad | varchar | Sí | Prioridad |

---

## Reglas de negocio

### Filtro temporal

`t.created > '2021-04-01'`.

### Subquery de Tema

El "Tema" se obtiene desde la tabla de form entries:

```sql
SELECT ticket_id, e.id, v.value
FROM ost_ticket t
LEFT JOIN ost_form_entry e ON e.object_id = t.ticket_id
LEFT JOIN ost_form_entry_values v ON e.id = v.entry_id
WHERE v.field_id > 44 AND form_id <> 2
ORDER BY t.ticket_id DESC
```

### Enriquecimiento de Tema

Se cruza con `diccionario.xlsx` por la columna `Tema` para obtener `tema2` (descripción legible).

---

## Estrategia de carga

`overwrite = TRUE`, `append = FALSE`. La tabla `SIF.os_ticket` se reemplaza completa en cada corrida.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| usuario | ost_user (osticket) |
| agente | ost_staff (osticket) |

---

## Uso funcional

Permite:

- Ver volumen y estado de tickets DBA.
- Productividad por agente.
- Análisis por tema / nivel / prioridad.
- Tiempo medio de resolución.

---

## Owner

DBA

---

## Archivo PBIX

`E:/.../reportes/OS-Ticket/Reporte Tickets.pbix`
