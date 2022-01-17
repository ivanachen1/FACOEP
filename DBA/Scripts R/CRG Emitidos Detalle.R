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
Resultados <- "~/Excel"                                                                                             
setwd(Resultados)
############################################## CONSULTAS ######################################################

INGRESADOSbase <- dbGetQuery(con, "SELECT 
CASE WHEN c.pprid IN (2,3,4,5,10,11,13,25,26) THEN 'DESCENTRALIZADO' ELSE 'CENTRALIZADO' END AS Efector,
pprnombre,
(crgimpbruto - crgimpdescuento) as Importe, CASE WHEN crgestado=1 THEN 'INGRESADO' ELSE '' END
                        ||
                        CASE WHEN crgestado=3 THEN 'PROFORMA' ELSE '' END
                        ||
                        CASE WHEN crgestado=4 THEN 'FACTURADO' ELSE '' END
                        ||
                        CASE WHEN crgestado=9 THEN 'AUDITADO' ELSE '' END
                        ||
                        CASE WHEN crgestado=10 THEN 'ASIGNADO/PENDIENTE' ELSE '' END
                        ||
                        CASE WHEN crgestado=11 THEN 'ASIGNADO/PENDIENTE' ELSE '' END
                        ||
                        CASE WHEN crgestado IS NULL THEN 'INGRESADO' ELSE '' END AS Estado,
                        c.obsocialescodigo, obsocialesdescripcion, crgfchemision 
                        FROM crg c
LEFT JOIN crgdet cd ON cd.pprid = c.pprid AND cd.crgnum = c.crgnum
LEFT JOIN proveedorprestador pp ON pp.pprid = c.pprid
LEFT JOIN obrassociales os ON os.obsocialescodigo = c.obsocialescodigo
WHERE crgfchemision >= '2019-01-01' AND crgfchemision <= '2019-12-31'
group by c.pprid, pprnombre, c.obsocialescodigo, c.crgnum, c.crgestado, c.crgfchemision, crgimpbruto, crgimpdescuento, obsocialesdescripcion")

efectores <- dbGetQuery(con, "SELECT pprnombre, pprid as pprid
                         FROM proveedorprestador pp 
                        WHERE pprcodsigehos > 0 AND pprid IN (2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,19,20,21,22,23,24,25,26,424,425,702,704,938,1268,1466,1607,1644,1855,2334,2678,2701,2709,2711,2728,2819,2824,2826,2838,2841,2864,2912,2936,2991)")
cesacs <- dbGetQuery(con, "SELECT pprnombre, pprid as pprid FROM proveedorprestador where pprnombre LIKE '%CESAC%'")

efectores <- rbind(efectores, cesacs)

INGRESADOSbase <- left_join(efectores, INGRESADOSbase, all.x = TRUE)

INGRESADOSbase$Centro <- ifelse(INGRESADOSbase$obsocialescodigo == 90001199, "PAMI",
                                ifelse(INGRESADOSbase$obsocialescodigo == 90001003 | INGRESADOSbase$obsocialescodigo == 90001162, "PAMI", 
                                       ifelse(INGRESADOSbase$obsocialescodigo == 90000172 | INGRESADOSbase$obsocialescodigo == 90001226, "INCLUIR", "OOSS")))

INGRESADOSbase$pprnombre <- ifelse(INGRESADOSbase$pprnombre %like% 'CESAC' | INGRESADOSbase$pprnombre %like% 'CEMAR', "CESACS (Primer Nivel)", INGRESADOSbase$pprnombre)

reporte <- select(INGRESADOSbase, "Fecha" = crgfchemision, "Hospital" = pprnombre, Centro, importe)
reporte$mes <- month(reporte$Fecha)
reporte$mes  <- meses[ reporte$mes  ]
reporte$Fecha <- NULL

reporte <- aggregate(.~mes+Hospital+Centro, reporte, sum)

INCLUIR <- select(filter(reporte, reporte$Centro == 'INCLUIR'), mes, Hospital, importe)
INCLUIR <- spread(INCLUIR, mes, importe, fill = 0)
INCLUIR$Total <- rowSums(INCLUIR[2:13])

PAMI <- select(filter(reporte, reporte$Centro == 'PAMI'), mes, Hospital, importe)
PAMI <- spread(PAMI, mes, importe, fill = 0)
PAMI$Total <- rowSums(PAMI[2:13])

OOSS <- select(filter(reporte, reporte$Centro == 'OOSS'), mes, Hospital, importe)
OOSS <- spread(OOSS, mes, importe, fill = 0)
OOSS$Total <- rowSums(OOSS[2:13])

TODOS <- select(reporte, mes, Hospital, importe)
TODOS <- aggregate(.~mes+Hospital, TODOS, sum)
TODOS <- spread(TODOS, mes, importe, fill = 0)
TODOS$Total <- rowSums(TODOS[2:13])

letraytamano <- createStyle(fontName = "Tahoma", fontSize = 9, numFmt="CURRENCY",halign = "center", valign = "center")
titulos3 <- createStyle(fgFill = "#BABDB6",textDecoration = "bold", halign = "center", valign = "center", fontSize = 10,fontName = "Tahoma")
titulos4 <- createStyle(fgFill = "#e1e0de", textDecoration = "bold", halign = "left", valign = "center", fontSize = 9,fontName = "Tahoma")
titulos5 <- createStyle(textDecoration = "bold", halign = "right", valign = "center", fontSize = 9,numFmt="CURRENCY",fontName = "Tahoma")

wb <- createWorkbook()
addWorksheet(wb, "Todos los Centros")
mergeCells(wb, "Todos los Centros", rows = 1, cols = 1:14)
writeData(wb, "Todos los Centros", "CRG Emitidos Durante 2019 para Todos los Centros", startCol = 1, startRow = 1)
writeData(wb, "Todos los Centros", TODOS, startCol = 1, startRow = 2)
addStyle(wb, "Todos los Centros", titulos3, rows = 1, cols = 1:14,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "Todos los Centros", titulos4, rows = 2, cols = 1:14,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "Todos los Centros", titulos4, rows = 2:38, cols = 1,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "Todos los Centros", titulos5, rows = 3:38, cols = 14,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "Todos los Centros", letraytamano, rows = 3:38, cols = 2:13,gridExpand = TRUE, stack = FALSE)
setColWidths(wb, "Todos los Centros", cols = 1, widths = "34")
setColWidths(wb, "Todos los Centros", cols = 2:ncol(TODOS), widths = "17")

addWorksheet(wb, "PAMI")
mergeCells(wb, "PAMI", rows = 1, cols = 1:14)
writeData(wb, "PAMI", "CRG Emitidos Durante 2019 para Centros PAMI", startCol = 1, startRow = 1)
writeData(wb, "PAMI", PAMI, startCol = 1, startRow = 2)
addStyle(wb, "PAMI", titulos3, rows = 1, cols = 1:14,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "PAMI", titulos4, rows = 2, cols = 1:14,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "PAMI", titulos4, rows = 2:38, cols = 1,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "PAMI", titulos5, rows = 3:38, cols = 14,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "PAMI", letraytamano, rows = 3:38, cols = 2:13,gridExpand = TRUE, stack = FALSE)
setColWidths(wb, "PAMI", cols = 1, widths = "34")
setColWidths(wb, "PAMI", cols = 2:ncol(PAMI), widths = "17")

addWorksheet(wb, "INCLUIR")
mergeCells(wb, "INCLUIR", rows = 1, cols = 1:14)
writeData(wb, "INCLUIR", "CRG Emitidos Durante 2019 para Centros INCLUIR", startCol = 1, startRow = 1)
writeData(wb, "INCLUIR", INCLUIR, startCol = 1, startRow = 2)
addStyle(wb, "INCLUIR", titulos3, rows = 1, cols = 1:14,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "INCLUIR", titulos4, rows = 2, cols = 1:14,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "INCLUIR", titulos4, rows = 2:38, cols = 1,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "INCLUIR", titulos5, rows = 3:38, cols = 14,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "INCLUIR", letraytamano, rows = 3:38, cols = 2:13,gridExpand = TRUE, stack = FALSE)
setColWidths(wb, "INCLUIR", cols = 1, widths = "34")
setColWidths(wb, "INCLUIR", cols = 2:ncol(INCLUIR), widths = "17")

addWorksheet(wb, "OOSS")
mergeCells(wb, "OOSS", rows = 1, cols = 1:14)
writeData(wb, "OOSS", "CRG Emitidos Durante 2019 para Centros OOSS", startCol = 1, startRow = 1)
writeData(wb, "OOSS", OOSS, startCol = 1, startRow = 2)
addStyle(wb, "OOSS", titulos3, rows = 1, cols = 1:14,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "OOSS", titulos4, rows = 2, cols = 1:14,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "OOSS", titulos4, rows = 2:38, cols = 1,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "OOSS", titulos5, rows = 3:38, cols = 14,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "OOSS", letraytamano, rows = 3:38, cols = 2:13,gridExpand = TRUE, stack = FALSE)
setColWidths(wb, "OOSS", cols = 1, widths = "34")
setColWidths(wb, "OOSS", cols = 2:ncol(OOSS), widths = "17")

saveWorkbook(wb, paste("CRG Emitidos 2019", ".xlsx", sep = ""), overwrite = TRUE)

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

