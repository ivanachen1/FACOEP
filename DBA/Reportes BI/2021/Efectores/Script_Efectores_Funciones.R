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

GetDatabase <- function(x = archivo_parametros){
  pw <- filter(archivo_parametros,Parametros.servidor == "database")
  pw <- filter(pw,Usar == TRUE)
  pw <- pw$Valor
  return(pw)
}

GetPassword <- function(x = archivo_parametros){
  pw <- filter(archivo_parametros,Parametros.servidor == "password")
  pw <- filter(pw,Usar == TRUE)
  pw <- pw$Valor
  return(pw)
}

GetUser <- function(x = archivo_parametros){
  user <- filter(archivo_parametros,Parametros.servidor == "user")
  user <- filter(user,Usar == TRUE)
  user <- user$Valor
  return(user)}

GetHost <- function(x = archivo_parametros){
  host <- filter(archivo_parametros,Parametros.servidor == "host")
  host <- filter(host,Usar == TRUE)
  host <- host$Valor
  return(host)}


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
  
TransFormTablaApertura <- function(archivo,print = FALSE){
  archivo <- archivo$idApertura
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

                      
  