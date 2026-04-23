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
                                      pprnombre,
                                      CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
                                      CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as factura,
                                      c.comprobantefechaemision as emision,
                                      nomencladornombre as Prestacion,
                                      comprobantecrgdetimportecrg as importecrg,
                                      comprobantecrgdetimportefactur as importepostrec,
                                      asoc.comprobantefechaemision as emisionrecibo,
                                      CAST(a.comprobanteasoctipo AS TEXT) || ' - ' || CAST(a.comprobanteasoccodigo as TEXT) as recibo, comprobantecrgdetpractica, crgdetcantidad as dias
  
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
                                      
                                      LEFT JOIN proveedorprestador pp ON pp.pprid = cd.comprobantepprid
                                    
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
                                    
                                    WHERE obsocialescodigo NOT IN ('90001199', '90001003', '90001162', '90000172', '90001226') and
                                          c.comprobantetipoentidad = 2 and
                                          c.comprobantefechaemision > '2019-01-01' and
                                          c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') and
                                          (a.comprobanteasoctipo IS NULL OR a.comprobanteasoctipo = 'RECX2') and
                                          comprobantecrgdetpractica IN ('4.08', '60.10','60.11', '60.12')")

Facturado$prestacion <- "Dia UTI"
Facturado$Cantidad <- 1
Facturado$emisionrecibo <- fifelse(is.na(Facturado$emisionrecibo), as.Date('1900-01-01'), as.Date(Facturado$emisionrecibo))
Facturado$recibo <- ifelse(is.na(Facturado$recibo), " - ", Facturado$recibo)

Facturado <- aggregate(.~pprnombre+os+factura+emision+prestacion+emisionrecibo+recibo+comprobantecrgdetpractica, Facturado, sum)
# aca hace un group by y el primer argumento te dice por que campos agrupar, el ultimo te dice que operacion hacer y el segundo es el dataframe que queres agrupar
Facturado$Abonado <- ifelse(Facturado$recibo == " - ", 'No', 
                                   ifelse(Facturado$importepostrec == Facturado$importecrg, "Pago Total",
                                          ifelse(Facturado$importepostrec == 0, "Debitado", "Pago Parcial")))

Facturado <- aggregate(.~pprnombre+os+factura+emision+prestacion+emisionrecibo+recibo+comprobantecrgdetpractica+Abonado, Facturado, sum)

Facturado <- filter(Facturado, Facturado$os != "1003 - OSPAÑA")
Facturado$Mes <- month(Facturado$emision)
Facturado$Mes <- meses[ Facturado$Mes  ]

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
                                    
                                    WHERE obsocialescodigo NOT IN ('90001199', '90001003', '90001162', '90000172', '90001226') and
                                          c.comprobantetipoentidad = 2 and
                                          c.comprobantefechaemision > '2019-01-01' and
                                          c.tipocomprobantecodigo IN ('NCA', 'NCB', 'NCECA') and
                                          comprobantecrgdetpractica IN ('4.08', '60.10','60.11', '60.12')")


Debitos <- filter(Debitos, Debitos$os != "1003 - OSPAÑA")




fact2019 <- filter(Facturado, Facturado$emision >= '2019-01-01')
fact2019 <- filter(fact2019, fact2019$emision <= '2019-12-31')

cob2019 <- filter(fact2019, fact2019$recibo != " - ")

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

covid5a7 <- filter(fact2020, fact2020$emision >= '2020-05-01')
covid5a7 <- filter(covid5a7, covid5a7$emision <= '2020-07-31')

#codigos 60.10 y 60.11

covid5a7 <- filter(covid5a7, covid5a7$comprobantecrgdetpractica != "4.08                ")

covid8a12 <- filter(fact2020, fact2020$emision >= '2020-08-01')
covid8a12 <- filter(covid8a12, covid8a12$emision <= '2020-12-31')

#codigos 60.11 y 60.12

covid8a12 <- filter(covid8a12, covid8a12$comprobantecrgdetpractica != "4.08                ")
covid8a12 <- filter(covid8a12, covid8a12$comprobantecrgdetpractica != "60.10               ")

covid <- rbind(covid5a7,covid8a12)

fact2020 <- filter(fact2020, fact2020$comprobantecrgdetpractica == "4.08                ")


fact2020 <- rbind(fact2020, covid)

cob2020 <- filter(fact2020, fact2020$recibo != " - ")

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

#write.csv(FacturadoCobrado, "FacturadoCobrado.csv")




det2019 <- select(fact2019, "Hospital" = pprnombre, "Total" = importecrg, "Cantidad Internaciones" = Cantidad, "Cantidad Dias" = dias)
det2019 <- aggregate(.~Hospital, det2019, sum)
inclu2019 <- select(inclu2019, "Hospital" = pprnombre, "Incluir" = importecrg)
inclu2019 <- aggregate(.~Hospital, inclu2019, sum)
det2019 <- left_join(det2019, inclu2019)
osba2019 <- select(osba2019, "Hospital" = pprnombre, "Osba" = importecrg)
osba2019 <- aggregate(.~Hospital, osba2019, sum)
det2019 <- left_join(det2019, osba2019)
ioma2019 <- select(ioma2019, "Hospital" = pprnombre, "Ioma" = importecrg)
ioma2019 <- aggregate(.~Hospital, ioma2019, sum)
det2019 <- left_join(det2019, ioma2019)

#write.csv(det2019, "2019.csv")


det2020 <- select(fact2020, "Hospital" = pprnombre, "Total" = importecrg, "Cantidad Internaciones" = Cantidad, "Cantidad Dias" = dias)
det2020 <- aggregate(.~Hospital, det2020, sum)
inclu2020 <- select(inclu2020, "Hospital" = pprnombre, "Incluir" = importecrg)
inclu2020 <- aggregate(.~Hospital, inclu2020, sum)
det2020 <- left_join(det2020, inclu2020)
osba2020 <- select(osba2020, "Hospital" = pprnombre, "Osba" = importecrg)
osba2020 <- aggregate(.~Hospital, osba2020, sum)
det2020 <- left_join(det2020, osba2020)
ioma2020 <- select(ioma2020, "Hospital" = pprnombre, "Ioma" = importecrg)
ioma2020 <- aggregate(.~Hospital, ioma2020, sum)
det2020 <- left_join(det2020, ioma2020)

#write.csv(det2020, "2020.csv")


det2021 <- select(fact2021, "Hospital" = pprnombre, "Total" = importecrg, "Cantidad Internaciones" = Cantidad, "Cantidad Dias" = dias)
det2021 <- aggregate(.~Hospital, det2021, sum)
inclu2021 <- select(inclu2021, "Hospital" = pprnombre, "Incluir" = importecrg)
inclu2021 <- aggregate(.~Hospital, inclu2021, sum)
det2021 <- left_join(det2021, inclu2021)
osba2021 <- select(osba2021, "Hospital" = pprnombre, "Osba" = importecrg)
osba2021 <- aggregate(.~Hospital, osba2021, sum)
det2021 <- left_join(det2021, osba2021)
ioma2021 <- select(ioma2021, "Hospital" = pprnombre, "Ioma" = importecrg)
ioma2021 <- aggregate(.~Hospital, ioma2021, sum)
det2021 <- left_join(det2021, ioma2021)

#write.csv(det2021, "2021.csv")

fact2021$det <- ifelse(fact2021$os == "1069 - INCLUIR SALUD BS AS", "Incluir",
                       ifelse(fact2021$os == "395 - OBSBA", "OSBA",
                              ifelse(fact2021$os == "346 - IOMA", "IOMA", "Otros")))

detargerich <- select(filter(fact2021, pprnombre == "HOSPITAL ARGERICH                       "), Mes, det, importepostrec)
detargerich <- aggregate(.~Mes+det, detargerich, sum)
detargerich <- spread(detargerich, Mes, importepostrec)

detdurand <- select(filter(fact2021, pprnombre == "HOSPITAL DURAND                         "), Mes, det, importepostrec)
detdurand <- aggregate(.~Mes+det, detdurand, sum)
detdurand <- spread(detdurand, Mes, importepostrec)

detfernandez <- select(filter(fact2021, pprnombre == "HOSPITAL FERNANDEZ                      "), Mes, det, importepostrec)
detfernandez <- aggregate(.~Mes+det, detfernandez, sum)
detfernandez <- spread(detfernandez, Mes, importepostrec)

detsantojanni <- select(filter(fact2021, pprnombre == "HOSPITAL SANTOJANNI                     "), Mes, det, importepostrec)
detsantojanni <- aggregate(.~Mes+det, detsantojanni, sum)
detsantojanni <- spread(detsantojanni, Mes, importepostrec)

write.csv(detargerich, "data.csv")



