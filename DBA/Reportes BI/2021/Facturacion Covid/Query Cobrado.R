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
Resultados <- "C:/Users/iachenbach/Desktop/FACOEP/DBA/Scripts R"
setwd(Resultados)
postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")


FacturadoCobrado <- dbGetQuery(con, "SELECT
                                      pprnombre,
                                      c.tipocomprobantecodigo as tipofact, c.comprobantecodigo as factura,
                                      c.comprobantefechaemision as emision,
                                      comprobantecrgdetpractica as Prestacion,
                                      comprobantecrgdetimportecrg as importecrg,
                                      comprobantecrgdetimportefactur as importepostrec,
                                      asoc.comprobantefechaemision as emisionrecibo,
                                      a.comprobanteasoctipo as tiporec, a.comprobanteasoccodigo as recibo,
                                      CASE WHEN (c.comprobantedetalle LIKE '%ANULA%') THEN 'Si' ELSE 'No' END AS anulado
  
                                    FROM 
                                      comprobantes c
                                    
                                    LEFT JOIN 
                                      comprobantecrgdet cd ON cd.comprobantetipoentidad = c.comprobantetipoentidad and
                                                              cd.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                              cd.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                                              cd.comprobanteprefijo = c.comprobanteprefijo and
                                                              cd.comprobantecodigo = c.comprobantecodigo
                                                              
                                    LEFT JOIN
                                      proveedorprestador pp ON pp.pprid = cd.comprobantepprid
                                                                      
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
                                    
                                    WHERE obsocialescodigo NOT IN ('90001199', '90001003', '90001162', '90000172', '90001226') and 
                                          c.comprobantetipoentidad = 2 and
                                          c.comprobantefechaemision > '2020-01-01' and
                                          c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') and
                                          (a.comprobanteasoctipo IS NULL OR a.comprobanteasoctipo = 'RECX2') and
                                          comprobantecrgdetpractica  LIKE '60.%' OR comprobantecrgdetpractica LIKE '%COV%' ")




FacturadoCobrado$tipofact <- str_squish(FacturadoCobrado$tipofact)
FacturadoCobrado$tiporec <- str_squish(FacturadoCobrado$tiporec)
FacturadoCobrado <- filter(FacturadoCobrado, FacturadoCobrado$tipofact %in% c("FACA2", "FACB2", "FAECA"))
FacturadoCobrado <- filter(FacturadoCobrado, FacturadoCobrado$tiporec %in% c("RECX2",NA))
# la funcion paste() se utiliza para concatenar cadenas de texto y separarlas con un delimitador
FacturadoCobrado$factura <- paste(FacturadoCobrado$tipofact, "-", FacturadoCobrado$factura, sep = " ")
FacturadoCobrado$recibo <- paste(FacturadoCobrado$tiporec, "-", FacturadoCobrado$recibo, sep = " ")
FacturadoCobrado$tipofact <- NULL
FacturadoCobrado$tiporec <- NULL

FacturadoCobrado$Cantidad <- 1
FacturadoCobrado$emisionrecibo <- fifelse(is.na(FacturadoCobrado$emisionrecibo), as.Date('1900-01-01'), as.Date(FacturadoCobrado$emisionrecibo))
FacturadoCobrado$recibo <- ifelse(is.na(FacturadoCobrado$recibo), " - ", FacturadoCobrado$recibo)

FacturadoCobrado <- aggregate(.~pprnombre+factura+emision+prestacion+emisionrecibo+recibo+anulado, FacturadoCobrado, sum)
FacturadoCobrado$Cobrado <- ifelse(FacturadoCobrado$recibo == " - ", 0, FacturadoCobrado$importecrg)
FacturadoCobrado$Facturado <- FacturadoCobrado$importecrg


Cobrado <- select(FacturadoCobrado,
                  "Efector" = pprnombre,
                  "Emision" = emisionrecibo,
                  "Recibo" = recibo,
                  "Prestacion" = prestacion,
                  "Cantidad" = Cantidad,
                  "Cobrado" = Cobrado,
                  "Anulado" = anulado)
Cobrado <- filter(Cobrado, Cobrado > 0)
Cobrado <- filter(Cobrado, Emision >= '2020-01-01')