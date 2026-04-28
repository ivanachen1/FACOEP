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


data <- dbGetQuery(con, "SELECT
CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as Factura,
CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
   c.comprobantefechaemision,
  comprobantetotalimporte, entrega,
  CASE WHEN c.comprobanteintimacion = TRUE THEN 'Intimado' ELSE 'No Intimado' END AS Intimado, intimacionfecha, intimacionfecharecepcion,
  CAST(ci.comprobanteimputaciontipo AS TEXT) || ' - ' || CAST(ci.comprobanteimputacioncodigo AS TEXT) as imputacion, ci.comprobanteimputacionfecha as fechaimputacion, 
  comprobanteimputacionimporte as importeimputacion, comprobantesaldo, ii.intimacionnro
  
  FROM comprobantes c
   LEFT JOIN obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo
   

LEFT JOIN comprobantesimputaciones ci ON ci.empcod = c.empcod and
  											ci.sucursalcodigo = c.sucursalcodigo and
											ci.comprobantetipoentidad = c.comprobantetipoentidad and
											ci.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
											ci.tipocomprobantecodigo = c.tipocomprobantecodigo and
											ci.comprobanteprefijo = c.comprobanteprefijo and
											ci.comprobantecodigo = c.comprobantecodigo
                                       
                      LEFT JOIN intimacionintimaciondet i ON 
                                                              i.intimacionsucursal = c.sucursalcodigo and
                                                              i.intimacioncompempcod = c.empcod and
                                                              i.intimaciontipoentidad = c.comprobantetipoentidad and
                                                              i.intimacionentidadcodigo = c.comprobanteentidadcodigo and
                                                              i.intimaciontipocomp = c.tipocomprobantecodigo and
                                                              i.intimacioncompprefijo = c.comprobanteprefijo and
                                                              i.intimacioncompcodigo = c.comprobantecodigo
                                                              
                      LEFT JOIN intimacion ii ON ii.intimacionnro = i.intimacionnro and
                                                 ii.intimaciontipocomprobantes = i.intimaciontipocomprobantes
                                                 
                     LEFT JOIN (SELECT
                    comprobanteentidadcodigo,
                    tipocomprobantecodigo,
                    comprobantecodigo,
                    MAX(comprobantehisfechatramite) as entrega
                    FROM comprobanteshistorial 
                    WHERE comprobantehisestado = 4
                    GROUP BY comprobanteentidadcodigo, tipocomprobantecodigo, comprobantecodigo) as h ON h.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                                                                                   h.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                                                                                                   h.comprobantecodigo = c.comprobantecodigo
                                  
  WHERE  c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') and 
  c.comprobantetipoentidad = 2
                   ")


data <- filter(data, data$os != "1003 - OSPAÃ'A")
data <- filter(data, data$os != "1 - I.N.S.S.J. y P.")

data$vencimiento <- data$entrega + 30

data$intimacionfecharecepcion <- ifelse(data$intimacionfecharecepcion == '0001-01-01', NA, data$intimacionfecharecepcion)
data$intimacionfecharecepcion <- as.Date(data$intimacionfecharecepcion)

reporte <- filter(data, data$intimacionfecha >= '2021-01-01')
reporte <- filter(reporte, reporte$fechaimputacion > reporte$intimacionfecharecepcion)



reporte <- select(reporte,
                  "Nro Intimacion" = intimacionnro,
                  "Factura" = factura,
                  "Cliente" = os,
                  "Emision" = comprobantefechaemision,
                  "Importe" = comprobantetotalimporte,
                  "Vencimiento" = vencimiento,
                  "Fecha Intimacion" = intimacionfecha,
                  "Recepcion Intimacion" = intimacionfecharecepcion,
                  "Imputacion" = imputacion,
                  "Fecha Imputacion" = fechaimputacion,
                  "Importe Imputacion" = importeimputacion,
                  "Saldo" = comprobantesaldo)

write.csv(reporte, "reporte.csv")

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})


