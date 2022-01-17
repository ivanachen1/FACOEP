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
pw <- {"facoep2017"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep", host = "172.31.24.12", port = 5432, user = "postgres", password = pw)
postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")
############################################################################################################

data <- dbGetQuery(con, "SELECT	
	c.comprobanteentidadcodigo as ID,
	clientenombre as Nombre,
	c.comprobantefechaemision as FechaEmision,
  c.tipocomprobantecodigo as Tipo,
  c.comprobanteprefijo as Prefijo,
  c.comprobantecodigo as Numero,
  c.comprobantesaldo as Saldo,
  h.entrega,
  c.comprobantefechavencimiento as FechaVencimiento,
  c.comprobanteintimacion as Intimado,
  int.intimacionfecha as FechaIntimacion,
  c.comprobantemandatario as Mandatario,
  man.enviocompfecha as FechaMand,
  man.cert as CertificadoDeuda,
  c.comprobantecovid AS covid,
  tur.turismo,
  comprobanteimputacionfecha as FechaComprobanteImputado,
  comprobanteimputaciontipo as TipoComprobanteImputado,
  comprobanteimputacionprefijo as PrefijoComprobanteImputado,
  comprobanteimputacioncodigo as CodigoComprobanteImputado,
  comprobanteimputacionimporte as ImporteImputado
  
 
  FROM comprobantes c
  LEFT JOIN clientes os ON os.clienteid = c.comprobanteentidadcodigo
  LEFT JOIN (SELECT
                    comprobanteentidadcodigo,
                    tipocomprobantecodigo,
                    comprobantecodigo,
                    MAX(comprobantehisfechatramite) as entrega
                    FROM comprobanteshistorial 
                    WHERE comprobantehisestado = 4
                    GROUP BY comprobanteentidadcodigo, tipocomprobantecodigo, comprobantecodigo) as h ON h.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                                                                                   h.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                                                                                                   h.comprobantecodigo = c.comprobantecodigo
                                                                                                                   
  LEFT JOIN (SELECT
              comprobanteentidadcodigo, tipocomprobantecodigo, comprobantecodigo, comprobanteintimacion, intimacionfecha
              FROM comprobantes co
              LEFT JOIN intimacion i ON i.intimacionnro = co.comprobanteintimanro) as int ON int.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                                                            int.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                                                                            int.comprobantecodigo = c.comprobantecodigo and
                                                                                            int.comprobanteintimacion = c.comprobanteintimacion
  
 LEFT JOIN (SELECT
              comprobanteentidadcodigo, tipocomprobantecodigo, comprobantecodigo, comprobantemandatario, enviocompfecha, mandatarioexpcertificadodeuda as cert
              FROM comprobantes com
              LEFT JOIN enviocomprobantes e ON e.enviocompnro = com.comprobanteenvionro
              LEFT JOIN mandatarioexp m ON m.mandatarioexpid = e.mandatarioexpid) as man ON man.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                                                            man.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                                                                            man.comprobantecodigo = c.comprobantecodigo and
                                                                                            man.comprobantemandatario = c.comprobantemandatario
                                                                                            
  LEFT JOIN (SELECT
                    comp.comprobanteentidadcodigo, comp.tipocomprobantecodigo, comp.comprobantecodigo,
                    CASE WHEN crg.comprobantepprid = 3140 THEN 'Si' ELSE 'No' END AS Turismo
                    FROM comprobantes comp
                    LEFT JOIN comprobantecrg crg ON crg.comprobanteprefijo = comp.comprobanteprefijo and
                    			  								  crg.empcod = comp.empcod and
                    											  crg.tipocomprobantecodigo = comp.tipocomprobantecodigo and
                    											  crg.sucursalcodigo = comp.sucursalcodigo and
                    											  crg.comprobantetipoentidad = comp.comprobantetipoentidad and
                    											  crg.comprobantecodigo = comp.comprobantecodigo and
                    											  crg.comprobanteentidadcodigo = comp.comprobanteentidadcodigo
                    GROUP BY comp.comprobanteentidadcodigo, comp.tipocomprobantecodigo, comp.comprobantecodigo, turismo
                    ORDER BY turismo DESC) as tur ON tur.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                     tur.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                                     tur.comprobantecodigo = c.comprobantecodigo
                                                     
  RIGHT JOIN comprobantesimputaciones ci ON ci.empcod = c.empcod and
  											ci.sucursalcodigo = c.sucursalcodigo and
											ci.comprobantetipoentidad = c.comprobantetipoentidad and
											ci.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
											ci.tipocomprobantecodigo = c.tipocomprobantecodigo and
											ci.comprobanteprefijo = c.comprobanteprefijo and
											ci.comprobantecodigo = c.comprobantecodigo
											
 
		order by c.comprobantefechaemision")

data$intimado <- ifelse(data$intimado == TRUE, "Si", "No")
data$mandatario <- ifelse(data$mandatario == TRUE, "Si", "No")

Reporte <- select(data,
                  "ID" = id,
                  "Nombre" = nombre,
                  "Fecha de Emision" = fechaemision,
                  "Tipo" = tipo,
                  "Prefijo" = prefijo,
                  "Código" = numero,
                  "Saldo" = saldo,
                  "Fecha de Entrega" = entrega,
                  "Fecha de Vencimiento" = fechavencimiento,
                  "Intimado" = intimado,
                  "Fecha de Intimación" = fechaintimacion,
                  "Mandatario" = mandatario,
                  "Fecha Mandatario" = fechamand,
                  "Certificado de Deuda" = certificadodeuda,
                  "CoVid" = covid,
                  "Turismo" = turismo,
                  "Fecha Comprobante Imputado" = fechacomprobanteimputado,
                  "Tipo Imputado" = tipocomprobanteimputado,
                  "Prefijo Imputado" = prefijocomprobanteimputado,
                  "Código Imputado" = codigocomprobanteimputado,
                  "Importe Imputado" = importeimputado)

write.csv(Reporte, "asd.csv")

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

