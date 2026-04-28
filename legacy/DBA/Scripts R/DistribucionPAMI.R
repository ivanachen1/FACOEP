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

data <- dbGetQuery(con, "SELECT
         c.comprobantecodigo,
         c.comprobantefechaemision,
         pprnombre,
         c.comprobanteenviadores,
         crg.comprobantecrgimportetotaldeta
         
         FROM comprobantes c
                          LEFT JOIN comprobantecrg crg ON crg.empcod = c.empcod and
                                                          crg.sucursalcodigo = c.sucursalcodigo and
                                                          crg.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                          crg.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                                          crg.comprobanteprefijo = c.comprobanteprefijo and
                                                          crg.comprobantecodigo = c.comprobantecodigo
                                                          
         LEFT JOIN proveedorprestador p ON p.pprid = crg.comprobantepprid
                                                          
         WHERE comprobantepprid = 20 and c.tipocomprobantecodigo = 'RECX2' and c.comprobanteenviadores = TRUE and c.comprobanteentidadcodigo = 1
         ")


data$año <- year(data$comprobantefechaemision)
data$mes <- month(data$comprobantefechaemision)

data2017 <- filter(data, año == 2017)
data2017$mes <- meses[ data2017$mes  ]
data2017 <- select(data2017, mes, "importe" = comprobantecrgimportetotaldeta)
data2017 <- aggregate(.~mes, data2017, sum)
data2017 <- spread(data2017, mes, importe)


data2018 <- filter(data, año == 2018)
data2018$mes <- meses[ data2018$mes  ]
data2018 <- select(data2018, mes, "importe" = comprobantecrgimportetotaldeta)
data2018 <- aggregate(.~mes, data2018, sum)
data2018 <- spread(data2018, mes, importe)

data2019 <- filter(data, año == 2019)
data2019$mes <- meses[ data2019$mes  ]
data2019 <- select(data2019, mes, "importe" = comprobantecrgimportetotaldeta)
data2019 <- aggregate(.~mes, data2019, sum)
data2019 <- spread(data2019, mes, importe)

data2020 <- filter(data, año == 2020)
data2020$mes <- meses[ data2020$mes  ]
data2020 <- select(data2020, mes, "importe" = comprobantecrgimportetotaldeta)
data2020 <- aggregate(.~mes, data2020, sum)
data2020 <- spread(data2020, mes, importe)

data2021 <- filter(data, año == 2021)
data2021$mes <- meses[ data2021$mes  ]
data2021 <- select(data2021, mes, "importe" = comprobantecrgimportetotaldeta)
data2021 <- aggregate(.~mes, data2021, sum)
data2021 <- spread(data2021, mes, importe)


