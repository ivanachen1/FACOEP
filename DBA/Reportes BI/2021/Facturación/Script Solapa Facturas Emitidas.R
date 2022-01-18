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


query <- "SELECT comprobanteccosto,
                      CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
                      c.tipocomprobantecodigo,
                      c.comprobanteprefijo,
                      c.comprobantecodigo,
                      c.comprobantefechaemision,
                      c.comprobantetotalimporte,
                      c.comprobantedetalle,
                      os.obsocialescodigo



  FROM comprobantes c
   LEFT JOIN obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo
                                  
  WHERE c.comprobantetipoentidad = 2"



Bruto <- dbGetQuery(con,query) 


Bruto <- filter(Bruto, Bruto$os != "1003 - OSPAÃ‘A")
Bruto <- filter(Bruto, Bruto$os != "1 - I.N.S.S.J. y P.")