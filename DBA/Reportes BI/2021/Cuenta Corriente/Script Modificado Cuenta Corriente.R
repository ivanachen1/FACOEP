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
library(BBmisc)
drv <- dbDriver("PostgreSQL")

alafecha <- as.Date(Sys.Date())
realizacion <- Sys.time()



########################################### CREDENCIALES SERVER ########################################################

workdirectory_one <- "C:/Users/iachenbach/Desktop/FACOEP/DBA/Reportes BI/2021/Cuenta Corriente"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranzas/Versión 7"

GetArchivoParametros <- function(){
  x = "parametros_servidor.xlsx"
  path_one <- workdirectory_one
  path_two <- workdirectory_two
  intento  <- is.error(try(read.xlsx(paste(path_two,x,sep = "/")),silent = F,outFile = "Error"))
  
  
  if(intento == TRUE){
    return(read.xlsx(paste(path_one,x,sep = "/")))} else {return(read.xlsx(paste(path_two,x,sep = "/")))}
}  

GetPassword <- function(x = archivo_parametros){
  pw <- filter(archivo_parametros,Parametros.servidor == "password")
  pw <- filter(pw,Usar == TRUE)
  pw <- pw$Valor
  return(pw)
}

GetUser <- function(x = archivo_parametros){
  user <- filter(archivo_parametros,Parametros.servidor == "user")
  user <- filter(user,Usar == TRUE)
  user <- user$Valor
  return(user)}

GetHost <- function(x = archivo_parametros){
  host <- filter(archivo_parametros,Parametros.servidor == "host")
  host <- filter(host,Usar == TRUE)
  host <- host$Valor
  return(host)}


GetFile <- function(file_name){
  path_one <- workdirectory_one
  path_two <- workdirectory_two
  intento  <- is.error(try(read.xlsx(paste(path_two,file_name,sep = "/")),silent = F,outFile = "Error"))

  if(intento == TRUE){
    return(read.xlsx(paste(path_one,file_name,sep = "/")))} else {return(read.xlsx(paste(path_two,file_name,sep = "/")))}
} 

TransformFile <- function(dataframe,FilterOne){
  dataframe <- subset(dataframe, tipo == FilterOne)
  dataframe <- data.frame(dataframe$Comprobante)
  return(dataframe)
}


archivo_parametros <- GetArchivoParametros()

pw <- GetPassword()

user <- GetUser()

host <- GetHost() 

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep",
                 host = host, port = 5432, 
                 user = user, password = pw)

postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")


########################################### ETL ##########################################################

query <- ("SELECT	
	CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
  CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(comprobanteprefijo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as Factura,
  c.tipocomprobantecodigo,
  h.entrega,
  c.comprobantetotalimporte,
  recs.comprobanteimputaciontipo,
  CAST(recs.comprobanteimputaciontipo AS TEXT) || ' - ' || CAST(recs.comprobanteimputacionprefijo AS TEXT) || ' - ' || CAST(recs.comprobanteimputacioncodigo AS TEXT) as Recibo,
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
	comprobanteimputacionprefijo,
	comprobanteimputacioncodigo,
	comprobanteimputacionfecha as fechaimputacion,
	sum(comprobanteimputacionimporte) as cobrado
	
	FROM comprobantesimputaciones
	WHERE comprobanteimputacionfecha > '2017-01-01'
	GROUP BY comprobanteentidadcodigo, comprobanteimputacionfecha, tipocomprobantecodigo, comprobantecodigo, comprobanteimputaciontipo,comprobanteimputacionprefijo,comprobanteimputacioncodigo
	ORDER By comprobantecodigo) as recs ON recs.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
											recs.tipocomprobantecodigo = c.tipocomprobantecodigo and
											recs.comprobantecodigo = c.comprobantecodigo
											
   
 WHERE c.comprobantefechaemision > '2017-01-01' and c.comprobantedetalle NOT LIKE 'ANULADO%' and c.comprobantesaldo > 0
		order by c.comprobantefechaemision")


data <- dbGetQuery(con,query)


data2 <- data

data2 <- subset(data2,tipocomprobantecodigo %in% facturas)


# Fecha de Vencimiento
data$vencimiento <- data$entrega + 30

unique(data$vencimiento)
# Entregada?

# Solo las adeudadas
data <- filter(data, is.na(recibo))

# dias transcurridos desde la entrega al vencimiento

data$dias <- difftime(Sys.Date(), data$entrega, units = "days")

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