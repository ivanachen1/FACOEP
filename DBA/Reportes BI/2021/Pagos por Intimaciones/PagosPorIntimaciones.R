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

pw <- {"serveradmin"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "Facoep", host = "10.22.0.142", port = 5432, user = "postgres", password = pw)


#pw <- {"odoo"} 
#drv <- dbDriver("PostgreSQL")
#con <- dbConnect(drv, dbname = "facoep", host = "localhost", port = 5432, user = "odoo", password = pw)

query <- paste("SELECT",
               "CONCAT(c.tipocomprobantecodigo,'-',c.comprobantecodigo) as Factura,",
               "CONCAT(c.comprobanteentidadcodigo,'-',obsocialessigla) as OS,",
               "c.comprobantefechaemision,",
               "comprobantetotalimporte, entrega,",
               "CASE WHEN c.comprobanteintimacion = TRUE THEN 'Intimado' ELSE 'No Intimado' END AS Intimado,",
               "intimacionfecha,",
               "intimacionfecharecepcion,",
               "CONCAT(ci.comprobanteimputaciontipo,'-',comprobanteimputacioncodigo) as imputacion,",
               "ci.comprobanteimputacionfecha as fechaimputacion,",
               "comprobanteimputacionimporte as importeimputacion,",
               "comprobantesaldo,",
               "ii.intimacionnro",
               "FROM comprobantes c",
               "LEFT JOIN obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo",
               "LEFT JOIN comprobantesimputaciones ci ON ci.empcod = c.empcod and",
               "ci.sucursalcodigo = c.sucursalcodigo and",
               "ci.comprobantetipoentidad = c.comprobantetipoentidad and",
               "ci.comprobanteentidadcodigo = c.comprobanteentidadcodigo and",
               "ci.tipocomprobantecodigo = c.tipocomprobantecodigo and",
               "ci.comprobanteprefijo = c.comprobanteprefijo and",
               "ci.comprobantecodigo = c.comprobantecodigo",
               "LEFT JOIN intimacionintimaciondet i ON",
               "i.intimacionsucursal = c.sucursalcodigo and",
               "i.intimacioncompempcod = c.empcod and",
               "i.intimaciontipoentidad = c.comprobantetipoentidad and",
               "i.intimacionentidadcodigo = c.comprobanteentidadcodigo and",
               "i.intimaciontipocomp = c.tipocomprobantecodigo and",
               "i.intimacioncompprefijo = c.comprobanteprefijo and",
               "i.intimacioncompcodigo = c.comprobantecodigo",
               "LEFT JOIN intimacion ii ON ii.intimacionnro = i.intimacionnro and",
               "ii.intimaciontipocomprobantes = i.intimaciontipocomprobantes",
               "LEFT JOIN (SELECT",
               "comprobanteentidadcodigo,",
               "tipocomprobantecodigo,",
               "comprobantecodigo,",
               "MAX(comprobantehisfechatramite) as entrega",
               "FROM comprobanteshistorial",
               "WHERE comprobantehisestado = 4",
               "GROUP BY comprobanteentidadcodigo, tipocomprobantecodigo, comprobantecodigo) as h",
               "ON h.comprobanteentidadcodigo = c.comprobanteentidadcodigo and",
               "h.tipocomprobantecodigo = c.tipocomprobantecodigo and",
               "h.comprobantecodigo = c.comprobantecodigo",
               "WHERE  c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') and",
               "c.comprobantetipoentidad = 2")

#cat(query)

data <- dbGetQuery(con,query)


data <- filter(data, data$os != "1003 - OSPAÃ'A")
data <- filter(data, data$os != "1 - I.N.S.S.J. y P.")
data$factura <- gsub(" ","",data$factura)
data$imputacion <- gsub(" ","",data$imputacion)

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

rm(data)

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})


