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
Resultados <- "~/Excel"                                                                                             
setwd(Resultados)
############################################## CONSULTAS ######################################################

  data <- dbGetQuery(con, "SELECT
  pprnombre,
  obsocialesdescripcion,
  comprobantecrgdetafinumdoc,
  c.comprobantefechaemision,
  comprobantecrgdetimportefactur,
  comprobantecrgdetpractica
  
  FROM comprobantes c
  LEFT JOIN comprobantecrgdet cd ON cd.comprobantetipoentidad = c.comprobantetipoentidad and
  cd.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
  cd.tipocomprobantecodigo = c.tipocomprobantecodigo and
  cd.comprobanteprefijo = c.comprobanteprefijo and
  cd.comprobantecodigo = c.comprobantecodigo
  LEFT JOIN obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo
  LEFT JOIN proveedorprestador pp ON pp.pprid = comprobantepprid
  WHERE comprobantefechaemision BETWEEN '2020-01-01' AND '2021-03-31' AND c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') 
                   and 
                   comprobantecrgdetpractica = '36.00' and c.comprobanteentidadcodigo = 174
                    ")


 data2 <- dbGetQuery(con, "SELECT
  pprnombre,
  obsocialesdescripcion,
    comprobantecrgdetafinumdoc,
  c.comprobantefechaemision,
  comprobantecrgdetimportefactur,
  comprobantecrgdetpractica
  
  FROM comprobantes c
  LEFT JOIN comprobantecrgdet cd ON cd.comprobantetipoentidad = c.comprobantetipoentidad and
  cd.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
  cd.tipocomprobantecodigo = c.tipocomprobantecodigo and
  cd.comprobanteprefijo = c.comprobanteprefijo and
  cd.comprobantecodigo = c.comprobantecodigo
  LEFT JOIN obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo
  LEFT JOIN proveedorprestador pp ON pp.pprid = comprobantepprid
  WHERE comprobantefechaemision BETWEEN '2019-01-01' AND '2019-12-31' AND c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') 
                AND 
                   comprobantecrgdetpractica IN('4.09','4.10')
                    ")

data <- rbind(data, data2)

data <- filter(data, data$obsocialesdescripcion != 'Afiliados PAMI CÃ¡pita MSAL GCABA')
data <- filter(data, data$comprobantefechaemision > '2019-01-01')
data <- filter(data, data$comprobantefechaemision < '2019-12-31')
write.xlsx(data, "Data.xlsx")

data$mes <- as.integer(month(data$comprobantefechaemision))
data$mes <- meses[ data$mes  ]

dataEF <- select(data, "efector" = pprnombre, "Practica" = comprobantecrgdetpractica, mes, "importe" = comprobantecrgdetimportefactur)
dataEF <- aggregate(.~efector+mes+Practica, dataEF, sum)
dataEF <- spread(dataEF, mes, importe)
dataEF[is.na(dataEF)] <- 0

dataOS <- select(data, "os" = obsocialesdescripcion,"Practica" = comprobantecrgdetpractica, mes, "importe" = comprobantecrgdetimportefactur)
dataOS <- aggregate(.~os+mes+Practica, dataOS, sum)
dataOS <- spread(dataOS, mes, importe)
dataOS[is.na(dataOS)] <- 0

write.csv(dataOS, "os.csv", row.names = FALSE, sep = ",")
