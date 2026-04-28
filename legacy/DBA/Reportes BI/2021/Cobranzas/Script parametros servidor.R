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

workdirectory_one <- "C:/Users/iachenbach/Desktop/FACOEP/DBA/Reportes BI/2021/Cobranzas/Version 2/archivos_V4"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranzas/Versión 7"

GetArchivoParametros <- function(){
  x = "parametros_servidor.xlsx"
  path_one <- workdirectory_one
  path_two <- workdirectory_two
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


archivo_parametros <- GetArchivoParametros()

pw <- GetPassword()

user <- GetUser()

host <- GetHost() 
  
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep",
                 host = host, port = 5432, 
                 user = user, password = pw)


alafecha <- as.Date(Sys.Date())
realizacion <- Sys.time()
postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")

############################################## CONSULTAS ######################################################

query_comprobantes <- "SELECT	
                    	 c.comprobanteentidadcodigo,
                       c.tipocomprobantecodigo,
                       os.obsocialescodigo,
                       os.obsocialessigla,
                       c.comprobanteprefijo,
                       c.comprobantecodigo,
                       c.comprobanteccosto,
                       c.comprobantefechaemision,
                       c.comprobantecovid AS covid,
                       c.comprobantetotalimporte,
                       CASE WHEN (c.comprobantedetalle LIKE '%ANULA%') THEN 'Si' ELSE 'No' END AS anulado
                      
                       FROM comprobantes c
                       LEFT JOIN obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo" 

tabla_comprobantes <- dbGetQuery(con,query_comprobantes)
