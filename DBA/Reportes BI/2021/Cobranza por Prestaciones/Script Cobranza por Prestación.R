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


#setwd("E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Automatizado/data")

#fecha_actual <- today("UTC")


fecha_actual <- as.Date("2022-02-28")

#print(fecha_actual)
dia_actual <- day(fecha_actual)
mes_actual <- month(fecha_actual)
anio_actual <- year(fecha_actual)


primer_dia_mes <- 1

query <- glue("SELECT
              pprnombre as Efector,
              CAST(os.clienteid AS TEXT) || ' - ' || CAST(clientenombre AS TEXT) as OS,
              CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as recibo,
              c.comprobantefechaemision as emision,
              cd.comprobantecrgnro,
              comprobantecrgdetpractica as Prestacion,
              comprobantecrgdetimportefactur as ImportePrestacion,
              c.comprobanteccosto as CentroCosto
              
              
              FROM 
              comprobantes c
              
              LEFT JOIN 
              comprobantecrgdet cd ON cd.comprobantetipoentidad = c.comprobantetipoentidad and
              cd.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
              cd.tipocomprobantecodigo = c.tipocomprobantecodigo and
              cd.comprobanteprefijo = c.comprobanteprefijo and
              cd.comprobantecodigo = c.comprobantecodigo
              
              LEFT JOIN 
              clientes os ON os.clienteid = c.comprobanteentidadcodigo
              
              LEFT JOIN 
              proveedorprestador pp ON pp.pprid = cd.comprobantepprid
              
              WHERE c.tipocomprobantecodigo IN ('RECX2') and c.comprobantefechaemision > '2017-01-01'")


print(query)
data <- dbGetQuery(con,query)

data$PoseeCrg <- ifelse(is.na(data$comprobantecrgnro),"No","Si")
data$TipoApertura <- ifelse(data$PoseeCrg == "No",
                            "Sin Apertura",
                            ifelse(!is.na(data$comprobantecrgnro) && is.na(data$prestacion),
                                   "Apertura Cabecera",
                                   "Apertura Detalle"))

RecibosConSinApertura <- unique(select(data,"Recibo" = recibo,
                                             "TipoApertura" = TipoApertura,
                                             "EmsionRecibo" = emision))

ft <- data.frame(table(RecibosConSinApertura$TipoApertura))


data$cantidad <- ifelse(data$TipoApertura == "Apertura Detalle",1,0)


#view(data)

data$emision <- as.Date(data$emision)

max_fecha_emision <- max(data$emision)
#view(emision)

#nombre_archivo <- glue("Facturado_{mes_actual}_{anio_actual}.csv")

#write.csv(data,nombre_archivo)

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})



