# Reporte: Facturacion-Migrado

## Descripción

Reporte multiprocesos de **facturación general** (versión migrada de los reportes de facturación previos). Cubre varias solapas: Facturas Emitidas, Facturas PAMI, CRG SIF-Sigehos, Evolución de Efectores y Monitoreo de Objetivos. Soporta dos `.pbix` complementarios (general + hospitales) y se alimenta de un set amplio de Excels de configuración.

Es uno de los reportes más completos del set: combina facturación, objetivos, financiadores, exclusiones manuales, multiplicadores por tipo de comprobante y enriquecimiento por centro de costo.

---

## Tipo

Reporte / dashboard de facturación general (multi-solapa).

---

## Frecuencia

Diaria (refresco contra Producción).

---

## Primary Key sugerida

N/A.

---

## Fuente origen

### Tablas transaccionales (Producción)

- `comprobantes`
- `clientes`
- `comprobantecrg`
- `crg`
- `proveedorprestador`

### Lookup externo (`excels/`)

- `tipo_comprobante.xlsx` (lista de tipos a procesar + multiplicadores + flag SIF2)
- `centro_costo_comprobantes.xlsx`
- `Codigos Obra Social a Desestimar.xlsx`
- `ComprobantesDesestimar.xlsx`
- `Efectores.xlsx`
- `EfectoresObjetivos.xlsx` / `EfectoresObjetivosNew.xlsx`
- `Objetivos.xlsx`
- `Detalles PAMI Cápita.xlsx`
- `FacturasPAMI.xlsx`
- `tipo_financiador.xlsx`
- `crg_estados.xlsx`
- `databases.xlsx`
- `parametros_servidor.xlsx`

---

## Proceso que la genera

### Archivos PowerBI (en `informes/`)

- `Facturacion.pbix` (vista general)
- `Facturación Hospitales.pbix` (vista hospitales)

### Scripts R (en `scripts/`)

- `Script Solapa Facturas Emitidas.R` → solapa Facturas Emitidas
- `Script Solapa Facturas PAMI.R` → solapa Facturas PAMI
- `Solapa CRG SIF-SIGEHOS.R` → solapa comparativa SIF vs Sigehos
- `script_solapa_evolucion_efectores.R` → solapa Evolución de Efectores
- `script_solapa_monitoreo_objetivos.R` → solapa Monitoreo de Objetivos
- `Script_Facturacion_Funciones.R` (helpers comunes)
- `query para migrar CRG SIF-Sigehos.txt` (query de referencia)

---

## Campos relevantes

### Salida principal (Facturas Emitidas)

| Campo | Descripción |
|---|---|
| Financiador | `clienteid - clientenombre` |
| tipocomprobantecodigo | Tipo de comprobante |
| Fecha Emision | Fecha de emisión |
| Centro de Costos | Decodificado desde `centro_costo_comprobantes.xlsx` |
| Anio / Mes / Dia / Nombre del Mes | Desglose calendario |
| importe | `comprobantetotalimporte * Multiplicador` (signo del tipo de comprobante) |
| Anulado | "SI" si la descripción contiene "ANULADO", "NO" en otro caso |
| NroComprobante | `tipo-prefijo-codigo` |

---

## Reglas de negocio

### Filtro principal de comprobantes

- `comprobantetipoentidad = 2` (cliente).
- `tipocomprobantecodigo IN (lista de tipo_comprobante.xlsx)`.
- `comprobantefechaemision > '2017-01-01'`.

### Multiplicador por tipo de comprobante

Cada tipo de comprobante tiene un `Multiplicador` (+1 / -1) en `tipo_comprobante.xlsx`. El importe final se calcula como:

```
importe = comprobantetotalimporte * Multiplicador
```

Esto permite que las notas de crédito resten automáticamente.

### Marcado de anulado

`Anulado = "SI"` cuando `comprobantedetalle LIKE '%ANULADO%'`.

### Filtro adicional para SIF2

Para la solapa de Evolución de Efectores se filtra por `SIF2 = TRUE` en `tipo_comprobante.xlsx`.

### Exclusiones manuales

- Códigos de obra social listados en `Codigos Obra Social a Desestimar.xlsx` se excluyen del query.
- Comprobantes específicos listados en `ComprobantesDesestimar.xlsx` (se construyen como `tipo-prefijo-codigo`) se excluyen del DataFrame final.

### Limpieza de comprobantes

`CleanTablaComprobantes` arma `NroComprobante = TRIM(tipocomprobantecodigo) + "-" + comprobanteprefijo + "-" + comprobantecodigo` y deduplica.

### Lectura de credenciales

Vía `parametros_servidor.xlsx` (host, user, password, database).

---

## Estrategia de carga

Los scripts trabajan en memoria y alimentan los `.pbix` (carpeta `informes/`). No persisten tabla destino propia.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| comprobante | comprobantes / wwcomprobantes |
| clienteid | clientes |
| comprobanteccosto | centrocostos / centro_costo_comprobantes.xlsx |
| efector | efectores / EfectoresObjetivos.xlsx |

---

## Uso funcional

Permite:

- Ver facturación emitida por financiador, centro de costo, efector.
- Aplicar correctamente signo de NC mediante multiplicador.
- Comparar facturación PAMI cápita vs extracápita.
- Hacer monitoreo de objetivos por efector.
- Detectar evolución temporal por hospital.
- Solapa CRG SIF vs Sigehos.

---

## Owner

DBA

---

## Archivos PBIX

- `E:/.../reportes/Facturacion-Migrado/informes/Facturacion.pbix`
- `E:/.../reportes/Facturacion-Migrado/informes/Facturación Hospitales.pbix`
