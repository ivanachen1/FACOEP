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
saveWorkbook(wb, "PAMI 2020upd.xlsx", overwrite = TRUE)

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
