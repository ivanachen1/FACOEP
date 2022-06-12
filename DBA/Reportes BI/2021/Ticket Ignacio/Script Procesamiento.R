########################################### LIBRERIAS ########################################################
library(data.table)
library(tidyverse)
library(stringr)
library(openxlsx)
library(scales)
library(formattable)
library(stringr)
library(plyr)
library(zoo)
library(lubridate)
library("RPostgreSQL")
library(BBmisc)
library(glue)
library(readxl)
library(stringr)

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "Facoep",
                 host = "10.22.0.142", port = 5432, 
                 user = "postgres", password = "serveradmin")



query <- paste("SELECT",
               "c.comprobanteentidadcodigo as id,",
               "c.comprobantefechaemision as emision,",
               "c.tipocomprobantecodigo as tipo,",
               "c.comprobanteprefijo as prefijo,",
               "c.comprobantecodigo as numerorecibo,",
               "c.comprobantetotalimporte as importerecibo,",
               "c.comprobanteorigen as origen,",
               "c.ComprobanteEnviadoRes as comprobanteenviado246,",
               "tipo.tipovalorcodigo as tipovalortipo,",
               "tipo.tipovalordescripcion as tipovalor,",
               "val.valorserie as serie,",
               "val.valornumero as numerovalor,",
               "banco.bancodescripcion as banco,",
               "val.valorlibradorctabncnum as numctecorriente,",
               "val.valorlibrador as librador,",
               "val.valorfechaemision as emisionvalor,",
               "val.valorfechavencimiento as vencimientovalor,",
               "val.valorimporte as importevalor,",
               "val.ValorEnviadoRes as depositado",
              
               "FROM comprobantes as c",
               "LEFT JOIN valores as val",
               "ON val.valortipomoventra = c.tipocomprobantecodigo AND",
               "val.valorcmpprefijoentra = c.comprobanteprefijo AND",
               "val.valormovcodigoentra = c.comprobantecodigo",
              
               "LEFT JOIN tipovalor as tipo",
               "ON val.tipovalorcodigo = tipo.tipovalorcodigo",
              
               "LEFT JOIN banco",
               "ON val.valorbancocodigo = banco.bancocodigo",
              
               "WHERE c.tipocomprobantecodigo IN('RECX2')")

#AND c.comprobanteentidadcodigo <> -1

data <- dbGetQuery(con,query)

data$Depositado <- ifelse((data$tipovalortipo == 5 | data$tipovalortipo == 6) && !(is.na(data$valormovcodigosale) | data$valormovcodigosale == " "),
                          "SI","NO")

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
