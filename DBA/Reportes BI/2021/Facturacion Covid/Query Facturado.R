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
library(glue)
library(lubridate)
library("RPostgreSQL")

pw <- {"odoo"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep",
                 host = "localhost", port = 5432, 
                 user = "odoo", password = pw)


alafecha <- as.Date(Sys.Date())
realizacion <- Sys.time()

PrestacionesQuery <- dbGetQuery(conn = con,"SELECT DISTINCT comprobantecrgdetpractica
                                FROM comprobantecrgdet 
                                WHERE comprobantecrgdetpractica  LIKE '60.%' OR comprobantecrgdetpractica LIKE '%COV%'")

PrestacionesQuery <- PrestacionesQuery$comprobantecrgdetpractica
PrestacionesQuery <- as.vector(PrestacionesQuery)
PrestacionesQuery <- toString(sprintf("'%s'", PrestacionesQuery))

postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")

FacturadoCobradoQuery <- glue("SELECT pprnombre,
                          CONCAT(det.tipocomprobantecodigo,'-',det.comprobanteprefijo,'-',det.comprobantecodigo) as comprobante,
                          facturas.emision,
                          det.comprobantecrgdetpractica as Prestacion,
                          det.comprobantecrgdetimportecrg as importecrg,
                          comprobantecrgdetimportefactur,
                          facturas.anulado

                          FROM comprobantecrgdet det
                                 
                          LEFT JOIN (SELECT tipocomprobantecodigo,
												                    comprobanteprefijo,
												                    comprobantecodigo,
                                            comprobantefechaemision as emision,
                                            CASE WHEN (comprobantedetalle LIKE '%ANULA%') THEN 'Si' ELSE 'No' END AS anulado
												                    FROM comprobantes
												                    WHERE tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB')) as facturas
                                 
                                            ON det.tipocomprobantecodigo = facturas.tipocomprobantecodigo AND
								 	                          det.comprobanteprefijo = facturas.comprobanteprefijo AND
									                          det.comprobantecodigo = facturas.comprobantecodigo
                                 
                          LEFT JOIN
                          proveedorprestador pp ON pp.pprid = det.comprobantepprid
                                                                      
                          LEFT JOIN 
                          obrassociales os ON os.obsocialesclienteid = det.comprobanteentidadcodigo

                          WHERE 
                          det.comprobantetipoentidad = 2 AND
                          det.comprobantecodigo NOT IN (553,687,953,955,4516,4901,4934,13295,13316,13916,13941,14061,14152,14754,15144,15557,15817) AND
                          facturas.emision > '2020-01-01' AND
                          det.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') AND
								          det.comprobantecrgdetpractica IN ({PrestacionesQuery})")


FacturacionQuery <- dbGetQuery(conn = con,FacturadoCobradoQuery)
FacturacionQuery$comprobante <- gsub(" ","",FacturacionQuery$comprobante)
FacturacionQuery$Cantidad <- 1

FacturacionQuery <- aggregate(.~pprnombre+comprobante+emision+prestacion+anulado, FacturacionQuery, sum)


FacturacionQuery$anio <- year(FacturacionQuery$emision)
FacturacionQuery$Mes <- month(FacturacionQuery$emision)
FacturacionQuery$NombreMes <- format(FacturacionQuery$emision,"%B")

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
