## Reingenieria de Facturado Cobrado Covid

# Obtener el universo de analisis
# 1 - Obtener a nivel de crg todas las facturas emitidas con los montos totales --> tengo que usar el campo importe facturado 
# 2 - Obtener a nivel de crg todos los recibos emitidos con los montos totales --> tengo que usar el campo importe facturado
# 3 - Tener en cuenta que debo utilizar los recibos y facturas a nivel covid --> tengo que identificar los CRGs que contengan esos codigos



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



##################################### Prestaciones Facturadas ################################################

# Hay que tener en cuenta que la apertura del recibo es a partir de Febrero 2022, por lo tanto 
# voy a identificar que facturas poseen prestaciones Covid y de ahi comparar con los recibos para identificar
# Pagos parciales y pagos totales 

PrestacionesCovid <- dbGetQuery(conn = con
                                ,paste("SELECT DISTINCT(comprobantecrgdetpractica) as prestacion FROM comprobantecrgdet",
                                "WHERE comprobantecrgdetpractica  LIKE '60.%'",
                                "OR comprobantecrgdetpractica LIKE '%COV%'"))

PrestacionesCovid <- PrestacionesCovid$prestacion
PrestacionesCovid <- as.vector(PrestacionesCovid)
PrestacionesCovid <- toString(sprintf("'%s'", PrestacionesCovid))

#Ejecuto la Query de Facturado por prestaciones para identificar las facturas que quiero ver

FacturacionCovid <- glue(paste("SELECT DISTINCT",
                                   "pprnombre as Efector,",
                                   "cd.comprobantepprid,",
                                   "cd.comprobantecrgnro,",
                                   "CONCAT(c.tipocomprobantecodigo,'-',c.comprobanteprefijo,'-',c.comprobantecodigo) as factura,",
                                   "c.tipocomprobantecodigo as tipofactura,",
                                   "c.comprobanteprefijo as prefijo,",
                                   "c.comprobantecodigo as numerofactura,",
                                   "c.comprobantefechaemision as emision",
                                   "FROM", 
                                   "comprobantes c",
                                   "LEFT JOIN", 
                                   "comprobantecrgdet cd ON cd.comprobantetipoentidad = c.comprobantetipoentidad and",
                                   "cd.comprobanteentidadcodigo = c.comprobanteentidadcodigo and",
                                   "cd.tipocomprobantecodigo = c.tipocomprobantecodigo and",
                                   "cd.comprobanteprefijo = c.comprobanteprefijo and",
                                   "cd.comprobantecodigo = c.comprobantecodigo",
                                   "LEFT JOIN", 
                                   "proveedorprestador pp ON pp.pprid = cd.comprobantepprid",
                                   "WHERE c.tipocomprobantecodigo IN ('FACA2','FACB2', 'FAECA', 'FAECB')", 
                                   "and cd.comprobantecrgdetpractica IN ({PrestacionesCovid})"))

#Universo de CRGs y pprids

FacturacionCovid <- dbGetQuery(conn = con,FacturacionCovid)

UniversoCRGs <- select(FacturacionCovid,
                       "pprid" = comprobantepprid,
                       "crgnro" = comprobantecrgnro)


CRGsAnalizar <- glue(paste("SELECT",
                      "CONCAT(c.tipocomprobantecodigo,'-',c.comprobanteprefijo,'-',c.comprobantecodigo) as factura,",
                      "c.tipocomprobantecodigo,",
                      "c.comprobanteprefijo as prefijo,",
                      "c.comprobantecodigo as numerocomprobante,",
                      "c.comprobantecrgimportetotaldeta as importefacturado,",
                      "c.comprobantecrgnro,",
                      "c.comprobantepprid,",
                      "det.comprobantepprid,",
                      "det.comprobantecrgnro",
                      
                      "FROM comprobantecrg c",
                      "LEFT JOIN (SELECT DISTINCT",
                                  "pprnombre as Efector,",
                                  "cd.comprobantepprid,",
                                  "cd.comprobantecrgnro",
                                  "FROM", 
                                  "comprobantes c",
                                  "LEFT JOIN", 
                                  "comprobantecrgdet cd ON cd.comprobantetipoentidad = c.comprobantetipoentidad and",
                                  "cd.comprobanteentidadcodigo = c.comprobanteentidadcodigo and",
                                  "cd.tipocomprobantecodigo = c.tipocomprobantecodigo and",
                                  "cd.comprobanteprefijo = c.comprobanteprefijo and",
                                  "cd.comprobantecodigo = c.comprobantecodigo",
                                  "LEFT JOIN", 
                                  "proveedorprestador pp ON pp.pprid = cd.comprobantepprid",
                                  "WHERE c.tipocomprobantecodigo IN ('FACA2','FACB2', 'FAECA', 'FAECB')",
                                  "AND cd.comprobantecrgdetpractica IN ({PrestacionesCovid})) det",
                              
                      "ON c.comprobantecrgnro = det.comprobantecrgnro AND",
                         "c.comprobantepprid = det.comprobantepprid",
                      
                      "WHERE det.comprobantepprid IS NOT NULL"))
                      
print(CRGsAnalizar)

CRGsAnalizar <- dbGetQuery(conn = con,CRGsAnalizar)                      



lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

"
SELECT tipocomprobantecodigo,
comprobanteprefijo,
comprobantecodigo,
comprobantepprid,
comprobantecrgnro,
comprobantecrgimporteneto

FROM comprobantecrg 
WHERE tipocomprobantecodigo IN('FACA2','RECX2') AND
comprobanteprefijo =1 AND 
comprobantecodigo IN (8754,2703) AND
comprobantepprid = 11 AND 
comprobantecrgnro = 9270
"