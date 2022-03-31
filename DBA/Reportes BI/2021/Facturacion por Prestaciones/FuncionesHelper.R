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
library("RPostgreSQL")
library(lubridate)
library(glue)

GetParameter <- function(x = archivo_parametros,parameter){
  parameter <- filter(archivo_parametros,Parametros.servidor == parameter)
  parameter <- filter(parameter,Usar == TRUE)
  parameter <- parameter$Valor
  return(parameter)
}

VerificadorCambioMes <- function(FechaActual,UltimaFechaMes){
  CambioAnio <- FALSE
  #obtengo los datos de la fecha actual
  dia_actual <- day(FechaActual)
  mes_actual <- month(FechaActual)
  anio_actual <- year(FechaActual)
  #obtengo los datos del ultimo dia del mes actual
  UltimoDia <- day(UltimaFechaMes)
  mesUltimoDia <- month(UltimoDia)
  AnioUltimoDia <- year(FechaActual)
  
  PrimerDiaMes <- 1
  
  #Armo los casos de prueba
  #Caso 1: sigo en el mismo mes y anio y cambio dia
  if(anio_actual == AnioUltimoDia & mes_actual == mesUltimoDia & dia_actual != UltimoDia){
    dia_anterior <- dia_actual - 1}
  #Caso 2: cambio de mes estando en el mismo anio 
  if(anio_actual == AnioUltimoDia & mes_actual != )
  
}