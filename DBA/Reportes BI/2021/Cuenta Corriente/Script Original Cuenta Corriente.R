########################################### LIBRERIAS ########################################################

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
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname="facoep",host="localhost",port="5432",user="odoo",password="odoo")

rm(pw)
meses <- c("01 - Enero","02 - Febrero","03 - Marzo",
           "04 - Abril","05 - Mayo","06 - Junio",
           "07 - Julio","08 - Agosto","09 - Septiembre",
           "10 - Octubre","11 - Noviembre","12 - Diciembre")
alafecha <- as.Date(Sys.Date())
realizacion <- Sys.time()
postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")

############################################################################################################

data <- dbGetQuery(con, "SELECT	
	CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
  CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as Factura,
  h.entrega,
  c.comprobantetotalimporte,
  CAST(recs.comprobanteimputaciontipo AS TEXT) || ' - ' || CAST(recs.comprobanteimputacioncodigo AS TEXT) as Recibo,
  recs.fechaimputacion,
  CASE WHEN c.comprobanteintimacion = TRUE THEN 'Intimado' ELSE 'No Intimado' END AS Intimacion,
CASE WHEN c.comprobantemandatario = TRUE THEN 'Mandatario' ELSE 'No Mandatario' END AS Mandatario
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
	comprobanteimputacioncodigo,
	comprobanteimputacionfecha as fechaimputacion,
	sum(comprobanteimputacionimporte) as cobrado
	
	FROM comprobantesimputaciones 
	WHERE comprobanteimputaciontipo = 'RECX2' and tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA') and comprobanteimputacionfecha > '2017-01-01' 
	GROUP BY comprobanteentidadcodigo, comprobanteimputacionfecha, tipocomprobantecodigo, comprobantecodigo, comprobanteimputaciontipo, comprobanteimputacioncodigo
	ORDER By comprobantecodigo) as recs ON recs.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
											recs.tipocomprobantecodigo = c.tipocomprobantecodigo and
											recs.comprobantecodigo = c.comprobantecodigo
											
   
  WHERE c.comprobantefechaemision > '2017-01-01' and 
        c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') and c.comprobantetipoentidad = 2 and c.comprobantedetalle NOT LIKE 'ANULADO%' and c.comprobantesaldo > 0
		order by c.comprobantefechaemision")

data <- filter(data, os != "1003 - OSPAÃ'A")
data <- filter(data, os != "1 - I.N.S.S.J. y P.")
data$DetalleOsNoEntregadas <- ifelse(data$os == "1069 - INCLUIR SALUD BS AS", "Incluir Prov.", 
                                     ifelse(data$os == "1 - FACOEP - PAMI", "PAMI", "Otras O.S.")) 
# Fecha de Vencimiento
data$vencimiento <- data$entrega + 30

# vencimiento = dia del mes en curso + dias restantes para llegar para llegar al ultimo dia + 60

# Entregada?
data$entregada <- ifelse(is.na(data$entrega), "Fc No Entregadas", "Entregada")

# Solo las adeudadas
data <- filter(data, is.na(recibo))

# Tipos de Deuda
data$tipodeuda <- ifelse(difftime(Sys.Date(), data$entrega, units = "days") > 60, "Deuda Vencida", 
                         ifelse(difftime(Sys.Date(), data$entrega, units = "days") == 60, "Deuda Corriente", "A Vencer"))

data$tipodeuda <- ifelse(is.na(data$tipodeuda), data$entregada, data$tipodeuda)
data$tipovencida <- ifelse(data$mandatario == "Mandatario", "Mandatario", data$intimacion)

FacoDeuda <- select(data, 
                    "O.S." = os,
                    "Factura" = factura,
                    "Entregada" = entregada,
                    "Fecha Entrega" = entrega,
                    "Fecha Vencimiento" = vencimiento,
                    "Tipo Deuda" = tipodeuda,
                    "Intimacion" = intimacion,"Importe" = comprobantetotalimporte, "DetalleOsNoEntregadas" = DetalleOsNoEntregadas, "TipoVencida" = tipovencida)