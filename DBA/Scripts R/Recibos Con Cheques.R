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
pw <- {"facoep2017"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep",
                 host = "172.31.24.12", port = 5432, 
                 user = "postgres", password = pw)
rm(pw)
meses <- c("01 - Enero","02 - Febrero","03 - Marzo",
           "04 - Abril","05 - Mayo","06 - Junio",
           "07 - Julio","08 - Agosto","09 - Septiembre",
           "10 - Octubre","11 - Noviembre","12 - Diciembre")
alafecha <- as.Date(Sys.Date())-3
realizacion <- Sys.time()
Resultados <- "~/Excel"                                                                                             
setwd(Resultados)

############################################## CONSULTA ######################################################

recibos <- dbGetQuery(con, "SELECT
comprobantefechaemision,
tipocomprobantecodigo,
comprobanteprefijo,
comprobantecodigo,
comprobantetotalimporte,
comprobantesaldo,
comprobanteapertura,
comprobanteenviadores,
valorcodigo,
valorserie,
valornumero,
valorfechaemision,
valorfechavencimiento,
valorimporte
FROM comprobantes c 
LEFT JOIN valores v ON v.valortipomoventra = tipocomprobantecodigo AND v.valormovcodigoentra = comprobantecodigo
WHERE tipocomprobantecodigo = 'RECX2' and comprobantefechaemision BETWEEN '2019-01-01' AND '2020-01-30' ")



recibosVec <- duplicated(recibos[,4]) | duplicated(recibos[,4], fromLast = TRUE)

recibosconmasdeuncheque <- recibos[recibosVec, ]

recibosconmasdeuncheque$tieneapertura <- ifelse(recibosconmasdeuncheque$comprobanteapertura > 0, "Si", "No")
recibosconmasdeuncheque$estadoapertura <- ifelse(recibosconmasdeuncheque$comprobanteapertura == 1, "APERTURA", ifelse(recibosconmasdeuncheque$comprobanteapertura == 2, "AUDITADO", "CONFIRMADO"))
recibosconmasdeuncheque$comprobanteenviadores <- ifelse(recibosconmasdeuncheque$comprobanteenviadores == TRUE, "Si", "No")


  recibosconmasdeuncheque <- as.data.frame(lapply(recibosconmasdeuncheque, as.character), stringsAsFactors = FALSE)
  
  
  recibosconmasdeuncheque <- head(do.call(rbind, by(recibosconmasdeuncheque, recibosconmasdeuncheque$comprobantecodigo, rbind, "")), -1 )
  recibosconmasdeuncheque$comprobantetotalimporte <- as.numeric(recibosconmasdeuncheque$comprobantetotalimporte)
  recibosconmasdeuncheque$valorimporte <- as.numeric(recibosconmasdeuncheque$valorimporte)


  recibosconmasdeuncheque <- select(recibosconmasdeuncheque, 
                                    "Fecha de Emision" = comprobantefechaemision,
                                    "Tipo" = tipocomprobantecodigo,
                                    "Prefijo" = comprobanteprefijo,
                                    "Código" = comprobantecodigo,
                                    "Importe" = comprobantetotalimporte,
                                    "Saldo" = comprobantesaldo,
                                    "Tiene Apertura" = tieneapertura,
                                    "Estado Apertura" = estadoapertura,
                                    "Enviado Res.246" = comprobanteenviadores,
                                    "Valor Código" = valorcodigo,
                                    "Serie" = valorserie,
                                    "Número" = valornumero,
                                    "Fecha de Emisión" = valorfechaemision,
                                    "Fecha de Vencimiento" = valorfechavencimiento,
                                    "Importe" = valorimporte)

recibosconmasdeuncheque[is.na(recibosconmasdeuncheque)] <- " "



  write.csv(recibosconmasdeuncheque, "Recibos.csv")
  








