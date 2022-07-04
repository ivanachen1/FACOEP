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
library(BBmisc)

drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv, dbname = 'Facoep', 
                 host = '10.22.0.142',
                 port = 5432,
                 user = 'postgres',
                 password = 'serveradmin')

Query <- paste("with recibos as (SELECT", 
                "comprobanteentidadcodigo as cliente,",
                "comprobantefechaemision as emision,",
                "tipocomprobantecodigo as tipo,",
                "comprobanteprefijo as prefijo,",
                "comprobantecodigo as numero,",
                "ccostodescripcion as centro,",
                "comprobanteasientocodigo as asiento,",
                "comprobantetotalimporte as haber",
                
                "FROM comprobantes c",
                "LEFT JOIN centrocostos cc ON c.comprobanteccosto = cc.ccostocodigo",
                
                "WHERE tipocomprobantecodigo IN ('RECX2', 'RECM') and comprobanteentidadcodigo <> -1),",
              
              "imputaciones as ( SELECT", 
                "comprobanteentidadcodigo as clienteimp,",
                "comprobantefechaemision as emisionimp,",
                "tipocomprobantecodigo as tipoimp,",
                "comprobanteprefijo as prefijoimp,",
                "comprobantecodigo as numeroimp,",
                "ccostodescripcion as centroimp,",
                "comprobanteasientocodigo as asientoimp,",
                
                "CASE", 
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND c.comprobanteorigen = 'M' THEN 'Manual'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'P' THEN 'Proforma'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'A' THEN 'Auditar'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'C' THEN 'Cancelacion'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'L' THEN 'Liquido Producto'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'Z' THEN 'Ninguno'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'R' THEN 'Resolucion 246 Anexo A'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'B' THEN 'Resolucion 246 Anexo B'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'O' THEN 'Adelanto'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'H' THEN 'Deuda Historica'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'D' THEN 'Refacturacion'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'J' THEN 'Mandatario'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'I' THEN 'Intimacion'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'V' THEN 'Factura Vencida'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'S' THEN 'Liquidacion'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'E' THEN 'Convenio'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'F' THEN 'Convenio Cta Cte'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'X' THEN 'Mandatario DH'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'Q' THEN 'Prefactura'",
                "WHEN tipocomprobantecodigo LIKE '%ND%' AND  c.comprobanteorigen = 'K' THEN 'Acuerdo OS' ELSE '' END AS Origen",
                
                "FROM comprobantes c",
                "LEFT JOIN centrocostos cc ON c.comprobanteccosto = cc.ccostocodigo",
                "WHERE tipocomprobantecodigo LIKE '%FAC%' OR tipocomprobantecodigo LIKE '%ND%')",
              
                "SELECT",
                "recibos.*,",
                "imputaciones.emisionimp,",
                "imputaciones.tipoimp,",
                "imputaciones.prefijoimp,",
                "imputaciones.numeroimp,",
                "imputaciones.centroimp,",
                "imputaciones.asientoimp,",
                "CASE WHEN comprobanteimputaciontipo LIKE '%FAC%' THEN comprobanteimputacionimporte ELSE 0 END AS Capital,",
                "CASE WHEN comprobanteimputaciontipo LIKE '%ND%' THEN comprobanteimputacionimporte ELSE 0 END AS Interes,",
                "imputaciones.origen",
                
                "FROM comprobantesimputaciones ci",
                "RIGHT JOIN recibos ON recibos.cliente = ci.comprobanteentidadcodigo and",
                "recibos.tipo = ci.tipocomprobantecodigo and",
                "recibos.prefijo = ci.comprobanteprefijo and",
                "recibos.numero = ci.comprobantecodigo",
                
                "LEFT JOIN imputaciones ON imputaciones.clienteimp = ci.comprobanteentidadcodigo and",
                "imputaciones.tipoimp = ci.comprobanteimputaciontipo and",
                "imputaciones.prefijoimp = ci.comprobanteimputacionprefijo and",
                "imputaciones.numeroimp = ci.comprobanteimputacioncodigo")
cat(Query)

print(Query)

Reporte <- dbGetQuery(con,Query)
