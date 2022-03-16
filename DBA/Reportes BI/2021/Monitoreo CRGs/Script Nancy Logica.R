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
library(BBmisc)

drv <- dbDriver("PostgreSQL")

alafecha <- as.Date(Sys.Date())
realizacion <- date(alafecha)


GetArchivoParametros <- function(path_one,path_two){
  x = "parametros_servidor.xlsx"
  intento  <- is.error(try(read.xlsx(paste(path_two,x,sep = "/")),silent = F,outFile = "Error"))
  
  
  if(intento == TRUE){
    return(read.xlsx(paste(path_one,x,sep = "/")))} else {return(read.xlsx(paste(path_two,x,sep = "/")))}
}  

GetPassword <- function(x = archivo_parametros){
  pw <- filter(archivo_parametros,Parametros.servidor == "password")
  pw <- filter(pw,Usar == TRUE)
  pw <- pw$Valor
  return(pw)
}

GetDatabase <- function(x = archivo_parametros){
  pw <- filter(archivo_parametros,Parametros.servidor == "database")
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

GetWorkDirectory <- function(x = archivo_parametros){
  workdirectory <- filter(archivo_parametros,Parametros.servidor == "workdirectory")
  workdirectory <- filter(workdirectory,Usar == TRUE)
  workdirectory <- workdirectory$Valor
  return(workdirectory)}

