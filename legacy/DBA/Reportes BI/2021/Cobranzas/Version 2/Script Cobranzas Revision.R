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
# Agustín no está trayendo el prefijo de los comprobantes implicando que no discrimine el punto de venta de los recibos.
# Por Ejemplo: El comprobante 1 tenia el prefijo 1 y 2 y él aplico una funcion para volar importes duplicados, tomando
# en cuenta los comprobantes de prefijo 1 y no los de 2....


pw <- {"odoo"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep", host = "localhost", port = 5432, user = "odoo", password = pw)
postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")


RecibosFechasCorregido <- dbGetQuery(con, "SELECT c.comprobanteccosto as CentroCosto,
CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
  c.comprobanteprefijo,
  c.tipocomprobantecodigo,
  c.comprobantecodigo,
  c.comprobantefechaemision,
  comprobantetotalimporte,
  comprobanteasoctipo, comprobanteasoccodigo, entrega

  FROM comprobantes c
   LEFT JOIN obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo
   
LEFT JOIN comprobantesasociados a ON a.comprobanteprefijo = c.comprobanteprefijo and
                                       a.empcod = c.empcod and
                                       a.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                       a.sucursalcodigo = c.sucursalcodigo and
                                       a.comprobantetipoentidad = c.comprobantetipoentidad and
                                       a.comprobantecodigo = c.comprobantecodigo and
                                       a.comprobanteentidadcodigo = c.comprobanteentidadcodigo
                                       
                      LEFT JOIN (SELECT
                    tipocomprobantecodigo,
                    comprobantecodigo,
                    MAX(comprobantehisfechatramite) as entrega
                    FROM comprobanteshistorial 
                    WHERE comprobantehisestado = 4
                    GROUP BY comprobanteentidadcodigo, tipocomprobantecodigo, comprobantecodigo) as h ON           h.tipocomprobantecodigo = a.comprobanteasoctipo and
                                                                                                                   h.comprobantecodigo = a.comprobanteasoccodigo
                                  
  WHERE c.comprobantetipoentidad = 2")


RecibosFechasCorregido <- filter(RecibosFechasCorregido, RecibosFechasCorregido$os != "1003 - OSPAÃ'A")
RecibosFechasCorregido <- filter(RecibosFechasCorregido, RecibosFechasCorregido$os != "1 - I.N.S.S.J. y P.")

RecibosFechasCorregido$llaveduplicados <- paste(RecibosFechasCorregido$comprobanteprefijo,RecibosFechasCorregido$comprobantecodigo,RecibosFechasCorregido$tipocomprobantecodigo,sep = "-")





#RecibosFechasCorregido$comprobantetotalimporte <- ifelse(duplicated(RecibosFechasCorregido$llaveduplicados), 0, RecibosFechasCorregido$comprobantetotalimporte)
# Esta linea no está funcionando como se pretende. Vuela los duplicados de la columna comprobantetotalimporte
#RecibosFechasCorregido$entrega <- fifelse(is.na(RecibosFechasCorregido$entrega), RecibosFechasCorregido$comprobantefechaemision, RecibosFechasCorregido$entrega)
#RecibosFechasCorregido$Dias <- RecibosFechasCorregido$comprobantefechaemision - RecibosFechasCorregido$entrega
#RecibosFechasCorregido$TipoDeuda <- ifelse(RecibosFechasCorregido$Dias > 60, "Deuda Vencida", "Deuda Corriente")

#listado_prefijos <- unique(RecibosFechasCorregido$comprobanteprefijo)



#total_cobrado_corregido <- sum(RecibosFechasCorregido$comprobantetotalimporte)

#diferencia <- total_cobrado_corregido - total_cobrado
#diferencia

#porcentaje_diferencia <- paste(round((diferencia / total_cobrado_corregido) * 100,digits = 2),"%")


