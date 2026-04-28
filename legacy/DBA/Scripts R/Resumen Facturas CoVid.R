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
	CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
  	CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as Factura,
  	c.comprobantefechaemision,
  h.entrega,
  c.comprobantecovid AS covid,
  c.comprobantetotalimporte,
  recs.cobrado,
  cred.notacredito,
  debs.debitado

  

  
  FROM comprobantes c
  LEFT JOIN obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo
  LEFT JOIN (SELECT
                    comprobanteentidadcodigo,
                    tipocomprobantecodigo,
                    comprobantecodigo,
                    MAX(comprobantehisfechatramite) as entrega
                    FROM comprobanteshistorial 
                    WHERE comprobantehisestado = 4
                    GROUP BY comprobanteentidadcodigo, tipocomprobantecodigo, comprobantecodigo) as h ON h.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                                                                                   h.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                                                                                                   h.comprobantecodigo = c.comprobantecodigo
    
   LEFT JOIN (SELECT 	comprobanteentidadcodigo,			
	tipocomprobantecodigo,
	 comprobantecodigo,
	comprobanteimputaciontipo,
	sum(comprobanteimputacionimporte) as cobrado
	FROM comprobantesimputaciones 
	WHERE comprobanteimputaciontipo = 'RECX2' and tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA') and comprobanteimputacionfecha > '2020-01-01'
	GROUP BY comprobanteentidadcodigo, tipocomprobantecodigo, comprobantecodigo, comprobanteimputaciontipo
	ORDER By comprobantecodigo) as recs ON recs.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
											recs.tipocomprobantecodigo = c.tipocomprobantecodigo and
											recs.comprobantecodigo = c.comprobantecodigo
											
   LEFT JOIN (SELECT 	a.comprobanteentidadcodigo,			
	a.tipocomprobantecodigo,
	 a.comprobantecodigo,
	a.comprobanteasoctipo,
	sum(c.comprobantetotalimporte) as notacredito
	FROM comprobantesasociados a
	LEFT JOIN comprobantes c on a.comprobanteasoctipo = c.tipocomprobantecodigo and
								a.comprobanteasoccodigo = c.comprobantecodigo
	WHERE comprobanteasoctipo IN ('NCA','NCB', 'NCECA') and a.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA')
	GROUP BY a.comprobanteentidadcodigo, a.tipocomprobantecodigo, a.comprobantecodigo, a.comprobanteasoctipo
	ORDER By comprobantecodigo) as cred on cred.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
											cred.tipocomprobantecodigo = c.tipocomprobantecodigo and
											cred.comprobantecodigo = c.comprobantecodigo
	LEFT JOIN (SELECT 	a.comprobanteentidadcodigo,			
	a.tipocomprobantecodigo,
	 a.comprobantecodigo,
	a.comprobanteasoctipo,
	sum(c.comprobantetotalimporte) as debitado
	FROM comprobantesasociados a
	LEFT JOIN comprobantes c on a.comprobanteasoctipo = c.tipocomprobantecodigo and
								a.comprobanteasoccodigo = c.comprobantecodigo
	WHERE comprobanteasoctipo IN ('NDA','NDB', 'NDECA') and a.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA')
	GROUP BY a.comprobanteentidadcodigo, a.tipocomprobantecodigo, a.comprobantecodigo, a.comprobanteasoctipo
	ORDER By comprobantecodigo) as debs on debs.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
											debs.tipocomprobantecodigo = c.tipocomprobantecodigo and
											debs.comprobantecodigo = c.comprobantecodigo
  
  
                              
  WHERE c.comprobantefechaemision > '2019-01-01' and 
        c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') and c.comprobantetipoentidad = 2
		order by debs.debitado")


data <- filter(data, data$os != "1003 - OSPAÃ‘A")
data <- filter(data, data$os != "1 - I.N.S.S.J. y P.")

data <- filter(data, entrega > "2020-06-01" | is.na(data$entrega))

data$PeriodoEntrega <- data$entrega

day(data$PeriodoEntrega) <- days_in_month(data$PeriodoEntrega)

data$Vencimiento <- data$PeriodoEntrega + days(60)

data$año <- year(data$Vencimiento)

data$Vencimiento <- fifelse(is.na(data$año), "FC No Entregadas", 
                            ifelse(data$año == '2021', "Vtos. 2021", month(data$Vencimiento)))

data$Vencimiento <- ifelse(data$Vencimiento == 8, "08 Agosto",
                          ifelse(data$Vencimiento == 9, "09 Septiembre",
                                 ifelse(data$Vencimiento == 10, "10 Octubre",
                                        ifelse(data$Vencimiento == 11, "11 Noviembre",
                                               ifelse(data$Vencimiento == 12, "12 Diciembre", data$Vencimiento)))))


data$CoVid <- ifelse(data$covid == "TRUE", "CoVid", "No CoVid")

Detalle <- select(data, 
                      "Financiador" = os,
                      "Factura" = factura,
                      "Emision" = comprobantefechaemision,
                      "Entrega" = entrega,
                      "PeriodoEntrega" = PeriodoEntrega,
                      "CoVid" = CoVid,
                      "Vencimiento" = Vencimiento,
                      "Facturado" = comprobantetotalimporte,
                      "Debitado" = debitado,
                      "NotaCredito" = notacredito,
                      "Cobrado" = cobrado,
                      )
Detalle$Debitado <- ifelse(is.na(Detalle$Debitado), 0, Detalle$Debitado)
Detalle$NotaCredito <- ifelse(is.na(Detalle$NotaCredito), 0, Detalle$NotaCredito)
Detalle$Cobrado <- ifelse(is.na(Detalle$Cobrado), 0, Detalle$Cobrado)

write.csv(Detalle, "Detalle.csv")


Final <- select(data,
                  "CoVid" = CoVid,
                  "Vencimiento" = Vencimiento,
                  "Facturado" = comprobantetotalimporte,
                  "Debitado" = debitado,
                  "Nota Crédito" = notacredito,
                  "Cobrado" = cobrado)
Final[is.na(Final)] <- 0

Final <- aggregate(.~CoVid+Vencimiento, Final, sum)

write.csv(Final, "Reporte.csv")

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})


