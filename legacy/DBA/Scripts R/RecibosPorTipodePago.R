library(RPostgreSQL)
library(data.table)
library(tidyverse)
library(stringr)
library(openxlsx)
library(scales)
library(formattable)
library(dplyr)
library(plyr)
library(zoo)
pw <- {"facoep2017"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep2020", host = "172.31.24.12", port = 5432, user = "postgres", password = pw)
postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")
############################################################################################################

data <- dbGetQuery(con, "SELECT
c.comprobantefechaemision as FechaEmisionRecibo,
c.tipocomprobantecodigo as Tipo,
c.comprobantecodigo as Numero,
c.comprobanteentidadcodigo as cliente,
ccostodescripcion as centrocosto,
sccostodescripcion as subcentrocosto,
tpoliqdescripcion as tipoliquidacion,
c.ejercicio,
c.comprobanteasientocodigo,
tipovalordescripcion,
valorimporte,
valorfechaemision

FROM (SELECT *,
CASE WHEN comprobantefechaemision BETWEEN '2017-01-01' and '2017-12-31' THEN '1'  ELSE '' END
||
CASE WHEN comprobantefechaemision BETWEEN '2018-01-01' and '2018-12-31' THEN '2' ELSE '' END
||
CASE WHEN comprobantefechaemision BETWEEN '2019-01-01' and '2019-12-31' THEN '3' ELSE '' END
||
CASE WHEN comprobantefechaemision BETWEEN '2020-01-01' and '2020-12-31' THEN '4' ELSE '' END AS ejercicio
FROM comprobantes) as c
LEFT JOIN centrocostos ON centrocostos.ccostocodigo = c.comprobanteccosto
LEFT JOIN subcentrocostos ON subcentrocostos.ccostocodigo = c.comprobanteccosto and subcentrocostos.ccostocodigo = centrocostos.ccostocodigo and subcentrocostos.sccostocodigo = c.comprobantesccosto
LEFT JOIN tipoliquidacion tp ON tp.ccostocodigo = c.comprobanteccosto and
								tp.sccostocodigo = c.comprobantesccosto and
								tp.tpoliqcodigo = c.comprobantetipoliq
LEFT JOIN (select valortipomoventra, valormovcodigoentra, valorentidadcodigoentra, valorimporte, tipovalordescripcion, valorfechaemision
from valores 
LEFT JOIN tipovalor ON tipovalor.tipovalorcodigo = valores.tipovalorcodigo) as v on v.valortipomoventra = c.tipocomprobantecodigo and v.valormovcodigoentra = c.comprobantecodigo and v.valorentidadcodigoentra = c.comprobanteentidadcodigo
WHERE tipocomprobantecodigo IN ('RECX2', 'RECM') and c.comprobantetipoentidad = 2")

data$rec <- paste(data$tipo,data$numero)

  Reporte <- select(data, 
                  "Emision Recibo" = fechaemisionrecibo,
                  "Recibo" = rec,
                  "Cliente" = cliente,
                  "Centro de Costos" = centrocosto,
                  "SubCentro de Costos" = subcentrocosto,
                  "Tipo de Liquidacion" = tipoliquidacion,
                  "Asiento" = comprobanteasientocodigo,
                  "Tipo Valor" = tipovalordescripcion,
                  "Importe Valor" = valorimporte,
                  "Fecha Valor" = valorfechaemision)

  write.csv(Reporte, "RecibosChequeTransferencia.csv")

  # Cierra todo
  lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
  
  