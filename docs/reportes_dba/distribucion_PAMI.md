# Reporte: distribucion_PAMI

## Descripción

Variante alternativa del proceso `Apertura Mensual PAMI Capita` (de `Recupero_Gastos`) pensada para correr **directamente sobre la base consolidada Sigehos** (`sigehos_recupero`) en lugar de la base de Producción Facoep. Calcula el porcentaje de afiliados FACOEP-PAMI por hospital del convenio para liquidación capitada.

A diferencia de la versión de Recupero_Gastos:

- Filtra solo anexos con estado `Arancelado` o `Facturado`.
- Usa la columna `origin` (hospital de origen) en vez de `Efector`.
- Toma la lista de efectores con flag `Convenio = TRUE` desde `Efectores.xlsx`.

---

## Tipo

Proceso mensual de cálculo de apertura.

---

## Frecuencia

Mensual (manual, `alafecha` se setea hardcodeada en el script).

---

## Primary Key sugerida

- pprid (mes y año implícitos en el nombre del archivo)

---

## Fuente origen

### Base consultada

- Postgres consolidado Sigehos: `172.31.24.12 / sigehos_recupero`

### Tabla consultada

- `anexos_recupero` (vía `getQueryAnexos`)

### Lookup externo

- `Efectores.xlsx` (efectores con flag `Convenio`)
- `databases.xlsx` (de la carpeta `Conexion CRGs`, mapeo `database` → `pprid`)

---

## Proceso que la genera

### Scripts

- `Apertura Mensual PAMI Capita.R`
- `FuncionesHelper.R`

### Output mensual

- `Apertura {mes}-{anio}.xlsx`

---

## Campos relevantes

### Apertura

| Campo | Descripción |
|---|---|
| pprnombre | Nombre del efector |
| pprid | ID del efector |
| Percentage | Cantidad de afiliados / total de afiliados |

---

## Reglas de negocio

### Rango temporal

`Desde` y `Hasta` se calculan vía helper `getDateRange(alafecha)`. `alafecha` está hardcodeada (al momento del script: `'2022-09-15'`); en producción debería tomarse `Sys.Date()` (línea comentada).

### Filtro de estado

```r
filter(data, estado == 'Arancelado' | estado == 'Facturado')
```

### Filtro de financiador

`FinanciadorNombre = 'FACOEP PAMI'` (vía `getQueryAnexos`).

### Cálculo de afiliados

```r
Afiliados <- unique(select(data, origin, Mes, documento))
Afiliados <- aggregate(.~origin+Mes, Afiliados, sum)
```

Cuenta afiliados únicos por hospital y mes.

### Cálculo de porcentaje

`Percentage = Total / SUM(Total)`.

### Filtro de efectores con convenio

Se cruza con `Efectores.xlsx` y se filtra por `Convenio == TRUE`.

### Encoding

`SET client_encoding = 'windows-1252'`.

---

## Estrategia de carga

No persiste en DB. Genera Excel `Apertura {mes}-{anio}.xlsx` en el directorio del script.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| origin / database | databases.xlsx (Conexion CRGs) |
| pprid | proveedorprestador |
| documento | afiliado |

---

## Uso funcional

Permite:

- Cálculo alternativo de la apertura mensual PAMI directamente sobre la consolidación Sigehos (sin pasar por Producción Facoep).
- Comparar contra la apertura del proceso `Recupero_Gastos`.

---

## Owner

DBA / Recupero

---

## Script generador

`E:/.../reportes/distribucion_PAMI/Apertura Mensual PAMI Capita.R`
