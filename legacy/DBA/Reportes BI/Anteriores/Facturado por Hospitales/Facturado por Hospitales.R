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

Base <- dbGetQuery(con, "SELECT
  pprnombre,
  obsocialescodigo,
  CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
  comprobantecrgdetafinumdoc,
  c.tipocomprobantecodigo,
  c.comprobantecodigo,
  c.comprobantefechaemision,
  comprobantecrgdetimportefactur,
  comprobantecrgdetpractica
  
  FROM comprobantes c
  LEFT JOIN comprobantecrgdet cd ON cd.comprobantetipoentidad = c.comprobantetipoentidad and
  cd.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
  cd.tipocomprobantecodigo = c.tipocomprobantecodigo and
  cd.comprobanteprefijo = c.comprobanteprefijo and
  cd.comprobantecodigo = c.comprobantecodigo
  LEFT JOIN obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo
  LEFT JOIN proveedorprestador pp ON pp.pprid = comprobantepprid
  WHERE comprobantefechaemision BETWEEN '2020-01-01' AND '2020-12-31' AND c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') and
                   obsocialescodigo NOT IN ('90001226', '90001199', '90001162', '90001003', '90001001','90000557','90000110','90000551','90000551','90000101', '90000044')")


Base <- select(Base, "Efector" = pprnombre, "OS" = os, "TipoFac" = tipocomprobantecodigo, "Fact" = comprobantecodigo, "Mes" = comprobantefechaemision, "Importe" = comprobantecrgdetimportefactur)

Base <- aggregate(.~Efector+OS+TipoFac+Fact+Mes, Base, sum)

#Base$Mes <- as.Date(paste("2020",month(Base$Emision),"01", sep= "-"))

Base <- select(Base, Efector, OS, Mes, Importe)

Base <- aggregate(.~Efector+OS+Mes, Base, sum)


#El codigo 90001071 (1069) es para incluir salud provincia, el importe se mide aparte
