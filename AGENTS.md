# AGENTS.md — Guía para agentes LLM sobre el DW de FACOEP

> **Audiencia:** este archivo está escrito para un **agente LLM** que debe responder preguntas de usuarios sobre los datos del DataWarehouse de FACOEP. **No** está pensado para lectura humana lineal: es un manual de referencia para que el agente arme la query SQL correcta y dé una interpretación adecuada de los resultados.
>
> Cuando un humano necesite la documentación, debe ir a `docs/tablas/` (modelo de datos) y `docs/reportes_dba/` (reportes BI). Este archivo asume que esos otros docs existen y los referencia.

---

## 0. Cómo usar este documento (para el agente)

Cuando recibas una pregunta sobre datos:

1. **Identificá la intención** en la sección 4 ("Árbol de decisión por intención"). Si la pregunta cae en más de una intención, pedí desambiguación al usuario.
2. **Resolvé los términos del usuario** contra la sección 3 ("Glosario operacional → tabla canónica"). El usuario puede decir "factura", "OS", "efector", "impugnación" — cada uno tiene una tabla y campo canónico.
3. **Decidí la tabla origen**:
   - Si la métrica está **materializada** (sección 9), usá esa tabla. **NO** recalcules desde tablas crudas si ya hay una tabla derivada que resuelve el caso.
   - Si no, usá la tabla canónica de la sección 3 + joins de la sección 5.
4. **Aplicá siempre los filtros obligatorios** de la sección 6.
5. **Validá contra "trampas comunes"** (sección 7) antes de devolver SQL.
6. **Devolvé al usuario:**
   - El SQL ejecutable.
   - Una interpretación en lenguaje natural (1–3 líneas) que explique *qué está midiendo* y *cuál es la regla de negocio aplicada*.
   - Si la pregunta toca un caso ambiguo / con regla tribal (sección 10), citá explícitamente la regla.
7. Si no encontrás la respuesta acá, **NO inventes**. Decí: "no tengo regla canónica para X; necesito confirmar con el equipo."

---

## 1. Bases y conexiones

| Alias | Host | Base | Rol |
|---|---|---|---|
| Producción | `10.22.1.61` | `facoep` | Origen transaccional. **NO consultar directo** desde reportes; usar SIF (DW). |
| SIF | `10.22.1.44` | `SIF` | DataWarehouse principal. Es el destino habitual de queries de reporting. |
| DBA | `10.22.1.44` | `DBA` | Tablas custom / agregadas. Vive acá lo materializado por procesos Python (objetivos, débitos aceptados, cobranza por prestación, etc.). |
| SIF_HISTORICAL | `10.22.1.44` | `SIF_HISTORICAL` | Snapshots diarios de algunas tablas (ej: `wwcomprobantes_historial`, `informes_hospitalizacion_historical`). |
| Sigehos consolidado | `172.31.24.12` | `sigehos_recupero` | Consolidación legacy de bases SIGEHOS por hospital. Reemplazado por `sigehos_*_recupero` en SIF. |

**Default para una pregunta de reporting:** SIF. Si la pregunta es sobre métricas mensuales agregadas (objetivos, NC aceptadas), DBA.

---

## 2. Familias de comprobantes (catálogo crítico)

Toda métrica de facturación / cobranza / impugnación depende de filtrar por la familia correcta de `wwcomprobantes.tipo`. Mapeo canónico (de [docs/tablas/wwcomprobantes.md](docs/tablas/wwcomprobantes.md)):

| Tipo | Familia | Subfamilia | Unidad de negocio |
|---|---|---|---|
| FACA2, FACB2, FAECA, FAECB | **Facturas FACOEP** | Factura | FACOEP |
| NCA, NCB, NCECA | **Créditos FACOEP** | Nota de Crédito | FACOEP |
| NDA, NDB | **Débitos FACOEP** | Nota de Débito | FACOEP |
| FACASIA, FACASIB | Facturas ASI | Factura | ASI |
| NCAASI, NCBASI | Créditos ASI | Nota de Crédito | ASI |
| NDAASI, NDASIB | Débitos ASI | Nota de Débito | ASI |
| **NOTADB** | **Impugnaciones FACOEP** | Impugnaciones | FACOEP |
| RECX2, RECM | Recibos | Recibo | FACOEP |

**Reglas de uso:**

- **Facturado FACOEP** → `tipo IN ('FACA2','FACB2','FAECA','FAECB')` + típicamente `centro_costo = 'FACOEP'`.
- **Impugnaciones** → `tipo = 'NOTADB'`. Es la **única** familia que registra impugnaciones de obras sociales / clientes.
- **NC por aceptación de impugnación** → `tipo IN ('NCA','NCB','NCECA')` + `detalle LIKE 'Impugnación aceptada como resultado de la auditoria correspondiente realizada%'`. El filtro del `detalle` es **imprescindible**: hay NC por otros motivos que NO son por aceptar impugnación.
- **Cobranza** → `tipo IN ('RECX2','RECM')`.
- **ASI vs FACOEP** → si el usuario habla de "FACOEP" sin más, asumir unidad de negocio FACOEP y excluir ASI.

---

## 3. Glosario operacional → tabla / campo canónico

Tabla de mapeo "el usuario dice X" → "uso esta tabla y este campo". Usar esto antes de armar cualquier query.

| Término del usuario | Significa | Tabla canónica | Campo / filtro |
|---|---|---|---|
| CRG | Comprobante de Recupero de Gastos | `crg` (cabecera) / `comprobantecrg` (cabecera facturada) / `comprobantecrgdet` (detalle facturado) / `detallecrg` (detalle pre-comprobante) | `nro_crg + id_proveedor` |
| DPH / CPH | Detalle de Prestación Hospitalaria | `crgdet` / `comprobantecrgdet` | `crgdetnumerocph` / `dph` |
| Factura | Comprobante de venta FACOEP | `wwcomprobantes` | `tipo IN ('FACA2','FACB2','FAECA','FAECB')` |
| NOTADB / Impugnación | Documento que registra una impugnación | `wwcomprobantes` + `comprobantecrgdet` | `c.tipo = 'NOTADB'` |
| NC / Nota de Crédito | Crédito FACOEP (acepta impugnación) | `wwcomprobantes` o **mejor** `efectores_montos_aceptados` (DBA, materializada) | `tipo IN ('NCA','NCB','NCECA')` |
| Recibo | Cobranza | `wwcomprobantes` | `tipo IN ('RECX2','RECM')` |
| Cliente / OS / Obra Social | Quién paga la factura | `wwcomprobantes.id_entidad` o `clientes.clienteid` o `obrassociales.obsocialescodigo` | depende del contexto |
| Efector / Hospital / Proveedor | Quién prestó el servicio | `efectores` (lookup) / `proveedorprestador` (origen) | `id_proveedor / pprid` |
| Afiliado / Paciente | El paciente | `comprobantecrgdet` / `detallecrg` | `numero_documento_afiliado`, `numero_afiliado` |
| Centro de Costo | Asignación contable | `wwcomprobantes.centro_costo` o `centrocostos` | `centro_costo` (string), `ccostocodigo` |
| Periodo | Mes/año del CRG | `crg.crgperiodnum` o `comprobantecrg.periodo` | `periodo` |
| Cápita / Extracápita | Modalidad de convenio PAMI | `informehospprestmodo` (1 = Capita, otro = ExtraCapita) | derivado |
| Cumplimiento de objetivo | Facturado neto vs objetivo | `objetivos_efectores` (DBA) | `total_neto_mes / objetivo` |
| Débito médico aceptado | NC por impugnación aceptada | `efectores_montos_aceptados` (DBA) | `aceptado_NC` |
| Cobranza por prestación | Recibos abiertos a prestación/CRG | `cobranza_prestaciones_data` (DBA) | tabla materializada |
| Saldo / Deuda | Saldo pendiente del comprobante | `wwcomprobantes` | `saldo` |
| Anulado | Comprobante anulado | `wwcomprobantes` | `es_anulado = 'SI'` (`detalle LIKE '%ANULADO%'`) |
| Refacturación | Marca de refacturación | `wwcomprobantes` | `es_refacturacion = 'SI'` |
| OME | Orden Médica Electrónica | `orden_medica_electronica` | - |
| OP | Orden de Prestación | `autorizaciones_practicas.op` | - |
| Internación / Informe Hospitalización | Internación de afiliado | `informes_hospitalizacion` + `informes_hospitalizacion_practicas` | `numero_informe` |

---

## 4. Árbol de decisión por intención

Cada entrada describe una **pregunta tipo** que el usuario podría hacer y la **decisión de tabla / lógica** que el agente debe tomar.

### 4.1 ¿Cuánto se facturó?

**Intención:** facturación bruta emitida (no neto, no cobrado).

**Decisión:**

- A nivel **comprobante / cabecera** → `wwcomprobantes`, sumar `importe_total`.
- A nivel **CRG** → `comprobantecrg`, sumar `importe_facturado`.
- A nivel **prestación dentro del CRG** → `comprobantecrgdet`, sumar `importe_a_facturar`.
- Si la pregunta es "facturación de un mes para los objetivos / cumplimiento" → usar la pre-agregada en `objetivos_efectores.total_facturado_mes` (DBA).

**Filtro obligatorio:** `tipo IN ('FACA2','FACB2','FAECA','FAECB')`. Si es FACOEP puro → `+ centro_costo = 'FACOEP'`.

**Documentación detallada:**
- [docs/tablas/wwcomprobantes.md](docs/tablas/wwcomprobantes.md)
- [docs/tablas/comprobantecrg.md](docs/tablas/comprobantecrg.md)
- [docs/tablas/comprobantecrgdet.md](docs/tablas/comprobantecrgdet.md)
- [docs/reportes_dba/Efectores_V2.md](docs/reportes_dba/Efectores_V2.md) — Hoja 1

---

### 4.2 ¿Cuánto se cobró?

**Intención:** cobranza efectiva (recibos imputados a facturas).

**Decisión:**

- A nivel **recibo a cabecera** → `wwcomprobantes WHERE tipo IN ('RECX2','RECM')`.
- A nivel **prestación cobrada** → `cobranza_prestaciones_data` (DBA materializada, rango móvil 180 días).
- Si pregunta "cobrado post-intimación" → script ad-hoc `Pagos_por_Intimaciones.R` (no hay tabla materializada).

**Filtro obligatorio:** `comprobanteentidadcodigo <> -1`.

**Documentación:**
- [docs/reportes_dba/cobranza_por_prestaciones.md](docs/reportes_dba/cobranza_por_prestaciones.md)
- [docs/reportes_dba/Pagos_por_Intimaciones.md](docs/reportes_dba/Pagos_por_Intimaciones.md)

---

### 4.3 ¿Cuánto se impugnó?

**Intención:** impugnaciones emitidas por las OS / clientes contra facturas FACOEP.

**Decisión:** `wwcomprobantes` JOIN `comprobantecrgdet` filtrando por NOTADB.

**Filtros obligatorios:**

```sql
c.tipo = 'NOTADB'
AND nro_crg IS NOT NULL
AND efector  IS NOT NULL
```

**Importante:** sumar `det.importe_a_debitar` para "rechazado" y `det.importe_a_acreditar` para "aceptado".

**Filtro `rechazada` (auto-generado por refacturación):** Las NOTADB con `c.detalle LIKE '%Comprobante generado automáticamente por copia de NOTADB por refacturación.(Rechazo)%'` son **duplicados administrativos**. Por defecto, **excluirlas** (`rechazada = 'NO'`). Si el usuario pide explícitamente las refacturaciones, mantenerlas.

**Documentación:**
- [docs/reportes_dba/Efectores_V2.md](docs/reportes_dba/Efectores_V2.md) — Hojas 3, 4, 5

---

### 4.4 ¿Cuánto se aceptó como NC (débitos aceptados)?

**Intención:** lo efectivamente acreditado al cliente vía Nota de Crédito por una impugnación aceptada.

**Decisión:** **usar la tabla materializada** `DBA.efectores_montos_aceptados`. **NO recalcular** desde `wwcomprobantes` salvo que la pregunta exceda el rango móvil de 45 días que tiene el proceso.

**Filtros obligatorios** (si por alguna razón hay que recalcular desde wwcomprobantes):

```sql
c.tipo IN ('NCA','NCB','NCECA')
AND c.detalle LIKE 'Impugnación aceptada como resultado de la auditoria correspondiente realizada%'
AND c.centro_costo = 'FACOEP'
AND nro_crg IS NOT NULL
AND efector  IS NOT NULL
```

**Documentación:**
- [docs/reportes_dba/Efectores_V2.md](docs/reportes_dba/Efectores_V2.md) — Hoja 6

---

### 4.5 ¿Está cumpliendo el objetivo X efector?

**Intención:** % de cumplimiento de objetivo mensual.

**Decisión:** **usar `DBA.objetivos_efectores`** (tabla materializada). NO reconstruir.

**Métricas listas:**

```sql
SELECT efector, anio, mes,
       total_facturado_mes,
       total_nc_mes,
       total_neto_mes,
       objetivo,
       (total_neto_mes / NULLIF(objetivo,0)) * 100 AS pct_cumplimiento
FROM objetivos_efectores
WHERE anio = ... AND mes = ...
```

**Aviso al usuario si filtra por año < 2026:** la tabla solo materializa de 2026 en adelante. Datos previos pueden estar incompletos.

**Documentación:**
- [docs/reportes_dba/Efectores_V2.md](docs/reportes_dba/Efectores_V2.md) — Hoja 7

---

### 4.6 ¿Qué prestaciones / CRGs hizo X afiliado?

**Intención:** historial asistencial de un afiliado.

**Decisión:**

- Post-comprobante (lo facturado): `comprobantecrgdet WHERE numero_documento_afiliado = '<DNI>'`.
- Pre-comprobante (todo lo cargado, aún sin facturar): `detallecrg WHERE numero_documento = '<DNI>'`.

**Documentación:**
- [docs/tablas/comprobantecrgdet.md](docs/tablas/comprobantecrgdet.md)
- [docs/tablas/detallecrg.md](docs/tablas/detallecrg.md)

---

### 4.7 ¿Cuál es el estado / historia de un CRG?

**Intención:** trazabilidad operativa del CRG.

**Decisión:**

- **Estado actual** → `crg WHERE nro_crg = ... AND id_proveedor = ...` (campo `estado_actual`).
- **Línea de tiempo de cambios** → `crg_historial`, ordenado por `fecha`.

**Documentación:**
- [docs/tablas/crg.md](docs/tablas/crg.md)
- [docs/tablas/crg_historial.md](docs/tablas/crg_historial.md)

---

### 4.8 ¿Datos de SIGEHOS (hospitales del GCBA)?

**Intención:** información de CRGs / DPHs / Anexos provenientes de los hospitales públicos.

**Decisión:** usar las tablas `sigehos_*_recupero` (ya consolidadas en SIF):

- `sigehos_crg_recupero` (cabecera CRG GCBA)
- `sigehos_dph_recupero` (detalle DPH)
- `sigehos_anexos_recupero` (anexos / remitos)

**NO usar** las tablas legacy `crg_recupero`, `dph_recupero`, `anexos_recupero` (vivían en el proceso `Conexion CRGs` viejo).

**Documentación:**
- [docs/tablas/integracion_recupero_gastos.md](docs/tablas/integracion_recupero_gastos.md)

---

### 4.9 ¿Qué autorizaciones / OPs tiene un afiliado?

**Intención:** flujo ambulatorio.

**Decisión:**

- Cabecera: `autorizaciones`.
- Detalle de prácticas autorizadas: `autorizaciones_practicas`.
- OME: `orden_medica_electronica`.

**Documentación:**
- [docs/tablas/autorizaciones.md](docs/tablas/autorizaciones.md)
- [docs/tablas/autorizaciones_practicas.md](docs/tablas/autorizaciones_practicas.md)
- [docs/tablas/orden_medica_electronica.md](docs/tablas/orden_medica_electronica.md)

---

### 4.10 ¿Internaciones?

**Intención:** flujo de hospitalización.

**Decisión:**

- Cabecera: `informes_hospitalizacion`.
- Detalle de prácticas: `informes_hospitalizacion_practicas`.
- Snapshot histórico diario: `informes_hospitalizacion_historical` (en SIF_HISTORICAL).

**Documentación:**
- [docs/tablas/informes_hospitalizacion.md](docs/tablas/informes_hospitalizacion.md)
- [docs/tablas/informe_hospitalizacion_practicas.md](docs/tablas/informe_hospitalizacion_practicas.md)

---

### 4.11 ¿Auditoría médica?

**Intención:** quién audita, cuánto, qué importe agrega.

**Decisión:**

- Detalle por importe: `auditoria_medica_importe`.
- Detalle por usuario: `auditoria_medica_usuarios`.
- Catálogo: `auditoria_medica_centros`.

**Documentación:**
- [docs/tablas/auditoria_medica.md](docs/tablas/auditoria_medica.md)
- [docs/reportes_dba/AuditoriaMedica.md](docs/reportes_dba/AuditoriaMedica.md)

---

### 4.12 ¿Salud / monitoreo del DW (frescura, alertas)?

**Intención:** pregunta operativa: ¿está actualizado el DW?

**Decisión:**

- Frescura por tabla → proceso `datawarehouse_alerts` (mail + Excel `TablasDesactualizadas.xlsx`).
- Volumen por tabla → proceso `conteo_tablas` (Excel diario por entorno).

**Documentación:**
- [docs/reportes_dba/datawarehouse_alerts.md](docs/reportes_dba/datawarehouse_alerts.md)
- [docs/tablas/conteo_tablas.md](docs/tablas/conteo_tablas.md)

---

## 5. Joins canónicos

El agente NO debe inventar el join. Estos son los patrones literales a copiar.

### 5.1 wwcomprobantes ↔ comprobantecrgdet (cabecera ↔ detalle)

```sql
LEFT JOIN comprobantecrgdet det
  ON c.comprobante = det.comprobante
 AND c.id_entidad  = det.id_entidad
 AND c.entidad     = det.tipo_entidad
```

### 5.2 wwcomprobantes ↔ comprobantecrg (cabecera ↔ cabecera CRG)

```sql
LEFT JOIN comprobantecrg crg
  ON c.comprobante = crg.comprobante
```

### 5.3 comprobantecrg ↔ crg (cabecera facturada ↔ cabecera maestra)

```sql
LEFT JOIN crg
  ON crg.id_proveedor = comprobantecrg.id_proveedor
 AND crg.nro_crg      = comprobantecrg.nro_crg
```

### 5.4 detallecrg / comprobantecrgdet ↔ efectores

```sql
LEFT JOIN efectores ef
  ON det.id_proveedor = ef.id_proveedor
```

### 5.5 wwcomprobantes ↔ clientes (id_entidad = clienteid cuando entidad = 'Cliente')

```sql
LEFT JOIN clientes cl
  ON cl.clienteid = c.id_entidad
```

### 5.6 crg ↔ obrassociales

```sql
LEFT JOIN obrassociales os
  ON crg.id_obra_social = os.obsocialescodigo
```

### 5.7 wwcomprobantes ↔ comprobantesimputaciones (factura ↔ recibo imputado)

```sql
LEFT JOIN comprobantesimputaciones ci
  ON ci.empcod                    = c.empcod
 AND ci.sucursalcodigo            = c.sucursalcodigo
 AND ci.comprobantetipoentidad    = c.comprobantetipoentidad
 AND ci.comprobanteentidadcodigo  = c.comprobanteentidadcodigo
 AND ci.tipocomprobantecodigo     = c.tipocomprobantecodigo
 AND ci.comprobanteprefijo        = c.comprobanteprefijo
 AND ci.comprobantecodigo         = c.comprobantecodigo
```

### 5.8 wwcomprobantes ↔ comprobanteshistorial (estado / entrega)

```sql
LEFT JOIN (
    SELECT comprobanteentidadcodigo, tipocomprobantecodigo, comprobantecodigo,
           MAX(comprobantehisfechatramite) AS entrega
    FROM comprobanteshistorial
    WHERE comprobantehisestado = 4
    GROUP BY 1,2,3
) h
  ON h.comprobanteentidadcodigo = c.comprobanteentidadcodigo
 AND h.tipocomprobantecodigo    = c.tipocomprobantecodigo
 AND h.comprobantecodigo        = c.comprobantecodigo
```

---

## 6. Filtros obligatorios (lo que SIEMPRE va)

| Contexto | Filtro |
|---|---|
| Cualquier query sobre `wwcomprobantes` o `comprobantes` | `comprobanteentidadcodigo <> -1` |
| Facturas FACOEP | `tipo IN ('FACA2','FACB2','FAECA','FAECB')` |
| Solo unidad FACOEP (excluir ASI) | `+ centro_costo = 'FACOEP'` |
| NOTADB | `c.tipo = 'NOTADB' AND nro_crg IS NOT NULL AND efector IS NOT NULL` |
| NOTADB excluyendo refacturaciones automáticas | `+ NOT (c.detalle LIKE '%Comprobante generado automáticamente por copia de NOTADB por refacturación.(Rechazo)%')` |
| NC por aceptación de impugnación | `c.tipo IN ('NCA','NCB','NCECA') AND c.detalle LIKE 'Impugnación aceptada%' AND c.centro_costo = 'FACOEP' AND nro_crg IS NOT NULL AND efector IS NOT NULL` |
| Cobranza | `c.tipo IN ('RECX2','RECM')` |
| Convenio PAMI internaciones | `afitpamiprofe = 1 AND InformeHospBajaFecha IS NULL` |
| Anexos PAMI Sigehos | `obrasocial.os_nombre = 'FACOEP PAMI'` |

---

## 7. Trampas comunes (NO hacer)

❌ **NO confundir `recupero_gastos` (tabla custom de SIF generada por proceso R) con `sigehos_*_recupero` (tablas que vienen de la integración SIGEHOS).** Son dominios distintos. Ver sección 4.8 vs Hoja 2 de Efectores V2.

❌ **NO sumar NOTADB al facturado.** La NOTADB es impugnación, no factura. Si querés "facturado neto", restá NC aceptadas (ver 4.4 / 4.5).

❌ **NO calcular "facturado neto" como `facturado − NOTADB`.** El neto se calcula contra **NCs aceptadas**, no contra NOTADBs (no toda impugnación se acepta). Fórmula correcta: `total_neto_mes = total_facturado_mes - total_nc_mes` (de `objetivos_efectores`).

❌ **NO consultar `comprobantes` (tabla de Producción) directo desde un reporte.** Usar `wwcomprobantes` (DW). Único caso de excepción: necesitás un campo que el DW no tiene mapeado.

❌ **NO sumar `importe_a_debitar + importe_a_acreditar` como "total".** Son destinos opuestos: uno es lo rechazado (no se cobra), otro es lo aceptado (se acredita por NC).

❌ **NO usar las tablas legacy `crg_recupero`, `dph_recupero`, `anexos_recupero`.** Vivían en `sigehos_recupero`. Reemplazadas por `sigehos_crg_recupero`, `sigehos_dph_recupero`, `sigehos_anexos_recupero` en SIF.

❌ **NO mezclar familias de comprobantes en un mismo SUM sin signos.** Si vas a netear facturas con NC en una sola query, multiplicá por el `Multiplicador` del Excel `tipo_comprobante.xlsx` (+1 / -1) o separá por familia.

❌ **NO asumir que `centro_costo = 'FACOEP'` es default.** En el sistema conviven FACOEP y ASI; muchas tablas tienen ambas. Filtrá explícitamente si el usuario habla de FACOEP.

❌ **NO buscar "objetivos" en SIF.** Viven en `DBA.objetivos_mensuales` (input manual) y `DBA.objetivos_efectores` (procesado).

❌ **NO usar `obsocialescodigo` para joinear con `clientes`**: la clave es `obsocialesclienteid` → `clienteid`.

❌ **NO sumar todo `aceptado_NC` y `aceptado_notadb` indiscriminadamente** en `efectores_montos_aceptados`. `aceptado_NC` es lo de la NC; `aceptado_notadb` es lo del NOTADB original (puede coincidir o no). El valor canónico para cumplimiento es `aceptado_notadb` (que es lo que `objetivos_efectores` toma como `total_nc_mes`).

❌ **NO ignorar que `objetivos_efectores` filtra `anio >= 2026`.** Si el usuario filtra años previos, advertir.

❌ **NO sumar internaciones de `informes_hospitalizacion` directamente con su histórico** (`informes_hospitalizacion_historical`): el histórico tiene una fila por día por informe (snapshot), suma duplica.

---

## 8. Patrones SQL listos (cookbook)

Esqueletos canónicos. El agente los adapta al filtro / agrupamiento que pida el usuario.

### 8.1 Facturado por efector y mes

```sql
SELECT
    ef.nombre_proveedor                        AS efector,
    EXTRACT(YEAR  FROM c.fecha_emision)::int   AS anio,
    EXTRACT(MONTH FROM c.fecha_emision)::int   AS mes,
    SUM(crg.importe_facturado)                 AS total_facturado
FROM comprobantecrg crg
LEFT JOIN wwcomprobantes c
  ON crg.comprobante = c.comprobante
LEFT JOIN efectores ef
  ON crg.id_proveedor = ef.id_proveedor
WHERE crg.tipo IN ('FACA2','FACB2','FAECA','FAECB')
  AND c.centro_costo = 'FACOEP'
GROUP BY 1,2,3
ORDER BY 2,3,1;
```

### 8.2 Impugnaciones (NOTADB) por efector / motivo

```sql
SELECT
    ef.nombre_proveedor                AS efector,
    det.motivo_debito                  AS tipo_debito,
    det.categoria_motivo_debito        AS categoria,
    det.motivo_debito_credito          AS motivo,
    SUM(det.importe_a_debitar)         AS rechazado,
    SUM(det.importe_a_acreditar)       AS aceptado
FROM wwcomprobantes c
LEFT JOIN comprobantecrgdet det
  ON c.comprobante = det.comprobante
 AND c.id_entidad  = det.id_entidad
 AND c.entidad     = det.tipo_entidad
LEFT JOIN efectores ef
  ON det.id_proveedor = ef.id_proveedor
WHERE c.tipo = 'NOTADB'
  AND det.nro_crg IS NOT NULL
  AND ef.efector  IS NOT NULL
  -- excluir refacturaciones automáticas:
  AND c.detalle NOT LIKE '%Comprobante generado automáticamente por copia de NOTADB por refacturación.(Rechazo)%'
GROUP BY 1,2,3,4
ORDER BY rechazado DESC;
```

### 8.3 Cumplimiento mensual (usa tabla materializada)

```sql
SELECT
    efector,
    anio, mes,
    total_facturado_mes,
    total_nc_mes,
    total_neto_mes,
    objetivo,
    CASE WHEN objetivo > 0
         THEN ROUND((total_neto_mes / objetivo) * 100, 2)
         ELSE NULL
    END AS pct_cumplimiento
FROM objetivos_efectores
WHERE anio = :anio AND mes = :mes
ORDER BY pct_cumplimiento DESC NULLS LAST;
```

### 8.4 Facturación por DNI (afiliado)

```sql
SELECT
    det.efector,
    det.financiador,
    det.tipo_prestacion,
    det.fecha_prestacion,
    det.nro_crg,
    det.practica,
    SUM(det.importe_a_facturar) AS facturado
FROM comprobantecrgdet det
WHERE det.tipo IN ('FACB2','FACA2','FAECA','FAECB')
  AND TRIM(det.tipo_documento_afiliado) = 'DNI'
  AND det.numero_documento_afiliado = :dni
  AND det.fecha_prestacion >= :desde
GROUP BY 1,2,3,4,5,6;
```

### 8.5 Estado actual + historia de un CRG

```sql
-- Estado actual
SELECT * FROM crg
WHERE nro_crg = :nro_crg AND id_proveedor = :id_proveedor;

-- Historia
SELECT fecha, estado, usuario, observacion
FROM crg_historial
WHERE nro_crg = :nro_crg AND id_proveedor = :id_proveedor
ORDER BY fecha;
```

### 8.6 Cobranza efectiva por factura (post-imputación)

```sql
SELECT
    c.comprobante                       AS factura,
    c.fecha_emision,
    c.importe_total,
    c.saldo,
    SUM(ci.comprobanteimputacionimporte) AS total_cobrado
FROM wwcomprobantes c
LEFT JOIN comprobantesimputaciones ci
  ON ci.empcod                   = c.empcod
 AND ci.sucursalcodigo           = c.sucursalcodigo
 AND ci.comprobantetipoentidad   = c.comprobantetipoentidad
 AND ci.comprobanteentidadcodigo = c.id_entidad
 AND ci.tipocomprobantecodigo    = SUBSTRING(c.comprobante FROM 1 FOR POSITION('-' IN c.comprobante)-1)
 -- nota: el join real desde wwcomprobantes requiere descomponer 'comprobante'
WHERE c.tipo IN ('FACA2','FACB2','FAECA','FAECB')
GROUP BY 1,2,3,4;
```

> Nota: el join correcto entre `wwcomprobantes` y `comprobantesimputaciones` requiere descomponer el campo `comprobante` o trabajar contra la tabla origen `comprobantes` con la PK compuesta. Ver patrón 5.7.

### 8.7 Top 10 OS con mayor facturación del mes

```sql
SELECT
    cl.clientenombre AS obra_social,
    SUM(c.importe_total) AS total
FROM wwcomprobantes c
LEFT JOIN clientes cl ON cl.clienteid = c.id_entidad
WHERE c.tipo IN ('FACA2','FACB2','FAECA','FAECB')
  AND c.centro_costo = 'FACOEP'
  AND EXTRACT(YEAR  FROM c.fecha_emision) = :anio
  AND EXTRACT(MONTH FROM c.fecha_emision) = :mes
GROUP BY 1
ORDER BY total DESC
LIMIT 10;
```

---

## 9. Cuándo NO escribir SQL ad-hoc — preferir tabla materializada

Si la pregunta del usuario cae en alguno de estos casos, **leer la tabla materializada**, no recalcular:

| Pregunta apunta a... | Usar (no recalcular) | Doc |
|---|---|---|
| Cumplimiento mensual de objetivos | `DBA.objetivos_efectores` | [Hoja 7 Efectores V2](docs/reportes_dba/Efectores_V2.md) |
| NC aceptadas / Débitos médicos aceptados | `DBA.efectores_montos_aceptados` | [Hoja 6 Efectores V2](docs/reportes_dba/Efectores_V2.md) |
| Cobranza por prestación (180 días móvil) | `DBA.cobranza_prestaciones_data` | [docs/reportes_dba/cobranza_por_prestaciones.md](docs/reportes_dba/cobranza_por_prestaciones.md) |
| Detalle de débitos médicos | `DBA.detalle_debitos_medicos` | [docs/reportes_dba/detalle_debitos_medicos.md](docs/reportes_dba/detalle_debitos_medicos.md) |
| Facturación por DNI | `DBA.facturacion_por_dni` | [docs/reportes_dba/Facturacion_por_DNI.md](docs/reportes_dba/Facturacion_por_DNI.md) |
| Tickets DBA (osTicket) | `SIF.os_ticket` | [docs/reportes_dba/OS_Ticket.md](docs/reportes_dba/OS_Ticket.md) |
| Conteo / volumen de tablas | Excel diario en `conteo_tablas/resultados/` | [docs/tablas/conteo_tablas.md](docs/tablas/conteo_tablas.md) |
| Frescura del DW | `TablasDesactualizadas.xlsx` (`datawarehouse_alerts`) | [docs/reportes_dba/datawarehouse_alerts.md](docs/reportes_dba/datawarehouse_alerts.md) |
| Síntesis semanal comercial | Excel mensual `FACOEP Sintesis Semanal {fecha}.xlsx` | [docs/reportes_dba/sintesis_semanal.md](docs/reportes_dba/sintesis_semanal.md) |
| Apertura PAMI Cápita mensual | Excel `Apertura {mes}-{anio}.xlsx` | [docs/reportes_dba/Recupero_Gastos.md](docs/reportes_dba/Recupero_Gastos.md) |
| Informe de créditos (8 casos) | `DBA.informe_creditos` | [docs/reportes_dba/informe_de_creditos.md](docs/reportes_dba/informe_de_creditos.md) |
| Matriz de clientes (Pareto) | reporte `matriz_de_clientes` | [docs/reportes_dba/matriz_de_clientes.md](docs/reportes_dba/matriz_de_clientes.md) |

---

## 10. Reglas tribales (knowledge no codificada en queries)

> **Sección a completar por el equipo.** Reglas que viven en la cabeza de los usuarios y deben aplicarse al interpretar resultados, aunque no estén en los scripts.

<!-- TODO: el equipo debe ir agregando acá reglas como:
     - "Para OS X, históricamente se descuenta Y porque..."
     - "Los CRG con particularidad Z no cuentan en el reporte W"
     - "El efector con id 41 fue rebautizado como 2334 a partir de fecha X"
     - "El multiplicador de NDB es +1 pero su impacto contable es negativo, NO confundir"
     - etc.
-->

### 10.1 Identidades de efector renombradas

| id_efector viejo | id_efector nuevo | Aplicabilidad | Comentario |
|---|---|---|---|
| 41 | 2334 | Solo en `objetivos_mensuales`; el script `main.py` de objetivos lo corrige automáticamente. | _(completar contexto)_ |

### 10.2 Comprobantes con ajustes manuales

| Comprobante | Acción | Razón |
|---|---|---|
| FACB2-1-16901 | Excluir + reemplazar por versión de `crgs_corregidos.xlsx` | Duplicación de monto facturado. |
| FACA2-1-7581 | Excluir + reemplazar | Duplicación de monto facturado. |
| FACB2-1-27492 | Excluir + reemplazar | Duplicación de monto facturado. |

### 10.3 Otras reglas

_(pendiente)_ — completar con conocimiento del equipo.

---

## 11. Preguntas reales recurrentes (knowledge base de preguntas → SQL)

> **Sección a completar.** Acá vamos a ir agregando, una por una, las preguntas reales que recibe el equipo (de Slack, mails, tickets, conversaciones), con la respuesta canónica en SQL + interpretación.

**Plantilla por entrada:**

```markdown
### P: <pregunta literal del usuario>

**Intención canónica:** <reformulación clara>

**Tabla origen:** <tabla principal>

**SQL:**
```sql
<query lista para ejecutar>
```

**Interpretación esperada:** <lo que el agente le devuelve al usuario en lenguaje natural>

**Pitfalls:** <qué advertir si se aplican filtros raros>
```

### 11.1 — ¿Cuánto se factura por DNI?

**Intención canónica:** facturación bruta acumulada por número de documento del afiliado (paciente).

**Tabla origen:**

- **Cálculo en vivo:** `comprobantecrgdet` filtrado por familia de Facturas FACOEP.
- **Atajo materializado (recomendado si la pregunta es recurrente):** `DBA.facturacion_por_dni` (tabla custom generada por el script de [Facturacion_por_DNI](docs/reportes_dba/Facturacion_por_DNI.md)). Limita a `fecha_prestacion > '2024-05-31'`.

**SQL canónico (en vivo, sobre `comprobantecrgdet`):**

```sql
SELECT
    TRIM(det.tipo_documento_afiliado) AS tipo_documento,
    det.numero_documento_afiliado     AS dni,
    SUM(det.importe_a_facturar)       AS total_facturado
FROM comprobantecrgdet det
WHERE det.tipo IN ('FACA2','FACB2','FAECA','FAECB')   -- familia Facturas FACOEP
  -- AND TRIM(det.tipo_documento_afiliado) = 'DNI'    -- descomentar si solo DNI argentinos
  -- AND det.numero_documento_afiliado = :dni         -- descomentar para un DNI puntual
  -- AND det.fecha_prestacion BETWEEN :desde AND :hasta
GROUP BY 1, 2
ORDER BY total_facturado DESC;
```

**Variante usando la tabla materializada:**

```sql
SELECT tipo, numero, SUM(facturado) AS total_facturado
FROM facturacion_por_dni              -- DBA
WHERE numero = :dni
GROUP BY 1, 2;
```

**Interpretación esperada:** "El afiliado con DNI {dni} tiene $X facturados en el período. Es facturación **bruta** (familia Facturas FACOEP); no resta NC ni descuenta impugnaciones."

**Pitfalls:**

- `comprobantecrgdet` agrupa a nivel prestación. Si querés totales por afiliado, agregar `GROUP BY tipo_documento, numero_documento`.
- `numero_documento_afiliado` puede traer espacios; aplicar TRIM cuando se compare por valor exacto.
- Si la respuesta es para un afiliado que tiene prácticas anteriores a `2024-05-31`, la tabla materializada **no las tiene** — caer al cálculo en vivo.

---

### 11.2 — ¿Cuánto se factura por prestación?

**Intención canónica:** facturación bruta acumulada por código de práctica (no por nomenclador, salvo que el usuario aclare).

**Tabla origen:**

- **Cálculo en vivo:** `comprobantecrgdet` filtrado por familia de Facturas FACOEP, agrupando por `practica`.
- **Atajo:** existe un reporte materializado `facturacion_por_prestaciones` en DBA (ver [Facturacion-Migrado](docs/reportes_dba/Facturacion_Migrado.md)) — usar esa tabla solo si la pregunta apunta a la métrica oficial reportada por el área.

**SQL canónico:**

```sql
SELECT
    det.practica,
    det.tipo_prestacion,
    SUM(det.importe_a_facturar) AS total_facturado,
    COUNT(*)                    AS cantidad_lineas
FROM comprobantecrgdet det
WHERE det.tipo IN ('FACA2','FACB2','FAECA','FAECB')   -- familia Facturas FACOEP
  -- AND det.fecha_emision_comprobante BETWEEN :desde AND :hasta
  -- AND det.practica = :practica
GROUP BY 1, 2
ORDER BY total_facturado DESC;
```

**Interpretación esperada:** "La práctica {practica} ({tipo_prestacion}) facturó $X bruto en {N} líneas. Familia Facturas FACOEP."

**Pitfalls:**

- No confundir `practica` con `codigo_nomenclador`: son dos catálogos distintos. Si el usuario habla de "código nomenclador", agrupar por ese campo.
- Si el usuario espera ver el resultado del **PowerBI** "Facturación por Prestaciones", validar que la query coincida con la lógica del reporte (puede tener exclusiones específicas) — preguntar al área.

---

### 11.3 — ¿Cuánto se factura por Efector?

**Intención canónica:** facturación bruta acumulada por proveedor / hospital / efector.

**Tabla origen:**

- **Cálculo en vivo (a nivel prestación):** `comprobantecrgdet` filtrado por familia de Facturas FACOEP.
- **Cálculo en vivo (a nivel CRG):** `comprobantecrg` con `tipo IN ('FACA2','FACB2','FAECA','FAECB')` (más rápido, no abre por prestación).
- **Atajo:** la **Hoja 1 del reporte Efectores V2** ya resuelve este caso ([docs/reportes_dba/Efectores_V2.md](docs/reportes_dba/Efectores_V2.md) → Hoja 1).
- **Pre-agregado mensual:** `DBA.objetivos_efectores.total_facturado_mes` si la pregunta es por mes / cumplimiento de objetivo.

**SQL canónico (a nivel prestación):**

```sql
SELECT
    det.id_proveedor,
    det.efector,
    SUM(det.importe_a_facturar) AS total_facturado
FROM comprobantecrgdet det
WHERE det.tipo IN ('FACA2','FACB2','FAECA','FAECB')   -- familia Facturas FACOEP
  -- AND det.fecha_emision_comprobante BETWEEN :desde AND :hasta
GROUP BY 1, 2
ORDER BY total_facturado DESC;
```

**SQL canónico (a nivel CRG, más rápido):**

```sql
SELECT
    crg.id_proveedor,
    ef.nombre_proveedor          AS efector,
    SUM(crg.importe_facturado)   AS total_facturado
FROM comprobantecrg crg
LEFT JOIN efectores ef
  ON crg.id_proveedor = ef.id_proveedor
WHERE crg.tipo IN ('FACA2','FACB2','FAECA','FAECB')
  -- AND crg.fecha_emision BETWEEN :desde AND :hasta
GROUP BY 1, 2
ORDER BY total_facturado DESC;
```

**Variante mensual (pre-agregada):**

```sql
SELECT id_efector, efector, anio, mes, total_facturado_mes
FROM objetivos_efectores                 -- DBA
WHERE anio = :anio AND mes = :mes
ORDER BY total_facturado_mes DESC;
```

**Interpretación esperada:** "El efector {efector} facturó $X bruto en el período. Familia Facturas FACOEP. (Si pidió neto: ver `objetivos_efectores.total_neto_mes`.)"

**Pitfalls:**

- Si el usuario quiere "neto" (descontando NC aceptadas), **no** restar NOTADBs: usar `total_neto_mes` de `objetivos_efectores`. Ver Trampas 7.
- Para sumar por efector entre `comprobantecrgdet` y `comprobantecrg` se llega al mismo total bruto, pero a nivel detalle puede haber leves diferencias por casos sin prestación. Si el usuario reporta una diferencia entre los dos caminos, advertir y validar.
- `comprobantecrg` tiene además correcciones manuales desde `crgs_corregidos.xlsx` (tres comprobantes con duplicación reemplazada — ver sección 10.2). `comprobantecrgdet` también las refleja porque comparte proceso.

---

### 11.4 — ¿Cuáles son los CRGs que ingresaron al SIF?

**Intención canónica:** universo de CRGs provenientes de los hospitales del GCBA (SIGEHOS) que fueron consolidados en SIF a través del proceso de integración SIGEHOS.

**Tabla origen:** `sigehos_crg_recupero` (en SIF). Es la cabecera de CRGs traídos vía la integración Oracle/MySQL → SIF documentada en [docs/tablas/integracion_recupero_gastos.md](docs/tablas/integracion_recupero_gastos.md).

**NO confundir con:**

- `crg` (cabecera del DW SIF, que es el universo de CRGs del sistema SIF nativo).
- `recupero_gastos` (tabla custom de SIF que cruza CRG con proforma / comprobante FACOEP, ver [Hoja 2 Efectores V2](docs/reportes_dba/Efectores_V2.md)).
- Tablas legacy `crg_recupero` (deprecadas, ver sección 7).

**SQL canónico:**

```sql
SELECT
    fecha,                     -- fecha de emisión del CRG en Sigehos
    numero          AS nro_crg,
    tipo_anexo,
    estado,
    cant_dphs,
    financiador_sigla,
    financiador_nombre,
    importe_total,
    origin,                    -- 'recupero_v2' (Oracle) o nombre de la base MySQL del hospital (V1)
    id_proveedor_sif,
    efector
FROM sigehos_crg_recupero
-- WHERE fecha BETWEEN :desde AND :hasta
-- AND efector = :efector
ORDER BY fecha DESC;
```

**Variante: solo los CRGs que llegaron por Oracle (V2):**

```sql
SELECT *
FROM sigehos_crg_recupero
WHERE origin = 'recupero_v2';
```

**Variante: cantidad de CRGs ingresados por hospital y mes:**

```sql
SELECT
    efector,
    EXTRACT(YEAR  FROM fecha)::int AS anio,
    EXTRACT(MONTH FROM fecha)::int AS mes,
    COUNT(*)                       AS cant_crgs,
    SUM(importe_total)             AS importe_total
FROM sigehos_crg_recupero
GROUP BY 1, 2, 3
ORDER BY 2 DESC, 3 DESC, cant_crgs DESC;
```

**Interpretación esperada:** "Llegaron al SIF {N} CRGs desde SIGEHOS en el período, por un importe total de $X. La fuente puede ser V1 (extracción MySQL por base de hospital) o V2 (Oracle centralizado, `origin = 'recupero_v2'`)."

**Pitfalls:**

- La pregunta "¿Cuáles son los CRGs que ingresaron al SIF?" puede ser ambigua: ¿quiere decir CRGs **desde SIGEHOS hacia SIF** (esta sección) o CRGs **dados de alta en SIF nativamente**? Si dudás, preguntá. El indicador es: si menciona hospitales del GCBA / Sigehos / Recupero de Gastos PAMI, es esta tabla. Si menciona "estados", "auditoría médica", "carga manual", es la tabla `crg` de SIF.
- El proceso tiene ventana móvil (90 días en madrugada / 365 días en horario diurno, ver `integracion_recupero_gastos.md` → "Ventana de extracción"). CRGs anteriores a esa ventana pueden no estar refrescados.
- `tipo_anexo` se normaliza (acentos / capitalización); aplicar TRIM si se compara por valor.
- En V2 (Oracle), el campo `documento` puede venir vacío en `sigehos_dph_recupero`.

---

### 11.5 (Ejemplo) — ¿Cuánto facturó FACOEP en marzo 2025?

**Intención:** facturación bruta del mes para unidad FACOEP.

**Tabla origen:** `wwcomprobantes`.

**SQL:**

```sql
SELECT SUM(c.importe_total) AS total_facturado_marzo_2025
FROM wwcomprobantes c
WHERE c.tipo IN ('FACA2','FACB2','FAECA','FAECB')
  AND c.centro_costo = 'FACOEP'
  AND EXTRACT(YEAR  FROM c.fecha_emision) = 2025
  AND EXTRACT(MONTH FROM c.fecha_emision) = 3;
```

**Interpretación esperada:** "FACOEP facturó $X en marzo 2025 (familia de Facturas FACOEP, unidad FACOEP, sin restar NC ni anular refacturaciones)."

**Pitfalls:** Este es **bruto** (no neto). Si el usuario quería neto → ver sección 4.5 (`objetivos_efectores.total_neto_mes`).

---

## 12. Mantenimiento

- **Cuando se agregue una tabla nueva** al DW, primero se documenta en `docs/tablas/<tabla>.md` y luego se incorpora al árbol de decisión (sección 4) y al glosario (sección 3) de este archivo.
- **Cuando aparezca una pregunta nueva** que recurra, agregarla en sección 11 con su SQL canónico.
- **Cuando se descubra una trampa nueva**, agregarla en sección 7.
- **Cuando una regla tribal se descubra durante una respuesta**, codificarla en sección 10.
- Este archivo es **fuente de verdad para el agente**: si una respuesta sale mal, primero arreglá acá; después arreglás el .md específico.
