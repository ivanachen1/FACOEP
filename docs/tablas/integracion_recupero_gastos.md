# Integración: SIGEHOS Recupero de Gastos

## Descripción general

Proceso ETL que integra información operativa del sistema SIGEHOS vinculada al circuito de **Recupero de Gastos** hacia la base analítica SIF.

El proceso consolida información proveniente de dos fuentes:

### Fuente V1
Extracción desde múltiples bases MySQL por efector.

### Fuente V2
Extracción centralizada desde Oracle mediante vistas institucionales:

- `USUARIO_RDG.RDGV_CRG_FACOEP`
- `USUARIO_RDG.RDGV_DPH_FACOEP`
- `USUARIO_RDG.RDGV_REMITO_FACOEP`


# Maestro de homologación de efectores

## Archivo utilizado

`databases.xlsx`

## Finalidad

Se utiliza como tabla maestra para homologar cada base / efector de SIGEHOS con los identificadores internos de SIF.

## Campos relevantes usados en el proceso

| Campo Excel | Uso |
|-----------|-----|
| database | Nombre de base MySQL del efector |
| id | id_proveedor_sif |
| Efector Facoep | nombre efector |
| id_version_dos | id_sigehos usado en Oracle V2 |

---

# Reglas de matcheo de efectores

## Para V1 (MySQL por base)

Cada extracción se ejecuta sobre una base distinta (`database`).

Luego se agregan:

- `origin = database`
- `id_proveedor_sif = id`
- `efector = Efector Facoep`

Es decir, el nombre de la base determina qué efector representa.

## Para V2 (Oracle centralizado)

Las vistas traen `ID_EFECTOR`.

Ese valor se matchea contra:

- `databases.id_version_dos`

Y luego se incorpora:

- `id_proveedor_sif = databases.id`
- `efector = databases.Efector Facoep`

Esto permite unificar V1 y V2 bajo el mismo catálogo de efectores.


---

## Tablas generadas

1. `sigehos_crg_recupero`
2. `sigehos_dph_recupero`
3. `sigehos_anexos_recupero`

---

# Tabla: sigehos_crg_recupero

## Descripción

Cabecera de CRG (Comprobantes de Recupero de Gastos).  
Representa agrupadores de recupero emitidos a financiadores.

## Tipo

Hecho transaccional / cabecera documental

## Frecuencia

Diaria

## Primary Key sugerida

fecha  
numero  
origin

## Campos

| Campo | Tipo | Descripción |
|------|------|-------------|
| fecha | date | Fecha de emisión del CRG |
| numero | integer | Número de CRG |
| tipo_anexo | varchar | Tipo de anexo |
| estado | varchar | Estado del CRG |
| cant_dphs | integer | Cantidad de DPH asociados |
| financiador_sigla | varchar | Sigla financiador |
| financiador_nombre | varchar | Nombre financiador |
| importe_total | numeric | Importe total del CRG |
| origin | varchar | Fuente origen |
| id_proveedor_sif | integer | ID proveedor SIF |
| efector | varchar | Nombre efector |

## Reglas de negocio

- Para V2 se toma `origin = recupero_v2`
- Para V1 el origin corresponde a la base del efector
- Se elimina rango de fechas previo antes de insertar
- `tipo_anexo` se normaliza (acentos / capitalización)

---

# Tabla: sigehos_dph_recupero

## Descripción

Detalle de prestaciones hospitalarias recuperables vinculadas a un CRG.

## Tipo

Hecho transaccional / detalle asistencial

## Frecuencia

Diaria

## Primary Key sugerida

fecha  
numero  
origin

## Campos

| Campo | Tipo | Descripción |
|------|------|-------------|
| fecha | date | Fecha de creación |
| numero | integer | Número DPH |
| tipo_anexo | varchar | Tipo anexo |
| estado | varchar | Estado |
| nro_crg | integer | Número CRG relacionado |
| financiador_sigla | varchar | Sigla financiador |
| financiador_nombre | varchar | Nombre financiador |
| apellidos | varchar | Apellido paciente |
| nombres | varchar | Nombre paciente |
| documento | varchar | Documento |
| importe_total | numeric | Importe total |
| origin | varchar | Fuente origen |
| id_proveedor_sif | integer | ID proveedor |
| efector | varchar | Nombre efector |

## Reglas de negocio

- Vincula prestaciones individuales a CRG
- Permite trazabilidad paciente-financiador
- En V2 el documento puede omitirse según extracción Oracle

---

# Tabla: sigehos_anexos_recupero

## Descripción

Anexos / remitos generados dentro del circuito de recupero.

## Tipo

Hecho transaccional operativo

## Frecuencia

Diaria

## Primary Key sugerida

fecha  
nro_anexo  
origin

## Campos

| Campo | Tipo | Descripción |
|------|------|-------------|
| fecha | date | Fecha del anexo |
| nro_anexo | integer | Número de anexo |
| apellidos | varchar | Apellido paciente |
| nombres | varchar | Nombre paciente |
| documento | varchar | Documento |
| tipo_anexo | varchar | Tipo anexo |
| financiador_sigla | varchar | Sigla financiador |
| financiador_nombre | varchar | Nombre financiador |
| especialidad | varchar | Especialidad médica |
| importe | numeric | Importe asociado |
| id_dph | integer | DPH relacionado |
| estado | varchar | Estado derivado |
| origin | varchar | Fuente origen |
| id_proveedor_sif | integer | ID proveedor |
| efector | varchar | Nombre efector |

## Reglas de negocio

### Estado calculado para la tabla anexos (V1)

| Condición | Resultado |
|--------|-----------|
| importe null + id_dph null | Sin Arancelar |
| importe <> 0 + id_dph = 0 | Arancelado |
| importe <> 0 + id_dph <> 0 | Facturado |

### Carga

- Se reemplaza información por rango de fechas
- Para V2 se utiliza `origin = recupero_v2`

---

# Arquitectura del proceso

## Script principal

`connection_PHPMyAdmin.py`

## Módulos auxiliares

- `HelperFunctions.py`
- `ConexionSigehosOracle.py`

---

# Ventana de extracción

## Horario madrugada / mañana

- últimos 90 días

## Resto del día

- últimos 365 días

---

# Conexiones origen

## MySQL

Servidor productivo SIGEHOS slave.

## Oracle

Instancia institucional SIGESAN.

## Destino

PostgreSQL SIF.

---

# Calidad de datos sugerida

## CRG

- numero no nulo
- importe_total >= 0

## DPH

- nro_crg existente en CRG
- paciente informado

## Anexos

- nro_anexo único por fecha + origin
- estado válido

---

# Owner

DBA / BI / Recupero de Gastos

---

# Observaciones funcionales

- Permite analizar recupero por efector
- Seguimiento de facturación
- Performance por financiador
- Prestaciones pendientes de facturar
- Volumen documental por período
- Indicadores de recupero hospitalario

---

# Issues relacionados

## Ticket #770666 — errores en tablero de recupero de gasto

- **URL:** [soporte-facoep.buenosaires.gob.ar/Soporte/scp/tickets.php?id=19706](https://soporte-facoep.buenosaires.gob.ar/Soporte/scp/tickets.php?id=19706)
- **Código de ticket:** #770666
- **Fecha de apertura:** 22/07/2026
- **Reportante:** Nancy Ganza (nganza@buenosaires.gob.ar)
- **Hospital afectado:** Medrano
- **Estado:** Validación Usuario Final (resuelto)
- **Departamento:** Soporte Nivel 3 — Tema "Tableros BI"

### Descripción del reporte

> "Encontramos inconsistencias en algunos Anexos que figuran en estado cerrado en el tablero de recupero de gasto, pero en Sigehos están en otro estado 'reservado' desde el 30-6."

### Diagnóstico

#### Síntoma técnico

Al ejecutar la V2 del pipeline (`connection_PHPMyAdmin.py` → bloque `run_v2`), el `DELETE` previo a la inserción en Postgres SIF sobre `sigehos_anexos_recupero` no completaba en tiempo razonable, dando la sensación de que "no borraba" y sin errores visibles en consola.

#### Estado del proceso al momento del diagnóstico

La extracción desde Oracle terminaba correctamente (log `Extracción finalizada` a las 16:55:41). El cuello de botella **no estaba en Oracle** sino en la etapa de borrado/inserción en Postgres. En memoria ya estaban los tres DataFrames listos:

| Dataset | Filas | Columnas |
|---|---|---|
| anexos | 533.439 | 15 |
| dphs | 105.888 | 13 |
| crgs | 99.599 | 11 |

#### Investigación

Se abrió una segunda conexión a `SIF` y se consultó `pg_stat_activity` para ver las queries activas:

```sql
SELECT pid, state, now() - query_start AS duracion, wait_event_type, left(query, 120) AS query
FROM pg_stat_activity
WHERE datname = 'SIF' AND state <> 'idle'
ORDER BY query_start;
```

Evidencia:

| pid | state | duracion | wait_event_type | query |
|---|---|---|---|---|
| 28836 | active | 00:04:59 | **IO** | `DELETE FROM sigehos_anexos_recupero WHERE fecha BETWEEN '2025-07-22' AND '2026-07-22' AND origin = 'recupero_v2'` |

- El `DELETE` estaba **activo**, no colgado ni bloqueado por lock.
- `wait_event_type = IO` (lectura de disco) descarta bloqueo por otra transacción.
- Duración creciente (~5 min y subiendo).

Se descartó también la sospecha inicial de "error silencioso" del bloque `except` de `delete_part_v2` (que imprime pero no relanza) porque la query estaba efectivamente ejecutándose.

#### Causa raíz técnica

**El `DELETE` estaba haciendo un *full table scan* sobre `sigehos_anexos_recupero` por ausencia de índice sobre las columnas del `WHERE` (`origin`, `fecha`).** La query en sí era correcta y sintácticamente equivalente a la de V1; el problema era de rendimiento: sin índice, Postgres recorre las cientos de miles de filas para localizar las del rango, lo que explica la lentitud y la percepción de que "no borraba".

Factores agravantes secundarios:

- `execute_values` con `page_size = 100` (default) → miles de round-trips de red para insertar 533k filas.
- `time_module.sleep(180)` fijo al final del script, sumando 3 minutos innecesarios por corrida.

### Causa funcional del código (por qué el ticket veía "cerrado" vs "reservado")

Esta es la conexión entre el problema técnico y lo que la usuaria vio en el tablero:

1. **El script sigue una estrategia `DELETE + INSERT` por rango**, definida en `delete_part_v2` seguida de `Postgres_Insert_values`:

    ```python
    # simplificado:
    delete_part_v2(conn, table='sigehos_anexos_recupero',
                   date1=since, date2=until, origin='recupero_v2')
    Postgres_Insert_values(conn, df=anexos_v2, table='sigehos_anexos_recupero')
    ```

    Cuando esa secuencia **completa correctamente**, la tabla queda con la versión más reciente de cada anexo tal como está en Sigehos hoy.

2. **Cuando el `DELETE` no termina** (o el proceso se aborta / se supera un timeout / el operador corta el script viendo que "no avanza"), la tabla `sigehos_anexos_recupero` queda **con los registros viejos del rango**. Los INSERT posteriores nunca llegan a ejecutarse, o si lo hacen sobre datos no borrados generan estados inconsistentes.

3. **En el tablero, cada anexo se muestra con el `estado` de la tabla en SIF**. Si el registro nunca se refrescó, el usuario ve el **estado histórico** (por ejemplo `"cerrado"`), aunque en Sigehos ese anexo ya haya cambiado a `"reservado"` (30-6 en el ticket).

4. Por eso el síntoma del ticket es una **inconsistencia funcional visible en el tablero de Recupero de Gastos**: los anexos aparecen en un estado que no coincide con Sigehos, con desfase de días. La causa raíz de esa inconsistencia funcional es que el DELETE + INSERT no está terminando, y esto se debe al full table scan sin índice sobre `(origin, fecha)`.

**En resumen:**

> `DELETE` sin índice de soporte → full table scan → duración creciente / no termina → los cambios de estado de Sigehos no se materializan en SIF → el tablero muestra estado histórico → el usuario percibe "inconsistencia" entre Sigehos y el tablero.

Corregir la causa técnica (crear los índices) resuelve simultáneamente la causa funcional: el proceso vuelve a completar en segundos, cada corrida reemplaza el estado por el vigente en Sigehos y el tablero refleja lo real.

### Fix implementado

1. **Creación de índices `(origin, fecha)`** sobre las 3 tablas de la integración (prioridad alta):

    ```sql
    CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_anexos_origin_fecha
      ON sigehos_anexos_recupero (origin, fecha);

    CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_crg_origin_fecha
      ON sigehos_crg_recupero (origin, fecha);

    CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_dph_origin_fecha
      ON sigehos_dph_recupero (origin, fecha);
    ```

    Con estos índices, el mismo `DELETE` que tardaba ~5 minutos pasa a resolverse en segundos. Se usa `CONCURRENTLY` para no tomar lock sobre la tabla durante la creación.

2. **Aumento del `page_size` de inserción** en `Postgres_Insert_values` (`HelperFunctions.py`):

    ```python
    extras.execute_values(cursor, query, tuples, page_size=1000)
    ```

3. **Reducción del `sleep` final** de 180 s a 5–10 s. El `close()` de las conexiones ya es sincrónico y no requiere 3 minutos.

4. **Mejora preventiva de visibilidad** en `delete_part_v2` para relanzar la excepción y evitar fallos silenciosos futuros:

    ```python
    except (Exception, psycopg2.DatabaseError) as error:
        conn.rollback()
        print(f"[{table}] ERROR en delete_part_v2: {error}")
        raise
    ```

### Referencias

- Informe de diagnóstico completo: `informe_diagnostico_v2_recupero.md` (22/07/2026, autor: Ivan Achenbach).
- Componente afectado: `connection_PHPMyAdmin.py` → bloque `run_v2`.
- Tabla principal afectada: `sigehos_anexos_recupero` (SIF).