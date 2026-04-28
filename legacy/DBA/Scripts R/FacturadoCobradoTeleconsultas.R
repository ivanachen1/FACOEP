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
Resultados <- "C:/Users/user/Desktop/Agus/R" 
setwd(Resultados)
postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")

############################################## CONSULTAS ######################################################

FacturadoCobrado <- dbGetQuery(con, "SELECT
                                      CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
                                      CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as factura,
                                      c.comprobantefechaemision as emision,
                                      nomencladornombre as Prestacion,
                                      comprobantecrgdetimportecrg as importecrg,
                                      comprobantecrgdetimportefactur as importepostrec,
                                      asoc.comprobantefechaemision as emisionrecibo,
                                      CAST(a.comprobanteasoctipo AS TEXT) || ' - ' || CAST(a.comprobanteasoccodigo as TEXT) as recibo
  
                                    FROM 
                                      comprobantes c
                                    
                                    LEFT JOIN 
                                      comprobantecrgdet cd ON cd.comprobantetipoentidad = c.comprobantetipoentidad and
                                                              cd.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                              cd.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                                              cd.comprobanteprefijo = c.comprobanteprefijo and
                                                              cd.comprobantecodigo = c.comprobantecodigo
                                                                      
                                    LEFT JOIN 
                                      obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo
                                    
                                    LEFT JOIN 
                                      comprobantesasociados a ON a.empcod = c.empcod and
                                                                 a.sucursalcodigo = c.sucursalcodigo and
                                                                 a.comprobantetipoentidad = c.comprobantetipoentidad and
                                                                 a.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                                 a.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                                                 a.comprobanteprefijo = c.comprobanteprefijo and
                                                                 a.comprobantecodigo = c.comprobantecodigo
                                                                         
                                    LEFT JOIN 
                                      comprobantes asoc ON asoc.tipocomprobantecodigo = a.comprobanteasoctipo and
                                                           asoc.comprobantecodigo = a.comprobanteasoccodigo
                                    
                                    LEFT JOIN (SELECT nomencladorprestacion, nomencladornombre FROM nomenclador WHERE nomencladorprestacion LIKE '60.%') n ON n.nomencladorprestacion = comprobantecrgdetpractica
                                    
                                    WHERE obsocialescodigo NOT IN ('90001199', '90001003', '90001162', '90000172', '90001226') and 
                                          c.comprobantetipoentidad = 2 and
                                          c.comprobantefechaemision > '2020-01-01' and
                                          c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') and
                                          (a.comprobanteasoctipo IS NULL OR a.comprobanteasoctipo = 'RECX2') and
                                          comprobantecrgdetpractica IN ('60.3', '60.3.0')")

FacturadoCobrado$prestacion <- "Tele consulta clínica COVID-19"
FacturadoCobrado$Cantidad <- 1
FacturadoCobrado$emisionrecibo <- fifelse(is.na(FacturadoCobrado$emisionrecibo), as.Date('1900-01-01'), as.Date(FacturadoCobrado$emisionrecibo))
FacturadoCobrado$recibo <- ifelse(is.na(FacturadoCobrado$recibo), " - ", FacturadoCobrado$recibo)
FacturadoCobrado <- aggregate(.~os+factura+emision+prestacion+emisionrecibo+recibo, FacturadoCobrado, sum)

FacturadoCobrado$Abonado <- ifelse(FacturadoCobrado$recibo == " - ", 'No', 
                                   ifelse(FacturadoCobrado$importepostrec == FacturadoCobrado$importecrg, "Pago Total",
                                          ifelse(FacturadoCobrado$importepostrec == 0, "Debitado", "Pago Parcial")))

FacturadoCobrado <- aggregate(.~os+factura+emision+prestacion+emisionrecibo+recibo+Abonado, FacturadoCobrado, sum)

write.csv(FacturadoCobrado, "FacturadoCobrado.csv")



