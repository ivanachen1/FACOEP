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

reporte <- select(INGRESADOSbase, pprnombre, Centro, importe)

reporte <- aggregate(.~pprnombre+Centro, reporte, sum)
reporte <- spread(reporte, Centro, importe, fill = 0)
reporte$Total <- rowSums(reporte[2:4])
reporte[nrow(reporte)+1,] = c("Total", sum(reporte$INCLUIR), sum(reporte$OOSS), sum(reporte$PAMI), sum(reporte$Total))
reporte$INCLUIR <- as.numeric(reporte$INCLUIR)
reporte$OOSS <- as.numeric(reporte$OOSS)
reporte$PAMI <- as.numeric(reporte$PAMI)
reporte$Total <- as.numeric(reporte$Total)
names(reporte) <- c("Hospital", "INCLUIR", "OOSS", "PAMI", "Total")


letraytamano <- createStyle(fontName = "Tahoma", fontSize = 9, numFmt="CURRENCY",halign = "center", valign = "center")
titulos4 <- createStyle(fgFill = "#BABDB6", textDecoration = "bold", halign = "center", valign = "center", fontSize = 9,fontName = "Tahoma")
titulos5 <- createStyle(fgFill = "#BABDB6", textDecoration = "bold", halign = "left", valign = "center", fontSize = 9,fontName = "Tahoma")

wb <- createWorkbook()
addWorksheet(wb, "Emitidos 2019")
writeData(wb, "Emitidos 2019", reporte, startCol = 1, startRow = 1)
addStyle(wb, "Emitidos 2019", titulos4, rows = 1, cols = 1:ncol(reporte),gridExpand = TRUE, stack = FALSE)
addStyle(wb, "Emitidos 2019", titulos4, rows = 1:3, cols = 1,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "Emitidos 2019", titulos5, rows = 1:nrow(reporte)+1, cols = 1,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "Emitidos 2019", letraytamaño, rows = 1:nrow(reporte)+1, cols = 2:ncol(reporte)+1,gridExpand = TRUE, stack = FALSE)
setColWidths(wb, "Emitidos 2019", cols = 1, widths = "34")
setColWidths(wb, "Emitidos 2019", cols = 2:5, widths = "17")

saveWorkbook(wb, paste("CRG Emitidos 2019", ".xlsx", sep = ""), overwrite = TRUE)

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

  