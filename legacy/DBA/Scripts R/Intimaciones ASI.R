########################################### LIBRERIAS ####################################################################################  
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
pw <- {"facoep2017"} 
drv <- dbDriver("PostgreSQL")

facoep <- dbConnect(drv, dbname = "facoep",
                    host = "172.31.24.12", port = 5432, 
                    user = "postgres", password = pw)

asiliq <- dbConnect(drv, dbname = "asiliq",
                    host = "172.31.24.12", port = 5432, 
                    user = "postgres", password = pw)

FACOEPASI <- dbConnect(drv, dbname = "FACOEP_ASI",
                       host = "172.31.24.12", port = 5432, 
                       user = "postgres", password = pw)

rm(pw)
alafecha <- as.integer(format(as.Date(Sys.Date()), "%m"))
Resultados <- "~/ComprobantesASIaFACOEP"                                                                                             
setwd(Resultados)

######################################################################

paola <- read.xlsx("/home/agustinnieto/temp/Inventario CREDITOS.xlsx", sheet = 6)
paola <- paola[-c(1,2,3,4,5,6),] 
comprobantespaola <- select(paola,X6, Cliente,X3, X4,Tipo.de.Entidad)
comprobantespaola <- comprobantespaola[-c(1,2,3,4,5,6),] 
names(comprobantespaola) <- c("comprobanteentidadcodigo","tipocomprobantecodigo","comprobanteprefijo", "comprobantecodigo", "comprobantefechaemision")
comprobantespaola$tipocomprobantecodigo <- ifelse(comprobantespaola$tipocomprobantecodigo == "FACASIA", "FACA2  ",
                                                  ifelse(comprobantespaola$tipocomprobantecodigo == "FACASIB", "FACB2  ",
                                                         ifelse(comprobantespaola$tipocomprobantecodigo == "NDAASI", "NDA    ", 
                                                                ifelse(comprobantespaola$tipocomprobantecodigo == "NDBASI", "NDB    ", ""))))

comprobantespaola$comprobantecodigo <- as.integer(comprobantespaola$comprobantecodigo)
comprobantespaola$comprobanteentidadcodigo <- as.integer(comprobantespaola$comprobanteentidadcodigo)
comprobantespaola$comprobanteprefijo <- as.integer(comprobantespaola$comprobanteprefijo)
comprobantespaola$comprobantefechaemision <- convertToDate(comprobantespaola$comprobantefechaemision, origin = "1900-01-01")
comprobantespaola <- head(comprobantespaola, -1)
comprobantespaola <- unique(comprobantespaola)
