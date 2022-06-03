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
library(kwb.geosalz)






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

ReadSigehosData <- function(workdirectory,StartRow){

  file_list <- list.files(path=workdirectory)
  dataset <- data.frame()
  print(file_list)
  
  correct_format <- ".xlsx"
  
  for (i in 1:length(file_list)){
    
    correct_format <- ".xlsx" 
    
    if(str_detect(file_list[i],correct_format) == TRUE){
      EfectorName <- read.xlsx(xlsxFile = paste(workdirectory,
                                                file_list[i],sep = "/"))
      EfectorName <- names(EfectorName)[[1]]
      temp_data <- read.xlsx(xlsxFile = paste(workdirectory,file_list[i],sep = "/"),startRow = StartRow)
      temp_data$Efector <- EfectorName
      dataset <- rbind(dataset, temp_data)}}
  
  #dataset$Fecha <- as.Date(dataset$Fecha, origin = "1899-12-30")
  
  return(dataset)}

SigehosFileControl <- function(DataFrameSigehos,DataframeEfectoresObjetivos,FileName){
  SigehosControl <- data.frame("EfectorSigehos" = unique(DataFrameSigehos$Efector))
  Control <- left_join(SigehosControl,DataframeEfectoresObjetivos,
                       by= c("EfectorSigehos" = "EfectorSigehos"),
                       keep = TRUE)

  Control <- select(Control,"EfectorSigehos" = EfectorSigehos.x,
                    "EfectorSigehosExcel" = EfectorSigehos.y,
                    "ID" = ID,
                    "EfectorObjetivos" = EfectorObjetivos)
  
  Control <- filter(Control,is.na(ID))
  write.xlsx(Control,FileName,overwrite = TRUE)
  
  return(Control)
  
}
  