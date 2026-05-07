# Reporte: Recupero_Gastos

## Descripción

Reportes PowerBI vinculados al **Recupero de Gastos PAMI / financiadores**. Exponen las tres tablas materializadas por el proceso de integración SIGEHOS → SIF documentado en [docs/tablas/integracion_recupero_gastos.md](../tablas/integracion_recupero_gastos.md):

- `sigehos_crg_recupero` (cabecera CRG)
- `sigehos_dph_recupero` (detalle DPH)
- `sigehos_anexos_recupero` (anexos / remitos)

Conviven dos `.pbix` con vistas distintas:

- `Recupero Gastos.pbix`: vista general (KPIs por efector / financiador, evolución, pendientes de facturar, volumen documental).
- `Informe Sigehos Conectado.pbix`: vista en vivo del estado de la integración SIGEHOS.

Adicionalmente la carpeta tiene un proceso mensual (`Apertura Mensual PAMI Capita.R`) que se mantiene como script auxiliar para calcular el porcentaje de afiliados por efector usado en la liquidación capitada.

---

## Tipo

Reportes / dashboards basados en las tablas SIGEHOS materializadas + un proceso mensual auxiliar de apertura.

---

## Frecuencia

- Reportes BI: diaria (refresco contra las tablas DW del proceso de integración).
- Apertura mensual: una vez por mes.

---

## Primary Key sugerida

N/A (las tablas DW que consume tienen sus propias PKs — ver `docs/tablas/integracion_recupero_gastos.md`).

---

## Fuente origen

### Tablas DW (base SIF)

- `sigehos_crg_recupero`
- `sigehos_dph_recupero`
- `sigehos_anexos_recupero`

Las tres tablas están materializadas por el proceso ETL documentado en [`docs/tablas/integracion_recupero_gastos.md`](../tablas/integracion_recupero_gastos.md), que las puebla a partir de:

- **V1**: bases MySQL SIGEHOS por efector.
- **V2**: vistas Oracle institucionales (`USUARIO_RDG.RDGV_CRG_FACOEP`, `RDGV_DPH_FACOEP`, `RDGV_REMITO_FACOEP`).

### Tablas auxiliares (Producción Facoep)

- `proveedorprestador` (para enriquecimiento de efectores en el proceso mensual).

### Lookup externo

- `databases.xlsx` (homologación efector ↔ base SIGEHOS, ver tabla maestra en `integracion_recupero_gastos.md`).
- `Financiadores.xlsx`, `FinanciadoresCompletar.xlsx`, `FinanciadoresDPH.xlsx`.
- `parametros_servidor.xlsx`.

---

## Proceso que la genera

### Archivos PowerBI

- `Recupero Gastos.pbix` — vista general.
- `Informe Sigehos Conectado.pbix` — vista en vivo de la integración.

### Cómo refrescan

Power Query consume directamente las tablas `sigehos_crg_recupero`, `sigehos_dph_recupero`, `sigehos_anexos_recupero` desde la base destino (SIF). Los pasos típicos del PBIX (visibles en el Editor de Power Query del reporte general):

- Origen → Navegación a `public.sigehos_*_recupero`.
- Columnas condicionales (estado / clasificaciones).
- Reemplazos de valores y normalización de tipos.
- Renombre de columnas para presentación.

No hay scripts R que reescriban estas tablas: la transformación pesada vive en el proceso de integración.

### Scripts R (auxiliares, en la carpeta del reporte)

- `Apertura Mensual PAMI Capita.R` → genera Excel mensual con apertura % de afiliados por efector (ver detalle abajo).
- `Script CRG Informe.R`, `Script DPH Informe.R`, `Script Anexos Informe.R` → wrappers que leen las tablas para análisis ad-hoc en R.
- `Script Efectores.R`, `Script Financiadores.R` → maestros auxiliares.
- `Script_Facturacion_Funciones.R` (helpers).

### Output mensual (Apertura)

- `//facoep/Sistemas/PAMI CAPITA/Apertura {mes}-{anio}.xlsx`.

---

## Campos relevantes

Los del modelo de las tablas DW que consume. Resumen:

### sigehos_crg_recupero

`fecha`, `numero`, `tipo_anexo`, `estado`, `cant_dphs`, `financiador_sigla`, `financiador_nombre`, `importe_total`, `origin`, `id_proveedor_sif`, `efector`.

### sigehos_dph_recupero

`fecha`, `numero`, `tipo_anexo`, `estado`, `nro_crg`, `financiador_sigla`, `financiador_nombre`, `apellidos`, `nombres`, `documento`, `importe_total`, `origin`, `id_proveedor_sif`, `efector`.

### sigehos_anexos_recupero

`fecha`, `nro_anexo`, `apellidos`, `nombres`, `documento`, `tipo_anexo`, `financiador_sigla`, `financiador_nombre`, `especialidad`, `importe`, `id_dph`, `estado`, `origin`, `id_proveedor_sif`, `efector`.

(Diccionario completo en [`docs/tablas/integracion_recupero_gastos.md`](../tablas/integracion_recupero_gastos.md).)

---

## Reglas de negocio

### Reglas heredadas del proceso de integración

Las reglas duras de transformación (homologación efector via `databases.xlsx`, `origin = recupero_v2` para V2, normalización de `tipo_anexo`, estado calculado de anexos por combinación `importe` / `id_dph`) viven en el proceso de integración. Ver `docs/tablas/integracion_recupero_gastos.md`.

### Reglas del proceso mensual `Apertura Mensual PAMI Capita`

#### Rango temporal

Se calcula sobre el **mes calendario completo anterior** al día de ejecución:

```r
LastDate  <- floor_date(today(), unit = "month") - 1
FirstDate <- as.Date(paste(year(LastDate), month(LastDate), 1, sep = "-"))
```

#### Cálculo de afiliados

Sobre `anexos_recupero` (versión legacy del script — apunta a la base `sigehos_recupero` directa, no a la tabla del DW):

```r
Afiliados <- unique(select(data, Efector, Mes, Documento))
Afiliados <- aggregate(.~Efector+Mes, Afiliados, sum)
```

Cuenta afiliados únicos por efector y mes.

#### Filtro de efectores incluidos

Solo se consideran los `pprid` específicos de la lista hardcodeada:

`5, 13, 17, 25, 4, 2678, 19, 9, 21, 11, 10, 23, 2, 6, 26, 14, 3, 24, 20, 16, 22`.

#### Cálculo de porcentaje

```
Percentage = Total_efector / SUM(Total)
```

#### Encoding

`SET client_encoding = 'windows-1252'`.

---

## Estrategia de carga

- Reportes BI: refresco directo contra `public.sigehos_*_recupero` en SIF (no persisten tabla destino propia).
- Apertura mensual: genera Excel en `//facoep/Sistemas/PAMI CAPITA/`. No persiste en DB.

---

## Relaciones principales

| Campo | Tabla relacionada |
|---|---|
| id_proveedor_sif | proveedorprestador / efectores |
| nro_crg (en sigehos_dph_recupero) | sigehos_crg_recupero |
| id_dph (en sigehos_anexos_recupero) | sigehos_dph_recupero |
| documento | afiliado |
| financiador_sigla | obrassociales / Financiadores.xlsx |

---

## Uso funcional

Permite:

- Analizar recupero por efector / financiador / período.
- Seguimiento de facturación (vía `tipo_anexo` y `estado`).
- Detectar prestaciones pendientes de facturar.
- Performance por financiador.
- Volumen documental (CRGs / DPHs / Anexos) por período.
- Apertura mensual de afiliados PAMI por efector para liquidación capitada.

---

## Owner

DBA / Recupero / BI

---

## Archivos PBIX

- `E:/.../reportes/Recupero_Gastos/Recupero Gastos.pbix`
- `E:/.../reportes/Recupero_Gastos/Informe Sigehos Conectado.pbix`

---

## Documentación relacionada

- [`docs/tablas/integracion_recupero_gastos.md`](../tablas/integracion_recupero_gastos.md) — proceso ETL que materializa las tablas que consume este reporte.
