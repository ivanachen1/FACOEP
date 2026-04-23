library(RPostgreSQL)
library(DBI)
library(openxlsx)
library(tidyverse)
library(data.table)

options(max.print=1000000)

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname="facoep",host="172.31.24.12",port="5432",user="postgres",password="facoep2017")

Resultados <- "C:/Users/user/Desktop/Agus/R" 
setwd(Resultados)
consultaSQL <-
  dbGetQuery(con, "SELECT
cp.comprobantecodigo as nrofactura,
pprnombre as efector,
comprobantecrgnro as crg,
comprobantecrgdetafitipodoc as tipodoc,
comprobantecrgdetafinumdoc as nrodoc,
comprobantecrgdetafinomape as afiliado,
comprobantecrgdetafinumero as nroafiliado,
comprobantecrgdetpractica as crgdetpractica,
crgdetcantidad,
crgdetfechaprestacion as fecha,
comprobantecrgdetimportefactur as importe,
cp.tipocomprobantecodigo as tipo,
cp.comprobanteprefijo as prefijo

from comprobantes cp
LEFT JOIN comprobantecrgdet cr   ON 	 cr.empcod = cp.empcod and
					 cr.sucursalcodigo = cp.sucursalcodigo and
					 cr.comprobantetipoentidad = cp.comprobantetipoentidad and
					 cr.comprobanteentidadcodigo = cp.comprobanteentidadcodigo and
					 cr.tipocomprobantecodigo = cp.tipocomprobantecodigo and
					 cr.comprobanteprefijo = cp.comprobanteprefijo and
					 cr.comprobantecodigo = cp.comprobantecodigo
LEFT JOIN proveedorprestador pp ON pp.pprid = cr.comprobantepprid

LEFT JOIN crgdet cd ON cd.pprid = cr.comprobantepprid and cd.crgnum = cr.comprobantecrgnro and cd.crgdetid = cr.comprobantecrgdetid

WHERE cp.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') and 
      cp.comprobanteentidadcodigo = 176 and
      cp.comprobantecodigo = 18740
")

anexo.factura <- as.data.table(consultaSQL)

anexo.fc.ospacp <- select(anexo.factura, nrofactura, efector, crg, tipodoc, nrodoc,
                        afiliado, nroafiliado
                        , crgdetpractica, crgdetcantidad, fecha, importe,
                        tipo, prefijo)
wb <- createWorkbook()
addWorksheet(wb, "AnexoFcOSPACP18740")
writeData(wb, "AnexoFcOSPACP18740", anexo.fc.ospacp, colNames = T)
encabezados <- createStyle(fontSize = 12, fontColour = NULL, halign = "center",
                           fgFill = "#FFFF33", border="TopBottomLeftRight", borderColour = "#000000", borderStyle = "Thin")
addStyle(wb, sheet = "AnexoFcOSPACP18740", encabezados, rows = 1, cols = 1:13, gridExpand = TRUE)
setRowHeights(wb, "AnexoFcOSPACP18740", rows = c(1), heights = c(21))
saveWorkbook(wb, "AnexoFcOSPACP18740.xlsx", overwrite = T)

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
