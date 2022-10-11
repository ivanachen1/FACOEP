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
#library(reader)
library(stringr)



GetArchivoParametros <- function(path_one,path_two,file){
  intento  <- is.error(try(read.xlsx(paste(path_two,file,sep = "/")),silent = F,outFile = "Error"))
  if(intento == TRUE){
    return(read.xlsx(paste(path_one,file,sep = "/")))} else {return(read.xlsx(paste(path_two,file,sep = "/")))}
}

GetParameter <- function(x = archivo_parametros,parameter){
  pw <- filter(archivo_parametros,Parametros.servidor == parameter)
  pw <- filter(pw,Usar == TRUE)
  pw <- pw$Valor
  return(pw)
}

GetFile <- function(file_name,path_one,path_two){
  intento  <- is.error(try(read.xlsx(paste(path_two,file_name,sep = "/")),silent = F,outFile = "Error"))

  if(intento == TRUE){
    return(read.xlsx(paste(path_one,file_name,sep = "/")))} else {return(read.xlsx(paste(path_two,file_name,sep = "/")))}
}

TransformFile <- function(dataframe,FilterOne){
  dataframe <- subset(dataframe, tipo == FilterOne)
  colnames(dataframe) <- c("Comprobante","tipo")
  return(dataframe)
}

GetListaINSQL<- function(archivo,Filter,print = FALSE){
  archivo <- subset(archivo, clasificacion == Filter)
  archivo <- archivo$tipo_comprobante
  archivo <- unique(archivo)
  archivo <- as.vector(archivo)
  archivo <- toString(sprintf("'%s'", archivo))
  ifelse(print == TRUE,print(archivo),return(archivo))

}

TransFormTablaApertura <- function(archivo,print = FALSE){
  archivo <- archivo$idApertura
  archivo <- unique(archivo)
  archivo <- as.vector(archivo)
  archivo <- toString(sprintf("'%s'", archivo))
  ifelse(print == TRUE,print(archivo),return(archivo))
}

dfQueryFacturas <- function(tipo_facturas,fecha_minima,fecha_maxima){
  
  anio_inicio <- year(fecha_minima)
  mes_inicio <- month(fecha_minima)
  dia_inicio <- day(fecha_minima)
  
  anio_fin <- year(fecha_maxima)
  mes_fin <- month(fecha_maxima)
  dia_fin <- day(fecha_maxima)
  
  query <- paste("SELECT",  
                 "comprobanteentidadcodigo as clienteid,",
                 "sum(comprobantetotalimporte) as importe_facturado",
                 "FROM comprobantes", 
                 "WHERE comprobantetipoentidad = 2 AND",
                 "tipocomprobantecodigo IN ({tipo_facturas}) AND",
                 "comprobantefechaemision BETWEEN",
                 "'{anio_inicio}-{mes_inicio}-{dia_inicio}' AND",
                 "'{anio_fin}-{mes_fin}-{dia_fin}'",
                 "GROUP BY comprobanteentidadcodigo",sep = " ")
  
  query <- glue(query)
  
  return(query)
  
}

QueryImputaciones <- function(tipo_facturas,tipo_imputaciones,fecha_minima_factura,fecha_maxima_factura,fecha_minima_imputacion,fecha_maxima_imputacion,nombre_imputacion){
  
  anio_inicio_factura <- year(fecha_minima_factura)
  mes_inicio_factura <- month(fecha_minima_factura)
  dia_inicio_factura <- day(fecha_minima_factura)
  
  anio_fin_factura <- year(fecha_maxima_factura)
  mes_fin_factura <- month(fecha_maxima_factura)
  dia_fin_factura <- day(fecha_maxima_factura)
  
  anio_inicio_imputacion <- year(fecha_minima_imputacion)
  mes_inicio_imputacion <- month(fecha_minima_imputacion)
  dia_inicio_imputacion <- day(fecha_minima_imputacion)
  
  anio_fin_imputacion <- year(fecha_maxima_imputacion)
  mes_fin_imputacion <- month(fecha_maxima_imputacion)
  dia_fin_imputacion <- day(fecha_maxima_imputacion)
  
  query <- paste("SELECT",  
                 "facturas.comprobanteentidadcodigo as clienteid,",
                 "SUM(imputacion.comprobanteimputacionimporte) as importe_{nombre_imputacion}",
                 
                 "FROM comprobantes as facturas",
                 
                 "LEFT JOIN", 
                 "comprobantesimputaciones as imputacion",
                 
                 "ON", 
                 "facturas.tipocomprobantecodigo = 	imputacion.tipocomprobantecodigo AND",
                 "facturas.comprobanteprefijo = 		imputacion.comprobanteprefijo AND",
                 "facturas.comprobantecodigo = 		imputacion.comprobantecodigo AND",
                 "facturas.comprobanteentidadcodigo = imputacion.comprobanteentidadcodigo",
                 
                 "WHERE facturas.comprobantetipoentidad = 2", 
                 "AND facturas.tipocomprobantecodigo IN ({tipo_facturas})",
                 "AND facturas.comprobantefechaemision",
                 "BETWEEN '{anio_inicio_factura}-{mes_inicio_factura}-{dia_inicio_factura}' AND",
                 "'{anio_fin_factura}-{mes_fin_factura}-{dia_fin_factura}'",
                 "AND imputacion.comprobanteimputaciontipo IN ({tipo_imputaciones})",
                 "AND imputacion.comprobanteimputacionfecha BETWEEN",
                 "'{anio_inicio_imputacion}-{mes_inicio_imputacion}-{dia_inicio_imputacion}'",
                 "AND '{anio_fin_imputacion}-{mes_fin_imputacion}-{dia_fin_imputacion}'",
                 
                 "GROUP BY",
                 "facturas.comprobanteentidadcodigo",sep = " ")
  
  query <- glue(query)
  
  return(query)
  
}

queryNotaDB <- function(tipo_facturas,tipo_notadb,fecha_minima_factura,fecha_maxima_factura,fecha_minima_notadb,fecha_maxima_notadb,nombre_notadb){
  
  anio_inicio_factura <- year(fecha_minima_factura)
  mes_inicio_factura <- month(fecha_minima_factura)
  dia_inicio_factura <- day(fecha_minima_factura)
  
  anio_fin_factura <- year(fecha_maxima_factura)
  mes_fin_factura <- month(fecha_maxima_factura)
  dia_fin_factura <- day(fecha_maxima_factura)
  
  anio_inicio_notadb <- year(fecha_minima_notadb)
  mes_inicio_notadb <- month(fecha_minima_notadb)
  dia_inicio_notadb <- day(fecha_minima_notadb)
  
  anio_fin_notadb <- year(fecha_maxima_notadb)
  mes_fin_notadb <- month(fecha_maxima_notadb)
  dia_fin_notadb <- day(fecha_maxima_notadb)
  
  query <- paste("SELECT", 
                 "comp.comprobanteentidadcodigo as clienteid,",
                 "sum(aux.comprobantetotalimporte) as importe_impugnado",
                 
                 "FROM comprobantes comp",
                 
                 "LEFT JOIN (",
                 "SELECT", 
                 "comprobanteentidadcodigo,",
                 "tipocomprobantecodigo,",
                 "comprobanteprefijo,",
                 "comprobantecodigo,",
                 "comprobanteasoctipo,",
                 "comprobanteasocprefijo,",
                 "comprobanteasoccodigo",
                   
                 "FROM comprobantesasociados",
                   
                 "WHERE comprobanteasoctipo IN({tipo_notadb}) ) as asoc",
                 
                 "ON", 
                 
                 "comp.comprobanteentidadcodigo = asoc.comprobanteentidadcodigo AND",
                 "comp.tipocomprobantecodigo 	  = asoc.tipocomprobantecodigo AND",
                 "comp.comprobanteprefijo 	  = asoc.comprobanteprefijo AND",
                 "comp.comprobantecodigo 		  = asoc.comprobantecodigo",
                 
                 "LEFT JOIN (",
                   "SELECT",
                   "comprobanteentidadcodigo,",
                   "tipocomprobantecodigo,",
                   "comprobanteprefijo,",
                   "comprobantecodigo,",
                   "comprobantefechaemision,",
                   "comprobantetotalimporte",
                   
                   "FROM comprobantes",
                   
                   "WHERE tipocomprobantecodigo IN ({tipo_notadb}) AND",
                   "comprobantefechaemision BETWEEN",
                 "'{anio_inicio_notadb}-{mes_inicio_notadb}-{dia_inicio_notadb}' AND",
                 "'{anio_fin_notadb}-{mes_fin_notadb}-{dia_fin_notadb}') as aux",
                 
                 "ON",
                 "asoc.comprobanteentidadcodigo = aux.comprobanteentidadcodigo AND",
                 "asoc.comprobanteasoctipo	  = aux.tipocomprobantecodigo AND",
                 "asoc.comprobanteasocprefijo 	  = aux.comprobanteprefijo AND",
                 "asoc.comprobanteasoccodigo 		  = aux.comprobantecodigo",
                 
                 "WHERE comp.comprobantetipoentidad = 2 AND",
                 "comp.tipocomprobantecodigo IN ({tipo_facturas}) AND",
                 "comp.comprobantefechaemision BETWEEN",
                 "'{anio_inicio_factura}-{mes_inicio_factura}-{dia_inicio_factura}'",
                 "AND '{anio_fin_factura}-{mes_fin_factura}-{dia_fin_factura}' AND",
                 "aux.comprobantefechaemision BETWEEN",
                 "'{anio_inicio_notadb}-{mes_inicio_notadb}-{dia_inicio_notadb}'",
                 "AND '{anio_fin_notadb}-{mes_fin_notadb}-{dia_fin_notadb}'",
                 "GROUP BY comp.comprobanteentidadcodigo",sep = " ")
  
  query <- glue(query)
  
  return(query)
}

GetMasterDate <- function(dataframe){
  dataframe$Fecha_Corte <- paste(dataframe$anio_inicio,
                                 dataframe$mes_inicio,
                                 dataframe$dia_inicio,sep = "-")
  
  dataframe$Fecha_Corte <- as.Date(dataframe$Fecha_Corte)
  
  dataframe$fecha_fin_factura <- dataframe$Fecha_Corte - 1
  dataframe$Fecha_inicio_factura <- dataframe$Fecha_Corte - 365
  dataframe$Fecha_inicio_otros <- dataframe$Fecha_inicio_factura
  dataframe$Fecha_fin_otros <- ceiling_date(dataframe$Fecha_Corte,"month")
  dataframe$Fecha_fin_otros <- ceiling_date(dataframe$Fecha_fin_otros,"month") - days(1)
  return(dataframe)
  
}
