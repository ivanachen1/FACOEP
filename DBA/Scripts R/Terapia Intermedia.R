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

Facturado <- dbGetQuery(con, "SELECT
                                      CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
                                      CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as factura,
                                      c.comprobantefechaemision as emision,
                                      nomencladornombre as Prestacion,
                                      comprobantecrgdetimportecrg as importecrg,
                                      comprobantecrgdetimportefactur as afacturar,
                                      comprobantecrgdetpractica, crgdetcantidad as dias
  
                                    FROM 
                                      comprobantes c
                                    
                                    LEFT JOIN 
                                      comprobantecrgdet cd ON cd.comprobantetipoentidad = c.comprobantetipoentidad and
                                                              cd.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                              cd.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                                              cd.comprobanteprefijo = c.comprobanteprefijo and
                                                              cd.comprobantecodigo = c.comprobantecodigo
                                                              
                                    LEFT JOIN (select pprid, crgnum, crgdetid, crgdetcantidad FROM crgdet) as cdd ON cdd.pprid = cd.comprobantepprid and
                                                                                                                  cdd.crgnum = cd.comprobantecrgnro and
                                                                                                                  cdd.crgdetid = cd.comprobantecrgdetid
                                                                      
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
                                    
                                    LEFT JOIN (SELECT nomencladorprestacion, nomencladornombre FROM nomenclador WHERE nomencladorprestacion LIKE '4.08') n ON n.nomencladorprestacion = comprobantecrgdetpractica
                                    
                                    WHERE 
                                          c.comprobantetipoentidad = 2 and
                                          c.comprobantefechaemision > '2019-01-01' and
                                          c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') and
                                          (a.comprobanteasoctipo IS NULL OR a.comprobanteasoctipo = 'RECX2') and
                                          comprobantecrgdetpractica IN ('IAC.01','IAC.02','IAC.03') ")

Facturado$prestacion <- "Dia T. Intermedia"
Facturado$Cantidad <- 1

Facturado <- aggregate(.~os+factura+emision+prestacion+comprobantecrgdetpractica, Facturado, sum)

Facturado <- filter(Facturado, Facturado$os != "1003 - OSPAÑA")
Facturado <- filter(Facturado, Facturado$os != "1 - FACOEP � PAMI")

Debitos <- dbGetQuery(con, "SELECT
                                      CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
                                      CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as nota,
                                      c.comprobantefechaemision as emision,
                                      nomencladornombre as Prestacion,
                                      comprobantecrgdetimportecrg as importecrg,
                                      comprobantecrgdetimporteacredi as aacreditar,
                                      asoc.comprobantefechaemision as Emisionfactura,
                                      CAST(a.comprobanteasoctipo AS TEXT) || ' - ' || CAST(a.comprobanteasoccodigo as TEXT) as factura, comprobantecrgdetpractica, crgdetcantidad as dias
  
                                    FROM 
                                      comprobantes c
                                    
                                    LEFT JOIN 
                                      comprobantecrgdet cd ON cd.comprobantetipoentidad = c.comprobantetipoentidad and
                                                              cd.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                              cd.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                                              cd.comprobanteprefijo = c.comprobanteprefijo and
                                                              cd.comprobantecodigo = c.comprobantecodigo
                                                              
                                    LEFT JOIN (select pprid, crgnum, crgdetid, crgdetcantidad FROM crgdet) as cdd ON cdd.pprid = cd.comprobantepprid and
                                                                                                                  cdd.crgnum = cd.comprobantecrgnro and
                                                                                                                  cdd.crgdetid = cd.comprobantecrgdetid
                                                                      
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
                                    
                                    LEFT JOIN (SELECT nomencladorprestacion, nomencladornombre FROM nomenclador WHERE nomencladorprestacion LIKE '4.08') n ON n.nomencladorprestacion = comprobantecrgdetpractica
                                    
                                    WHERE 
                                          c.comprobantetipoentidad = 2 and
                                          c.comprobantefechaemision > '2019-01-01' and
                                          c.tipocomprobantecodigo IN ('NCA', 'NCB', 'NCECA') and
                                          comprobantecrgdetpractica IN ('IAC.01','IAC.02','IAC.03') ")


Debitos <- filter(Debitos, Debitos$os != "1003 - OSPAÑA")


fact2019 <- filter(Facturado, Facturado$emision >= '2019-01-01')
fact2019 <- filter(fact2019, fact2019$emision <= '2019-12-31')


inclu2019 <- filter(fact2019, fact2019$os == "1069 - INCLUIR SALUD BS AS")
osba2019 <- filter(fact2019, fact2019$os == "395 - OBSBA")
ioma2019 <- filter(fact2019, fact2019$os == "346 - IOMA")

Deb2019 <- filter(Debitos, Debitos$emision >= '2019-01-01')
Deb2019 <- filter(Deb2019, Deb2019$emision <= '2019-12-31')
Deb2019 <- filter(Deb2019, Deb2019$emisionfactura >= '2019-01-01')
Deb2019 <- filter(Deb2019, Deb2019$emisionfactura <= '2019-12-31')

debinclu2019 <- filter(Deb2019, Deb2019$os == "1069 - INCLUIR SALUD BS AS")
debosba2019 <- filter(Deb2019, Deb2019$os == "395 - OBSBA")
debioma2019 <- filter(Deb2019, Deb2019$os == "346 - IOMA")


fact2020 <- filter(Facturado, Facturado$emision >= '2020-01-01')
fact2020 <- filter(fact2020, fact2020$emision <= '2020-12-31')


inclu2020 <- filter(fact2020, fact2020$os == "1069 - INCLUIR SALUD BS AS")
osba2020 <- filter(fact2020, fact2020$os == "395 - OBSBA")
ioma2020 <- filter(fact2020, fact2020$os == "346 - IOMA")

Deb2020 <- filter(Debitos, Debitos$emision >= '2020-01-01')
Deb2020 <- filter(Deb2020, Deb2020$emision <= '2020-12-31')
Deb2020 <- filter(Deb2020, Deb2020$emisionfactura >= '2020-01-01')
Deb2020 <- filter(Deb2020, Deb2020$emisionfactura <= '2020-12-31')

debinclu2020 <- filter(Deb2020, Deb2020$os == "1069 - INCLUIR SALUD BS AS")
debosba2020 <- filter(Deb2020, Deb2020$os == "395 - OBSBA")
debioma2020 <- filter(Deb2020, Deb2020$os == "346 - IOMA")

fact2021 <- filter(Facturado, Facturado$emision >= '2021-01-01')
fact2021 <- filter(fact2021, fact2021$emision <= '2021-12-31')
inclu2021 <- filter(fact2021, fact2021$os == "1069 - INCLUIR SALUD BS AS")
osba2021 <- filter(fact2021, fact2021$os == "395 - OBSBA")
ioma2021 <- filter(fact2021, fact2021$os == "346 - IOMA")

Deb2021 <- filter(Debitos, Debitos$emision >= '2021-01-01')
Deb2021 <- filter(Deb2021, Deb2021$emision <= '2021-12-31')
Deb2021 <- filter(Deb2021, Deb2021$emisionfactura >= '2021-01-01')
debinclu2021 <- filter(Deb2021, Deb2021$os == "1069 - INCLUIR SALUD BS AS")
debosba2021 <- filter(Deb2021, Deb2021$os == "395 - OBSBA")
debioma2021 <- filter(Deb2021, Deb2021$os == "346 - IOMA")



