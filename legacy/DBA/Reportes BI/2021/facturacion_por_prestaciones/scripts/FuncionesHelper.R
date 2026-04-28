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
library(lubridate)
library("RPostgreSQL")
library(BBmisc)
library(glue)
library(readxl)
#library(reader)
library(stringr)



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
                 "cd.comprobantepprid as EfectorCodigo,",
                 "c.comprobanteentidadcodigo as CodigoOOSS,",
                 "CONCAT(c.tipocomprobantecodigo,'-',c.comprobanteprefijo,'-',c.comprobantecodigo) as factura,",
                 "c.comprobantefechaemision as emision,",
                 "comprobantecrgdetpractica as Prestacion,",
                 "comprobantecrgdetimportefactur as ImportePrestacion,",
                 "c.comprobanteccosto as CentroCosto",
                 "FROM",
                 "comprobantes c",
                 "LEFT JOIN",
                 "comprobantecrgdet cd",
                 "ON",
                 "cd.comprobantetipoentidad = c.comprobantetipoentidad and",
                 "cd.comprobanteentidadcodigo = c.comprobanteentidadcodigo and",
                 "cd.tipocomprobantecodigo = c.tipocomprobantecodigo and",
                 "cd.comprobanteprefijo = c.comprobanteprefijo and",
                 "cd.comprobantecodigo = c.comprobantecodigo",
                 "WHERE c.tipocomprobantecodigo IN ('FACA2','FACB2', 'FAECA', 'FAECB')",
                 "AND c.comprobantefechaemision BETWEEN '{anio_anterior}-{mes_anterior}-{dia_anterior}' AND",
                 "'{anio_actual}-{mes_actual}-{dia_actual}'")

  query <- glue(query)

  return(query)}

GetFile <- function(file_name,path_one,path_two){
  intento  <- is.error(try(read.xlsx(paste(path_two,file_name,sep = "/")),silent = F,outFile = "Error"))

  if(intento == TRUE){
    return(read.xlsx(paste(path_one,file_name,sep = "/")))} else {return(read.xlsx(paste(path_two,file_name,sep = "/")))}
}



# tengo que crear una funcion que me haga una lista de archivos en R y de ahi identificar cuales me faltan generar para el mes anterior.
