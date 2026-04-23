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

cleanData <- function(data){
  data$recibo <- gsub(" ","",data$recibo)
  data$prestacion <- ifelse(data$prestacion == "                    ",
                            "Sin Definir",
                            ifelse(is.na(data$prestacion),"Sin Definir",data$prestacion))
  
  data$prestacion <- gsub(" ","",data$prestacion)
  data$prestacion <- toupper(data$prestacion)
  data$efector <- gsub(" ","",data$efector)
  
  paste("Etapa1",class(data))
  
  data$TipoApertura <- ifelse(is.na(data$comprobantecrgnrocrg) & is.na(data$comprobantecrgdetnrocrg),
                              "Sin Apertura",
                              ifelse(!is.na(data$comprobantecrgnrocrg) & is.na(data$comprobantecrgdetnrocrg),
                                     "Apertura Cabecera",
                                     "Apertura Detalle"))
  data$cantidad <- 1
  
  
  data$emision <- as.Date(data$emision)
  
  data$comprobantecrgnro <- as.character(data$comprobantecrgnro)
  
  data$comprobantecrgnro <- ifelse(is.na(data$comprobantecrgnro),"Sin Asignar SIF",data$comprobantecrgnro)
  
  data$importeprestacion <- ifelse(is.na(data$importeprestacion),0,data$importeprestacion)
  
  data$efector <- ifelse(is.na(data$efector),"Sin Asignar SIF",data$efector)
  
  data$os <- ifelse(is.na(data$os),"Sin Asignar SIF",data$os)
  
  paste("Etapa2",class(data))
  
  
  
  return(data)
}

dataTransform <- function(data){
  data <- aggregate(.~efector+os+recibo+emision+comprobantecrgnro+prestacion+importeprestacion+centrocosto+TipoApertura+origen,
                    data, sum)
  
  paste("Etapa3",class(data))
  
  data$idRow <- paste(data$efector,
                      data$os,data$recibo,
                      data$emision,
                      data$comprobantecrgnro,
                      data$prestacion,
                      data$importeprestacion,
                      data$centrocosto,
                      data$TipoApertura,
                      data$origen,
                      data$comprobantecrgnrocrg,
                      data$cantidad,sep = "-")
  return(data)
}




  