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
con <- dbConnect(drv, dbname="facoep",host="172.31.24.12",port="5432",user="postgres",password="facoep2017")

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
CAST(nota.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(nota.comprobantecodigo AS TEXT) as nota,
CAST(nota.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(os.obsocialessigla AS TEXT) as OS,
hosp.pprnombre as Efector,
crgs.comprobantecrgnro as CRG,
--crgdetnumerocph as DPH,
mot.motivodebitodescripcion as TipoDebito,
cat.motivodebitocategorianombre as Categoria,
dets.comprobantecrgdetmotivodescrip as Observaciones,
ComprobanteCRGDetImporteDebita as Rechazado,
ComprobanteCRGDetImporteAcredi as Aceptado,
dets.comprobantecrgdetpractica as codigo


					
FROM COMPROBANTES nota 

LEFT JOIN COMPROBANTECRG crgs ON	crgs.empcod = nota.empcod and 
					crgs.sucursalcodigo = nota.sucursalcodigo and
					crgs.comprobantetipoentidad = nota.comprobantetipoentidad and
					crgs.comprobanteentidadcodigo = nota.comprobanteentidadcodigo and
					crgs.tipocomprobantecodigo = nota.tipocomprobantecodigo and
					crgs.comprobanteprefijo = nota.comprobanteprefijo and
					crgs.comprobantecodigo = nota.comprobantecodigo

LEFT JOIN COMPROBANTECRGDET dets ON 	dets.empcod = crgs.empcod and 
					dets.sucursalcodigo = crgs.sucursalcodigo and
					dets.comprobantetipoentidad = crgs.comprobantetipoentidad and
					dets.comprobanteentidadcodigo = crgs.comprobanteentidadcodigo and
					dets.tipocomprobantecodigo = crgs.tipocomprobantecodigo and
					dets.comprobanteprefijo = crgs.comprobanteprefijo and
					dets.comprobantecodigo = crgs.comprobantecodigo and
					dets.comprobantepprid = crgs.comprobantepprid and
					dets.comprobantecrgnro = crgs.comprobantecrgnro
					
LEFT JOIN proveedorprestador hosp ON 	hosp.pprid = dets.comprobantepprid

LEFT JOIN motivodebito mot ON mot.motivodebitoid = dets.comprobantecrgdetmotivodebcred

LEFT JOIN motivodebitocategoria cat ON cat.motivodebitoid = dets.comprobantecrgdetmotivodebcred and
										cat.motivodebitocategoriaid = dets.comprobantecrgdetmotdebcredcat

LEFT JOIN obrassociales os ON os.obsocialesclienteid = nota.comprobanteentidadcodigo

--LEFT JOIN crgdet cd ON cd.pprid = dets.comprobantepprid and cd.crgnum = dets.comprobantecrgnro and cd.crgdetid = dets.comprobantecrgdetid

WHERE  
	nota.comprobantefechaemision BETWEEN '2021-01-01' and '2021-06-30' and
	comprobantecrgdetmotivodebcred = 11 and nota.tipocomprobantecodigo = 'NOTADB'
")

data <- unique(data)



write.csv(data, "data.csv")
