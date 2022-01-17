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
alafecha <- as.Date(Sys.Date())
realizacion <- Sys.time()
####################################### TOTAL DE AUTOR/INTERN QUE TIENEN OP EN CABECERA O PRACTICA #############  
AMBULATORIOSCAB <- dbGetQuery(con, "SELECT

                         CASE WHEN A.AUTORIZACIONEMISOR IS NULL THEN 'FACOEP' ELSE B.PPRNOMBRE END AS EMISOR,
                         A.AUTORIZACIONNROORDEN AS NUM,
                         AUTORIZACIONPRESTORDEN AS OP,
                         autorizacionprestordenemision as fechaemisionop,
                         autorizacionfecha AS FECHAautorizacion,
                         autorizacionprestordenactivaci as fechaactivacion,
                         case when autorizacionfechabaja IS NOT NULL THEN 'ANULADO' ELSE '' END AS estado

 
                         FROM 
                         
                         AUTORIZACION AS A
                         LEFT JOIN PROVEEDORPRESTADOR AS B ON A.AUTORIZACIONEMISOR = B.PPRID
                         WHERE autorizacionfecha >= '2020-01-17' AND
                         AUTORIZACIONPRESTORDEN > 0
 
                         ORDER BY
                         EMISOR")

AMBULATORIOSDET <- dbGetQuery(con, "SELECT
                         CASE WHEN A.AUTORIZACIONEMISOR IS NULL THEN 'FACOEP' ELSE B.PPRNOMBRE END AS EMISOR,
                         A.AUTORIZACIONNROORDEN AS NUM,
                         autorizacionlineaop AS OP,
                         autorizacionlineaopemision as fechaemisionop,
                         autorizacionfecha AS FECHAautorizacion,
                         autorizacionlineaopactivacion as fechaactivacion,
                         case when autorizacionfechabaja IS NOT NULL THEN 'ANULADO' ELSE '' END AS estado
                         
                         FROM 
                         
                         AUTORIZACION AS A
                         LEFT JOIN PROVEEDORPRESTADOR AS B ON A.AUTORIZACIONEMISOR = B.PPRID
                         LEFT JOIN AUTORIZACIONLINEA L ON L.autorizacionnroorden = A.autorizacionnroorden
 

                         
                         WHERE autorizacionfecha >= '2020-01-17' AND
                         autorizacionlineaop > 0
                          
                         
                         ORDER BY
                         
                         EMISOR")

AMBULATORIOSDET <- unique(AMBULATORIOSDET)

AMBULATORIOS <- rbind(AMBULATORIOSCAB, AMBULATORIOSDET)

AMBULATORIOS <- unique(AMBULATORIOS)

AMBULATORIOS$estado <- ifelse(is.na(AMBULATORIOS$fechaactivacion), "CARGADO", ifelse(AMBULATORIOS$estado == "ANULADO", "ANULADO", "ACTIVADO"))

AMBULATORIOS$tipo <- "AMBULATORIO"


INTERNACIONESCAB <- dbGetQuery(con, "SELECT

                         CASE WHEN A.informehospefectorid IS NULL THEN 'FACOEP' ELSE B.PPRNOMBRE END AS EMISOR,
                         informehospnro AS NUM,
                         informehospprestorden AS OP,
                         informehospprestordenemision as fechaemisionop,
                         informehospaltafecha AS FECHAautorizacion,
                         informehospprestordenactivacio as fechaactivacion,
 case when informehospbajafecha IS NOT NULL THEN 'ANULADO' ELSE '' END AS estado
                         
                         FROM 
                         
                         informehosp as A
                         LEFT JOIN PROVEEDORPRESTADOR AS B ON A.informehospefectorid = B.PPRID
                         WHERE informehospaltafecha >= '2020-01-17' AND
                         informehospprestorden > 0
 
                         ORDER BY
                         EMISOR")

INTERNACIONESCAB <- unique(INTERNACIONESCAB)


INTERNACIONESDET <- dbGetQuery(con, "SELECT
                         CASE WHEN A.informehospefectorid IS NULL THEN 'FACOEP' ELSE B.PPRNOMBRE END AS EMISOR,
                         A.informehospnro AS NUM,
                         informehosplineaop AS OP,
                         informehosplineaopemision as fechaemisionop,
                         informehosplineafechaalta AS FECHAautorizacion,
                         informehosplineaopactivacion as fechaactivacion,
                         case when informehospbajafecha IS NOT NULL THEN 'ANULADO' ELSE '' END AS estado
                         
                         
                         FROM 
                         
                         informehosp as A
                         LEFT JOIN PROVEEDORPRESTADOR AS B ON A.informehospefectorid = B.PPRID
                         LEFT JOIN informehosplinea L ON L.informehospnro = A.informehospnro
 

                         
                         WHERE informehospaltafecha >= '2020-01-17' AND
                         informehosplineaop > 0
                          
                         
                         ORDER BY
                         
                         EMISOR")

INTERNACIONESDET <- unique(INTERNACIONESDET)
INTERNACIONES <- rbind(INTERNACIONESCAB, INTERNACIONESDET)
INTERNACIONES <- unique(INTERNACIONES)
INTERNACIONES$tipo <- "INTERNACION"
INTERNACIONES$estado <- ifelse(is.na(INTERNACIONES$fechaactivacion), "CARGADO", ifelse(INTERNACIONES$estado == "ANULADO", "ANULADO", "ACTIVADO"))


OPS <- rbind(AMBULATORIOS, INTERNACIONES)

OPS <- filter(OPS, OPS$op > 0)

OPS <- unique(OPS)

OPS <- select(OPS,
              "Tipo" = tipo,
              "Emisor" = emisor,
              "Código" = num,
              "OP" = op,
              "Emision OP" = fechaemisionop, 
              "Fecha Remito" = fechaautorizacion,
              "Activación" = fechaactivacion,
                "Estado" = estado)

OPS$`Emision OP` <- ifelse(OPS$`Emision OP` == '1-01-01', NA, format(OPS$`Emision OP`, "%Y-%m-%d"))
OPS$Activación <- ifelse(OPS$Activación == '1-01-01', NA, format(OPS$Activación, "%Y-%m-%d"))
OPS$`Fecha Remito` <- ifelse(OPS$`Fecha Remito` == '1-01-01', NA, format(OPS$`Fecha Remito`, "%Y-%m-%d"))

OPS[is.na(OPS)] <- "Sin Fecha"
 
##################################################### EXCEL Y FORMATO ################################################################
wb <- createWorkbook()
letraytamaño <- createStyle(fontName = "Tahoma", fontSize = 9, numFmt="GENERAL",halign = "center", valign = "center")
titulos2 <- createStyle(fgFill = "#BABDB6", textDecoration = "bold", halign = "center", valign = "center", fontSize = 10,fontName = "Tahoma")
titulos3 <- createStyle(fgFill = "#C7C9C3",textDecoration = "bold", halign = "left", valign = "center", fontSize = 7,fontName = "Tahoma")
titulos4 <- createStyle(fgFill = "#BABDB6", textDecoration = "bold", halign = "center", valign = "center", fontSize = 9,fontName = "Tahoma")
titulos5 <- createStyle(fgFill = "#BABDB6", textDecoration = "bold", halign = "left", valign = "center", fontSize = 9,fontName = "Tahoma")
titulosdet <- createStyle(textDecoration = "bold", halign = "left", valign = "center", fontSize = 9,fontName = "Tahoma", border = "TopBottomLeftRight")
totales <- createStyle(textDecoration = "bold", halign = "right", valign = "center", fontSize = 9,fontName = "Tahoma")





addWorksheet(wb, "OP")
mergeCells(wb, "OP", rows = 1:2, cols = 1:8)
mergeCells(wb, "OP", rows = 3, cols = 1:8)
writeData(wb, "OP", "Autorizaciones/InformesHosp con OP en Cabecera o Detalle por Fecha Remito Octubre 2019 a Enero 2020", startCol = 1, startRow = 1)
writeData(wb, "OP", paste("Realización del reporte:", realizacion), startCol = 1, startRow = 3)
writeData(wb, "OP", OPS, colNames = T, startCol = 1, startRow = 4)
addStyle(wb, "OP", letraytamaño, rows = 1:(nrow(OPS)+4), cols = 1:8,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "OP", titulos2, rows = 1:2, cols = 1:8,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "OP", titulos3, rows = 3, cols = 1:8,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "OP", titulos4, rows = 4, cols = 1:8,gridExpand = TRUE, stack = FALSE)

setColWidths(wb, "OP", cols = 1:8, widths = "22")

saveWorkbook(wb, "OP desde 17.01.2020upd.xlsx", overwrite = T)

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
