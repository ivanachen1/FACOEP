## Reingenieria de Facturado Cobrado Covid

# Obtener el universo de analisis
# 1 - Obtener a nivel de crg todas las facturas emitidas con los montos totales --> tengo que usar el campo importe facturado 
# 2 - Obtener a nivel de crg todos los recibos emitidos con los montos totales --> tengo que usar el campo importe facturado


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
library(lubridate)
library(glue)

pw <- {"odoo"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep",
                 host = "localhost", port = 5432, 
                 user = "odoo", password = pw)

comprobantes <-read.xlsx("C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Cobranza por Prestaciones/tipo_comprobante.xlsx")
comprobantes <- filter(comprobantes,Usar == "SI")
comprobantes2 <- comprobantes
comprobantes2 <- comprobantes2$Tipo
comprobantes2 <- as.vector(comprobantes2)
comprobantes2 <- toString(sprintf("'%s'", comprobantes2))

FacturacionCabecerasQuery <- glue(paste("SELECT",
                              "CONCAT(comp.tipocomprobantecodigo,'-',comp.comprobanteprefijo,'-',comp.comprobantecodigo) as factura,",
                              "c.comprobantefechaemision as emision,",
                              "pp.pprnombre as Efector,",
                               "comp.tipocomprobantecodigo,",
                               "comp.comprobanteprefijo as prefijo,",
                               "comp.comprobantecodigo as numerocomprobante,",
                               "comp.comprobantecrgimportetotaldeta as importefacturado,",
                               "comp.comprobantecrgimporteneto as neto,",
                               "CONCAT(comp.comprobantepprid,'-',comp.comprobantecrgnro) as crg,",
                               "comp.comprobantepprid,",
                               "comp.comprobantecrgnro",
                                                        
                               "FROM comprobantecrg comp",
                              
                               "LEFT JOIN comprobantes c",
                               "ON comp.tipocomprobantecodigo = c.tipocomprobantecodigo AND",
                               "comp.comprobanteprefijo = c.comprobanteprefijo AND",
                               "comp.comprobantecodigo = c.comprobantecodigo",

                               "LEFT JOIN", 
                               "proveedorprestador pp ON pp.pprid = comprobantepprid",
                                 
                                 
                               "WHERE comp.tipocomprobantecodigo IN ({comprobantes2}) AND",
                               "c.comprobanteentidadcodigo <> -1 AND",
                               "c.comprobantefechaemision > '2017-01-01' "))


#print(FacturacionCabecerasQuery)

FacturacionCabeceras <- dbGetQuery(conn = con,FacturacionCabecerasQuery)

FacturacionCabeceras$factura <- gsub(" ","",FacturacionCabeceras$factura)
FacturacionCabeceras$tipocomprobantecodigo <- gsub(" ","",FacturacionCabeceras$tipocomprobantecodigo)
FacturacionCabeceras$crg <- gsub(" ","",FacturacionCabeceras$crg)

FacturacionCabeceras <- left_join(FacturacionCabeceras,comprobantes, by = c("tipocomprobantecodigo" = "Tipo"))
# Resolver por que carajo hay notas de debito en negativo y otras en positivo. tengo que crear un doble control

FacturacionCabeceras$facturado <- ifelse(FacturacionCabeceras$importefacturado < 0 & FacturacionCabeceras$Resolucion == 2,
                                       FacturacionCabeceras$importefacturado * -1,
                                       ifelse(FacturacionCabeceras$importefacturado > 0 & FacturacionCabeceras$Resolucion == 2,
                                       FacturacionCabeceras$importefacturado * 1,
                                       FacturacionCabeceras$importefacturado * FacturacionCabeceras$Multiplicador))

FacturacionCabeceras$importeneto <- ifelse(FacturacionCabeceras$neto< 0 & FacturacionCabeceras$neto == 2,
                                       FacturacionCabeceras$neto * -1,
                                       ifelse(FacturacionCabeceras$neto > 0 & FacturacionCabeceras$neto == 2,
                                              FacturacionCabeceras$neto * 1,
                                              FacturacionCabeceras$neto * FacturacionCabeceras$Multiplicador))

FacturacionCabeceras$importefacturado <- NULL
FacturacionCabeceras$neto <- NULL
FacturacionCabeceras$Multiplicador <- NULL
FacturacionCabeceras$Observacion <- NULL


FacturacionAgrupado <- select(FacturacionCabeceras,
                              "efector" = efector,
                              "crg" = crg,
                              "nrocrg"=comprobantecrgnro,
                              "pprid" = comprobantepprid,
                              "Facturado" = facturado,
                              "Neto" = importeneto)

FacturacionAgrupado <- aggregate(.~efector+crg+pprid+nrocrg,FacturacionAgrupado, sum)
FacturacionAgrupado$Facturado <- round(FacturacionAgrupado$importe,2)
FacturacionAgrupado$Neto <- round(FacturacionAgrupado$Neto,2)

FacturacionAgrupado$TipoNeto <- ifelse(FacturacionAgrupado$Neto < 0, "Negativo",
                                   ifelse(FacturacionAgrupado$Neto == 0,"Saldado","Positivo"))

FacturacionAgrupado$TipoFacturado <- ifelse(FacturacionAgrupado$Facturado < 0, "Negativo",
                                       ifelse(FacturacionAgrupado$Facturado == 0,"Saldado","Positivo"))

AnalisisNeto <- data.frame(table(FacturacionAgrupado$TipoNeto))

AnalisisFacturado <- data.frame(table(FacturacionAgrupado$TipoFacturado))


lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
