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
library(lubridate)
library("RPostgreSQL")
library(gsubfn)
library(glue)
library(dplyr)


pw <- {"odoo"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep",
                 host = "localhost", port = 5432, 
                 user = "odoo", password = pw)


postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")


################################# QUERY ########################################################################

query_comprobantes_asociados <- ("SELECT	* FROM comprobantesasociados") 


query_comprobantes_asociados <- dbGetQuery(con,query_comprobantes_asociados)

query_comprobantes_asociados$tipocomprobantecodigo <- gsub(" ","",query_comprobantes_asociados$tipocomprobantecodigo)

query_comprobantes_asociados$nro_comprobante <- paste(query_comprobantes_asociados$tipocomprobantecodigo,query_comprobantes_asociados$comprobanteprefijo,query_comprobantes_asociados$comprobantecodigo,sep = "-")

query_comprobantes_asociados$comprobanteprefijo <- NULL
query_comprobantes_asociados$comprobantecodigo <- NULL

query_comprobantes_asociados$comprobanteasoctipo <- gsub(" ","",query_comprobantes_asociados$comprobanteasoctipo)

query_comprobantes_asociados$ComprobanteAsociadoNro <- paste(query_comprobantes_asociados$comprobanteasoctipo,query_comprobantes_asociados$comprobanteasocprefijo,query_comprobantes_asociados$comprobanteasoccodigo,sep = "-")

query_comprobantes_asociados$comprobanteasocprefijo <- NULL
query_comprobantes_asociados$comprobanteasoccodigo <- NULL
query_comprobantes_asociados$comprobanteasocobs <- NULL
query_comprobantes_asociados$tipocomprobantecodigo <- NULL


query_comprobantes <- "SELECT	
                    	 c.comprobanteentidadcodigo,
                       c.tipocomprobantecodigo,
                       os.obsocialescodigo,
                       os.obsocialessigla,
                       c.comprobanteprefijo,
                       c.comprobantecodigo,
                       c.comprobanteccosto,
                       c.comprobantefechaemision,
                       c.comprobantecovid AS covid,
                       c.comprobantetotalimporte,
                       CASE WHEN (c.comprobantedetalle LIKE '%ANULA%') THEN 'Si' ELSE 'No' END AS anulado
                      
                       FROM comprobantes c
                       LEFT JOIN obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo" 

tabla_comprobantes <- dbGetQuery(con,query_comprobantes)

tabla_comprobantes$tipocomprobantecodigo <- gsub(" ","",tabla_comprobantes$tipocomprobantecodigo)
  
tabla_comprobantes$nro_comprobante <- paste(tabla_comprobantes$tipocomprobantecodigo,tabla_comprobantes$comprobanteprefijo,tabla_comprobantes$comprobantecodigo,sep = "-")

tabla_comprobantes$Financiador <- paste(tabla_comprobantes$comprobanteentidadcodigo,tabla_comprobantes$obsocialessigla,sep = "-")

tabla_comprobantes$comprobanteprefijo <- NULL
#tabla_comprobantes$comprobantecodigo <- NULL

tabla_comprobantes$comprobanteentidadcodigo <- NULL
tabla_comprobantes$obsocialessigla <- NULL
#tabla_comprobantes$obsocialescodigo <- NULL

query_comprobantes_asociados <- left_join(x = query_comprobantes_asociados,y = tabla_comprobantes,by = c("ComprobanteAsociadoNro" = "nro_comprobante"))

query_comprobantes_asociados_copia <- select(query_comprobantes_asociados,
                                      "Financiador" = Financiador,
                                      "nro_comprobante" = nro_comprobante,
                                      "Nro_Comprobante_Asociado" = ComprobanteAsociadoNro,
                                      "Tipo_Comprobante_Asociado" = comprobanteasoctipo,
                                      "Fecha_Emision_Comprobante_Asociado" = comprobantefechaemision,
                                      "Importe_Comprobante_Asociado" = comprobantetotalimporte,
                                      "Fecha_Emision_Comprobante_Asociado" = comprobantefechaemision)


tabla_detalle <- left_join(x = tabla_comprobantes,y = query_comprobantes_asociados_copia,by = c("nro_comprobante" = "nro_comprobante"))

tabla_detalle <- select(tabla_detalle,
                        "Financiador" = Financiador.x,
                        "Codigo Obra Social" = obsocialescodigo,
                        "Tipo Comprobante" = tipocomprobantecodigo,
                        "Codigo Centro Costo" = comprobanteccosto,
                        "Fecha Emisión Comprobante" = comprobantefechaemision,
                        "Covid" = covid,
                        "Importe Comprobante" = comprobantetotalimporte,
                        "Anulado" = anulado,
                        "Nro Comprobante" = nro_comprobante,
                        "Nro Comprobante Asociado" = Nro_Comprobante_Asociado,
                        "Tipo Comprobante Asociado" = Tipo_Comprobante_Asociado,
                        "Fecha Emision Comprobante Asociado" = Fecha_Emision_Comprobante_Asociado,
                        "Importe Comprobante Asociado" = Importe_Comprobante_Asociado,
                        "Codigo Comprobante" = comprobantecodigo)
                        
                        
tabla_detalle$`Importe Comprobante Asociado`<- ifelse(is.na(tabla_detalle$`Importe Comprobante Asociado`),0,tabla_detalle$`Importe Comprobante Asociado`)

tabla_detalle$`Tipo Comprobante Asociado`<- ifelse(is.na(tabla_detalle$`Tipo Comprobante Asociado`),"NO TIENE",tabla_detalle$`Tipo Comprobante Asociado`)

tabla_detalle$`Nro Comprobante Asociado`<- ifelse(is.na(tabla_detalle$`Nro Comprobante Asociado`),"NO TIENE",tabla_detalle$`Nro Comprobante Asociado`)

parametros <- read.xlsx("C:/Users/iachenbach/Desktop/FACOEP/DBA/Reportes BI/2021/Cobranzas/Version 2/archivos_V4/tabla_parametros_comprobantes_SolapaDetalle.xlsx")

tabla_detalle <- left_join(x = tabla_detalle,y = parametros,by = c("Tipo Comprobante" = "Comprobante"))

tabla_detalle$tipo_agrupado_comprobante <- tabla_detalle$tipo

tabla_detalle$tipo <- NULL

tabla_detalle <- left_join(x = tabla_detalle,y = parametros,by = c("Tipo Comprobante Asociado" = "Comprobante"))

tabla_detalle$tipo_agrupado_comprobante_asociado <- tabla_detalle$tipo

tabla_detalle$tipo <- NULL

tabla_solapa_detalle <- tabla_detalle



rm(query_comprobante_asociados,tabla_comprobantes,query_comprobantes_asociados_copia,query_comprobante_asociados,tabla_detalle,parametros)


