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


GetArchivoParametros <- function(path_one,path_two,file){
  x = "parametros_servidor.xlsx"
  path_one <- workdirectory_one
  path_two <- workdirectory_two
  intento  <- is.error(try(read.xlsx(paste(path_two,file,sep = "/")),silent = F,outFile = "Error"))
  
  
  if(intento == TRUE){
    return(read.xlsx(paste(path_one,file,sep = "/")))} else {return(read.xlsx(paste(path_two,file,sep = "/")))}
}

GetParameter <- function(x = archivo_parametros,parameter){
  pw <- filter(archivo_parametros,Parametros.servidor == parameter)
  pw <- filter(pw,Usar == TRUE)
  pw <- pw$Valor
  return(pw)}



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

GetListaINSQL<- function(archivo,print = FALSE){
  archivo <- archivo$Comprobante
  archivo <- unique(archivo)
  archivo <- as.vector(archivo)
  archivo <- toString(sprintf("'%s'", archivo))
  ifelse(print == TRUE,print(archivo),return(archivo))
  
}
  

CleanTablaComprobantes <- function(tabla_comprobantes){
  tabla_comprobantes$tipocomprobantecodigo <- gsub(" ","",tabla_comprobantes$tipocomprobantecodigo)
  tabla_comprobantes$NroComprobante <- paste(tabla_comprobantes$tipocomprobantecodigo,
                                             tabla_comprobantes$comprobanteprefijo,
                                             tabla_comprobantes$comprobantecodigo,sep = "-")
  
  tabla_comprobantes$comprobanteprefijo <- NULL
  tabla_comprobantes$comprobantecodigo <- NULL
  
  #tabla_comprobantes<- filter(tabla_comprobantes,os != is.na(os))
  tabla_comprobantes<- unique(tabla_comprobantes)
  
  return(tabla_comprobantes)
}

QueryNc <- glue(paste("SELECT",
                      "CONCAT(os.clienteid,'-',os.clientenombre) as OS,",
                      "CONCAT(asoc.tipocomprobantecodigo,'-',asoc.comprobanteprefijo,'-',asoc.comprobantecodigo) as Factura,",
                      "CONCAT(asoc.comprobanteimputaciontipo,'-',asoc.comprobanteimputacionprefijo,'-',asoc.comprobanteimputacioncodigo) as notacredito,",
                      "crg.comprobantecrgnro as nrocrgnotacredito,",
                      "crg.comprobantepprid as ppridnotacredito,",
                      "crg.comprobantecrgimportetotaldeta as importecrgnc",
                      
                      "FROM comprobantes c",
                      
                      "LEFT JOIN comprobantesimputaciones asoc ON",
                      "c.sucursalcodigo = asoc.sucursalcodigo and",
                      "c.comprobantetipoentidad = asoc.comprobantetipoentidad and",
                      "c.comprobanteentidadcodigo = asoc.comprobanteentidadcodigo and",
                      "c.tipocomprobantecodigo = asoc.tipocomprobantecodigo and",
                      "c.comprobanteprefijo = asoc.comprobanteprefijo and",
                      "c.comprobantecodigo = asoc.comprobantecodigo",
                      
                      "LEFT JOIN comprobantecrg crg ON",
                      "crg.empcod = asoc.empcod and",
                      "crg.tipocomprobantecodigo = asoc.comprobanteimputaciontipo and",
                      "crg.comprobanteprefijo = asoc.comprobanteimputacionprefijo and",
                      "crg.comprobantecodigo = asoc.comprobanteimputacioncodigo and",
                      "crg.sucursalcodigo = asoc.sucursalcodigo and",
                      "crg.comprobantetipoentidad = asoc.comprobantetipoentidad and",
                      "crg.comprobanteentidadcodigo = asoc.comprobanteentidadcodigo",
                      
                      "LEFT JOIN clientes os ON os.clienteid = c.comprobanteentidadcodigo",
                      "LEFT JOIN proveedorprestador pp ON pp.pprid = crg.comprobantepprid",
                      
                      "WHERE c.tipocomprobantecodigo IN ({FacturasQuery}) AND",
                      "c.comprobantefechaemision > '2017-12-31' AND",
                      "asoc.comprobanteimputaciontipo IN ({NotasDebito}) AND",
                      "c.comprobantetipoentidad = 2"),sep = "\n")

QueryFc <- glue(paste("SELECT",
                      "c.comprobanteccosto as CentroCosto,",
                      "c.comprobantesccosto as SubCentroCosto,",
                      "c.comprobantesaldo as saldo,",
                      "CASE WHEN c.comprobantedetalle LIKE '%ANULADO%' THEN 'SI' ELSE 'NO' END AS Anulada,",
                      "CASE WHEN c.comprobantedetalle LIKE '%intereses%' THEN 'SI'",
                      "WHEN c.comprobantedetalle LIKE '%Intereses%' THEN 'SI' ELSE 'NO' END AS Interes,",
                      "pprnombre,",
                      "CONCAT(os.clienteid,'-',os.clientenombre) as OS,",
                      "CONCAT(c.tipocomprobantecodigo,'-',c.comprobanteprefijo,'-',c.comprobantecodigo) as Factura,",
                      "crg.comprobantecrgnro as nrocrgfactura,",
                      "crg.comprobantepprid as ppridfactura,",
                      "c.comprobantefechaemision as EmisionFactura,",
                      "crg.comprobantecrgfchemision as crgfchemision,",
                      "crg.comprobantecrgimportetotaldeta as importecrg",
                      
                      "FROM comprobantes c",
                      
                      "LEFT JOIN comprobantecrg crg ON",
                      "crg.empcod = c.empcod and",
                      "crg.tipocomprobantecodigo = c.tipocomprobantecodigo and",
                      "crg.comprobanteprefijo = c.comprobanteprefijo and",
                      "crg.comprobantecodigo = c.comprobantecodigo and",
                      "crg.sucursalcodigo = c.sucursalcodigo and",
                      "crg.comprobantetipoentidad = c.comprobantetipoentidad and",
                      "crg.comprobanteentidadcodigo = c.comprobanteentidadcodigo",
                      
                      
                      "LEFT JOIN clientes os ON os.clienteid = c.comprobanteentidadcodigo",
                      "LEFT JOIN proveedorprestador pp ON pp.pprid = crg.comprobantepprid",
                      
                      "WHERE c.tipocomprobantecodigo IN ({FacturasQuery}) AND",
                      "c.comprobantefechaemision > '2017-12-31' AND",
                      "c.comprobantetipoentidad = 2"),sep = "\n")
  