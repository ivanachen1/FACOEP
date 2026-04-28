# Reporte: matriz_de_clientes

## Descripción

Reporte PowerBI que arma la **matriz de clientes (obras sociales)** mensual: para cada cliente consolida saldo histórico, facturación, notas de crédito, cobranzas, impugnaciones (NOTADB) y cálculos derivados (facturación neta, porcentajes individuales y acumulados, categorización Pareto).

Es uno de los reportes más completos del set: el script principal arma una tabla "Matriz" de una sola fila por cliente con todos los KPIs financieros, y agrega scoring tipo Pareto (categoría 1 = clientes que acumulan hasta el 80% de facturación, categoría 2 = el resto).

---

## Tipo

Reporte / dashboard mensual + cálculo de matriz consolidada por cliente.

---

## Frecuencia

Mensual.

---

## Primary Key sugerida

- clienteid + fecha_revision

---

## Fuente origen

### Bases consultadas

- Producción: `10.22.1.61 / facoep` y `10.22.1.44 / facoep`
- SIF (DBA local): `localhost / SIF`

### Tablas

- `clientes`
- `comprobantes`
- `comprobantesimputaciones`
- `comprobantesasociados`
- (más vistas e imágenes históricas de saldo)

### Lookup externo (en `files/`)

- `tipo_comprobante.xlsx` (factura / nota_credito / notadb / recibo)
- `tipo_comprobante_saldos.xlsx`
- `fechas_corte.xlsx` (calendario de cortes con `fecha_revision`, `Fecha_inicio_factura`, `fecha_fin_factura`, `Fecha_inicio_otros`, `Fecha_fin_otros`)
- `Calendar.csv`
- `cuenta_publica.xlsx`
- `historico_Saldos2.csv`
- `sub_categorias.xlsx`
- `parametros_servidor.xlsx`

---

## Proceso que la genera

### Archivo PowerBI

- `Matriz de Cliente.pbix`

### Scripts R (en `scripts/`)

- `Main.R` (orquestador principal)
- `FuncionesHelper.R` (queries dinámicos)
- `facturadoBruto.R` (cálculo de facturación bruta)
- `SaldosClientesExceltoPostgres.R` (carga de saldos desde Excel)
- `SaldosHistoricos.R` (mantenimiento de saldos históricos)
- `migracionData.R`
- `conexion-powerbi.R`

### Scripts Python (en `informes/`)

- `saldos_historicos.py`
- `HelperFunctions.py`
- `funciones_helper.py`

### Documentación interna

- `Query Crear Tabla Server.12.txt`
- `query imputaciones.txt`

---

## Campos relevantes (Matriz)

| Campo | Descripción |
|---|---|
| clienteid | ID del cliente |
| clientenombre | Nombre del cliente |
| saldo_historico | Saldo arrastrado al inicio del periodo |
| importe_facturado | Total facturado en el periodo |
| importe_notacredito | NC del periodo (más impugnado imputado) |
| importe_notacredito_original | NC sin sumar impugnaciones |
| importe_recibos | Cobranza |
| importe_impugnado_total | NOTADB total |
| importe_impugnado_desimputado | NOTADB sin imputar |
| importe_impugnado_imputado | `importe_impugnado_total - importe_impugnado_desimputado` |
| Facturacion_Neta_Cliente | `importe_facturado - importe_notacredito` |
| Facturacion_Bruta_Total | Suma de facturación de todos los clientes |
| porcentaje_cliente | `importe_facturado / Facturacion_Bruta_Total` |
| porcentaje_facturado_acumulado | Acumulado ordenado descendente |
| porcentaje_cobrado_cliente | `importe_recibos / Facturacion_Neta_Cliente` |
| Categoria_facturacion | 1 (acumulado < 80%), 2 (>= 80%), 0 (no facturó) |

---

## Reglas de negocio

### Selección del mes a procesar

Se filtra `fechas_corte.xlsx` por `fecha_revision = Sys.Date()` truncado a mes.

### Rango de fechas

Cada cliente se mide entre `Fecha_inicio_factura` y `fecha_fin_factura` (definidos en el calendario de cortes). Las imputaciones se miden entre `Fecha_inicio_otros` y `Fecha_fin_otros`.

### Tipos de comprobante

`tipo_comprobante.xlsx` se filtra por categoría:

- factura → `comprobantes_facturas`
- nota_credito → `comprobantes_nc`
- notadb → `comprobantes_notadb`
- recibo → `comprobantes_recibos`

Estos arrays se inyectan como IN-SQL en cada query.

### Reasignación de NC

```r
importe_notacredito_original = importe_notacredito
importe_notacredito          = importe_notacredito_original + importe_impugnado_imputado
```

Es decir: las impugnaciones imputadas se suman a la nota de crédito efectiva.

### Categorización Pareto

```r
Categoria_facturacion = 1 cuando porcentaje_facturado_acumulado < 0.8 y importe_facturado > 0
Categoria_facturacion = 2 cuando porcentaje_facturado_acumulado >= 0.8 y importe_facturado > 0
Categoria_facturacion = 0 cuando importe_facturado == 0
```

### Tratamiento de NULLs

`Matriz[is.na(Matriz)] = 0` (todos los NULLs se reemplazan por 0).

### Saldos históricos

Se obtienen vía `GetNewSaldosDeuda(clientes, fechaHasta)` (saldo arrastrado al cierre del periodo anterior).

---

## Estrategia de carga

El script genera la matriz en memoria. La persistencia / Excel intermedio depende de los scripts auxiliares (`SaldosClientesExceltoPostgres.R`, `migracionData.R`).

Subcarpeta `exportables/` y `informes/` contienen utilidades adicionales (Python para saldos históricos).

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| clienteid | clientes |
| comprobante | comprobantes |
| factura | wwcomprobantes |

---

## Uso funcional

Permite:

- Vista 360° de cada cliente: saldo, facturado, cobrado, NC, impugnado.
- Ranking Pareto (clientes que generan el 80% de la facturación).
- Tracking mensual de cobranza por cliente.
- Comparación contra cuenta pública.

---

## Owner

DBA / Cobranzas

---

## Archivo PBIX

`E:/.../reportes/matriz_de_clientes/Matriz de Cliente.pbix`
