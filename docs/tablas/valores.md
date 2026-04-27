# Tabla: valores

## Descripción

Tabla maestra de valores (cheques, transferencias y otros instrumentos de pago/cobro) registrados en el sistema. Contiene tipo de valor, código, fechas operativas (emisión, vencimiento, entrada, salida), serie/número, librador, importe, saldo, banco y comprobante de entrada.

Permite analizar la cartera de valores en cartera vs. valores ya despachados, su historial y conciliar contra comprobantes.

---

## Tipo

Hecho transaccional / maestro de valores.

---

## Frecuencia

Diaria.

---

## Primary Key sugerida

- codigo
- tipo_de_valor

---

## Fuente origen

### Tablas transaccionales

- `valores`
- `tipovalor`
- `banco`

### Lookup externo

- `estados.xlsx`

---

## Proceso que la genera

### Script principal

- `E:/DataWarehouse/valores/main.R`

### Helper

- `E:/DataWarehouse/valores/Funciones_Helper.R`
- `E:/DataWarehouse/valores/Funciones_Helper_valores.R`

### Tabla destino

- `public.valores` (base SIF)

---

## Campos

| # | Campo | Tipo | Nullable | Descripción |
|---|---|---|---|---|
| 1 | tipo_de_valor | varchar | Sí | Descripción del tipo de valor (ej. cheque, transferencia) |
| 2 | codigo | int | Sí | Código identificador del valor |
| 3 | fecha_emision | date | Sí | Fecha de emisión del valor |
| 4 | fecha_vencimiento | date | Sí | Fecha de vencimiento |
| 5 | propio | varchar | Sí | "SI" / "NO" según `tipovalorpropio` |
| 6 | serie | varchar | Sí | Serie del valor |
| 7 | numero | int | Sí | Número del valor |
| 8 | librador | varchar | Sí | Nombre del librador |
| 9 | importe | decimal | Sí | Importe del valor |
| 10 | fecha_entrada | date | Sí | Fecha de entrada (`valormovfechaentra`) |
| 11 | fecha_salida | date | Sí | Fecha de salida (`valormovfechasale`) |
| 12 | saldo | decimal | Sí | Saldo actual del valor |
| 13 | banco_abreviatura | varchar | Sí | Abreviatura del banco |
| 14 | tipo_comprobante_entrada | varchar | Sí | Tipo de comprobante por el cual ingresó (con TRIM) |
| 15 | comprobante_entrada | varchar | Sí | Comprobante de entrada construido como `tipo-prefijo-codigo` |
| 16 | historico_condicion | bool | Sí | TRUE si `fecha_salida IS NULL` (valor en cartera), FALSE si ya salió |
| 17 | estado | varchar | Sí | Estado del valor (enriquecido desde `estados.xlsx`) |

---

## Reglas de negocio

### Decodificación de propio

| Origen (`tipovalorpropio`) | Resultado |
|---|---|
| 0 | NO |
| 1 | SI |

### Construcción de comprobante_entrada

```
comprobante_entrada = TRIM(valortipomoventra) + "-" + valorcmpprefijoentra + "-" + valormovcodigoentra
```

### Cálculo de historico_condicion

`historico_condicion = TRUE` cuando `valormovfechasale IS NULL` (valor aún en cartera). FALSE cuando ya tiene fecha de salida.

### Enriquecimiento de estado

Se cruza `id_estado` contra `estados.xlsx`. El identificador técnico se elimina.

---

## Estrategia de carga

`overwrite = TRUE`, `append = FALSE`. La tabla se reemplaza completa en cada corrida.

---

## Relaciones principales

| Campo destino | Tabla relacionada |
|---|---|
| comprobante_entrada | wwcomprobantes / comprobantes_asociados |
| banco_abreviatura | banco |
| tipo_de_valor | tipovalor |

---

## Uso funcional

Permite:

- Analizar cartera de valores (`historico_condicion = TRUE`).
- Conciliar valores con comprobantes de entrada.
- Tracking de vencimientos y bancos.
- Separar entre valores propios y de terceros.

---

## Owner

DBA

---

## Script generador

`E:/DataWarehouse/valores/main.R`
