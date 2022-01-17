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
drv <- dbDriver("PostgreSQL")

alafecha <- as.Date(Sys.Date())
realizacion <- alafecha



########################################### CREDENCIALES SERVER ########################################################

workdirectory_one <- "C:/Users/User/Desktop/FACOEP/DBA/Reportes BI/2021/Cuenta Corriente/Cuenta Corriente 3"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranzas/Versión 7"

source("C:/Users/User/Desktop/FACOEP/DBA/Reportes BI/2021/Cuenta Corriente/Script_Historico_Saldos_Logica.r")

archivo_parametros <- GetArchivoParametros()

pw <- GetPassword()

user <- GetUser()

host <- GetHost() 

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep",
                 host = host, port = 5432, 
                 user = user, password = pw)

postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")


########################################### ETL ##########################################################

query <- GetQueryComprobantes()

tabla_parametros_comprobantes <- GetFile("tabla_parametros_comprobantes.xlsx")
tabla_parametros_comprobantes <- filter(tabla_parametros_comprobantes,tipo %in% c("factura","notadebito"))

ooss_desestimar <- GetFile("obras_sociales_desestimar.xlsx")

tabla_comprobantes <- dbGetQuery(con,query)

tabla_comprobantes <- CleanTablaComprobantes(tabla_comprobantes = tabla_comprobantes, tabla_parametros_comprobantes = tabla_parametros_comprobantes)

query_historial <- "SELECT * FROM comprobanteshistorial" 

comprobantes_historial <- dbGetQuery(con,query_historial)

comprobantes_historial <- CleanTablaComprobantesHistorial(comprobantes_historial = comprobantes_historial)

tabla_comprobantes <- left_join(tabla_comprobantes,comprobantes_historial,by = c("comprobante" = "comprobante"))

tabla_comprobantes$tipo_comprobante <- NULL
tabla_comprobantes$tipo <- NULL

rm(comprobantes_historial)

tabla_comprobantes$Fecha_Entrega <- replace_na(tabla_comprobantes$Fecha_Entrega,replace = "1980-01-01")                                

tabla_comprobantes$Fecha_Entrega <- as.Date(tabla_comprobantes$Fecha_Entrega)

tabla_comprobantes$FkCentroCostos <- paste(tabla_comprobantes$comprobanteccosto,tabla_comprobantes$comprobantesccosto,sep = "-")

condiciones_comerciales <- GetFile("condiciones_pago_cobranzas.xlsx")

tabla_comprobantes <- left_join(tabla_comprobantes,condiciones_comerciales,by = c("FkCentroCostos" = "FkCentroCostos"))

tabla_comprobantes$Plazo <- replace_na(tabla_comprobantes$Plazo,replace = 60)

tabla_comprobantes$Vencimiento <- tabla_comprobantes$Plazo + tabla_comprobantes$Fecha_Entrega

query_imputaciones <- "SELECT	* FROM comprobantesimputaciones" 

tabla_imputaciones <- dbGetQuery(con,query_imputaciones)

tabla_imputaciones <- CleanTablaImputaciones(tabla_imputaciones = tabla_imputaciones)


tabla_comprobantes <- left_join(tabla_comprobantes,tabla_imputaciones,by = c("comprobante" = "comprobante"))

tabla_comprobantes$tipocomprobantecodigo.y <- NULL

rm(tabla_imputaciones)

tabla_comprobantes <- LastClean(tabla_comprobantes = tabla_comprobantes)

# Faltaria calcular si el comprobante fue o no entregado y si la deuda es corriente o vencida en base a 
# los criterios de power bi en la V5

tabla_comprobantes$entregado <- ifelse(tabla_comprobantes$Fecha_Entrega == date("1980-01-01"),"Fc No Entregada","Fc Entregada")

tabla_comprobantes$fecha_actual <- as.Date(realizacion)

tabla_comprobantes$EstatusCuentaCorriente <- GetStatusCuentaCorriente(tabla_comprobantes)

tabla_medicion <- select(tabla_comprobantes,
                         "os" = os,
                         "fecha_emision" = fecha_emision,
                         "comprobante" = comprobante,
                         "ImporteComprobante" = comprobantetotalimporte,
                         "FkCentroCostos" = FkCentroCostos,
                         "FechaDeImputacion" = FechaDeImputacion,
                         "ImporteImputacion" = ImporteImputacion,
                         "TipoDeudaVencida" = TipoDeudaVencida,
                         "EstatusCuentaCorriente" = EstatusCuentaCorriente)

#TENGO QUE QUITAR EL IMPORTE DUPLICADO DEL COMPROBANTE PARA LUEGO HACER LOS ACUMULADOS


tabla_medicion$ImporteComprobante <- ifelse(duplicated(tabla_medicion$comprobante), 0, tabla_medicion$ImporteComprobante)


tabla_medicion$ImporteComprobanteAcumulado <- ave(tabla_medicion$ImporteComprobante, tabla_medicion$os, FUN=cumsum)


tabla_medicion$ImputacionAcumulado <- ave(tabla_medicion$ImporteImputacion, tabla_medicion$os, FUN=cumsum)




rm(archivo_parametros,condiciones_comerciales,tabla_parametros_comprobantes)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})



setwd("C:/Users/User/Desktop/FACOEP/DBA/Reportes BI/2021/Cuenta Corriente/Cuenta Corriente 3")
write.xlsx(tabla_comprobantes,"DataSetCC.xlsx")



