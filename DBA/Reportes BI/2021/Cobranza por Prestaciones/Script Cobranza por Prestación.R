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

pw <- {"serveradmin"} 
#pw <- {"facoep2017"}
drv <- dbDriver("PostgreSQL")
#con <- dbConnect(drv, dbname = "facoep",
#                 host = "172.31.24.12", port = 5432, 
#                 user = "postgres", password = pw)

con <- dbConnect(drv, dbname = "Facoep",
                 host = "10.22.0.142", port = 5432, 
                 user = "postgres",password = pw)

pathGrupoPrestaciones <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Cobranza por Prestaciones/Grupo Prestaciones.xlsx"


GrupoPrestaciones <- read.xlsx(pathGrupoPrestaciones)


#setwd("E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Automatizado/data")


query <- glue("SELECT
              pprnombre as Efector,
              CAST(os.clienteid AS TEXT) || ' - ' || CAST(clientenombre AS TEXT) as OS,
              CONCAT(c.tipocomprobantecodigo,'-',c.comprobanteprefijo,'-',c.comprobantecodigo) as recibo,
              c.comprobantefechaemision as emision,
              cc.comprobantecrgnro as comprobantecrgnrocrg,
              cd.comprobantecrgnro as comprobantecrgdetnrocrg,
              comprobantecrgdetpractica as Prestacion,
              comprobantecrgdetimportefactur as ImportePrestacion,
              c.comprobanteccosto as CentroCosto
              
              
              FROM 
              comprobantes c
              
              LEFT JOIN 
              (SELECT tipocomprobantecodigo,
                      comprobanteprefijo,
                      comprobantecodigo,
                      comprobantepprid,
                      comprobantecrgnro
               FROM comprobantecrg) as cc
               
               ON 
               
               c.tipocomprobantecodigo = cc.tipocomprobantecodigo and
               c.comprobanteprefijo = cc.comprobanteprefijo and
               c.comprobantecodigo = cc.comprobantecodigo
              
              LEFT JOIN 
              comprobantecrgdet cd 
              
              ON 

              cd.tipocomprobantecodigo = cc.tipocomprobantecodigo and
              cd.comprobanteprefijo = cc.comprobanteprefijo and
              cd.comprobantecodigo = cc.comprobantecodigo and
              cd.comprobantecrgnro = cc.comprobantecrgnro and
              cd.comprobantepprid = cc.comprobantepprid
              
              
              LEFT JOIN 
              clientes os ON os.clienteid = c.comprobanteentidadcodigo
              
              LEFT JOIN 
              proveedorprestador pp ON pp.pprid = cc.comprobantepprid
              
              WHERE c.tipocomprobantecodigo IN ('RECX2') and c.comprobanteentidadcodigo <> -1 AND c.comprobantefechaemision > '2017-01-01'")


data <- dbGetQuery(con,query)

data$recibo <- gsub(" ","",data$recibo)


data$TipoApertura <- ifelse(is.na(data$comprobantecrgnrocrg) & is.na(data$comprobantecrgdetnrocrg),
                            "Sin Apertura",
                            ifelse(!is.na(data$comprobantecrgnrocrg) & is.na(data$comprobantecrgdetnrocrg),
                                   "Apertura Cabecera",
                                   "Apertura Detalle"))

RecibosConSinApertura <- unique(select(data,"Recibo" = recibo,
                                             "TipoApertura" = TipoApertura,
                                             "EmsionRecibo" = emision,
                                             "ObraSocial" = os))


RecibosConSinApertura$ObraSocial <- ifelse(is.na(RecibosConSinApertura$ObraSocial),"Sin Asignar",RecibosConSinApertura$ObraSocial)

data$cantidad <- 1


data$emision <- as.Date(data$emision)

data$comprobantecrgnro <- as.character(data$comprobantecrgnro)

data$comprobantecrgnro <- ifelse(is.na(data$comprobantecrgnro),"Sin Asignar SIF",data$comprobantecrgnro)

data$prestacion <- ifelse(is.na(data$prestacion),"Sin Asignar SIF",data$prestacion)

data$importeprestacion <- ifelse(is.na(data$importeprestacion),0,data$importeprestacion)

data$efector <- ifelse(is.na(data$efector),"Sin Asignar SIF",data$efector)

data$os <- ifelse(is.na(data$os),"Sin Asignar SIF",data$os)


data <- aggregate(.~efector+os+recibo+emision+comprobantecrgnro+prestacion+importeprestacion+centrocosto+TipoApertura,
          data, sum)

CentroCostos <- dbGetQuery(conn = con,"SELECT * FROM centrocostos")


lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

ft <- data.frame(table(RecibosConSinApertura$TipoApertura))

