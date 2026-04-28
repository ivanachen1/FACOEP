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
                                          c.comprobantefechaemision > '2019-01-01' and
                                          c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') and
                                          (a.comprobanteasoctipo IS NULL OR a.comprobanteasoctipo = 'RECX2') and
                                          comprobantecrgdetpractica IN ('4.01', '4.02', '4.03', '4.04', '4.05', '4.06', '4.09', '4.10', '5.0', '60.09', '60.10', '4.08', '60.10','60.11', '60.12')")
Facturado$comprobantecrgdetpractica <- gsub(" ", "", Facturado$comprobantecrgdetpractica, fixed = TRUE)


# UTI-UCO = 4.08 + 2020/05-07 60.10 y 60.11 + 2020/08-12 60.11 y 60.12

# PISO = 4.01,02,03,04,05,06,09,10 5.0 + 2020 hasta 08 60.09 + 2020 post 08 60.10


piso <- filter(Facturado, Facturado$comprobantecrgdetpractica %in% c('4.01', '4.02', '4.03', '4.04', '4.05', '4.06', '4.09', '4.10', '5.0', '60.09', '60.10'))

chau <- filter(piso, piso$emision < '2020-08-01')
chau <- filter(chau, chau$comprobantecrgdetpractica == '60.10')

piso <- anti_join(piso, chau)
piso$year <- year(piso$emision)
piso$mes <- month(piso$emision)

piso2019 <- select(filter(piso, piso$year == 2019),
                          "Mes" = mes,
                          "Facturado" = importecrg,
                          "Cant Dias" = dias)
piso2019$Mes <- meses[ piso2019$Mes  ]

piso2019 <- aggregate(.~Mes, piso2019, sum)


piso2020 <- select(filter(piso, piso$year == 2020),
                   "Mes" = mes,
                   "Facturado" = importecrg,
                   "Cant Dias" = dias)
piso2020$Mes <- meses[ piso2020$Mes  ]

piso2020 <- aggregate(.~Mes, piso2020, sum)


FacturadoPAMI <- dbGetQuery(con, "SELECT 
                                      CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
                                      CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as factura,
                                      c.comprobantefechaemision as emision,
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
                                    
                                    
                                    WHERE obsocialescodigo IN ('90001199', '90001162') and
                                          c.comprobantetipoentidad = 2 and
                                          c.comprobantefechaemision > '2019-01-01' and
                                          c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') and
                                          (a.comprobanteasoctipo IS NULL OR a.comprobanteasoctipo = 'RECX2') and
                                          comprobantecrgdetpractica IN ('4.01', '4.02', '4.03', '4.04', '4.05', '4.06', '4.09', '4.10', '5.0', '60.09', '60.10', '4.08', '60.10','60.11', '60.12')")

FacturadoPAMI$comprobantecrgdetpractica <- gsub(" ", "", FacturadoPAMI$comprobantecrgdetpractica, fixed = TRUE)



pisoPAMI <- filter(FacturadoPAMI, FacturadoPAMI$comprobantecrgdetpractica %in% c('4.01', '4.02', '4.03', '4.04', '4.05', '4.06', '4.09', '4.10', '5.0', '60.09', '60.10'))

chauPAMI <- filter(pisoPAMI, pisoPAMI$emision < '2020-08-01')
chauPAMI <- filter(chauPAMI, chauPAMI$comprobantecrgdetpractica == '60.10')

pisoPAMI <- anti_join(pisoPAMI, chauPAMI)
pisoPAMI$year <- year(pisoPAMI$emision)
pisoPAMI$mes <- month(pisoPAMI$emision)

piso2019PAMI <- select(filter(pisoPAMI, pisoPAMI$year == 2019),
                   "Mes" = mes,
                   "Facturado" = importecrg,
                   "Cant Dias" = dias)
piso2019PAMI$Mes <- meses[ piso2019PAMI$Mes  ]

piso2019PAMI <- aggregate(.~Mes, piso2019PAMI, sum)


piso2020PAMI <- select(filter(pisoPAMI, pisoPAMI$year == 2020),
                   "Mes" = mes,
                   "Facturado" = importecrg,
                   "Cant Dias" = dias)
piso2020PAMI$Mes <- meses[ piso2020PAMI$Mes  ]

piso2020PAMI <- aggregate(.~Mes, piso2020PAMI, sum)




Debitos <- dbGetQuery(con, "SELECT 
                                      CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
                                      CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as factura,
                                      c.comprobantefechaemision as emision,
                                      comprobantecrgdetimporteacredi as acredita,
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
                                          c.comprobantefechaemision > '2019-01-01' and
                                          c.tipocomprobantecodigo IN ('NCA', 'NCB', 'NCECA') and
                                          comprobantecrgdetpractica IN ('4.01', '4.02', '4.03', '4.04', '4.05', '4.06', '4.09', '4.10', '5.0', '60.09', '60.10', '4.08', '60.10','60.11', '60.12')")
Debitos$comprobantecrgdetpractica <- gsub(" ", "", Debitos$comprobantecrgdetpractica, fixed = TRUE)

pisodeb <- filter(Debitos, Debitos$comprobantecrgdetpractica %in% c('4.01', '4.02', '4.03', '4.04', '4.05', '4.06', '4.09', '4.10', '5.0', '60.09', '60.10'))

chaudeb <- filter(pisodeb, pisodeb$emision < '2020-08-01')
chaudeb <- filter(chaudeb, chaudeb$comprobantecrgdetpractica == '60.10')

pisodeb <- anti_join(pisodeb, chaudeb)
pisodeb$year <- year(pisodeb$emision)
pisodeb$mes <- month(pisodeb$emision)

pisodeb2019 <- select(filter(pisodeb, pisodeb$year == 2019),
                       "Mes" = mes,
                       "Facturado" = acredita,
                       "Cant Dias" = dias)
pisodeb2019$Mes <- meses[ pisodeb2019$Mes  ]

pisodeb2019 <- aggregate(.~Mes, pisodeb2019, sum)


pisodeb2020 <- select(filter(pisodeb, pisodeb$year == 2020),
                       "Mes" = mes,
                       "Facturado" = acredita,
                       "Cant Dias" = dias)
pisodeb2020$Mes <- meses[ pisodeb2020$Mes  ]

pisodeb2020 <- aggregate(.~Mes, pisodeb2020, sum)



DebitosPAMI <- dbGetQuery(con, "SELECT 
                                      CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
                                      CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as factura,
                                      c.comprobantefechaemision as emision,
                                       comprobantecrgdetimporteacredi as acredita,
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
                                    
                                    
                                    WHERE obsocialescodigo IN ('90001199', '90001162') and
                                          c.comprobantetipoentidad = 2 and
                                          c.comprobantefechaemision > '2019-01-01' and
                                          c.tipocomprobantecodigo IN ('NCA', 'NCB', 'NCECA') and
                                          comprobantecrgdetpractica IN ('4.01', '4.02', '4.03', '4.04', '4.05', '4.06', '4.09', '4.10', '5.0', '60.09', '60.10', '4.08', '60.10','60.11', '60.12')")

DebitosPAMI$comprobantecrgdetpractica <- gsub(" ", "", DebitosPAMI$comprobantecrgdetpractica, fixed = TRUE)



debPAMI <- filter(DebitosPAMI, DebitosPAMI$comprobantecrgdetpractica %in% c('4.01', '4.02', '4.03', '4.04', '4.05', '4.06', '4.09', '4.10', '5.0', '60.09', '60.10'))

chauPAMI <- filter(debPAMI, debPAMI$emision < '2020-08-01')
chauPAMI <- filter(chauPAMI, chauPAMI$comprobantecrgdetpractica == '60.10')

debPAMI <- anti_join(debPAMI, chauPAMI)
debPAMI$year <- year(debPAMI$emision)
debPAMI$mes <- month(debPAMI$emision)

deb2019PAMI <- select(filter(debPAMI, debPAMI$year == 2019),
                       "Mes" = mes,
                       "Facturado" = importecrg,
                       "Cant Dias" = dias)
deb2019PAMI$Mes <- meses[ deb2019PAMI$Mes  ]

deb2019PAMI <- aggregate(.~Mes, deb2019PAMI, sum)


deb2020PAMI <- select(filter(debPAMI, debPAMI$year == 2020),
                       "Mes" = mes,
                       "Facturado" = importecrg,
                       "Cant Dias" = dias)
deb2020PAMI$Mes <- meses[ deb2020PAMI$Mes  ]

deb2020PAMI <- aggregate(.~Mes, deb2020PAMI, sum)

