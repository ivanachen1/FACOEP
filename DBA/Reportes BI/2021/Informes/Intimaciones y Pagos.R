############################################ LIBRERIAS ########################################################
library(data.table)
library(tidyverse)
library(stringr)
library(openxlsx)
library(scales)
library(formattable)
library(stringr)
library(plyr)
library(zoo)
library("RPostgreSQL")
library(lubridate)
library(glue)

pw <- {"odoo"} 
#pw <- {"facoep2017"}
drv <- dbDriver("PostgreSQL")
#con <- dbConnect(drv, dbname = "facoep",
#                 host = "172.31.24.12", port = 5432, 
#                 user = "postgres", password = pw)

con <- dbConnect(drv, dbname = "facoep",
                 host = "localhost", port = 5432, 
                 user = "odoo",password = pw)



query <- paste("SELECT",
               "CONCAT(c.tipocomprobantecodigo,'-',c.comprobanteprefijo,'-',c.comprobantecodigo) as factura,",
               "c.comprobanteintimacion as intimada,",
               "c.comprobantefechaemision as emisionfactura,",
               "CONCAT(asoc.comprobanteasoctipo,'-',asoc.comprobanteasocprefijo,'-',asoc.comprobanteasoccodigo) as recibo,",
               "aux.comprobantefechaemision as emisionrecibo,",
               "val.valorfechaemision as emisionvalor,",
               "valornumero as numerovalor",
               "FROM comprobantes C", 
               "LEFT JOIN comprobantesasociados asoc",
               "ON c.tipocomprobantecodigo = asoc.tipocomprobantecodigo AND",
               "c.comprobanteprefijo = asoc.comprobanteprefijo AND",
               "c.comprobantecodigo = asoc.comprobantecodigo",
               "LEFT JOIN comprobantes aux",
               "ON asoc.comprobanteasoctipo = aux.tipocomprobantecodigo AND",
               "asoc.comprobanteasocprefijo = aux.comprobanteprefijo AND",
               "asoc.comprobantecodigo = aux.comprobantecodigo",
               "LEFT JOIN valores val",
               "ON asoc.comprobanteasoctipo = val.valortipomoventra AND",
               "asoc.comprobanteasoccodigo = val.valormovcodigoentra",
               "WHERE c.tipocomprobantecodigo IN ('FACA2','FACB2','FAECA','FAECB') AND",
               "asoc.comprobanteasoctipo IN ('RECX2')")

data <- dbGetQuery(con,query)

data$factura <- gsub(" ","",data$factura)
data$recibo <- gsub(" ","",data$recibo)
data$emisionfactura <- as.Date(data$emisionfactura)
data$emisionrecibo <- as.Date(data$emisionrecibo)
data$emisionvalor <- as.Date(data$emisionvalor)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})



