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
meses <- c("01 - Enero","02 - Febrero","03 - Marzo",
           "04 - Abril","05 - Mayo","06 - Junio",
           "07 - Julio","08 - Agosto","09 - Septiembre",
           "10 - Octubre","11 - Noviembre","12 - Diciembre")
pw <- {"facoep2017"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep", host = "172.31.24.12", port = 5432, user = "postgres", password = pw)
postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")
Bruto <- dbGetQuery(con, "SELECT
                      CASE WHEN comprobanteccosto = 1 THEN  'PAMI' ELSE '' END
                      ||
                      CASE WHEN comprobanteccosto = 2 THEN 'INCLUIR' ELSE '' END
                      ||
                      CASE WHEN comprobanteccosto = 5 THEN 'FACOEP' ELSE '' END 
                      ||
                      CASE WHEN comprobanteccosto = 9 THEN 'ASI' ELSE '' END as CentroCosto,
                      CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
  c.tipocomprobantecodigo,
  c.comprobantecodigo,
  c.comprobantefechaemision,
  comprobantetotalimporte

  FROM comprobantes c
   LEFT JOIN obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo
                                  
  WHERE comprobantefechaemision BETWEEN '2021-01-01' AND '2021-12-31' AND 
  c.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') and 
  c.comprobantetipoentidad = 2
                   ")
Bruto <- unique(Bruto)
Bruto <- filter(Bruto, Bruto$os != "1003 - OSPAÑA")
Bruto <- filter(Bruto, Bruto$os != "1 - I.N.S.S.J. y P.")
Bruto <- Bruto[!duplicated(Bruto$comprobantecodigo), ]

Debitado <- dbGetQuery(con, "SELECT
                      CASE WHEN ccosto.comprobanteccosto = 1 THEN  'PAMI' ELSE '' END
                      ||
                      CASE WHEN ccosto.comprobanteccosto = 2 THEN 'INCLUIR' ELSE '' END
                      ||
                      CASE WHEN ccosto.comprobanteccosto = 5 THEN 'FACOEP' ELSE '' END
                      ||
                      CASE WHEN ccosto.comprobanteccosto = 9 THEN 'ASI' ELSE '' END as CentroCosto,
                      CASE WHEN c.comprobanteccosto = 1 THEN  'PAMI' ELSE '' END
                      ||
                      CASE WHEN c.comprobanteccosto = 2 THEN 'INCLUIR' ELSE '' END
                      ||
                      CASE WHEN c.comprobanteccosto = 5 THEN 'FACOEP' ELSE '' END
                      ||
                      CASE WHEN c.comprobanteccosto = 9 THEN 'ASI' ELSE '' END as CentroCosto2,
                      CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
  c.tipocomprobantecodigo,
  c.comprobantecodigo,
  c.comprobantefechaemision,
  c.comprobantetotalimporte

  FROM comprobantes c
   LEFT JOIN obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo
  
  LEFT JOIN comprobantesasociados a ON a.comprobanteprefijo = c.comprobanteprefijo and
                                       a.empcod = c.empcod and
                                       a.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                       a.sucursalcodigo = c.sucursalcodigo and
                                       a.comprobantetipoentidad = c.comprobantetipoentidad and
                                       a.comprobantecodigo = c.comprobantecodigo and
                                       a.comprobanteentidadcodigo = c.comprobanteentidadcodigo
  
  LEFT JOIN comprobantes ccosto ON a.comprobanteasoctipo = ccosto.tipocomprobantecodigo and
                                   a.comprobanteasocprefijo = ccosto.comprobanteprefijo and
                                   a.comprobanteasoccodigo = ccosto.comprobantecodigo
                                  
  WHERE c.comprobantefechaemision BETWEEN '2021-01-01' AND '2021-12-31' AND c.tipocomprobantecodigo IN ('NDA', 'NDB', 'NDECA')
                   ")
Debitado$centrocosto2 <- ifelse(Debitado$centrocosto2 == "", Debitado$centrocosto, Debitado$centrocosto2)
Debitado$centrocosto2 <- ifelse(Debitado$centrocosto2 == "", "INCLUIR", Debitado$centrocosto2)
Debitado$centrocosto <- Debitado$centrocosto2
Debitado$centrocosto2 <- NULL
Debitado <- filter(Debitado, Debitado$os != "1003 - OSPAÑA")
Debitado <- filter(Debitado, Debitado$os != "1 - I.N.S.S.J. y P.")
Debitado <- unique(Debitado)

NotasCredito <- dbGetQuery(con, "SELECT
                      CASE WHEN ccosto.comprobanteccosto = 1 THEN  'PAMI' ELSE '' END
                      ||
                      CASE WHEN ccosto.comprobanteccosto = 2 THEN 'INCLUIR' ELSE '' END
                      ||
                      CASE WHEN ccosto.comprobanteccosto = 5 THEN 'FACOEP' ELSE '' END
                      ||
                      CASE WHEN ccosto.comprobanteccosto = 9 THEN 'ASI' ELSE '' END as CentroCosto,
                      CASE WHEN c.comprobanteccosto = 1 THEN  'PAMI' ELSE '' END
                      ||
                      CASE WHEN c.comprobanteccosto = 2 THEN 'INCLUIR' ELSE '' END
                      ||
                      CASE WHEN c.comprobanteccosto = 5 THEN 'FACOEP' ELSE '' END
                      ||
                      CASE WHEN c.comprobanteccosto = 9 THEN 'ASI' ELSE '' END as CentroCosto2,
                      CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
  c.tipocomprobantecodigo,
  c.comprobantecodigo,
  c.comprobantefechaemision,
  c.comprobantetotalimporte

  FROM comprobantes c
   LEFT JOIN obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo
  
  LEFT JOIN comprobantesasociados a ON a.comprobanteprefijo = c.comprobanteprefijo and
                                       a.empcod = c.empcod and
                                       a.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                       a.sucursalcodigo = c.sucursalcodigo and
                                       a.comprobantetipoentidad = c.comprobantetipoentidad and
                                       a.comprobantecodigo = c.comprobantecodigo and
                                       a.comprobanteentidadcodigo = c.comprobanteentidadcodigo
  
  LEFT JOIN comprobantes ccosto ON a.comprobanteasoctipo = ccosto.tipocomprobantecodigo and
                                   a.comprobanteasocprefijo = ccosto.comprobanteprefijo and
                                   a.comprobanteasoccodigo = ccosto.comprobantecodigo
                                  
  WHERE c.comprobantefechaemision BETWEEN '2021-01-01' AND '2021-12-31' AND c.tipocomprobantecodigo IN ('NCA', 'NCB', 'NCECA')
                   ")
NotasCredito <- filter(NotasCredito, NotasCredito$os != "1003 - OSPAÑA")
NotasCredito <- filter(NotasCredito, NotasCredito$os != "1 - I.N.S.S.J. y P.")
NotasCredito$centrocosto2 <- ifelse(NotasCredito$centrocosto2 == "", NotasCredito$centrocosto, NotasCredito$centrocosto2)
NotasCredito$centrocosto <- NotasCredito$centrocosto2
NotasCredito$centrocosto2 <- NULL
NotasCredito <- unique(NotasCredito)
NotasCredito <- NotasCredito[!duplicated(NotasCredito$comprobantecodigo), ]


Comprobantes <- rbind(Bruto, Debitado, NotasCredito)
Comprobantes$comprobantetotalimporte <- ifelse(Comprobantes$tipocomprobantecodigo %like% "NC", Comprobantes$comprobantetotalimporte * -1, Comprobantes$comprobantetotalimporte)
Comprobantes2 <- filter(Comprobantes, Comprobantes$tipocomprobantecodigo == "NCB    ", Comprobantes$comprobantecodigo == 4476)
Comprobantes <- anti_join(Comprobantes, Comprobantes2)
