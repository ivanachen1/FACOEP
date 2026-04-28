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
library(glue)

##################### Campos de Fecha ######################################################

dia_actual <- today()
LastDate <- floor_date(dia_actual,unit = "month") - 1
FirstDate <- as.Date(paste(year(LastDate),month(LastDate),1,sep = "-"))

FirstYear <- year(FirstDate)
FirstMonth <- month(FirstDate)

LastYear <- year(LastDate)
LastMonth <- month(LastDate)
LastDay <- day(LastDate)

##################### Conexion con DB Facoep################################################
pw <- {"serveradmin"}
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "Facoep",
                 host = "10.22.0.142", port = 5432,
                 user = "postgres", password = pw)


##################### Conexion con DB Sigehos################################################


pw_sigehos <- {"facoep2017"}
drv_sigehos <- dbDriver("PostgreSQL")
con_sigehos <- dbConnect(drv_sigehos, dbname = "sigehos_recupero",
                 host = "172.31.24.12", port = 5432,
                 user = "postgres", password = pw_sigehos)

path <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Recupero_Gastos"

DB <- "databases.xlsx"

Efectores <- read.xlsx(paste(path,DB,sep = "/"))
Efectores <- Efectores[Efectores$RecuperoPami == TRUE,]

pprids <- dbGetQuery(con, "SELECT pprnombre, pprid FROM proveedorprestador")



Efectores <- left_join(Efectores, pprids)
############################################## CONSULTAS ######################################################


############# REEMPLAZAR RUTA DEL ARCHIVO INPUT AQUI###################################################################


dataQuery <- glue(paste("SELECT *",
                   "FROM anexos_recupero",
                   "WHERE fecha BETWEEN '{FirstYear}-{FirstMonth}- 1' AND",
                   "'{LastYear}-{LastMonth}-{LastDay}'",sep = " "))

print(dataQuery)

data <- dbGetQuery(con, dataQuery)


  #######################################################################################################################

############# REEMPLAZAR RUTA DEL ARCHIVO OUTPUT AQUI###################################################################
setwd("//facoep/Sistemas/PAMI CAPITA")
########################################################################################################################


data$Fecha <- convertToDate(data$Fecha, origin = "1900-01-01")

data$Mes <- month(data$Fecha)
data$Mes <- meses[ data$Mes  ]

Afiliados <- select(data, Efector, Mes, Documento)
Afiliados$Cantidad <- 1
Afiliados <- unique(Afiliados)
Afiliados <- select(Afiliados, Efector, Mes, Cantidad)
Afiliados <- aggregate(.~Efector+Mes, Afiliados, sum)
Afiliados$Total <- "Total"
Afiliados$Mes <- NULL
Afiliados <- spread(Afiliados, Total, Cantidad)
Afiliados <- left_join(Afiliados, Efectores)

Apertura <- filter(Afiliados, Afiliados$pprid %in% c(5,13,17,25,4,2678,19,9,21,11,10,23,2,6,26,14,3,24,20,16,22))

Apertura$Percentage <- Apertura$Total/sum(Apertura$Total)

Apertura <- select(Apertura, pprnombre, pprid, Percentage)

wb <- createWorkbook()
addWorksheet(wb, paste("Apertura", " ", month(first(data$Fecha)), "-", year(first(data$Fecha)), sep = ""), gridLines = TRUE)
writeData(wb, paste("Apertura", " ", month(first(data$Fecha)), "-", year(first(data$Fecha)), sep = ""), Apertura, colNames = FALSE)
saveWorkbook(wb, paste("Apertura", " ", month(first(data$Fecha)), "-", year(first(data$Fecha)),".xlsx", sep = ""), overwrite = TRUE)

