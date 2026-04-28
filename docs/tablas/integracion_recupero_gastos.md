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