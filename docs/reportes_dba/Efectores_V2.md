# Reporte: Efectores V2

## Descripción

Reporte PowerBI **Efectores V2** — versión vigente del tablero de seguimiento de efectores. Está construido por hojas, donde cada hoja se alimenta de una query independiente contra el DW SIF. La documentación se organiza **hoja por hoja**: para cada solapa se describe la query, los campos resultantes, las reglas de negocio aplicadas y las tablas DW involucradas.

A diferencia de los reportes que materializan tabla destino propia, Efectores V2 trabaja en modo Power Query / Import: cada query se ejecuta directamente contra SIF y arma su propio dataset.

---

## Tipo

Reporte / dashboard PowerBI multi-hoja.

---

## Frecuencia

Diaria (refresco contra SIF).

---

## Owner

DBA / BI

---

## Archivo PBIX

`Efectores V2.pbix` (en la carpeta de reportes; otras versiones — `Efectores.pbix`, `Efectores Hospitales.pbix`, `Efectores Viejo` — quedan fuera del alcance de esta documentación por estar deprecadas).

---

## Fuentes DW comunes

Las queries de las hojas combinan principalmente las siguientes tablas del DW SIF:

| Tabla | Documentación |
|---|---|
| `comprobantecrg` | [docs/tablas/comprobantecrg.md](../tablas/comprobantecrg.md) |
| `comprobantecrgdet` | [docs/tablas/comprobantecrgdet.md](../tablas/comprobantecrgdet.md) |
| `wwcomprobantes` | [docs/tablas/wwcomprobantes.md](../tablas/wwcomprobantes.md) |
| `crg` | [docs/tablas/crg.md](../tablas/crg.md) |
| `efectores` | [docs/tablas/tablas_lookup.md](../tablas/tablas_lookup.md) (proceso `tablas_lookup`) |

---

# Hojas del reporte

---

## Hoja 1 — Facturado por Efector - Comprobantes

### Descripción

Hoja que arma el **total facturado por efector a nivel cabecera de comprobante** (un comprobante = una fila del CRG facturado). Cada fila representa un CRG facturado a un cliente con su importe facturado, enriquecido con datos del comprobante (fecha de emisión, centro de costo), del CRG origen (tipo de prestación, fecha de carga) y del efector.

Es la base para visualizaciones del tipo "facturación por efector / cliente / mes / centro de costo / tipo de prestación", trabajando a nivel CRG (sin abrir prestaciones).

### Query

```sql
SELECT
    c.fecha_emision,
    crg.comprobante,
    ef.nombre_proveedor   AS efector,
    ef.id_proveedor       AS id_efector,
    cg.tipo_prestacion,
    crg.nro_crg,
    crg.id_entidad        AS id_cliente,
    crg.obra_social_nombre AS obra_social,
    c.centro_costo,
    cg.fecha_carga,
    crg.tipo,
    SUM(crg.importe_facturado) AS total_facturado
FROM comprobantecrg AS crg
LEFT JOIN wwcomprobantes AS c
    ON crg.comprobante = c.comprobante
LEFT JOIN crg AS cg
    ON crg.id_proveedor = cg.id_proveedor
   AND crg.nro_crg      = cg.nro_crg
LEFT JOIN efectores AS ef
    ON crg.id_proveedor = ef.id_proveedor
WHERE crg.tipo IN ('FACA2','FACB2','FAECA','FAECB')
GROUP BY 1,2,3,4,5,6,7,8,9,10,11
```

### Fuentes

| Tabla | Rol en la hoja |
|---|---|
| `comprobantecrg` (alias `crg`) | Cabecera del CRG facturado: aporta comprobante, nro_crg, id_entidad, obra_social_nombre, tipo, importe_facturado |
| `wwcomprobantes` (alias `c`) | Aporta `fecha_emision` y `centro_costo` del comprobante |
| `crg` (alias `cg`) | Aporta `tipo_prestacion` y `fecha_carga` del CRG origen |
| `efectores` (alias `ef`) | Aporta `nombre_proveedor` del efector |

### Campos resultantes

| # | Campo | Tipo | Origen | Descripción |
|---|---|---|---|---|
| 1 | fecha_emision | date | wwcomprobantes | Fecha de emisión del comprobante |
| 2 | comprobante | varchar | comprobantecrg | Comprobante construido (`tipo-prefijo-numero`) |
| 3 | efector | varchar | efectores | Nombre del proveedor / efector |
| 4 | id_efector | int | efectores | ID del efector |
| 5 | tipo_prestacion | varchar | crg | Tipo de prestación enriquecido (catálogo `tipo_prestacion.xlsx`) |
| 6 | nro_crg | int | comprobantecrg | Número de CRG facturado |
| 7 | id_cliente | int | comprobantecrg | ID de la entidad (cliente / obra social) |
| 8 | obra_social | varchar | comprobantecrg | Descripción de la obra social |
| 9 | centro_costo | varchar | wwcomprobantes | Centro de costo del comprobante |
| 10 | fecha_carga | timestamp | crg | Fecha de carga del CRG origen (primer movimiento de estado 1) |
| 11 | tipo | varchar | comprobantecrg | Tipo de comprobante (FACA2, FACB2, FAECA, FAECB) |
| 12 | total_facturado | decimal | comprobantecrg | `SUM(importe_facturado)` agrupado por las 11 dimensiones anteriores |

### Reglas de negocio

#### Filtro de tipos de comprobante

Se filtra por la **familia "Facturas FACOEP"** definida en el catálogo de `wwcomprobantes` (ver [docs/tablas/wwcomprobantes.md](../tablas/wwcomprobantes.md) → "Catálogo de familias"). Esa familia incluye los cuatro códigos de la cláusula `IN`:

| Tipo comprobante | Familia | Subfamilia | Unidad de negocio |
|---|---|---|---|
| FACA2 | Facturas FACOEP | Factura | FACOEP |
| FACB2 | Facturas FACOEP | Factura | FACOEP |
| FAECA | Facturas FACOEP | Factura | FACOEP |
| FAECB | Facturas FACOEP | Factura | FACOEP |

En consecuencia, la hoja **excluye** todas las otras familias: Créditos FACOEP (NCA, NCB, NCECA), Débitos FACOEP (NDA, NDB), Facturas ASI (FACASIA, FACASIB), Créditos ASI, Débitos ASI, NOTADB y otros comprobantes. Lo que se mide es estrictamente la facturación emitida por FACOEP (no ASI ni notas).

#### Vínculo `comprobantecrg ↔ wwcomprobantes`

Por `comprobante` (string `tipo-prefijo-numero`), permite traer la cabecera comercial del comprobante (fecha de emisión, centro de costo, etc.).

#### Vínculo `comprobantecrg ↔ crg`

Por `(id_proveedor, nro_crg)`. Trae datos del CRG origen (tipo de prestación enriquecido y fecha de carga real desde `crghistorial`).

#### Vínculo `comprobantecrg ↔ efectores`

Por `id_proveedor`. Es el lookup mantenido por el proceso DW `tablas_lookup` (con upsert por `id_proveedor`).

#### Agregación

`SUM(importe_facturado)` agrupado por las 11 dimensiones (`fecha_emision`, `comprobante`, `efector`, `id_efector`, `tipo_prestacion`, `nro_crg`, `id_cliente`, `obra_social`, `centro_costo`, `fecha_carga`, `tipo`).

> Nota: `importe_facturado` no es columna base de `comprobantecrg`: se incorpora a la tabla destino vía el `rbind` con `crgs_corregidos.xlsx` durante la corrida del proceso DW (ver `docs/tablas/comprobantecrg.md` → "Correcciones desde Excel"). En la práctica del DW, sí está presente como columna en la tabla destino.

### Granularidad

Una fila por **(comprobante, nro_crg, tipo_prestacion, centro_costo, fecha_carga)**. En la mayoría de los casos esto equivale a una fila por CRG facturado, salvo que el comprobante traiga múltiples CRGs / centros de costo.

### Uso funcional

Permite:

- Total facturado por efector y por mes.
- Apertura por tipo de prestación.
- Análisis por cliente / obra social.
- Distribución por centro de costo.

---

## Hoja 2 — Facturado por Efector - Recupero

### Descripción

Hoja "**Total Facturado por Efector. Fuente: SIF PANTALLA RECUPERO DE GASTOS**". Trabaja sobre el universo de **CRGs** (no facturas), con el importe a facturar agregado a nivel CRG / proveedor / obra social. Se alimenta de la tabla `recupero_gastos` de la base SIF, que es generada por el proceso DW de la carpeta `E:/DataWarehouse/recupero_gastos/` (no confundir con la integración SIGEHOS — ver "Aclaración" abajo).

A diferencia de la Hoja 1 ("Facturado por Efector - Comprobantes") que mira el comprobante emitido, esta hoja mira el **CRG** facturado: incluye CRGs aún no comprobantizados (donde los campos de comprobante quedan NULL) y agrega cabecera completa del CRG (estado, particularidad, tipo, financiador, obra social, etc.).

Las visualizaciones del PBIX incluyen:

- KPIs: `Importe Total` (suma de `importe_facturado`) e `Importe Incluir Prov` (subset de OSs INCLUIR).
- Filtros: Efector, Mes/Año Carga CRG, Mes/Año Emisión Comprobante, Centro de Costos.
- Bar chart "Importe Facturado por Mes".
- Treemap "Obras Sociales con Mayor Importe".
- Tabla "Importe Facturado por efector y por año" con desglose Incluir / Total OOSS.

### Query del PBIX

La hoja consume directamente la tabla `recupero_gastos` del DW SIF (host `10.22.1.44 / SIF`). El Power Query equivale a:

```sql
SELECT *
FROM recupero_gastos
```

Los filtros de visual (`fecha_emision_comprobante`, `fecha_carga_crg`, `centro_costo`, `efector`) se aplican como segmentaciones / filtros del PBIX sobre el dataset cargado.

### Tabla origen: `recupero_gastos`

#### Cómo se genera

La tabla la materializa el proceso DW:

| Item | Detalle |
|---|---|
| Script principal | `E:/DataWarehouse/recupero_gastos/main.R` |
| Helper | `E:/DataWarehouse/recupero_gastos/Funciones_Helper.R` |
| Base destino | `SIF` (`10.22.1.44`) |
| Tabla destino | `public.recupero_gastos` |
| Estrategia | `overwrite = TRUE`, `append = FALSE` (reemplazo total cada corrida) |
| Frecuencia | Diaria |

#### Query base (extracción)

```sql
SELECT
    crg.crgnum                       AS nro_crg,
    crg.pprid                        AS id_proveedor,
    prov.pprnombre                   AS nombre_proveedor,
    crg.crgperiod                    AS periodo,
    crg.crgestado                    AS id_estado,
    crg.crgtipoprestacion            AS id_tipo_prestacion,
    crg.crgfchemision                AS fecha_emision_crg,
    crg.crgfchcarga                  AS fecha_carga_crg,
    crg.crgtipocrg                   AS id_tipo_crg,
    crg.obsocialescodigo             AS id_obra_social,
    ooss.obsocialessigla             AS obra_social,
    clientes.clienteid               AS id_cliente,
    clientes.clientenombre           AS nombre_cliente,
    crg.crgusucarga                  AS usuario_carga,
    crgparticularidad                AS id_particularidad,
    pro.tipocomprobantecodigo        AS tipo_comprobante,
    pro.comprobanteprefijo           AS comprobante_prefijo,
    pro.comprobantecodigo            AS codigo_comprobante,
    cc.ccostoabreviatura             AS centro_costo,
    c.comprobantefechaemision        AS emision_comprobante,
    ooss.obsocialesnofacturable      AS os_no_facturable,
    ooss.obsocialesfinancia          AS id_tipo_financiador,
    ooss.obsocialestipo              AS id_tipo_obra_social,
    pro.proformanumero               AS numero_proforma,
    SUM(crgdet.crgdetimportefacturar) AS importe_facturado
FROM crg
LEFT JOIN obrassociales        ooss     ON crg.obsocialescodigo = ooss.obsocialescodigo
LEFT JOIN proveedorprestador   prov     ON crg.pprid             = prov.pprid
LEFT JOIN proforma             pro      ON crg.proformacodigo    = pro.proformacodigo
LEFT JOIN crgdet                        ON crg.pprid             = crgdet.pprid
                                       AND crg.crgnum            = crgdet.crgnum
LEFT JOIN comprobantes         c        ON pro.empcod                  = c.empcod
                                       AND pro.comprobantetipoentidad  = c.comprobantetipoentidad
                                       AND pro.comprobanteentidadcodigo = c.comprobanteentidadcodigo
                                       AND pro.comprobanteprefijo      = c.comprobanteprefijo
                                       AND pro.comprobantecodigo       = c.comprobantecodigo
                                       AND pro.tipocomprobantecodigo   = c.tipocomprobantecodigo
LEFT JOIN clientes                      ON ooss.obsocialesclienteid = clientes.clienteid
LEFT JOIN centrocostos         cc       ON c.comprobanteccosto     = cc.ccostocodigo
GROUP BY
    crg.crgnum, crg.pprid, prov.pprnombre,
    crg.crgperiod, crg.crgestado,
    crg.crgfchemision, crg.crgfchcarga, crg.crgtipocrg,
    crg.obsocialescodigo, ooss.obsocialessigla,
    crg.crgusucarga, crgparticularidad,
    pro.tipocomprobantecodigo, pro.comprobanteprefijo, pro.comprobantecodigo,
    cc.ccostoabreviatura, c.comprobantefechaemision,
    ooss.obsocialesnofacturable, ooss.obsocialesfinancia, ooss.obsocialestipo,
    pro.proformanumero, clientes.clienteid, clientes.clientenombre
```

#### Fuentes (Producción `facoep`)

| Tabla | Rol |
|---|---|
| `crg` | Cabecera del CRG (nro, periodo, estado, fechas, particularidad, tipo, etc.) |
| `crgdet` | Detalle del CRG → aporta `SUM(crgdetimportefacturar)` |
| `obrassociales` | Aporta sigla, financiador, tipo OS, flag no-facturable |
| `proveedorprestador` | Nombre del proveedor / efector |
| `proforma` | Vínculo CRG ↔ Proforma → tipo / prefijo / código de comprobante + `proformanumero` |
| `comprobantes` | Por la proforma, busca el comprobante real (fecha de emisión, centro de costo) |
| `clientes` | Razón social del cliente asociado a la OS |
| `centrocostos` | Abreviatura del centro de costo del comprobante |

#### Lookups Excel (en la carpeta del proceso)

- `tipos.xlsx` (tipos de CRG)
- `particularidad.xlsx`
- `tipos_financiador.xlsx`
- `tipos_obras_sociales.xlsx`
- `tipo_prestacion.xlsx` — se lee de `E:/DataWarehouse/tablas_lookup/files/`

#### Lookup desde DB (base SIF)

- `estados_crg`

### Diccionario de campos (tabla `recupero_gastos`)

| # | Campo | Tipo | Origen | Descripción |
|---|---|---|---|---|
| 1 | nro_crg | int | crg | Número de CRG |
| 2 | id_proveedor | int | crg | ID del proveedor / efector |
| 3 | nombre_proveedor | varchar | proveedorprestador | Nombre del proveedor (TRIM) |
| 4 | periodo | varchar | crg | Periodo del CRG (`crgperiod`) |
| 5 | fecha_emision_crg | date | crg | Fecha de emisión del CRG |
| 6 | fecha_carga_crg | timestamp | crg | Fecha de carga del CRG |
| 7 | id_obra_social | int | crg | Código de obra social |
| 8 | obra_social | varchar | obrassociales | Sigla de la obra social |
| 9 | id_cliente | int | clientes | ID del cliente asociado a la OS |
| 10 | nombre_cliente | varchar | clientes | Razón social del cliente (TRIM) |
| 11 | usuario_carga | varchar | crg | Usuario que cargó el CRG (`crgusucarga`) |
| 12 | tipo_comprobante | varchar | proforma | Tipo del comprobante asociado al CRG (TRIM, NULL si no hay comprobante todavía) |
| 13 | centro_costo | varchar | centrocostos | Abreviatura del centro de costo del comprobante |
| 14 | emision_comprobante | date | comprobantes | Fecha de emisión del comprobante asociado |
| 15 | numero_proforma | int | proforma | Número de proforma |
| 16 | importe_facturado | decimal | crgdet | `SUM(crgdetimportefacturar)` agrupado por las dimensiones del SELECT |
| 17 | comprobante | varchar | derivado | `tipo_comprobante-comprobante_prefijo-codigo_comprobante` (NULL si `tipo_comprobante` es NULL) |
| 18 | facturable | varchar | derivado | "SI" / "NO" según `obsocialesnofacturable` (NULL → FALSE → "SI") |
| 19 | estado | varchar | estados_crg (DB SIF) | Descripción del estado del CRG (lookup por `id_estado`) |
| 20 | tipo | varchar | tipos.xlsx | Tipo de CRG (lookup por `id_tipo_crg`) |
| 21 | particularidad | varchar | particularidad.xlsx | Particularidad del CRG (lookup por `id_particularidad`) |
| 22 | tipo_financiador | varchar | tipos_financiador.xlsx | Tipo de financiador (lookup por `id_tipo_financiador`) |
| 23 | tipo_obra_social | varchar | tipos_obras_sociales.xlsx | Tipo de OS (lookup por `id_tipo_obra_social`) |
| 24 | tipo_prestacion | varchar | tipo_prestacion.xlsx (tablas_lookup) | Tipo de prestación (lookup por `id_tipo_prestacion`) |

> Los identificadores técnicos `id_estado`, `id_tipo_crg`, `id_particularidad`, `id_tipo_financiador`, `id_tipo_obra_social`, `id_tipo_prestacion`, `comprobante_prefijo`, `codigo_comprobante` y `os_no_facturable` se eliminan del DataFrame antes del insert: solo quedan los campos enriquecidos.

### Reglas de negocio (proceso que arma `recupero_gastos`)

#### Universo: CRGs (no comprobantes)

A diferencia de Hoja 1 / `comprobantecrg` que parte de comprobantes, esta tabla parte de **`crg`** y sale a buscar el comprobante asociado vía `proforma`. Por lo tanto incluye CRGs aún no comprobantizados (donde `tipo_comprobante`, `comprobante`, `centro_costo`, `emision_comprobante`, `numero_proforma` quedan NULL).

#### Granularidad

Una fila por **(nro_crg, id_proveedor, comprobante_prefijo, codigo_comprobante, periodo, ...)**. En la práctica, una fila por CRG salvo que existan múltiples proformas / comprobantes asociados al mismo CRG.

#### Importe a facturar

```sql
SUM(crgdet.crgdetimportefacturar)
```

Se agrupa por todas las dimensiones del SELECT.

#### Construcción de `comprobante`

```r
data$tipo_comprobante <- str_trim(data$tipo_comprobante)
data$comprobante <- ifelse(
    is.na(data$tipo_comprobante),
    NA,
    paste(data$tipo_comprobante, data$comprobante_prefijo, data$codigo_comprobante, sep = "-")
)
```

Si no hay tipo de comprobante (CRG sin comprobantizar), `comprobante` queda NULL. Caso contrario se construye como `tipo-prefijo-codigo`.

#### Cálculo de `facturable`

| `obsocialesnofacturable` | `facturable` |
|---|---|
| NULL | SI (se trata como FALSE) |
| FALSE | SI |
| TRUE | NO |

#### Enriquecimientos

| Campo origen | Lookup | Resultado |
|---|---|---|
| id_estado | `estados_crg` (DB SIF) | estado |
| id_tipo_crg | `tipos.xlsx` | tipo |
| id_particularidad | `particularidad.xlsx` | particularidad |
| id_tipo_financiador | `tipos_financiador.xlsx` | tipo_financiador |
| id_tipo_obra_social | `tipos_obras_sociales.xlsx` | tipo_obra_social |
| id_tipo_prestacion | `tipo_prestacion.xlsx` (en `tablas_lookup/files/`) | tipo_prestacion |

#### Limpieza

- `nombre_proveedor` y `nombre_cliente` se aplican `str_trim`.
- `tipo_comprobante` se aplica `str_trim` antes de armar `comprobante`.

### Reglas / cálculos del PBIX

#### Importe Incluir Prov

KPI lateral. Se calcula filtrando `recupero_gastos` por las obras sociales del grupo "Incluir Prov" (lista interna del PBIX). En el screenshot aparece en blanco porque no hay registros que cumplan el filtro vigente.

#### Importe Total

`SUM(importe_facturado)` sobre todo el dataset (con los filtros del visual aplicados).

#### Filtros del visual

- Efector
- Mes Carga CRG / Año Carga CRG (sobre `fecha_carga_crg`)
- Mes Emisión Fact. / Año Emisión Fact. (sobre `emision_comprobante`)
- Centro de Costos (`centro_costo`)

### Aclaración importante

Existen dos universos distintos en el DW que comparten nombres parecidos y conviene no confundir:

| Tabla | Origen | Documentación |
|---|---|---|
| `recupero_gastos` | Proceso `E:/DataWarehouse/recupero_gastos/` (CRGs propios de SIF + proformas) | Esta hoja la usa |
| `sigehos_crg_recupero`, `sigehos_dph_recupero`, `sigehos_anexos_recupero` | Integración SIGEHOS → SIF (CRGs/DPHs/Anexos provenientes de los hospitales del GCBA) | [docs/tablas/integracion_recupero_gastos.md](../tablas/integracion_recupero_gastos.md) |

Esta hoja del Efectores V2 **usa la primera** (`recupero_gastos`), no las tablas de la integración SIGEHOS.

### Uso funcional

Permite:

- Ver el total a facturar por efector / cliente / obra social a nivel CRG (incluso CRGs aún no comprobantizados).
- Distribución mensual por fecha de carga del CRG y por fecha de emisión del comprobante.
- Identificar las obras sociales que más facturan vía treemap.
- Filtrar por centro de costo del comprobante asociado.
- KPI específico para el grupo "Incluir Prov".

---

## Hoja 3 — Impugnaciones por Efector (NOTADB)

### Descripción

Hoja "**Débitos por Efector, OOSS y Motivo**". Trabaja exclusivamente sobre los comprobantes tipo `NOTADB`, que según el catálogo de [docs/tablas/wwcomprobantes.md](../tablas/wwcomprobantes.md) son el **único tipo de comprobante que refleja las impugnaciones de las obras sociales o clientes**:

| Tipo comprobante | Familia | Subfamilia | Unidad de negocio |
|---|---|---|---|
| NOTADB | Comprobante interno Impugnaciones Facoep | Impugnaciones FACOEP | FACOEP |

> Cuando una impugnación es aceptada, se genera una Nota de Crédito FACOEP que descuenta saldo de deuda al cliente. La NOTADB en sí queda como el documento que registra la impugnación (con su importe rechazado / aceptado).

La hoja abre cada NOTADB al detalle de prestación, mostrando para cada combinación CRG / práctica el importe rechazado (`importe_a_debitar`) y el importe aceptado (`importe_a_acreditar`), además del motivo / categoría de débito y el tipo de prestación.

Las visualizaciones del PBIX incluyen:

- KPIs: `Impugnaciones Totales`, `Rechazado` (suma de `importe_a_debitar`), `Aceptado` (suma de `importe_a_acreditar`).
- Filtros: `Año Impugnación`, `Mes Impugnación`.
- Bar chart "Débitos por Efector".
- Pie chart "Porcentajes sobre el total" (Aceptado vs. Rechazado).
- Pie chart "Motivos" (Cobertura, Constatación, Débito, En blanco).
- Bar chart "Débitos por Obra Social".
- Line chart "Evolución Mensual de los montos Impugnados".
- **Filtro de página fijo: `rechazada = NO`** (ver regla de negocio abajo).

### Query

```sql
SELECT
    c.id_entidad,
    c.fecha_emision                    AS fecha_notadb,
    c.comprobante                      AS notadb,
    det.nro_crg,
    ef.nombre_proveedor,
    det.practica                       AS prestacion,
    det.motivo_debito                  AS tipo_debito,
    det.categoria_motivo_debito        AS categoria,
    det.motivo_debito_credito          AS motivo,
    det.tipo_prestacion,
    CASE
        WHEN c.detalle LIKE '%Comprobante generado automáticamente por copia de NOTADB por refacturación.(Rechazo)%'
            THEN 'SI'
        ELSE 'NO'
    END                                AS rechazada,
    SUM(det.importe_a_debitar)         AS rechazado,
    SUM(det.importe_a_acreditar)       AS aceptado
FROM wwcomprobantes AS c
LEFT JOIN comprobantecrgdet AS det
    ON c.comprobante = det.comprobante
   AND c.id_entidad  = det.id_entidad
   AND c.entidad     = det.tipo_entidad
LEFT JOIN efectores AS ef
    ON det.id_proveedor = ef.id_proveedor
WHERE c.tipo = 'NOTADB'
  AND det.nro_crg IS NOT NULL
  AND ef.efector  IS NOT NULL
GROUP BY 1,2,3,4,5,6,7,8,9,10,11
```

### Fuentes

| Tabla | Rol en la hoja |
|---|---|
| `wwcomprobantes` (alias `c`) | Cabecera del NOTADB: aporta `id_entidad`, `fecha_emision`, `comprobante`, `entidad`, `tipo`, `detalle` (para detectar auto-generado por refacturación) |
| `comprobantecrgdet` (alias `det`) | Detalle del CRG dentro del NOTADB: aporta `nro_crg`, `practica`, `motivo_debito`, `categoria_motivo_debito`, `motivo_debito_credito`, `tipo_prestacion`, `importe_a_debitar`, `importe_a_acreditar` |
| `efectores` (alias `ef`) | Aporta `nombre_proveedor` del efector |

### Campos resultantes

| # | Campo | Tipo | Origen | Descripción |
|---|---|---|---|---|
| 1 | id_entidad | int | wwcomprobantes | ID de la entidad (cliente / OS) que emitió la impugnación |
| 2 | fecha_notadb | date | wwcomprobantes | Fecha de emisión del NOTADB (= fecha de la impugnación) |
| 3 | notadb | varchar | wwcomprobantes | Identificador del NOTADB (`tipo-prefijo-numero`) |
| 4 | nro_crg | int | comprobantecrgdet | Número del CRG impugnado |
| 5 | nombre_proveedor | varchar | efectores | Nombre del efector |
| 6 | prestacion | varchar | comprobantecrgdet | Práctica afectada por la impugnación |
| 7 | tipo_debito | varchar | comprobantecrgdet | Descripción del motivo de débito (`motivo_debito`) |
| 8 | categoria | varchar | comprobantecrgdet | Categoría del motivo de débito |
| 9 | motivo | varchar | comprobantecrgdet | Motivo de débito / crédito enriquecido |
| 10 | tipo_prestacion | varchar | comprobantecrgdet | Tipo de prestación enriquecido |
| 11 | rechazada | varchar | derivado | "SI" / "NO" — flag que indica si el NOTADB es una copia auto-generada por refacturación (rechazo) |
| 12 | rechazado | decimal | comprobantecrgdet | `SUM(importe_a_debitar)` — monto efectivamente impugnado / debitado |
| 13 | aceptado | decimal | comprobantecrgdet | `SUM(importe_a_acreditar)` — monto que la impugnación aceptó acreditar |

### Reglas de negocio

#### Filtro principal: solo NOTADB

`c.tipo = 'NOTADB'` — única familia de comprobantes que registra impugnaciones. Esto excluye facturas, NC, recibos, etc.

Referencia: `wwcomprobantes` → "Catálogo de familias" → la NOTADB es el único comprobante de la familia "Impugnaciones FACOEP".

> Recordar el flujo: la **NOTADB** documenta la impugnación. Si la impugnación se acepta, posteriormente se emite una **Nota de Crédito FACOEP** (NCA / NCB / NCECA) que efectivamente descuenta saldo al cliente. Esta hoja mira solo el documento de la impugnación, no la NC posterior.

#### Filtros de exclusión

```sql
det.nro_crg IS NOT NULL
ef.efector  IS NOT NULL
```

- Se excluyen NOTADBs sin detalle de CRG (no impugnan una prestación específica).
- Se excluyen registros sin efector mapeado en `efectores` (ruido del lookup).

#### Vínculo `wwcomprobantes ↔ comprobantecrgdet`

Por la clave compuesta `(comprobante, id_entidad, entidad/tipo_entidad)`. Esto trae el detalle del CRG impugnado por cada NOTADB.

#### Vínculo `comprobantecrgdet ↔ efectores`

Por `id_proveedor`. Aporta el nombre del efector.

#### Detección de NOTADB auto-generado por refacturación

```sql
CASE
    WHEN c.detalle LIKE '%Comprobante generado automáticamente
                         por copia de NOTADB por refacturación.(Rechazo)%'
    THEN 'SI'
    ELSE 'NO'
END AS rechazada
```

Cuando una impugnación es rechazada y el CRG se refactura, el sistema genera **automáticamente una copia del NOTADB original** con esa leyenda en el detalle. Esos comprobantes son **duplicados administrativos** que no deben sumarse al impacto real, por eso el PBIX por defecto filtra `rechazada = NO`.

#### Importes

| Campo | Cálculo | Significado |
|---|---|---|
| `rechazado` | `SUM(det.importe_a_debitar)` | Monto impugnado / debitado por la OS |
| `aceptado` | `SUM(det.importe_a_acreditar)` | Monto que terminó acreditándose (NC posterior) |

### Reglas / cálculos del PBIX

#### Filtro fijo de página

`rechazada = NO` — visible en el panel "Filtros de esta página". Todos los visuales operan sobre el subset que excluye los duplicados auto-generados por refacturación.

#### KPIs

- **Impugnaciones Totales** = `SUM(rechazado) + SUM(aceptado)` (importe impugnado total).
- **Rechazado** = `SUM(rechazado)` (lo que la OS no terminó pagando).
- **Aceptado** = `SUM(aceptado)` (lo que se reconoció vía NC posterior).

#### Filtros visibles

- `AÑO IMPUGNACIÓN` y `MES IMPUGNACIÓN` (sobre `fecha_notadb`).

#### Visuales

- **Débitos por Efector**: bar chart con `Total (Millones)` por `nombre_proveedor`.
- **Porcentajes sobre el total**: pie chart Aceptado vs. Rechazado.
- **Motivos**: pie chart por `motivo` (Cobertura, Constatación, Débito, En blanco).
- **Débitos por Obra Social**: bar chart por `id_entidad` (etiqueta = nombre OS).
- **Evolución Mensual de los montos Impugnados**: line chart por `Month(fecha_notadb)`.

### Granularidad

Una fila por **(NOTADB, nro_crg, prestacion, motivo, tipo_prestacion, rechazada)**. En la práctica, una fila por cada práctica impugnada dentro de cada NOTADB.

### Uso funcional

Permite:

- Medir el peso de las impugnaciones por efector / obra social / motivo.
- Distinguir lo rechazado (no cobrado) de lo aceptado (acreditado por NC posterior).
- Detectar refacturaciones automáticas (mediante `rechazada = SI`).
- Evolución mensual de la conflictividad con cada OS.
- Identificar los motivos más recurrentes (Cobertura, Constatación, Débito).

---

## Hoja 4 — Motivos Impugnaciones (NOTADB)

### Descripción

Hoja "**Débitos por efector, OOSS y motivos**". **Comparte exactamente el mismo dataset que la Hoja 3** (`Impugnaciones por Efector (NOTADB)`): se alimenta de la misma query SQL contra `wwcomprobantes` + `comprobantecrgdet` + `efectores` filtrando por `c.tipo = 'NOTADB'`. Lo que cambia es el **enfoque de las visualizaciones**: en lugar de poner el foco en el efector / obra social, esta hoja se centra en los **motivos de impugnación** (Cobertura, Débito Médico, Constatación Prestación).

### Query

Misma query que la Hoja 3. Ver "Hoja 3 — Impugnaciones por Efector (NOTADB) → Query".

### Fuentes

Las mismas que la Hoja 3:

| Tabla | Rol |
|---|---|
| `wwcomprobantes` (alias `c`) | Cabecera del NOTADB |
| `comprobantecrgdet` (alias `det`) | Detalle del CRG dentro del NOTADB |
| `efectores` (alias `ef`) | Nombre del efector |

### Campos resultantes

Los mismos 13 campos que la Hoja 3. Ver tabla en "Hoja 3 → Campos resultantes".

### Reglas de negocio

Las mismas que la Hoja 3 (filtro `c.tipo = 'NOTADB'`, exclusión de NOTADB sin CRG / sin efector, detección de comprobante auto-generado por refacturación, etc.).

### Reglas / cálculos del PBIX (específicas de esta hoja)

#### Filtro fijo de página

`rechazada = NO` — igual que Hoja 3, se excluyen los duplicados auto-generados por refacturación.

#### KPIs

- **Impugnaciones Totales**, **Rechazado**, **Aceptado** — idénticos a Hoja 3.

#### Filtros visibles del visual

- `Año Impugnación`, `Mes Impugnación` (sobre `fecha_notadb`).
- **Efector** (sobre `nombre_proveedor`).
- **Obra Social** (sobre `id_entidad`). En el screenshot aparece filtrado por "O. S. DEL PERSONAL DE LA I..." como ejemplo de uso.

#### Visuales

| Visual | Tipo | Métrica | Dimensión |
|---|---|---|---|
| Débitos por Efector | Bar chart horizontal | `Aceptado` y `Rechazado` apilados | `nombre_proveedor` |
| Detalle Evolución Mensual de los montos Impugnados | Area chart (línea apilada) | `Aceptado` y `Rechazado` | `Month(fecha_notadb)` |
| **Motivos Montos Rechazados** | Pie chart | `SUM(rechazado)` | `motivo` (Cobertura / Débito Medico / Constatación Prestación) |
| **Motivos Montos Aceptados** | Pie chart | `SUM(aceptado)` | `motivo` (mismas categorías) |
| **Motivos Monto Total** | Pie chart | `SUM(rechazado) + SUM(aceptado)` | `motivo` |

> Los tres pie charts de motivos son la novedad de esta hoja respecto a la Hoja 3: la Hoja 3 mostraba un único pie de motivos (sin distinguir aceptado vs. rechazado), mientras que acá se desagregan en tres tortas para comparar la composición de motivos según el destino del importe.

### Granularidad

La misma que la Hoja 3 (una fila por NOTADB / nro_crg / prestacion / motivo / tipo_prestacion / rechazada).

### Uso funcional

Permite (complementario a Hoja 3):

- Comparar la **composición de motivos** entre lo Rechazado, lo Aceptado y el Total.
- Detectar si los motivos predominantes en lo rechazado coinciden o no con los de lo aceptado (ej.: Cobertura puede ser mayoritario en Rechazado pero no en Aceptado).
- Filtrar por una OS puntual y ver qué motivos pesan en su impugnación.
- Evolución mensual abierta en aceptado vs. rechazado (área apilada).

---

## Hoja 5 — Detalle Impugnaciones (NOTADB)

### Descripción

Hoja "**Detalle Débitos por Efector**". Tercera hoja de la serie NOTADB, **comparte exactamente el mismo dataset que las Hojas 3 y 4**: misma query SQL contra `wwcomprobantes` + `comprobantecrgdet` + `efectores` filtrando por `c.tipo = 'NOTADB'`. La diferencia es que esta hoja es la **vista al detalle**: en lugar de gráficos agregados, presenta una tabla operativa con una fila por impugnación / práctica, pensada para drill-down y consulta puntual.

Es la hoja de "auditoría / consulta directa" del flujo de impugnaciones: una vez que en Hojas 3 y 4 se identifica un caso de interés (un efector con mucho rechazo, un motivo predominante, etc.), acá se baja al detalle individual de los NOTADBs que lo componen.

### Query

Misma query que las Hojas 3 y 4. Ver "Hoja 3 — Impugnaciones por Efector (NOTADB) → Query".

### Fuentes

Las mismas que la Hoja 3:

| Tabla | Rol |
|---|---|
| `wwcomprobantes` (alias `c`) | Cabecera del NOTADB |
| `comprobantecrgdet` (alias `det`) | Detalle del CRG dentro del NOTADB |
| `efectores` (alias `ef`) | Nombre del efector |

### Campos resultantes

Los mismos 13 campos que la Hoja 3.

### Reglas de negocio

Las mismas que las Hojas 3 y 4 (filtro `c.tipo = 'NOTADB'`, exclusión de NOTADB sin CRG / sin efector, detección de copia auto-generada por refacturación, etc.).

### Reglas / cálculos del PBIX (específicas de esta hoja)

#### Filtro fijo de página

`rechazada = NO` — igual que Hojas 3 y 4, se excluyen los duplicados auto-generados por refacturación.

#### KPIs

- **IMPUGNACIONES TOTALES**, **ACEPTADO**, **RECHAZADO** — idénticos a Hoja 3.

#### Filtros visibles del visual (más granulares que Hoja 3 y 4)

| Filtro | Campo |
|---|---|
| MES | `Month(fecha_notadb)` |
| EFECTOR | `nombre_proveedor` |
| OOSS | `id_entidad` (nombre de la OS) |
| Tipo Prestación | `tipo_prestacion` |
| Categoria | `categoria` |
| NroCRG | `nro_crg` |
| Prestación | `prestacion` |
| Tipo Débito | `tipo_debito` (preseleccionado en `COBERTURA` en el screenshot) |

Esta hoja agrega filtros sobre **todas las dimensiones del dataset**, no solo las temporales / de efector. Sirve para acotar la tabla a un caso puntual.

#### Visual principal

Una **tabla "Detalle Débitos por Efector"** con (al menos) las siguientes columnas:

| Columna | Origen |
|---|---|
| Impugnación | `notadb` |
| financiador | nombre OS / cliente (probablemente derivado de `id_entidad` + lookup) |
| Efector | `nombre_proveedor` |
| Tipo Débito | `tipo_debito` |
| Tipo Prestación | `tipo_prestacion` |
| Categoria | `categoria` |
| Nro Crg | `nro_crg` |
| Prestación | `prestacion` |
| (Importes) | `aceptado` y/o `rechazado` |

> En el screenshot la tabla está acotada por el filtro `Tipo Débito = COBERTURA`, por lo que todas las filas visibles tienen esa categoría.

### Granularidad

La misma que las Hojas 3 y 4: una fila por **(NOTADB, nro_crg, prestacion, motivo, tipo_prestacion, rechazada)**.

### Uso funcional

Permite (complementario a Hojas 3 y 4):

- Consulta directa al detalle de cada NOTADB / práctica impugnada.
- Drill-down desde un caso identificado en Hoja 3 o 4.
- Auditoría individual: ver qué prácticas concretas componen un débito puntual.
- Filtrado fino por todas las dimensiones (Tipo Débito, Categoría, NroCRG, Prestación, etc.).
- Export a Excel / CSV de un subset acotado (operación típica del usuario sobre tablas de PowerBI).

---

## Hoja 6 — Débitos Aceptados (NC)

### Descripción

Hoja "**Montos Aceptados por Impugnaciones**". Cierra el flujo de impugnaciones que las Hojas 3, 4 y 5 dejaron abierto: muestra qué impugnaciones (NOTADB) terminaron concretándose en una **Nota de Crédito FACOEP** (NCA, NCB, NCECA) que efectivamente descontó saldo al cliente.

A diferencia de las Hojas 3-5 que miran el documento de la impugnación (NOTADB), esta hoja mira el **documento de la aceptación** (la NC FACOEP) y cruza cada NC con la NOTADB original que le dio origen. Esto permite responder: de todo lo impugnado, ¿cuánto terminó realmente como crédito al cliente, y por qué efector / prestación / motivo?

### Diferencia clave con Hojas 3-5

| Aspecto | Hojas 3-5 (NOTADB) | Hoja 6 (NC aceptadas) |
|---|---|---|
| **Familia de comprobante** | `c.tipo = 'NOTADB'` (Impugnaciones FACOEP) | `c.tipo IN ('NCA','NCB','NCECA')` (Créditos FACOEP) |
| **Pregunta que responde** | ¿Cuánto se impugnó? | ¿Cuánto se aceptó como NC y a quién? |
| **Acceso a datos** | Power Query directo a SIF (live) | Tabla materializada `DBA.efectores_montos_aceptados` |
| **Construcción** | Una sola query SQL | Proceso Python que ejecuta 2 queries + merge + insert |
| **Ventana temporal** | Sin filtro temporal explícito | NCs últimos 45 días + NOTADBs últimos 410 días |
| **Frecuencia de refresh** | Con cada refresh del PBIX | Diaria (script Python persiste tabla) |
| **Dónde vive el dato** | SIF (live) | DBA (custom, materializada) |

### Tabla origen: `efectores_montos_aceptados`

#### Cómo se genera

| Item | Detalle |
|---|---|
| Script principal | `E:/reportes/Efectores/debitos_aceptados/main.py` |
| Helpers | `Functions.py` (queries) + `postgres.py` (conexión / inserción) |
| Base destino | `DBA` (`10.22.1.44`) |
| Tabla destino | `efectores_montos_aceptados` (custom, no replica una tabla SIF) |
| Frecuencia | Diaria |
| Logs | `E:/reportes/Efectores/debitos_aceptados/logs/log_execution_YYYYMMDD_HHMMSS.txt` |

#### Ventana temporal

```python
until           = today - 1 día
threshold_nc    = 45
threshold_notadb = 45 + 365 = 410

since_nc       = until - 45 días     # rango para las NCs
since_notadb   = until - 410 días    # rango para los NOTADB
```

La diferencia de ventana se debe a que una NC puede aceptar una impugnación emitida hasta **un año atrás**, así que el lookup hacia atrás del NOTADB es mucho más amplio.

#### Query 1 — `get_nc()` (Notas de Crédito de aceptación)

```sql
SELECT
    c.id_entidad,
    c.fecha_emision                            AS fecha_nc,
    c.comprobante,
    det.tipo_prestacion,
    det.id_proveedor,
    det.nro_crg,
    det.nombre_proveedor,
    det.practica                                AS prestacion,
    CASE
        WHEN c.detalle LIKE 'Impugnación aceptada como resultado de la auditoria correspondiente realizada%'
            THEN 'NO'
        ELSE 'SI'
    END                                         AS rechazada,
    TRIM(substring(c.detalle FROM
                   position('NOTA DEBITO CLIENTE' IN c.detalle)
                   + length('NOTA DEBITO CLIENTE'))) AS substring_despues,
    SUM(det.importe_a_acreditar)                AS aceptado_NC,
    SUM(det.importe_a_debitar)                  AS rechazado_NC
FROM wwcomprobantes AS c
LEFT JOIN comprobantecrgdet AS det
    ON c.comprobante = det.comprobante
   AND c.id_entidad  = det.id_entidad
   AND c.entidad     = det.tipo_entidad
WHERE c.tipo IN ('NCA','NCB','NCECA')
  AND c.fecha_emision BETWEEN '{since_nc}' AND '{until}'
  AND c.detalle LIKE 'Impugnación aceptada como resultado de la auditoria correspondiente realizada%'
  AND nro_crg IS NOT NULL
  AND efector  IS NOT NULL
  AND c.centro_costo = 'FACOEP'
GROUP BY 1,2,3,4,5,6,7,8,9,10
```

#### Query 2 — `get_debitos_query()` (NOTADBs de referencia)

```sql
SELECT
    c.id_entidad,
    c.fecha_emision                       AS fecha_notadb,
    c.comprobante                         AS notadb,
    det.nro_crg,
    det.nombre_proveedor,
    det.practica                          AS prestacion,
    det.motivo_debito                     AS tipo_debito,
    det.categoria_motivo_debito           AS categoria,
    det.motivo_debito_credito             AS motivo,
    SUM(det.importe_a_debitar)            AS rechazado_notadb,
    SUM(det.importe_a_acreditar)          AS aceptado_notadb
FROM wwcomprobantes AS c
LEFT JOIN comprobantecrgdet AS det
    ON c.comprobante = det.comprobante
   AND c.id_entidad  = det.id_entidad
   AND c.entidad     = det.tipo_entidad
WHERE c.tipo = 'NOTADB'
  AND nro_crg IS NOT NULL
  AND efector  IS NOT NULL
  AND c.fecha_emision BETWEEN '{since_notadb}' AND '{until}'
GROUP BY 1,2,3,4,5,6,7,8,9
```

#### Merge en Python

Tras obtener ambos DataFrames, el script:

1. **Parsea el campo `substring_despues`** para reconstruir el `notadb` de origen:
   ```python
   for row in data.itertuples():
       notadb = str(row.substring_despues).split(" ")
       tipo = notadb[0]
       componente = notadb[1].split("-")
       prefijo = componente[0].replace('0', '')
       numero  = int(componente[1].split(".")[0])
       notadb_final = f"{tipo}-{prefijo}-{numero}"
   data['notadb'] = lista_notasdb
   ```

   Esto convierte el texto libre que aparece después de `"NOTA DEBITO CLIENTE"` en un identificador con el formato canónico `tipo-prefijo-numero` (mismo formato que `wwcomprobantes.comprobante`).

2. **Cruza NCs con NOTADBs** vía `pd.merge` (LEFT JOIN) por la clave compuesta:
   ```
   notadb + nro_crg + nombre_proveedor + prestacion + id_entidad
   ```

   Es un left join: si la NC no encuentra su NOTADB en la ventana de 410 días, los campos del NOTADB quedan NULL.

#### Persistencia

```sql
DELETE FROM efectores_montos_aceptados
WHERE fecha_nc BETWEEN '{since_nc}' AND '{until}'
```

Luego se ejecuta `INSERT INTO efectores_montos_aceptados ...` con el DataFrame consolidado.

### Diccionario de campos (tabla `efectores_montos_aceptados`)

| # | Campo | Origen | Descripción |
|---|---|---|---|
| 1 | id_entidad | NC | ID del cliente / OS al que se le emitió la NC |
| 2 | fecha_nc | NC | Fecha de emisión de la NC |
| 3 | comprobante | NC | Comprobante NC (`tipo-prefijo-numero`) |
| 4 | tipo_prestacion | NC | Tipo de prestación de la NC |
| 5 | id_proveedor | NC | ID del proveedor / efector |
| 6 | nro_crg | NC | Número de CRG asociado |
| 7 | nombre_proveedor | NC | Nombre del proveedor |
| 8 | prestacion | NC | Práctica acreditada |
| 9 | rechazada | derivado | "NO" si la NC corresponde a impugnación aceptada (siempre debería ser "NO" por el filtro del query) |
| 10 | substring_despues | NC | Texto bruto extraído del detalle, posterior a "NOTA DEBITO CLIENTE" |
| 11 | aceptado_NC | NC | `SUM(importe_a_acreditar)` de la NC — **el monto efectivamente acreditado al cliente** |
| 12 | rechazado_NC | NC | `SUM(importe_a_debitar)` de la NC |
| 13 | notadb | derivado | NOTADB original parseado desde `substring_despues` (formato `tipo-prefijo-numero`) |
| 14 | fecha_notadb | NOTADB (merge) | Fecha de emisión del NOTADB original |
| 15 | tipo_debito | NOTADB (merge) | `motivo_debito` del NOTADB |
| 16 | categoria | NOTADB (merge) | `categoria_motivo_debito` del NOTADB |
| 17 | motivo | NOTADB (merge) | `motivo_debito_credito` del NOTADB |
| 18 | rechazado_notadb | NOTADB (merge) | `SUM(importe_a_debitar)` del NOTADB original |
| 19 | aceptado_notadb | NOTADB (merge) | `SUM(importe_a_acreditar)` del NOTADB original |

> Las columnas 14-19 pueden quedar NULL cuando la NC no consigue matchear con ningún NOTADB en la ventana de 410 días.

### Reglas de negocio (proceso de construcción)

#### Filtro principal de la NC

Únicamente se consideran NCs que cumplen **todas** las condiciones:

- `c.tipo IN ('NCA','NCB','NCECA')` (Créditos FACOEP).
- `c.detalle LIKE 'Impugnación aceptada como resultado de la auditoria correspondiente realizada%'` (la NC fue emitida por aceptar una impugnación, no por otro motivo).
- `c.centro_costo = 'FACOEP'`.
- `nro_crg IS NOT NULL` y `efector IS NOT NULL`.
- `c.fecha_emision` dentro de los últimos 45 días.

#### Reconstrucción del NOTADB de origen

El detalle de la NC contiene un texto libre del tipo:

```
... NOTA DEBITO CLIENTE NDB 0001-00012345.xxx ...
```

El script extrae lo posterior a `"NOTA DEBITO CLIENTE"`, parsea `tipo`, `prefijo` (sin ceros a la izquierda) y `numero`, y arma el ID canónico `tipo-prefijo-numero`. Ese ID es el `notadb` que sirve para cruzar con el detalle del NOTADB original.

#### Cruce NC ↔ NOTADB

LEFT JOIN por `notadb + nro_crg + nombre_proveedor + prestacion + id_entidad`. La granularidad debe coincidir línea a línea (una práctica de la NC con la misma práctica del NOTADB original).

#### Manejo de errores

El script tiene un `try/except` global que captura cualquier error y lo loguea con stack trace en el archivo de log diario.

#### Carga incremental

```sql
DELETE FROM efectores_montos_aceptados
WHERE fecha_nc BETWEEN since_nc AND until
```

Se borra y reinserta solo el rango móvil de 45 días.

### Reglas / cálculos del PBIX

#### Filtro fijo de página

`rechazada = NO` — coherente con la lógica del query (el campo `rechazada` viene calculado: "NO" cuando la NC es por impugnación aceptada).

#### KPIs (en el screenshot)

Los KPIs en la franja superior comparten formato con las hojas anteriores. Trabajan sobre `aceptado_NC` (lo que efectivamente se acreditó vía NC).

#### Filtros visibles

| Filtro | Campo |
|---|---|
| Fecha NC | `fecha_nc` (rango con desde / hasta) |
| EFECTOR | `nombre_proveedor` |
| Categoria | `categoria` (del NOTADB original) |
| NC | `comprobante` |
| NroCRG | `nro_crg` |
| Prestación | `prestacion` |
| Tipo Débito | `tipo_debito` (del NOTADB original) |
| Tipo Prestación | `tipo_prestacion` |
| OOSS | `id_entidad` (nombre de la OS) |

#### Visuales (dos tablas de detalle)

- **Detalle Débitos por Efector**: una fila por NC con columnas `Emision (fecha_nc)`, `NC (comprobante)`, `financiador`, `Efector`, `Aceptado (aceptado_NC)`. Subtotales por NC.
- **Detalle Débitos por Prestación**: una fila por práctica acreditada con columnas `Emision`, `NC`, `financiador`, `Efector`, `Tipo Debito (tipo_debito del NOTADB)`, `Aceptado`.

> El PBIX dispone de la columna `Categoria` en el panel "Columnas" lo que permite agregarla al visual cuando se necesite drill-down adicional.

### Granularidad

Una fila por **(NC, nro_crg, prestacion, id_proveedor, id_entidad, tipo_prestacion, NOTADB_origen)**. Es decir: una fila por cada práctica de la NC que se cruzó (o no) con su NOTADB origen.

### Uso funcional

Permite:

- Cuantificar **cuánto efectivamente se aceptó** vía NC (a diferencia de Hojas 3-5 que muestran lo impugnado).
- Conectar cada NC con la NOTADB original que le dio origen, viendo en una misma fila los importes de impugnación (`rechazado_notadb`, `aceptado_notadb`) y los importes de la NC (`aceptado_NC`, `rechazado_NC`).
- Detectar inconsistencias: por ejemplo, NCs sin NOTADB matcheado (problemas de parsing del detalle), o diferencias entre lo aceptado en el NOTADB y lo efectivamente acreditado en la NC.
- Auditar el ciclo completo impugnación → aceptación → NC por efector / OS / prestación / motivo.
- Drill-down a nivel comprobante (qué NC concreta acreditó qué).

### Comparación rápida vs Hojas 3-5

> Hojas 3-5 contestan **"qué se impugnó"**.
> Hoja 6 contesta **"qué se terminó acreditando como NC"**.
>
> Ambas vistas son necesarias porque no toda impugnación se acepta, y la diferencia entre lo impugnado y lo aceptado es el indicador real de conflictividad con el cliente.

---

## Hoja 7 — Objetivos Mensuales

### Descripción

Hoja "**Cumplimiento de Objetivos**". Cierra el reporte mostrando el **cumplimiento mensual del objetivo de facturación neta por efector**. Combina en una sola vista:

- Lo facturado en el mes (Hoja 1).
- Los débitos efectivamente aceptados como NC (Hoja 6).
- El **facturado neto** = facturado − débitos aceptados.
- El **objetivo mensual** definido manualmente por la conducción.
- El **% de cumplimiento** = facturado neto / objetivo.

Es la hoja de gestión / KPI por excelencia: muestra para cada efector cuánto facturó, cuánto le descontaron por NC, cuánto neto le quedó, contra cuánto era su objetivo del mes y qué porcentaje cumplió.

### Tabla origen: `objetivos_efectores` (DBA)

A diferencia de las hojas anteriores, esta hoja **no consulta una sola tabla**: consume una tabla materializada (`DBA.objetivos_efectores`) que es el **resultado de cruzar 3 fuentes distintas** del DW + un objetivo manual mensual por efector. Esa tabla se materializa por proceso Python diario.

#### Cómo se genera

| Item | Detalle |
|---|---|
| Script principal | `main.py` (en la carpeta `Objetivos Mensuales` / análoga del proyecto Efectores) |
| Base destino | `DBA` (`10.22.1.44`) |
| Tabla destino | `public.objetivos_efectores` |
| PK | `(anio, mes, id_efector)` |
| Estrategia | UPSERT vía `INSERT ... ON CONFLICT (anio,mes,id_efector) DO UPDATE` |
| Frecuencia | Diaria |

#### DDL de la tabla destino

```sql
CREATE TABLE IF NOT EXISTS public.objetivos_efectores (
    anio                int    NOT NULL,
    mes                 int    NOT NULL,
    mesfecha            date   NOT NULL,
    id_efector          bigint NOT NULL,
    efector             text,
    total_facturado_mes numeric(18,2) NOT NULL DEFAULT 0,
    total_nc_mes        numeric(18,2) NOT NULL DEFAULT 0,
    total_neto_mes      numeric(18,2) NOT NULL DEFAULT 0,
    objetivo            numeric(18,2),
    updated_at          timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (anio, mes, id_efector)
);
```

#### Las 3 queries fuente

##### 1. Facturación del mes (SIF)

```sql
SELECT
    EXTRACT(YEAR  FROM c.fecha_emision)::int AS anio,
    EXTRACT(MONTH FROM c.fecha_emision)::int AS mes,
    ef.id_proveedor::bigint                  AS id_efector,
    ef.nombre_proveedor                      AS efector,
    SUM(crg.importe_facturado)               AS total_facturado_mes
FROM comprobantecrg crg
LEFT JOIN wwcomprobantes c
    ON crg.comprobante = c.comprobante
LEFT JOIN efectores ef
    ON crg.id_proveedor = ef.id_proveedor
WHERE crg.tipo IN ('FACA2','FACB2','FAECA','FAECB')
  AND c.centro_costo = 'FACOEP'
GROUP BY 1,2,3,4
```

> Nota: misma lógica de filtrado que la Hoja 1 (Familia "Facturas FACOEP" según `wwcomprobantes`), pero acá se restringe adicionalmente a `centro_costo = 'FACOEP'`.

##### 2. NC del mes (DBA — viene de Hoja 6)

```sql
SELECT
    EXTRACT(YEAR  FROM fecha_nc)::int AS anio,
    EXTRACT(MONTH FROM fecha_nc)::int AS mes,
    id_proveedor::bigint              AS id_efector,
    SUM(aceptado_notadb)              AS total_nc_mes
FROM efectores_montos_aceptados
GROUP BY 1,2,3
```

> Esto reutiliza la tabla materializada por la Hoja 6. Se suma `aceptado_notadb` (el monto que la NC efectivamente acreditó al cliente).

##### 3. Objetivos manuales (DBA)

```sql
SELECT
    EXTRACT(YEAR  FROM to_date(mesfecha, 'DD/MM/YYYY'))::int AS anio,
    EXTRACT(MONTH FROM to_date(mesfecha, 'DD/MM/YYYY'))::int AS mes,
    efector_id::bigint                                        AS id_efector,
    MAX(efector)                                              AS efector,
    COALESCE(NULLIF(MAX(objetivo::numeric), 0), 0)            AS objetivo
FROM public.objetivos_mensuales
WHERE efector_id <> -1
GROUP BY 1,2,3
```

> `objetivos_mensuales` es una tabla manual cargada por la conducción, donde cada efector tiene su objetivo de facturación neta por mes. Se castea `mesfecha` desde `'DD/MM/YYYY'` y se excluye el id `-1` (placeholder).

### Construcción del DataFrame final (Python)

#### Pipeline

1. **Leer las 3 fuentes** con `read_df()` y normalizar las claves (`anio`, `mes`, `id_efector` a `Int64`).

2. **Corrección manual de id_efector**:
   ```python
   fix_objetivos_id_41(df_o, old_id=41, new_id=2334)
   ```
   En el dataset de objetivos se reemplaza `id_efector = 41 → 2334` (corrección histórica).

3. **Filtro temporal** (`filter_rango_2026_a_mes_actual`):
   - `anio >= 2026`.
   - Hasta `(anio_actual, mes_actual)`.
   - Excluye filas con `anio`, `mes` o `id_efector` nulos.

4. **Universo de efectores** = `UNION` de los IDs de facturas, NCs y objetivos:
   ```python
   universo_ids = universo_ids_f ∪ universo_ids_nc ∪ universo_ids_o
   ```

5. **Calendario mensual** desde `2026-01-01` hasta el primer día del mes actual.

6. **Grilla cartesiana** meses × efectores (`df_cal × dim_ef`) → garantiza una fila por (anio, mes, id_efector) aún cuando ese efector no haya facturado, no tenga NC o no tenga objetivo en ese mes.

7. **3 LEFT JOINs** sobre la grilla para incorporar facturado, NC y objetivo.

8. **Defaults**: NULLs → 0 en `total_facturado_mes`, `total_nc_mes`, `objetivo`.

9. **Cálculo**:
   ```
   total_neto_mes = total_facturado_mes - total_nc_mes
   ```

10. **Resolución del nombre del efector**:
    - Primero se toma desde el dataset de facturas.
    - Si no aparece, se intenta desde el dataset de objetivos.
    - Si tampoco, se asigna `"SIN_NOMBRE_EN_DIM"`.

11. **UPSERT** sobre `DBA.objetivos_efectores` por la PK `(anio, mes, id_efector)`. Las columnas que cambian (mesfecha, efector, importes, objetivo, updated_at) se actualizan en el `ON CONFLICT`.

### Diccionario de campos (`objetivos_efectores`)

| # | Campo | Tipo | Descripción |
|---|---|---|---|
| 1 | anio | int | Año del periodo (PK) |
| 2 | mes | int | Mes del periodo (PK) |
| 3 | mesfecha | date | Primer día del mes (`anio-mes-01`) |
| 4 | id_efector | bigint | ID del efector (PK) |
| 5 | efector | text | Nombre del efector (resuelto desde facturas → objetivos → "SIN_NOMBRE_EN_DIM") |
| 6 | total_facturado_mes | numeric(18,2) | Facturación bruta del mes (de Hoja 1, filtrada por `centro_costo='FACOEP'`) |
| 7 | total_nc_mes | numeric(18,2) | Suma de `aceptado_notadb` de NC aceptadas en el mes (de Hoja 6) |
| 8 | total_neto_mes | numeric(18,2) | `total_facturado_mes - total_nc_mes` |
| 9 | objetivo | numeric(18,2) | Objetivo manual del mes para el efector (de `objetivos_mensuales`) |
| 10 | updated_at | timestamp | Fecha de última actualización por el proceso |

### Reglas de negocio

#### Filtro temporal hardcodeado: `anio >= 2026`

El proceso solo procesa periodos a partir de **enero 2026** (a pesar del comentario en el código que menciona "Enero 2025"). Los meses de 2025 hacia atrás no se cargan en `objetivos_efectores`.

> Si en el PBIX se aplica filtro de Año = 2025 (como en el screenshot) y aparecen valores, esos valores existen porque venían de una corrida anterior con la regla previa o porque la tabla destino conserva históricos. La regla actual del proceso solo materializa de 2026 en adelante.

#### Universo de efectores

`UNION` de:

- Efectores que facturaron en el periodo.
- Efectores con NC aceptadas en el periodo.
- Efectores con objetivo definido en el periodo.

Esto garantiza que un efector con objetivo pero **sin facturar** aparezca igual con `total_facturado_mes = 0` y `% cumplimiento = 0`. Inversamente, un efector que facturó pero no tenía objetivo aparece con `objetivo = 0`.

#### Corrección de id_efector

```
id_efector = 41  →  id_efector = 2334
```

Solo en el dataset de objetivos. Es una corrección manual por un cambio de codificación de un efector específico.

#### Cálculo de neto

```
total_neto_mes = total_facturado_mes - total_nc_mes
```

NC se restan en su totalidad, sin importar si la fecha de la NC es del mes corriente o de un mes anterior — porque en `efectores_montos_aceptados` se imputaron por `fecha_nc`.

#### Resolución de nombre

| Origen del nombre | Prioridad |
|---|---|
| Dataset de facturas (`efectores`) | 1 |
| Dataset de objetivos (`objetivos_mensuales`) | 2 (fallback) |
| Default | `"SIN_NOMBRE_EN_DIM"` |

#### UPSERT (idempotencia)

Como el script corre todos los días, los meses ya consolidados se vuelven a calcular y reescribir. Esto asegura que ajustes posteriores en facturas, NCs u objetivos se reflejen automáticamente.

### Reglas / cálculos del PBIX

#### Filtros fijos de página

- `CentroCostos = FACOEP` — solo se mira la unidad FACOEP.
- `rechazada = NO` — se mantiene el criterio de excluir NOTADBs auto-generados (la NC viene del cruce con esa data).

#### Filtros visibles

| Filtro | Campo |
|---|---|
| Año | `anio` |
| Mes | `mes` |
| Efector | `efector` |

#### KPIs (franja izquierda)

| KPI | Cálculo |
|---|---|
| **Total Facturado** | `SUM(total_facturado_mes)` |
| **Débitos Aceptados NC** | `SUM(total_nc_mes)` |
| **Facturado Neto** | `SUM(total_neto_mes)` |
| **Objetivo Mensual** | `SUM(objetivo)` |
| **% Cumplimiento** | `Facturado Neto / Objetivo Mensual × 100` |

> En el screenshot el ejemplo muestra `% Cumplimiento = 92,25 %` (145.023M neto / 157.206M objetivo).

#### Visual principal: tabla "Detalle"

| Columna | Origen |
|---|---|
| Efector | `efector` |
| Total Facturado | `total_facturado_mes` |
| Débitos Aceptados NC | `total_nc_mes` |
| Facturado Neto | `total_neto_mes` |
| Objetivo | `objetivo` |
| % | `total_neto_mes / objetivo` |

Una fila por efector (suma de los meses filtrados).

### Granularidad

Una fila por **(anio, mes, id_efector)**.

### Comparación con hojas anteriores

| Hoja | Mira | Universo | Construcción |
|---|---|---|---|
| 1 | Facturado por comprobante | Comprobantes facturados | Query directa |
| 2 | Facturado por CRG | CRGs (con o sin facturar) | Tabla DW `recupero_gastos` |
| 3-5 | Lo impugnado (NOTADB) | Impugnaciones emitidas | Query directa |
| 6 | Lo aceptado vía NC | NCs por impugnación aceptada | Tabla custom `efectores_montos_aceptados` (Python) |
| **7** | **Cumplimiento de objetivo** | **Grilla mes × efector (universo unión)** | **Tabla custom `objetivos_efectores` (Python, agrega Hoja 1 + Hoja 6 + objetivos manuales)** |

La Hoja 7 es la más "compuesta" del reporte: depende del proceso de la Hoja 6 (que a su vez depende de un proceso Python anterior) y de una carga manual mensual de objetivos.

### Uso funcional

Permite:

- KPI gerencial de cumplimiento mensual por efector.
- Ranking de efectores que más / menos cumplen su objetivo.
- Identificar efectores sin objetivo asignado (`objetivo = 0`).
- Identificar efectores con objetivo pero sin facturar (`total_facturado_mes = 0`).
- Análisis del impacto de las NC sobre la facturación neta (gap entre Total Facturado y Facturado Neto).
- Acumulado anual filtrando todos los meses.

### Tabla manual relacionada: `objetivos_mensuales`

Vale la pena documentar mínimamente la tabla fuente de los objetivos:

| Item | Detalle |
|---|---|
| Base | DBA (`10.22.1.44`) |
| Tabla | `public.objetivos_mensuales` |
| Carga | Manual (carga directa desde Excel / formulario, fuera del proceso automatizado) |
| Campos relevantes | `mesfecha` (varchar `DD/MM/YYYY`), `efector_id` (bigint), `efector` (text), `objetivo` (numeric) |
| Filtro de saneo | `efector_id <> -1` |

Es una tabla de input humano: si la conducción no carga el objetivo de un efector para un mes, ese efector aparecerá con `objetivo = 0` en `objetivos_efectores` y por ende `% cumplimiento = 0` (o sin sentido).

---

*(Próximas hojas se irán agregando a este mismo documento siguiendo la misma estructura: Descripción, Query, Fuentes, Campos, Reglas de negocio, Granularidad, Uso funcional.)*
