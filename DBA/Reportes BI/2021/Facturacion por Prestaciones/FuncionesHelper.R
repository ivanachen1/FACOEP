# funciones Helper

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

GetParameter <- function(x = archivo_parametros,parameter){
  parameter <- filter(archivo_parametros,Parametros.servidor == parameter)
  parameter <- filter(parameter,Usar == TRUE)
  parameter <- parameter$Valor
  return(parameter)
}

GetQuery <- function(fecha_actual,fecha_anterior){
  
  dia_actual <- day(fecha_actual)
  mes_actual <- month(fecha_actual)
  anio_actual <- year(fecha_actual)
  
  dia_anterior <- day(fecha_anterior)
  mes_anterior <- month(fecha_anterior)
  anio_anterior <- year(fecha_anterior)
  
  query <- paste("SELECT",
                 "pprnombre as Efector,",
                 "CAST(os.clienteid AS TEXT) || ' - ' || CAST(clientenombre AS TEXT) as OS,",
                 "CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as factura,",
                 "c.comprobantefechaemision as emision,",
                 "comprobantecrgdetpractica as Prestacion,",
                 "comprobantecrgdetimportefactur as ImportePrestacion,",
                 "c.comprobanteccosto as CentroCosto",
                 "FROM", 
                 "comprobantes c",
                 "LEFT JOIN", 
                 "comprobantecrgdet cd ON cd.comprobantetipoentidad = c.comprobantetipoentidad and",
                 "cd.comprobanteentidadcodigo = c.comprobanteentidadcodigo and",
                 "cd.tipocomprobantecodigo = c.tipocomprobantecodigo and",
                 "cd.comprobanteprefijo = c.comprobanteprefijo and",
                 "cd.comprobantecodigo = c.comprobantecodigo",
                 "LEFT JOIN", 
                 "clientes os ON os.clienteid = c.comprobanteentidadcodigo",
                 "LEFT JOIN", 
                 "proveedorprestador pp ON pp.pprid = cd.comprobantepprid",
                 "WHERE c.tipocomprobantecodigo IN ('FACA2','FACB2', 'FAECA', 'FAECB')", 
                 "AND c.comprobantefechaemision BETWEEN '{anio_anterior}-{mes_anterior}-{dia_anterior}' AND",
                 "'{anio_actual}-{mes_actual}-{dia_actual}'")
  
  query <- glue(query)
  
  nombre_archivo <- glue(paste("Facturado_{mes_actual}_{anio_actual}.csv"))
                         
  return(list(query,nombre_archivo))}



# tengo que crear una funcion que me haga una lista de archivos en R y de ahi identificar cuales me faltan generar para el mes anterior.