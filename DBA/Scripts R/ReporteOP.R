library(RPostgreSQL)
library(data.table)
library(tidyverse)
library(stringr)
library(openxlsx)
library(scales)
library(formattable)
library(dplyr)
library(plyr)
library(zoo)
caption <- "FACOEP S.E. - Ministerio de Salud GCBA"
M <- 1000000
pw <- {"facoep2017"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep", host = "172.31.24.12", port = 5432, user = "postgres", password = pw)
rm(pw)
dbExistsTable(con, "afiliado")
wb <- createWorkbook()



INTERNACIONES <- dbGetQuery(con, "SELECT 
--DATOS INTERNACION
CASE WHEN informehospefectorid IS NULL THEN 'FACOEP' ELSE PPRNOMBRE END AS EMISOR,
informehospnro as NroInternacion,
informehospaltafecha as FechaInternacion,
--DATOS OP
informehospprestorden as NroOP,
informehospprestordenemision as EmisionOP,
informehospprestordenactivacio as ActivacionOP

FROM informehosp h
LEFT JOIN proveedorprestador on pprid = informehospefectorid

WHERE informehospprestordenemision > '2020-01-01' and informehospprestorden > 0")


AMBULATORIOS <- dbGetQuery(con, "SELECT 

--DATOS AUTORIZACION
CASE WHEN AUTORIZACIONEMISOR IS NULL THEN 'FACOEP' ELSE PPRNOMBRE END AS EMISOR,
A.autorizacionnroorden as NroAutorizacion,
autorizacionfecha as FechaAutorizacion,
CASE WHEN autorizacionmodo = 1 THEN 'Capitada' ELSE '' END
||
CASE WHEN autorizacionmodo = 2 THEN 'ExtraCapita' ELSE '' END 
||
CASE WHEN autorizacionmodo = 3 THEN 'ExtraCapita' ELSE '' END as Modo,
--DATOS OP
autorizacionprestorden as NroOP,
autorizacionprestordenemision as EmisionOP,
autorizacionprestordenactivaci as ActivacionOP,
autorizacionlineanomenclador as Practica,
--ANULADO?
autorizacionfechabaja as Anulado

FROM autorizacion A
LEFT JOIN proveedorprestador on pprid = AUTORIZACIONEMISOR
LEFT JOIN autorizacionlinea as L on A.autorizacionnroorden = L.autorizacionnroorden
                                    LEFT JOIN nomenclador as N ON L.autorizacionlineanomenclador = N.nomencladorcodigo
                                    
WHERE autorizacionfecha between '2020-10-01' and '2021-05-31' and autorizacionprestorden > 0 and a.afitpamiprofe = 1")

wb <- createWorkbook()
addWorksheet(wb, "Internaciones (InformeHosp)", gridLines = TRUE)
writeData(wb, "Internaciones (InformeHosp)", INTERNACIONES, rowNames = FALSE)
addWorksheet(wb, "Ambulatorio (Autorizaciones)", gridLines = TRUE)
writeData(wb, "Ambulatorio (Autorizaciones)", AMBULATORIOS, rowNames = FALSE)

saveWorkbook(wb, "OP.xlsx", overwrite = TRUE)
