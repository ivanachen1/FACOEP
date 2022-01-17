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


### PAMI ###

####################################### TOTAL DE AUTOR/INTERN QUE TIENEN OP EN CABECERA O PRACTICA #############  
AMBULATORIOS <- dbGetQuery(con, "SELECT DISTINCT
A.autorizacionnroorden AS CODIGO,
autorizacionlineaid as ID,
autorizacionfecha AS FECHA,
CASE WHEN A.AUTORIZACIONEMISOR IS NULL THEN 'FACOEP' ELSE B.PPRNOMBRE END AS EMISOR,
CASE WHEN A.AUTORIZACIONSOLICITANTE IS NULL THEN 'FACOEP' ELSE C.PPRNOMBRE END AS SOLICITANTE,
CASE WHEN AUTORIZACIONTIPO = 1 THEN 'AMBULATORIO' ELSE 'AMBULATORIO' END AS TIPO,
CASE WHEN A.AFITPAMIPROFE = 1 THEN 'PAMI' ELSE '' END 
|| CASE WHEN A.AFITPAMIPROFE = 2 THEN 'INCLUIR' ELSE '' END 
|| CASE WHEN A.AFITPAMIPROFE = 3 THEN 'INCLUIR SALUD PROV 4' ELSE '' END AS PAMI,
CASE WHEN CAP.afiliadocapitamodo = 1 THEN 'RED FACOEP (CAP)' ELSE '' END
|| CASE WHEN CAP.AFILIADOCAPITAMODO = 2 THEN 'OTRA UGP (EXTCAP)' ELSE '' END AS CAPITA,
A.AFINUMBENEFICIO AS NUMBENEFICIO, 
A.AFINUMBENID AS BENEFICIOID, 
AFISEXO AS SEXO,
AFIFECNACIMIENTO AS NACIMIENTO,
diagdescripcion AS DIAGNOSTICO,
NOMENCLADORNOMBRE AS PRACTICA,
AUTORIZACIONLINEACANTIDAD AS CANTIDAD,
AUTORIZACIONPRESTORDEN AS OP,
AUTORIZACIONLINEAOP AS OPPRACTICA

FROM 

AUTORIZACION AS A
LEFT JOIN AUTORIZACIONLINEA AS L ON L.AUTORIZACIONNROORDEN = A.AUTORIZACIONNROORDEN
LEFT JOIN PROVEEDORPRESTADOR AS B ON A.AUTORIZACIONEMISOR = B.PPRID
LEFT JOIN PROVEEDORPRESTADOR AS C ON A.AUTORIZACIONSOLICITANTE = C.PPRID
NATURAL JOIN AFILIADO AS F
LEFT JOIN AFILIADOCAPITA AS CAP ON CAP.afinumbeneficio = F.AFINUMBENEFICIO
NATURAL JOIN DIAGNOSTICOS
INNER JOIN PROVEEDORPRESTADOR AS D ON A.AUTORIZACIONPRESTADOR = D.PPRID
INNER JOIN NOMENCLADOR AS N ON L.AUTORIZACIONLINEANOMENCLADOR = N.NOMENCLADORCODIGO

WHERE 
A.AFITPAMIPROFE = 1 AND autorizacionfecha > '2020-01-01'")
AMBULATORIOS <- AMBULATORIOS %>% distinct(codigo, id, .keep_all = TRUE)

INTERNACIONES <- dbGetQuery(con, "SELECT DISTINCT
A.informehospnro AS CODIGO,
informehosplineaid as ID,
informehospingresofechahora AS FECHA,
CASE WHEN A.informehospemisorid IS NULL THEN 'FACOEP' ELSE B.PPRNOMBRE END AS EMISOR,
CASE WHEN A.informehospsolicitante IS NULL THEN 'FACOEP' ELSE C.PPRNOMBRE END AS SOLICITANTE,
CASE WHEN informehospinternaciontipo = 1 THEN 'INTERNACION' ELSE 'INTERNACION' END AS TIPO,
CASE WHEN A.AFITPAMIPROFE = 1 THEN 'PAMI' ELSE '' END 
|| CASE WHEN A.AFITPAMIPROFE = 2 THEN 'INCLUIR' ELSE '' END 
|| CASE WHEN A.AFITPAMIPROFE = 3 THEN 'INCLUIR SALUD PROV 4' ELSE '' END AS PAMI,
CASE WHEN CAP.afiliadocapitamodo = 1 THEN 'RED FACOEP (CAP)' ELSE '' END
|| CASE WHEN CAP.AFILIADOCAPITAMODO = 2 THEN 'OTRA UGP (EXTCAP)' ELSE '' END AS CAPITA,
A.AFINUMBENEFICIO AS NUMBENEFICIO, 
A.AFINUMBENID AS BENEFICIOID, 
AFISEXO AS SEXO,
AFIFECNACIMIENTO AS NACIMIENTO,
diagdescripcion AS DIAGNOSTICO,
NOMENCLADORNOMBRE AS PRACTICA,
informehosplineacantidad AS CANTIDAD,
informehospprestorden AS OP,
informehosplineaop AS OPPRACTICA

FROM 

informehosp AS A
LEFT JOIN informehosplinea AS L ON L.informehospnro = A.informehospnro
LEFT JOIN PROVEEDORPRESTADOR AS B ON A.informehospemisorid = B.PPRID
LEFT JOIN PROVEEDORPRESTADOR AS C ON A.informehospsolicitante = C.PPRID
NATURAL JOIN AFILIADO AS F
LEFT JOIN AFILIADOCAPITA AS CAP ON CAP.afinumbeneficio = F.AFINUMBENEFICIO
LEFT JOIN DIAGNOSTICOS as d ON d.diagcodigo = a.informehospdiagprincipalid
INNER JOIN NOMENCLADOR AS N ON L.nomencladorcodigo = N.NOMENCLADORCODIGO

WHERE 
A.AFITPAMIPROFE = 1 AND informehospingresofechahora > '2020-01-01'")
INTERNACIONES <- INTERNACIONES %>% distinct(codigo, id, .keep_all = TRUE)

PAMI <- rbind(AMBULATORIOS, INTERNACIONES)

PAMI <- select(PAMI,
               "Codigo" = codigo,
               "ID" = id,
               "Fecha" = fecha,
               "Emisor" = emisor,
               "Solicitante" = solicitante,
               "Tipo" = tipo,
               "PAMI" = pami,
               "Capita" = capita,
               "Num. Beneficio" = numbeneficio,
               "ID Beneficio" = beneficioid,
               "Sexo" = sexo,
               "Nacimiento" = nacimiento,
               "Diagnostico" = diagnostico,
               "Practica" = practica,
               "Cantidad" = cantidad,
               "OP Cabecera" = op,
               "OP Practica" = oppractica)
addWorksheet(wb, "PAMI", gridLines = TRUE)
writeData(wb, "PAMI", PAMI, startCol = 1,  startRow = 1)


#### OP SIF #####

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
              "Codigo" = num,
              "OP" = op,
              "Emision OP" = fechaemisionop, 
              "Fecha Remito" = fechaautorizacion,
              "Activacion" = fechaactivacion,
              "Estado" = estado)

OPS$`Emision OP` <- ifelse(OPS$`Emision OP` == '1-01-01', NA, format(OPS$`Emision OP`, "%Y-%m-%d"))
OPS$Activacion <- ifelse(OPS$Activacion == '1-01-01', NA, format(OPS$Activacion, "%Y-%m-%d"))
OPS$`Fecha Remito` <- ifelse(OPS$`Fecha Remito` == '1-01-01', NA, format(OPS$`Fecha Remito`, "%Y-%m-%d"))

OPS[is.na(OPS)] <- "Sin Fecha"

##################################################### EXCEL Y FORMATO ################################################################
letraytamano <- createStyle(fontName = "Tahoma", fontSize = 9, numFmt="GENERAL",halign = "center", valign = "center")
titulos2 <- createStyle(fgFill = "#BABDB6", textDecoration = "bold", halign = "center", valign = "center", fontSize = 10,fontName = "Tahoma")
titulos3 <- createStyle(fgFill = "#C7C9C3",textDecoration = "bold", halign = "left", valign = "center", fontSize = 7,fontName = "Tahoma")
titulos4 <- createStyle(fgFill = "#BABDB6", textDecoration = "bold", halign = "center", valign = "center", fontSize = 9,fontName = "Tahoma")
titulos5 <- createStyle(fgFill = "#BABDB6", textDecoration = "bold", halign = "left", valign = "center", fontSize = 9,fontName = "Tahoma")
titulosdet <- createStyle(textDecoration = "bold", halign = "left", valign = "center", fontSize = 9,fontName = "Tahoma", border = "TopBottomLeftRight")
totales <- createStyle(textDecoration = "bold", halign = "right", valign = "center", fontSize = 9,fontName = "Tahoma")





addWorksheet(wb, "OP SIF")
mergeCells(wb, "OP SIF", rows = 1:2, cols = 1:8)
mergeCells(wb, "OP SIF", rows = 3, cols = 1:8)
writeData(wb, "OP SIF", "Autorizaciones/InformesHosp con OP en Cabecera o Detalle por Fecha Remito Octubre 2019 a Enero 2020", startCol = 1, startRow = 1)
writeData(wb, "OP SIF", paste("Realizacion del reporte:", realizacion), startCol = 1, startRow = 3)
writeData(wb, "OP SIF", OPS, colNames = T, startCol = 1, startRow = 4)
addStyle(wb, "OP SIF", letraytamano, rows = 1:(nrow(OPS)+4), cols = 1:8,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "OP SIF", titulos2, rows = 1:2, cols = 1:8,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "OP SIF", titulos3, rows = 3, cols = 1:8,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "OP SIF", titulos4, rows = 4, cols = 1:8,gridExpand = TRUE, stack = FALSE)

setColWidths(wb, "OP SIF", cols = 1:8, widths = "22")

#####

### Auditoria Medica ###

############################################################################################################
CONSULTA <- dbGetQuery(con, "SELECT crgfchemision,crgauditoriamedicafecha,crgdetfechaalta,
                                    crgauditoriamedicausuario, crgdetnumerocph,
                                    c.crgnum, crgdetmotivodebcred, 
                            crgdetmotivodescripcion, crgimpbrutooriginal, crgimpbruto, crgdetimportefacturar,
                            (SELECT MAX(crghistorialfecha) FROM crghistorial WHERE crghistorial.crgnum = c.crgnum AND crghistorial.pprid = c.pprid AND crghistorialestado = 3 AND crghistorialcod >= 2 AND crghistorialfecha > '2020-01-01') AS auditoria
                            FROM crg c
                            LEFT JOIN crgdet cd ON c.crgnum = cd.crgnum and c.pprid = cd.pprid
                            ")
CONSULTA <- filter(CONSULTA, !is.na(auditoria))
CONSULTA<- filter(CONSULTA, CONSULTA$crgauditoriamedicausuario %in% c("ABARE                         ", 
                                                                      "ALROMBOLA                     ", 
                                                                      "SSOCOLINSKY                   ", 
                                                                      "NCARBALLAL                    ", 
                                                                      "OPORFILIO                     ", 
                                                                      "DTRANSTENVOT                  ", 
                                                                      "NDIAZ                         ", 
                                                                      "MELMEAUDY                     ", 
                                                                      "FACUÃ'A                        ",
                                                                      "GMOURE                        "))
CONSULTA$crgauditoriamedicausuario <- ifelse(CONSULTA$crgauditoriamedicausuario == "FACUÃ'A                        ", "FACUÑA", CONSULTA$crgauditoriamedicausuario)
CONSULTA$crgdetfechaalta <- as.Date(CONSULTA$crgdetfechaalta)
CONSULTA$auditoria <- as.Date(CONSULTA$auditoria)
CONSULTA$crgauditoriamedicafecha <- fifelse(CONSULTA$crgauditoriamedicafecha == "0001-01-01", CONSULTA$auditoria, CONSULTA$crgauditoriamedicafecha)
CONSULTA$crgauditoriamedicafecha <- fifelse(is.na(CONSULTA$crgauditoriamedicafecha), CONSULTA$auditoria, CONSULTA$crgauditoriamedicafecha)
CONSULTA$crgauditoriamedicafecha <- fifelse(CONSULTA$crgauditoriamedicafecha < "2020-01-01", CONSULTA$auditoria, CONSULTA$crgauditoriamedicafecha)

AuditoriaMedica <- select(CONSULTA, "FechaAuditoriaMedica" = crgauditoriamedicafecha,
                          "Auditor" = crgauditoriamedicausuario,
                          "CRG" = crgnum,
                          "DPH" = crgdetnumerocph,
                          "Agrega" = crgdetmotivodebcred,
                          "AgregadoImporte" = crgdetimportefacturar,
                          "ImporteFinal" = crgimpbruto)

AuditoriaMedica <- aggregate(.~FechaAuditoriaMedica+Auditor+CRG+DPH+Agrega+ImporteFinal, AuditoriaMedica, sum)
AuditoriaMedica$AgregadoImporte <- ifelse(AuditoriaMedica$Agrega == 42, AuditoriaMedica$AgregadoImporte, 0)
AuditoriaMedica$Agrega <- NULL
AuditoriaMedica <- aggregate(.~FechaAuditoriaMedica+Auditor+CRG+DPH+ImporteFinal, AuditoriaMedica, sum)

AuditoriaMedica$CantidadDPH <- 1
AuditoriaMedica$DPH <- NULL

AuditoriaMedica <- aggregate(.~FechaAuditoriaMedica+Auditor+CRG+ImporteFinal, AuditoriaMedica, sum)

AuditoriaMedica$ImporteOriginal <- AuditoriaMedica$ImporteFinal - AuditoriaMedica$AgregadoImporte

AuditoriaMedica$CantidadCRG <- 1
AuditoriaMedica$CRG <- NULL
AuditoriaMedica <- aggregate(.~FechaAuditoriaMedica+Auditor, AuditoriaMedica, sum)

AuditoriaMedica <- select(AuditoriaMedica,
                          "Fecha" = FechaAuditoriaMedica,
                          Auditor,
                          CantidadCRG, CantidadDPH,
                          ImporteOriginal,
                          AgregadoImporte,
                          ImporteFinal)

addWorksheet(wb, "Auditoria Medica", gridLines = TRUE)
writeData(wb, "Auditoria Medica", AuditoriaMedica)



saveWorkbook(wb, "Update BaseGPAyAM.xlsx", overwrite = TRUE)

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
