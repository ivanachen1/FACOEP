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
Base <- dbGetQuery(con, "SELECT
CASE WHEN comprobanteccosto = 1 THEN  'PAMI' ELSE '' END
                      ||
                      CASE WHEN comprobanteccosto = 2 THEN 'INCLUIR' ELSE '' END
                      ||
                      CASE WHEN comprobanteccosto = 5 THEN 'FACOEP' ELSE '' END as CentroCosto,
  pprnombre,
  CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
  c.tipocomprobantecodigo,
  c.comprobantecodigo,
  c.comprobantefechaemision,
  comprobantecrgnro,
  comprobantecrgimportetotaldeta
  
  FROM comprobantes c
  LEFT JOIN comprobantecrg crg ON crg.comprobanteprefijo = c.comprobanteprefijo and
                                  crg.empcod = c.empcod and
                                  crg.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                  crg.sucursalcodigo = c.sucursalcodigo and
                                  crg.comprobantetipoentidad = c.comprobantetipoentidad and
                                  crg.comprobantecodigo = c.comprobantecodigo and
                                  crg.comprobanteentidadcodigo = c.comprobanteentidadcodigo
  LEFT JOIN obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo
  LEFT JOIN proveedorprestador pp ON pp.pprid = comprobantepprid
  WHERE comprobantefechaemision BETWEEN '2020-01-01' AND '2020-12-31' AND c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') and
                   comprobanteccosto = 5 and c.comprobantecodigo NOT IN ('10788', '10790', '10791')")
Base <- filter(Base, Base$os != "1003 - OSPAÑA")
Base <- unique(Base)

Base <- select(Base, "Efector" = pprnombre, "OS" = os, "TipoFac" = tipocomprobantecodigo, "Fact" = comprobantecodigo, "Emision" = comprobantefechaemision, "Importe" = comprobantecrgimportetotaldeta)

Base <- aggregate(.~Efector+OS+TipoFac+Fact+Emision, Base, sum)

Base <- select(Base, Efector, OS, Emision, Importe)

Base <- aggregate(.~Efector+OS+Emision, Base, sum)


#El codigo 90001071 (1069) es para incluir salud provincia, el importe se mide aparte
