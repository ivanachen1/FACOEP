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
meses <- c("01 - Enero","02 - Febrero","03 - Marzo",
           "04 - Abril","05 - Mayo","06 - Junio",
           "07 - Julio","08 - Agosto","09 - Septiembre",
           "10 - Octubre","11 - Noviembre","12 - Diciembre")
pw <- {"facoep2017"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep", host = "172.31.24.12", port = 5432, user = "postgres", password = pw)
postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")


RecibosFechas <- dbGetQuery(con, "SELECT
CASE WHEN comprobanteccosto = 1 THEN  'PAMI' ELSE '' END
||
CASE WHEN comprobanteccosto = 2 THEN 'INCLUIR' ELSE '' END
||
CASE WHEN comprobanteccosto = 5 THEN 'FACOEP' ELSE '' END
||
CASE WHEN comprobanteccosto = 9 THEN 'ASI' ELSE '' END as CentroCosto,
CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
  c.tipocomprobantecodigo,
  c.comprobantecodigo,
  c.comprobantefechaemision,
  comprobantetotalimporte,
  comprobanteasoctipo, comprobanteasoccodigo, entrega

  FROM comprobantes c
   LEFT JOIN obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo
   
LEFT JOIN comprobantesasociados a ON a.comprobanteprefijo = c.comprobanteprefijo and
                                       a.empcod = c.empcod and
                                       a.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                       a.sucursalcodigo = c.sucursalcodigo and
                                       a.comprobantetipoentidad = c.comprobantetipoentidad and
                                       a.comprobantecodigo = c.comprobantecodigo and
                                       a.comprobanteentidadcodigo = c.comprobanteentidadcodigo
                                       
                      LEFT JOIN (SELECT
                    tipocomprobantecodigo,
                    comprobantecodigo,
                    MAX(comprobantehisfechatramite) as entrega
                    FROM comprobanteshistorial 
                    WHERE comprobantehisestado = 4
                    GROUP BY comprobanteentidadcodigo, tipocomprobantecodigo, comprobantecodigo) as h ON           h.tipocomprobantecodigo = a.comprobanteasoctipo and
                                                                                                                   h.comprobantecodigo = a.comprobanteasoccodigo
                                  
  WHERE comprobantefechaemision BETWEEN '2021-01-01' AND '2021-12-31' AND 
  c.tipocomprobantecodigo IN ('RECX2') and 
  c.comprobantetipoentidad = 2
                   ")
RecibosFechas <- filter(RecibosFechas, RecibosFechas$os != "1003 - OSPAÑA")
RecibosFechas <- filter(RecibosFechas, RecibosFechas$os != "1 - I.N.S.S.J. y P.")
RecibosFechas$comprobantetotalimporte <- ifelse(duplicated(RecibosFechas$comprobantecodigo), 0, RecibosFechas$comprobantetotalimporte)
RecibosFechas$entrega <- fifelse(is.na(RecibosFechas$entrega), RecibosFechas$comprobantefechaemision, RecibosFechas$entrega)
RecibosFechas$Dias <- RecibosFechas$comprobantefechaemision - RecibosFechas$entrega
RecibosFechas$TipoDeuda <- ifelse(RecibosFechas$Dias > 60, "Deuda Vencida", "Deuda Corriente")

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
