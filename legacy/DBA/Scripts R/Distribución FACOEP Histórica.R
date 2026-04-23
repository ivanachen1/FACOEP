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
                                                          
         WHERE c.tipocomprobantecodigo = 'RECX2' and c.comprobanteenviadores = TRUE
         ")


data$año <- year(data$comprobantefechaemision)
data$Mes <- month(data$comprobantefechaemision)

data2017 <- filter(data, año == 2017)
data2017$Mes <- meses[ data2017$Mes  ]
data2017 <- select(data2017, Mes, "Hospital" = pprnombre, "Importe" = comprobantecrgimportetotaldeta)
data2017 <- aggregate(.~Mes+Hospital, data2017, sum)
data2017 <- spread(data2017, Mes, Importe)

data2018 <- filter(data, año == 2018)
data2018$Mes <- meses[ data2018$Mes  ]
data2018 <- select(data2018, Mes, "Hospital" = pprnombre, "Importe" = comprobantecrgimportetotaldeta)
data2018 <- aggregate(.~Mes+Hospital, data2018, sum)
data2018 <- spread(data2018, Mes, Importe)

data2019 <- filter(data, año == 2019)
data2019$Mes <- meses[ data2019$Mes  ]
data2019 <- select(data2019, Mes, "Hospital" = pprnombre, "Importe" = comprobantecrgimportetotaldeta)
data2019 <- aggregate(.~Mes+Hospital, data2019, sum)
data2019 <- spread(data2019, Mes, Importe)

data2020 <- filter(data, año == 2020)
data2020$Mes <- meses[ data2020$Mes  ]
data2020 <- select(data2020, Mes, "Hospital" = pprnombre, "Importe" = comprobantecrgimportetotaldeta)
data2020 <- aggregate(.~Mes+Hospital, data2020, sum)
data2020 <- spread(data2020, Mes, Importe)

data2021 <- filter(data, año == 2021)
data2021$Mes <- meses[ data2021$Mes  ]
data2021 <- select(data2021, Mes, "Hospital" = pprnombre, "Importe" = comprobantecrgimportetotaldeta)
data2021 <- aggregate(.~Mes+Hospital, data2021, sum)
data2021 <- spread(data2021, Mes, Importe)



wb <- createWorkbook()
addWorksheet(wb, "2017", gridLines = TRUE)
writeData(wb, "2017", data2017)
addWorksheet(wb, "2018", gridLines = TRUE)
writeData(wb, "2018", data2018)
addWorksheet(wb, "2019", gridLines = TRUE)
writeData(wb, "2019", data2019)
addWorksheet(wb, "2020", gridLines = TRUE)
writeData(wb, "2020", data2020)
addWorksheet(wb, "2021", gridLines = TRUE)
writeData(wb, "2021", data2021)

saveWorkbook(wb, "Distribución FACOEP Histórica.xlsx", overwrite = TRUE)


# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

