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
alafecha <- as.integer(format(as.Date(Sys.Date()), "%m"))
Resultados <- "~/Excel" 
realizacion <- Sys.time()
setwd(Resultados)
############################################################################################################
FACTURAS <- dbGetQuery(con, "SELECT c.comprobantefechaemision as fechaemision,
                           c.tipocomprobantecodigo as tipofactura,
                       c.comprobanteprefijo as prefijo,
                       c.comprobantecodigo as factura,
                       comprobantehisfechatramite as fecharecepcion,
                       c.comprobantetotalimporte as debe,
                       
                    

                       c.comprobantesaldo as saldo
                       
                       FROM comprobantes c
                       

                       LEFT JOIN comprobanteshistorial as h ON h.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                              h.comprobantetipoentidad = c.comprobantetipoentidad and
                                                              h.comprobanteprefijo = c.comprobanteprefijo and
                                                              h.comprobantecodigo  = c.comprobantecodigo and 
                                                              h.tipocomprobantecodigo = c.tipocomprobantecodigo 
                                                              AND comprobantehisestado = 4

                       
                       
                       WHERE c.tipocomprobantecodigo IN ('FACB2', 'FACA2', 'FAECA', 'FAECB') and 
                       comprobantehisfechatramite BETWEEN '01-03-2020' and '31-03-2020' and c.comprobantefechaemision > '01-06-2019'
                       order by c.comprobantefechaemision")
FACTURASRECIBOS <- aggregate(.~fechaemision+tipofactura+prefijo+factura+fecharecepcion+debe+saldo, FACTURASRECIBOS, sum)



FACTURASRECIBOS <- dbGetQuery(con, "SELECT c.comprobantefechaemision as fechaemision,
                           c.tipocomprobantecodigo as tipofactura,
                       c.comprobanteprefijo as prefijo,
                       c.comprobantecodigo as factura,
                       comprobantehisfechatramite as fecharecepcion,
                       c.comprobantetotalimporte as debe,
                       
                      
                      comprobanteimputacionimporte as importerec,

                       c.comprobantesaldo as saldo
                       
                       FROM comprobantes c
                       

                       LEFT JOIN comprobanteshistorial as h ON h.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                              h.comprobantetipoentidad = c.comprobantetipoentidad and
                                                              h.comprobanteprefijo = c.comprobanteprefijo and
                                                              h.comprobantecodigo  = c.comprobantecodigo and 
                                                              h.tipocomprobantecodigo = c.tipocomprobantecodigo 
                                                              AND comprobantehisestado = 4
                                                               
                       LEFT JOIN comprobantesimputaciones i  ON i.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                              i.comprobantetipoentidad = c.comprobantetipoentidad and
                                                              i.comprobanteprefijo = c.comprobanteprefijo and
                                                              i.comprobantecodigo  = c.comprobantecodigo and 
                                                              i.tipocomprobantecodigo = c.tipocomprobantecodigo
                       
                                                              
                      
                       
                       
                       WHERE c.tipocomprobantecodigo IN ('FACB2', 'FACA2', 'FAECA', 'FAECB') and 
                       comprobanteimputaciontipo = 'RECX2' and
                       comprobantehisfechatramite BETWEEN '01-03-2020' and '31-03-2020'
                       order by c.comprobantefechaemision")
FACTURASRECIBOS <- aggregate(.~fechaemision+tipofactura+prefijo+factura+fecharecepcion+debe+saldo, FACTURASRECIBOS, sum)

FACTURASNOTADB <- dbGetQuery(con, "SELECT c.comprobantefechaemision as fechaemision,
                           c.tipocomprobantecodigo as tipofactura,
                       c.comprobanteprefijo as prefijo,
                       c.comprobantecodigo as factura,
                       comprobantehisfechatramite as fecharecepcion,
                       c.comprobantetotalimporte as debe,
                       
                      
                      c2.comprobantetotalimporte as importenotadb,

                       c.comprobantesaldo as saldo
                       
                       FROM comprobantes c
                       

                       LEFT JOIN comprobanteshistorial as h ON h.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                              h.comprobantetipoentidad = c.comprobantetipoentidad and
                                                              h.comprobanteprefijo = c.comprobanteprefijo and
                                                              h.comprobantecodigo  = c.comprobantecodigo and 
                                                              h.tipocomprobantecodigo = c.tipocomprobantecodigo 
                                                              AND comprobantehisestado = 4
                                                               
                       LEFT JOIN comprobantesasociados s  ON s.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                              s.comprobantetipoentidad = c.comprobantetipoentidad and
                                                              s.comprobanteprefijo = c.comprobanteprefijo and
                                                              s.comprobantecodigo  = c.comprobantecodigo and 
                                                              s.tipocomprobantecodigo = c.tipocomprobantecodigo
                       
                        LEFT JOIN comprobantes as c2 ON        c2.comprobanteprefijo = s.comprobanteasocprefijo and
                                                              c2.comprobantecodigo  = s.comprobanteasoccodigo and 
                                                              c2.tipocomprobantecodigo = s.comprobanteasoctipo                                      
                      
                       
                       
                       WHERE c.tipocomprobantecodigo IN ('FACB2', 'FACA2', 'FAECA', 'FAECB') and 
                       s.comprobanteasoctipo = 'NOTADB' and
                       comprobantehisfechatramite BETWEEN '01-03-2020' and '31-03-2020'
                       order by c.comprobantefechaemision")
FACTURASNOTADB <- aggregate(.~fechaemision+tipofactura+prefijo+factura+fecharecepcion+debe+saldo, FACTURASNOTADB, sum)

FACTURASNC <- dbGetQuery(con, "SELECT c.comprobantefechaemision as fechaemision,
                           c.tipocomprobantecodigo as tipofactura,
                       c.comprobanteprefijo as prefijo,
                       c.comprobantecodigo as factura,
                       comprobantehisfechatramite as fecharecepcion,
                       c.comprobantetotalimporte as debe,
                       
                      
                      comprobanteimputacionimporte as importenc,

                       c.comprobantesaldo as saldo
                       
                       FROM comprobantes c
                       

                       LEFT JOIN comprobanteshistorial as h ON h.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                              h.comprobantetipoentidad = c.comprobantetipoentidad and
                                                              h.comprobanteprefijo = c.comprobanteprefijo and
                                                              h.comprobantecodigo  = c.comprobantecodigo and 
                                                              h.tipocomprobantecodigo = c.tipocomprobantecodigo 
                                                              AND comprobantehisestado = 4
                                                               
                       LEFT JOIN comprobantesimputaciones i  ON i.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                              i.comprobantetipoentidad = c.comprobantetipoentidad and
                                                              i.comprobanteprefijo = c.comprobanteprefijo and
                                                              i.comprobantecodigo  = c.comprobantecodigo and 
                                                              i.tipocomprobantecodigo = c.tipocomprobantecodigo
                       
                                                              
                      
                       
                       
                       WHERE c.tipocomprobantecodigo IN ('FACB2', 'FACA2', 'FAECA', 'FAECB') and 
                       comprobanteimputaciontipo IN ('NCA', 'NCB') and
                       comprobantehisfechatramite BETWEEN '01-03-2020' and '31-03-2020'
                       order by c.comprobantefechaemision")
FACTURASNC <- aggregate(.~fechaemision+tipofactura+prefijo+factura+fecharecepcion+debe+saldo, FACTURASNC, sum)

REPORTE <- left_join(FACTURAS, FACTURASRECIBOS)

REPORTE <- left_join(REPORTE, FACTURASNOTADB)

REPORTE <- left_join(REPORTE, FACTURASNC)

REPORTE <- setcolorder(REPORTE, c(1:6,9,10,8,7))

REPORTE <- REPORTE[order(REPORTE$fecharecepcion),]

names(REPORTE) <- c("Fecha Emisión", "Tipo", "Prefijo", "Número", "Fch. Recepción", "Debe", "Débitos", "Debs. Acep.", "Cobros", "Saldo al Día")


wb <- createWorkbook()

evenREPORTE <- 5 + seq(1, nrow(REPORTE), 2)

letraytamano1 <- createStyle(fontName = "Tahoma", fontSize = 9, numFmt="DATE",halign = "center", valign = "center")
letraytamano2 <- createStyle(fontName = "Tahoma", fontSize = 9, numFmt="CURRENCY",halign = "center", valign = "center")
letraytamano3 <- createStyle(fontName = "Tahoma", fontSize = 9,halign = "left", valign = "center")
titulos2 <- createStyle(fgFill = "#BABDB6", textDecoration = "bold", halign = "center", valign = "center", fontSize = 10,fontName = "Tahoma", numFmt="CURRENCY")
titulos3 <- createStyle(fgFill = "#C7C9C3",textDecoration = "bold", halign = "left", valign = "center", fontSize = 7,fontName = "Tahoma", numFmt="CURRENCY")
gris1 <- createStyle(fgFill = "#D7D7D7",fontName = "Tahoma", fontSize = 9,numFmt="DATE",halign = "center", valign = "center")
gris2 <- createStyle(fgFill = "#D7D7D7",fontName = "Tahoma", fontSize = 9,numFmt="CURRENCY",halign = "center", valign = "center")
gris3 <- createStyle(fgFill = "#D7D7D7",fontName = "Tahoma", fontSize = 9,halign = "left", valign = "center")


addWorksheet(wb, "Fact. con Fch. Recepcion Marzo", gridLines = FALSE)
mergeCells(wb, "Fact. con Fch. Recepcion Marzo", rows = 1:2, cols = 1:ncol(REPORTE))
mergeCells(wb, "Fact. con Fch. Recepcion Marzo", rows = 3, cols = 1:ncol(REPORTE))
writeData(wb, "Fact. con Fch. Recepcion Marzo", "Facturas Con Fecha de Recepcion Marzo 2020", startCol = 1, startRow = 1)
writeData(wb, "Fact. con Fch. Recepcion Marzo", paste("Realizacion del reporte:", realizacion), startCol = 1, startRow = 3)
addStyle(wb, "Fact. con Fch. Recepcion Marzo", titulos2, rows = 1:2, cols = 1:ncol(REPORTE), gridExpand = TRUE)
addStyle(wb, "Fact. con Fch. Recepcion Marzo", titulos3, rows = 3, cols = 1:ncol(REPORTE),gridExpand = TRUE, stack = FALSE)
writeData(wb, "Fact. con Fch. Recepcion Marzo", REPORTE, startCol = 1, startRow = 4)
addStyle(wb, "Fact. con Fch. Recepcion Marzo", titulos2, rows = 4, cols = 1:ncol(REPORTE),gridExpand = TRUE)
addStyle(wb, "Fact. con Fch. Recepcion Marzo", letraytamano3, rows = 5:(nrow(REPORTE)+5), cols = c(2,3,4,5,6,9,10),gridExpand = TRUE)
addStyle(wb, "Fact. con Fch. Recepcion Marzo", gris3, rows = evenREPORTE, cols = c(2,3,4,5,6,9,10),gridExpand = TRUE)
addStyle(wb, "Fact. con Fch. Recepcion Marzo", letraytamano1, rows = 5:(nrow(REPORTE)+5), cols = c(1,5),gridExpand = TRUE)
addStyle(wb, "Fact. con Fch. Recepcion Marzo", gris1, rows = evenREPORTE, cols = c(1,5),gridExpand = TRUE)
addStyle(wb, "Fact. con Fch. Recepcion Marzo", letraytamano2, rows = 5:(nrow(REPORTE)+5), cols = c(6,7,8,9,10),gridExpand = TRUE)
addStyle(wb, "Fact. con Fch. Recepcion Marzo", gris2, rows = evenREPORTE, cols = c(6,7,8,9,10),gridExpand = TRUE)
setColWidths(wb, "Fact. con Fch. Recepcion Marzo", cols = 1:ncol(REPORTE), widths = 17)


saveWorkbook(wb, "Facturas Recepcion Marzo.xlsx", overwrite = TRUE)


# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})



