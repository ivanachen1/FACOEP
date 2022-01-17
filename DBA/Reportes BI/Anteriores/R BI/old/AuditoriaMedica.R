########################################### LIBRERIAS ########################################################
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
pw <- {"facoep2017"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep",
                 host = "172.31.24.12", port = 5432, 
                 user = "postgres", password = pw)
rm(pw)
meses <- c("01 - Enero","02 - Febrero","03 - Marzo",
           "04 - Abril","05 - Mayo","06 - Junio",
           "07 - Julio","08 - Agosto","09 - Septiembre",
           "10 - Octubre","11 - Noviembre","12 - Diciembre")
alafecha <- as.integer(format(as.Date(Sys.Date()), "%m"))
realizacion <- Sys.time()
############################################################################################################
CONSULTA <- dbGetQuery(con, "SELECT crgfchemision,crgauditoriamedicafecha,crgdetfechaalta,
                                    crgauditoriamedicausuario, crgdetnumerocph,
                                    c.crgnum, crgdetmotivodebcred, 
                            crgdetmotivodescripcion, crgimpbrutooriginal, crgimpbruto, crgdetimportefacturar,
                            (SELECT MAX(crghistorialfecha) FROM crghistorial WHERE crghistorial.crgnum = c.crgnum AND crghistorial.pprid = c.pprid AND crghistorialestado = 3 AND crghistorialcod >= 2 AND crghistorialfecha > '2020-01-01') AS auditoria
                            FROM crg c
                            LEFT JOIN crgdet cd ON c.crgnum = cd.crgnum and c.pprid = cd.pprid
                            ")
CONSULTA <- filter(CONSULTA, !is.na(auditoria))
CONSULTA<- filter(CONSULTA, CONSULTA$crgauditoriamedicausuario %in% c("ABARE                         ", 
                                                                      "ALROMBOLA                     ", 
                                                                      "SSOCOLINSKY                   ", 
                                                                      "NCARBALLAL                    ", 
                                                                      "OPORFILIO                     ", 
                                                                      "DTRANSTENVOT                  ", 
                                                                      "NDIAZ                         ", 
                                                                      "MELMEAUDY                     ", 
                                                                      "FACUÃ‘A                       ",
                                                                      "GMOURE                        "))
CONSULTA$crgdetfechaalta <- as.Date(CONSULTA$crgdetfechaalta)
CONSULTA$auditoria <- as.Date(CONSULTA$auditoria)
CONSULTA$crgauditoriamedicafecha <- fifelse(CONSULTA$crgauditoriamedicafecha == "0001-01-01", CONSULTA$auditoria, CONSULTA$crgauditoriamedicafecha)
CONSULTA$crgauditoriamedicafecha <- fifelse(is.na(CONSULTA$crgauditoriamedicafecha), CONSULTA$auditoria, CONSULTA$crgauditoriamedicafecha)
CONSULTA$crgauditoriamedicafecha <- fifelse(CONSULTA$crgauditoriamedicafecha < "2020-01-01", CONSULTA$auditoria, CONSULTA$crgauditoriamedicafecha)

AuditoriaMedica <- select(CONSULTA, "FechaAuditoriaMedica" = crgauditoriamedicafecha,
                                    "Auditor" = crgauditoriamedicausuario,
                                    "CRG" = crgnum,
                                    "DPH" = crgdetnumerocph,
                                    "Agrega" = crgdetmotivodebcred,
                                    "AgregadoImporte" = crgdetimportefacturar,
                                    "ImporteFinal" = crgimpbruto)

AuditoriaMedica <- aggregate(.~FechaAuditoriaMedica+Auditor+CRG+DPH+Agrega+ImporteFinal, AuditoriaMedica, sum)
AuditoriaMedica$AgregadoImporte <- ifelse(AuditoriaMedica$Agrega == 42, AuditoriaMedica$AgregadoImporte, 0)
AuditoriaMedica$Agrega <- NULL
AuditoriaMedica <- aggregate(.~FechaAuditoriaMedica+Auditor+CRG+DPH+ImporteFinal, AuditoriaMedica, sum)

AuditoriaMedica$CantidadDPH <- 1
AuditoriaMedica$DPH <- NULL

AuditoriaMedica <- aggregate(.~FechaAuditoriaMedica+Auditor+CRG+ImporteFinal, AuditoriaMedica, sum)

AuditoriaMedica$ImporteOriginal <- AuditoriaMedica$ImporteFinal - AuditoriaMedica$AgregadoImporte

AuditoriaMedica$CantidadCRG <- 1
AuditoriaMedica$CRG <- NULL
AuditoriaMedica <- aggregate(.~FechaAuditoriaMedica+Auditor, AuditoriaMedica, sum)

AuditoriaMedica <- select(AuditoriaMedica,
                          "Fecha" = FechaAuditoriaMedica,
                          Auditor,
                          CantidadCRG, CantidadDPH,
                          ImporteOriginal,
                          AgregadoImporte,
                          ImporteFinal)

wb <- createWorkbook()
addWorksheet(wb, "Auditoria Medica", gridLines = TRUE)
writeData(wb, "Auditoria Medica", AuditoriaMedica)
saveWorkbook(wb, "AuditoriaMedicaupd.xlsx", overwrite = TRUE)
