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
realizacion <- Sys.time()
Resultados <- "~/Excel"                                                                                             
setwd(Resultados)

############################################## CONSULTA ######################################################

recibos <- dbGetQuery(con, "SELECT comprobantecodigo, comprobantetotalimporte 
                            
                            FROM comprobantes
                            
                            WHERE tipocomprobantecodigo = 'RECX2' and 
                            comprobantelistores = TRUE and 
                            comprobanteenviadores = FALSE
                            -- and comprobantefechaemision >= 'xxxx-xx-xx' and comprobantefechaemision <= 'xxxx-xx-xx'
                            
                            ORDER BY comprobantecodigo")
names(recibos) <- c("Codigo", "Importe")

############################################## FORMATO ######################################################

letraytamano <- createStyle(fontName = "Tahoma", fontSize = 9, numFmt="CURRENCY",halign = "center", valign = "center")
letraytamano3 <- createStyle(fontName = "Tahoma", fontSize = 9,halign = "center", valign = "center")
titulos2 <- createStyle(fgFill = "#BABDB6", textDecoration = "bold", halign = "center", valign = "center", fontSize = 10,fontName = "Tahoma")
titulos3 <- createStyle(fgFill = "#C7C9C3",textDecoration = "bold", halign = "left", valign = "center", fontSize = 7,fontName = "Tahoma")
titulos4 <- createStyle(fgFill = "#BABDB6", textDecoration = "bold", halign = "center", valign = "center", fontSize = 9,fontName = "Tahoma")

wb <- createWorkbook()
addWorksheet(wb, "Recibos")
mergeCells(wb, "Recibos", cols = 1:2, rows = 1:2)
mergeCells(wb, "Recibos", cols = 1:2, rows = 3)
writeData(wb, "Recibos", "Recibos Listos para 246", startCol = 1, startRow = 1)
writeData(wb, "Recibos", paste("Realizacion del reporte:", realizacion), startCol = 1, startRow = 3)
writeData(wb, "Recibos", recibos, startCol = 1, startRow = 4)
addStyle(wb, "Recibos", titulos2, rows = 1:2, cols = 1:2,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "Recibos", titulos3, rows = 3, cols = 1:2,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "Recibos", titulos4, rows = 4, cols = 1:2,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "Recibos", letraytamano, rows = 5:(nrow(recibos)+5), cols = 2,gridExpand = TRUE, stack = FALSE)
addStyle(wb, "Recibos", letraytamano3, rows = 5:(nrow(recibos)+5), cols = 1,gridExpand = TRUE, stack = FALSE)
setColWidths(wb, "Recibos", cols = 1:2, widths = "22")

saveWorkbook(wb, "Recibos Listos para 246.xlsx", overwrite = TRUE)

