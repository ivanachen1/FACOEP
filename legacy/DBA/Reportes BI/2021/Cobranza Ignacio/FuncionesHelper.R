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

#Ver lo de comprobantetipoentidad
getDeudaQuery <- function(fecha_vencimiento_one,fecha_vencimiento_two,tipo_facturas){
  query <- paste("SELECT id, tipo, periodo, sum(vencido) as monto",
                 "FROM (SELECT", 
                 "c.comprobanteentidadcodigo as id,",
                 "CASE WHEN comprobantepprid = 3140 THEN 'Turismo'",
                 "WHEN comprobantepprid = 3173 THEN 'Detectar' ELSE 'Reg-Cov' END AS Tipo,",
                 "entrega, vencimiento,",
                 "CASE WHEN vencimiento < '31-05-2022' THEN EXTRACT(YEAR FROM vencimiento)::varchar",
                 "WHEN EXTRACT(MONTH FROM vencimiento) = 6 THEN 'Actual'",
                 "WHEN vencimiento >= '01-07-2022' THEN 'A Vencer' ELSE '' END AS Periodo,",
                 "c.tipocomprobantecodigo, c.comprobantecodigo,",
                 "comprobantesaldo as vencido",
                          
                 "FROM comprobantes c",
                 "LEFT JOIN comprobantecrg crg ON",
                 "crg.tipocomprobantecodigo = c.tipocomprobantecodigo AND",
                 "crg.comprobantetipoentidad = c.comprobantetipoentidad AND",
                 "crg.comprobantecodigo = c.comprobantecodigo AND",
                 "crg.comprobanteentidadcodigo = c.comprobanteentidadcodigo",

                 "LEFT JOIN (SELECT",
                             "comprobanteentidadcodigo,",
                             "tipocomprobantecodigo,",
                             "comprobantecodigo,",
                             "MAX(comprobantehisfechatramite) as entrega,",
                             "(MAX(comprobantehisfechatramite) + INTERVAL '60 day') as vencimiento",
                             "FROM comprobanteshistorial", 
                             "WHERE comprobantehisestado IN (4,13)",
                             "GROUP BY 1,2,3) as h ",
                             "ON h.comprobanteentidadcodigo = c.comprobanteentidadcodigo AND",
                                   "h.tipocomprobantecodigo = c.tipocomprobantecodigo AND",
                                   "h.comprobantecodigo = c.comprobantecodigo",

                          
                             "WHERE c.tipocomprobantecodigo IN ('FACA2','FACB2','FAECA','FAECB','NDA', 'NDB', 'NDECA') AND",
                             "vencimiento < '31-07-2022' AND",
                             "c.comprobantesaldo > 0 AND", 
                             "c.comprobantemandatario = 'FALSE'", 
                                
                             "GROUP BY 1,2,3,4,5,6,7,8) as x group by 1,2,3")
  
  query <- glue(query)
  
  return(query)}

getRecibosQuery <- function(){
  query <- paste("SELECT",
                  "c.comprobanteentidadcodigo as id,",
                  "CASE WHEN cg.tipo IS NULL THEN 'Reg-Cov'",
                  "WHEN cg.tipo = 'Reg-Cov' THEN 'Reg-Cov'",
                  "WHEN cg.tipo = 'Turismo' THEN 'Turismo'", 
                  "WHEN cg.tipo = 'Detectar' THEN 'Detectar' ELSE '' END as tipo,",
                  "CASE WHEN vencimiento < '31-05-2022' THEN EXTRACT(YEAR FROM vencimiento)::varchar",
                  "WHEN EXTRACT(MONTH FROM vencimiento) = 6 THEN 'Actual'",
                  "WHEN vencimiento >= '01-07-2022' THEN 'A Vencer' ELSE '' END AS Periodo,",
                  "sum(ci.comprobanteimputacionimporte) as Recibos",
                          
                          
                  "FROM comprobantes c",
                  "LEFT JOIN (SELECT", 
                  "comprobanteentidadcodigo as id,",
                  "tipocomprobantecodigo,",
                  "comprobantecodigo,",
                  "CASE WHEN comprobantepprid = 3140 THEN 'Turismo'",
                  "WHEN comprobantepprid = 3173 THEN 'Detectar' ELSE 'Reg-Cov' END AS Tipo",
                          
                  "FROM comprobantecrg",
                  "WHERE tipocomprobantecodigo in ('RECX2')",
                  "GROUP BY 1,2,3,4) as cg", 
                  "ON cg.id = c.comprobanteentidadcodigo AND", 
                  "cg.tipocomprobantecodigo = c.tipocomprobantecodigo AND",
                  "cg.comprobantecodigo = c.comprobantecodigo",
                                             
                  "LEFT JOIN comprobantesimputaciones ci", 
                  "ON ci.empcod = c.empcod AND",
  								"ci.sucursalcodigo = c.sucursalcodigo AND",
									"ci.comprobantetipoentidad = c.comprobantetipoentidad AND",
									"ci.comprobanteentidadcodigo = c.comprobanteentidadcodigo AND",
									"ci.tipocomprobantecodigo = c.tipocomprobantecodigo AND",
									"ci.comprobanteprefijo = c.comprobanteprefijo AND",
									"ci.comprobantecodigo = c.comprobantecodigo",
                                            
                  "LEFT JOIN (SELECT",
                              "comprobanteentidadcodigo,",
                              "tipocomprobantecodigo,",
                              "comprobantecodigo,",
                              "MAX(comprobantehisfechatramite) as entrega,",
                              "(MAX(comprobantehisfechatramite) + INTERVAL '60 day') as vencimiento",
                              "FROM comprobanteshistorial", 
                              "WHERE comprobantehisestado IN (4,13)",
                              "GROUP BY 1,2,3) as h",
									            "ON h.comprobanteentidadcodigo = ci.comprobanteentidadcodigo AND",
                              "h.tipocomprobantecodigo = ci.comprobanteimputaciontipo AND",
                              "h.comprobantecodigo = ci.comprobanteimputacioncodigo",
                                                    
                              "WHERE c.tipocomprobantecodigo in ('RECX2') AND",
									            "ci.comprobanteimputaciontipo in ('FACA2','FACB2','FAECA','FAECB','NDA', 'NDB', 'NDECA') AND",
                              "EXTRACT(YEAR FROM c.comprobantefechaemision) = 2022 AND",
									            "EXTRACT(MONTH FROM c.comprobantefechaemision) = 06", 
                                
                          "GROUP BY 1,2,3")
  
  
  
  
  
}
