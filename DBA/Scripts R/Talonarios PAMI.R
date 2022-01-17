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
pw <- {"facoep2017"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep",
                 host = "172.31.24.12", port = 5432, 
                 user = "postgres", password = pw)
rm(pw)
meses <- c("01 - Enero","02 - Febrero","03 - Marzo",
           "04 - Abril","05 - Mayo","06 - Junio",
           "07 - Julio","08 - Agosto","09 - Septiembre",
           "10 - Octubre","11 - Noviembre","12 - Diciembre")
alafecha <- as.Date(Sys.Date())
realizacion <- Sys.time()
Resultados <- "C:/Users/user/Desktop/Agus/R" 
setwd(Resultados)
postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")
############################################## CONSULTAS ######################################################




Talonarios <- dbGetQuery(con, "SELECT
                                pedidoptalonariofchcarga as fechacarga,
                                pedidoptalonariofchasighosp fechaasignacion,
                                pedidoptalonarionro as talonarionro,
                                pprnombre as hospitalasignado
                                
                                FROM
                                pedidospamitalonarios p
                                LEFT JOIN proveedorprestador pp ON p.pedidoptalonariopprid = pp.pprid ")



names(Talonarios) <- c("Fecha de Carga", "Fecha de Asignacion", "Nro Talonario", "Hospital Asignado")

write.csv(Talonarios, "Talonarios PAMI.csv")

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
