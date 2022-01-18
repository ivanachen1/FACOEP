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

#pw <- {"odoo"} 
pw <- {"facoep2017"}
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep",
                 host = "172.31.24.12", port = 5432, 
                 user = "postgres", password = pw)

#con <- dbConnect(drv, dbname = "facoep",
#                 host = "localhost", port = 5432, 
#                 user = "odoo",password = pw)


setwd("E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Automatizado/data")

fecha_actual <- today("UTC")


#fecha_actual <- as.Date("2021-12-31")

#print(fecha_actual)
dia_actual <- day(fecha_actual)
mes_actual <- month(fecha_actual)
anio_actual <- year(fecha_actual)


primer_dia_mes <- 1

query <- glue("SELECT
              pprnombre as Efector,
              CAST(os.clienteid AS TEXT) || ' - ' || CAST(clientenombre AS TEXT) as OS,
              CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as factura,
              c.comprobantefechaemision as emision,
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
              
              WHERE c.tipocomprobantecodigo IN ('FACA2','FACB2', 'FAECA', 'FAECB') and c.comprobantefechaemision BETWEEN '{anio_actual}-{mes_actual}-01' and '{anio_actual}-{mes_actual}-{dia_actual}'")


print(query)
data <- dbGetQuery(con,query)

data$cantidad <- 1

#view(data)

data$emision <- as.Date(data$emision)

max_fecha_emision <- max(data$emision)
#view(emision)

nombre_archivo <- glue("Facturado_{mes_actual}_{anio_actual}.csv")

write.csv(data,nombre_archivo)

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})



