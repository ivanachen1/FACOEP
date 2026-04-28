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


GetTablaComprobantes <- function(){x = "SELECT	
	CAST(os.clienteid AS TEXT) || ' - ' || CAST(os.clientenombre AS TEXT) as OS,
  os.clientecuit,
  CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(comprobanteprefijo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as Comprobante,
  c.comprobantecodigo,
  c.comprobantefechaemision as fecha_Emision,
  c.tipocomprobantecodigo,
  c.comprobantetotalimporte,
 
  CASE WHEN c.comprobanteintimacion = TRUE THEN 'Intimado' ELSE 'No Intimado' END AS Intimacion,
  CASE WHEN c.comprobantemandatario = TRUE THEN 'Mandatario' ELSE 'No Mandatario' END AS Mandatario,
  c.comprobanteccosto,
  c.comprobantesccosto

  FROM comprobantes c
  LEFT JOIN clientes os ON os.clienteid = c.comprobanteentidadcodigo"
    return(x)
  }

CleanTablaComprobantes <- function(tabla_comprobantes){
  tabla_comprobantes$tipocomprobantecodigo <- gsub(" ","",tabla_comprobantes$tipocomprobantecodigo)
  tabla_comprobantes$NroComprobante <- paste(tabla_comprobantes$tipocomprobantecodigo,tabla_comprobantes$comprobanteprefijo,tabla_comprobantes$comprobantecodigo,sep = "-")
  tabla_comprobantes <- filter(tabla_comprobantes,tipo != is.na(tipo))
  tabla_comprobantes$comprobantecodigo <- NULL
  tabla_comprobantes$comprobanteprefijo <- NULL
  
  
  return(tabla_comprobantes)
  
  

  
  
  
  
  
  