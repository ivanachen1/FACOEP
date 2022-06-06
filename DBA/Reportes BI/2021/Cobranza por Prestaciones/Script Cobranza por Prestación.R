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
pw <- {"facoep2017"}
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "Facoep",
                 host = "10.22.0.142", port = 5432, 
                 user = "postgres", password = "serveradmin")

#con <- dbConnect(drv, dbname = "facoep",
#                 host = "localhost", port = 5432, 
#                 user = "odoo",password = pw)

pathGrupoPrestaciones <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Cobranza por Prestaciones/Grupo Prestaciones.xlsx"
PathOrigenes <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Cobranza por Prestaciones/Origen.xlsx"

GrupoPrestaciones <- read.xlsx(pathGrupoPrestaciones)
Origenes <- read.xlsx(PathOrigenes)

#setwd("E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Automatizado/data")

query <- glue(paste("SELECT",
              "pprnombre as Efector,",
              "CONCAT(os.clienteid,'-',os.clientenombre) as OS,",
              "CONCAT(c.tipocomprobantecodigo,'-',c.comprobanteprefijo,'-',c.comprobantecodigo) as recibo,",
              "c.comprobantefechaemision as emision,",
              "cc.comprobantecrgnro as comprobantecrgnrocrg,",
              "cd.comprobantecrgnro as comprobantecrgdetnrocrg,",
              "comprobantecrgdetpractica as Prestacion,",
              "comprobantecrgdetimportefactur as ImportePrestacion,",
              "c.comprobanteccosto as CentroCosto,",
              "c.comprobanteorigen as origen",
              
              
              "FROM comprobantes c",
              
              "LEFT JOIN", 
              "(SELECT tipocomprobantecodigo,",
                      "comprobanteprefijo,",
                      "comprobantecodigo,",
                      "comprobantepprid,",
                      "comprobantecrgnro",
               "FROM comprobantecrg) as cc",
               
               "ON c.tipocomprobantecodigo = cc.tipocomprobantecodigo AND",
               "c.comprobanteprefijo = cc.comprobanteprefijo AND",
               "c.comprobantecodigo = cc.comprobantecodigo",
              
              "LEFT JOIN comprobantecrgdet cd", 
              
              "ON cd.tipocomprobantecodigo = cc.tipocomprobantecodigo AND",
              "cd.comprobanteprefijo = cc.comprobanteprefijo AND",
              "cd.comprobantecodigo = cc.comprobantecodigo AND",
              "cd.comprobantecrgnro = cc.comprobantecrgnro AND",
              "cd.comprobantepprid = cc.comprobantepprid",
              
              
              "LEFT JOIN", 
              "clientes os ON os.clienteid = c.comprobanteentidadcodigo",
              
              "LEFT JOIN", 
              "proveedorprestador pp ON pp.pprid = cc.comprobantepprid",
              
              "WHERE c.tipocomprobantecodigo IN ('RECX2') AND",
              "c.comprobantefechaemision > '2017-01-01' AND",
              "c.comprobanteentidadcodigo <> -1"))


data <- dbGetQuery(con,query)

data$recibo <- gsub(" ","",data$recibo)
data$prestacion <- ifelse(data$prestacion == "                    ",
                          "Sin Definir",
                          ifelse(is.na(data$prestacion),"Sin Definir",data$prestacion))

data$prestacion <- gsub(" ","",data$prestacion)
data$efector <- gsub(" ","",data$efector)


data$TipoApertura <- ifelse(is.na(data$comprobantecrgnrocrg) & is.na(data$comprobantecrgnrocrg),
                            "Sin Apertura",
                            ifelse(!is.na(data$comprobantecrgnrocrg) & is.na(data$comprobantecrgdetnrocrg),
                                   "Apertura Cabecera",
                                   "Apertura Detalle"))

RecibosConSinApertura <- unique(select(data,"Recibo" = recibo,
                                             "TipoApertura" = TipoApertura,
                                             "EmsionRecibo" = emision,
                                             "ObraSocial" = os,
                                             "Origen" = origen))

RecibosConSinApertura <- left_join(RecibosConSinApertura,Origenes,by = c('Origen' = 'Sigla'))

RecibosConSinApertura$ObraSocial <- ifelse(is.na(RecibosConSinApertura$ObraSocial),
                                           "Sin Asignar",
                                           RecibosConSinApertura$ObraSocial)

data$cantidad <- 1


data$emision <- as.Date(data$emision)

data$comprobantecrgnro <- as.character(data$comprobantecrgnro)

data$comprobantecrgnro <- ifelse(is.na(data$comprobantecrgnro),"Sin Asignar SIF",data$comprobantecrgnro)

data$prestacion <- ifelse(is.na(data$prestacion),"Sin Asignar SIF",data$prestacion)

data$importeprestacion <- ifelse(is.na(data$importeprestacion),0,data$importeprestacion)

data$efector <- ifelse(is.na(data$efector),"Sin Asignar SIF",data$efector)

data$os <- ifelse(is.na(data$os),"Sin Asignar SIF",data$os)

data <- aggregate(.~efector+os+recibo+emision+comprobantecrgnro+prestacion+importeprestacion+centrocosto+TipoApertura+origen,
          data, sum)

data <- left_join(data,Origenes,by = c('origen' = 'Sigla'))

data$idRow <- paste(data$efector,
                    data$os,data$recibo,
                    data$emision,
                    data$comprobantecrgnro,
                    data$prestacion,
                    data$importeprestacion,
                    data$centrocosto,
                    data$TipoApertura,
                    data$origen,
                    data$comprobantecrgnrocrg,
                    data$cantidad,
                    data$Name,sep = "-")

CentroCostos <- dbGetQuery(conn = con,"SELECT * FROM centrocostos")

PrestacionesUnicas <- data.frame(select(data,"prestacion" = prestacion))

PrestacionesUnicas$prestacion <- toupper(PrestacionesUnicas$prestacion) 

PrestacionesUnicas <- unique(PrestacionesUnicas)
  
ft2 <- data.frame(table(PrestacionesUnicas$prestacion))


lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
     
