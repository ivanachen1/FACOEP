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
library(lubridate)
library("RPostgreSQL")
pw <- {"asi"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "Facoep", host = "10.1.1.2", port = 5432, user = "asi", password = pw)
rm(pw)
meses <- c("01 - Enero","02 - Febrero","03 - Marzo",
           "04 - Abril","05 - Mayo","06 - Junio",
           "07 - Julio","08 - Agosto","09 - Septiembre",
           "10 - Octubre","11 - Noviembre","12 - Diciembre")
alafecha <- as.Date(Sys.Date())
realizacion <- Sys.time()
Resultados <- "C:/Users/Administrator/Google Drive"                                                                                        
setwd(Resultados)


############################################################################################################

Consulta <- dbGetQuery(con, "SELECT
i.informehospnro as nro,
informehospingresofechahora as FechaIngreso,
informehospegresofechahora as FechaEgreso,
i.informehospefectorid,
pprnombre as hospital,
afinumdoc as Documento,
afiapenom,
af.afinumbeneficio,
CASE WHEN informehospprestmodo = 1 THEN 'Capitada' ELSE '' END
||
CASE WHEN informehospprestmodo = 2 THEN 'Prestacion' ELSE '' END 
||
CASE WHEN informehospprestmodo = 3 THEN 'En Transito' ELSE '' END as Modo,
informehospprogramada,
diagdescripcion as Diagnostico,
informehospunidadid, informehospunidadinternacion, informehospegresomotivo, InformeHospBajaFecha,informehospniveliii, afifecnacimiento

FROM informehosp i 
LEFT JOIN informehospunidad iu ON iu.informehospnro = i.informehospnro
LEFT JOIN proveedorprestador pp ON pp.pprid = i.informehospefectorid
LEFT JOIN diagnosticos d ON d.diagcodigo = i.informehospdiagprincipalid
LEFT JOIN afiliado af on af.afinumbeneficio = i.afinumbeneficio and 
							     af.afinumbenid = i.afinumbenid
							
WHERE i.afitpamiprofe = 1 and informehospegresofechahora IS NULL and InformeHospBajaFecha IS NULL and
                       informehospingresofechahora >= '2020-01-01' and (informehospegresomotivo IS NULL OR informehospegresomotivo = 0) and
                       i.informehospefectorid in (5,13,6,2678,17,4,19,12,21,9,11,10,23,2,26,14,7,8,3,24,20,15,16,22,702,25,425,424,1644,938, 704, 1855, 1466, 697)")

Consulta$modo <- ifelse(Consulta$modo == "Capitada", "Capita", "ExtraCapita")

Consulta$informehospprogramada <- ifelse(Consulta$informehospprogramada == 'TRUE', "Programada", "No Programada")

Consulta$diagnostico <- ifelse(Consulta$diagnostico %like% "CORONAV", "CoVid 19", "Otros")

Consulta <- Consulta[order(Consulta$nro, -Consulta$informehospunidadid),]
Consulta <- Consulta[!duplicated(Consulta$nro),]

Consulta$Sala <- ifelse(Consulta$informehospunidadinternacion == 1 , "UTI", 
                        ifelse(Consulta$informehospunidadinternacion == 2 , "UTI",
                               ifelse(Consulta$informehospunidadinternacion == 3 , "UCO",
                                      ifelse(Consulta$informehospunidadinternacion == 4 , "NEO",
                                             ifelse(Consulta$informehospunidadinternacion == 5 , "PISO",
                                                    ifelse(Consulta$informehospunidadinternacion == 6 , "GUARDIA", ""))))))
Consulta$Dias <- difftime(Sys.Date(),Consulta$fechaingreso, units = "days")
Consulta$Dias <- as.numeric(round(Consulta$Dias, digits = 0))

#Consulta$fechaingreso <- as.Date(Consulta$fechaingreso)

#duplicados <- Consulta[duplicated(Consulta$afiapenom) | duplicated(Consulta$afiapenom, fromLast = TRUE), ]
#duplicados <- select(duplicados, "Internacion Nro" = nro,
#                                  "Ingreso" = fechaingreso,
#                                   "Egreso" = fechaegreso,
#                                    "Hospital" = hospital,
#                                      "Documento" = documento,
#                                        "Nombre" = afiapenom,
#                                          "Modo" = modo,
#                                            "Diagnostico" = diagnostico)
#duplicados <- duplicados[order(duplicados$Nombre),]
#write.xlsx(duplicados, "Internaciones duplicadas.xlsx")
INTERNACIONES <- select(Consulta, "Hospital" = hospital,
                        "Fecha de Ingreso" = fechaingreso,
                        "Dias de estadia" = Dias, 
                        "Documento" = documento,
                        "Nombre" = afiapenom,
                        "Beneficio" = afinumbeneficio,
                        "Cobertura" = modo,
                        "Programada" = informehospprogramada,
                        "Diagnostico" = diagnostico,
                        "Sala" = Sala)

INTERNACIONES$Hospital <- ifelse(INTERNACIONES$Hospital == "HOSPITAL ALVAREZ                        ", "Alvarez",
                                 ifelse(INTERNACIONES$Hospital == "HOSPITAL ZUBIZARRETA                    ", "Zubizarreta",
                                        ifelse(INTERNACIONES$Hospital == "HOSPITAL SANTOJANNI                     ", "Santojanni",
                                               ifelse(INTERNACIONES$Hospital == "HOSPITAL RAMOS MEJIA                    ", "Ramos Mejia",
                                                      ifelse(INTERNACIONES$Hospital == "HOSPITAL PIROVANO                       ", "Pirovano",
                                                             ifelse(INTERNACIONES$Hospital == "HOSPITAL ARGERICH                       ", "Argerich",
                                                                    ifelse(INTERNACIONES$Hospital == "HOSPITAL DURAND                         ", "Durand",
                                                                           ifelse(INTERNACIONES$Hospital == "HOSPITAL PINERO                         ", "Piñero",
                                                                                  ifelse(INTERNACIONES$Hospital == "HOSPITAL TORNU                          ", "Tornu",
                                                                                         ifelse(INTERNACIONES$Hospital == "HOSPITAL RIVADAVIA                      ", "Rivadavia",
                                                                                                ifelse(INTERNACIONES$Hospital == "HOSPITAL MARIA CURIE                    ", "Curie",
                                                                                                       ifelse(INTERNACIONES$Hospital == "HOSPITAL UDAONDO                        ", "Udaondo",
                                                                                                              ifelse(INTERNACIONES$Hospital == "HOSPITAL PENNA                          ", "Penna",
                                                                                                                     ifelse(INTERNACIONES$Hospital == "HOSPITAL MUÃ‘IZ                          ", "Muñiz",
                                                                                                                            ifelse(INTERNACIONES$Hospital == "HOSPITAL FERNANDEZ                      ", "Fernandez",
                                                                                                                                   ifelse(INTERNACIONES$Hospital == "HOSPITAL VELEZ SARSFIELD                ", "Velez",
                                                                                                                                          ifelse(INTERNACIONES$Hospital == "HOSPITAL ROCCA                          ", "Rocca",
                                                                                                                                                 ifelse(INTERNACIONES$Hospital == "INSTITUTO DE REHABILITAC. PSICOFISICA   ", "I.R.E.P.",
                                                                                                                                                        ifelse(INTERNACIONES$Hospital == "HOSPITAL DRA. CECILIA GRIERSON          ", "Grierson",
                                                                                                                                                               ifelse(INTERNACIONES$Hospital == "HOSPITAL DE QUEMADOS                    ", "Quemados",
                                                                                                                                                                      ifelse(INTERNACIONES$Hospital == "HOSPITAL MARIA FERRER                   ", "Ferrer",
                                                                                                                                                                             ifelse(INTERNACIONES$Hospital == "HOSPITAL GUTIERREZ                      ", "Gutierrez",
                                                                                                                                                                                    ifelse(INTERNACIONES$Hospital == "HOSPITAL LAGLEYZE                       ", "Lagleyze",
                                                                                                                                                                                           ifelse(INTERNACIONES$Hospital == "HOSPITAL SANTA LUCIA                    ", "Santa Lucia",
                                                                                                                                                                                                  ifelse(INTERNACIONES$Hospital == "HOSPITAL SARDA                          ", "Sarda", INTERNACIONES$Hospital)))))))))))))))))))))))))





INTERNACIONES <- INTERNACIONES[!duplicated(INTERNACIONES$Documento),]

CRONICAS <- filter(Consulta, informehospniveliii == TRUE)
CRONICAS <- select(CRONICAS, "Hospital" = hospital,
                   "Fecha de Ingreso" = fechaingreso,
                   "Dias de estadia" = Dias, 
                   "Documento" = documento,
                   "Nombre" = afiapenom,
                   "Nacimiento" = afifecnacimiento,
                   "Cobertura" = modo,
                   "Diagnostico" = diagnostico,
                   "Sala" = Sala)
CRONICAS$Hospital <- ifelse(CRONICAS$Hospital == "HOSPITAL ALVAREZ                        ", "Alvarez",
                            ifelse(CRONICAS$Hospital == "HOSPITAL ZUBIZARRETA                    ", "Zubizarreta",
                                   ifelse(CRONICAS$Hospital == "HOSPITAL SANTOJANNI                     ", "Santojanni",
                                          ifelse(CRONICAS$Hospital == "HOSPITAL RAMOS MEJIA                    ", "Ramos Mejia",
                                                 ifelse(CRONICAS$Hospital == "HOSPITAL PIROVANO                       ", "Pirovano",
                                                        ifelse(CRONICAS$Hospital == "HOSPITAL ARGERICH                       ", "Argerich",
                                                               ifelse(CRONICAS$Hospital == "HOSPITAL DURAND                         ", "Durand",
                                                                      ifelse(CRONICAS$Hospital == "HOSPITAL PINERO                         ", "Piñero",
                                                                             ifelse(CRONICAS$Hospital == "HOSPITAL TORNU                          ", "Tornu",
                                                                                    ifelse(CRONICAS$Hospital == "HOSPITAL RIVADAVIA                      ", "Rivadavia",
                                                                                           ifelse(CRONICAS$Hospital == "HOSPITAL MARIA CURIE                    ", "Curie",
                                                                                                  ifelse(CRONICAS$Hospital == "HOSPITAL UDAONDO                        ", "Udaondo",
                                                                                                         ifelse(CRONICAS$Hospital == "HOSPITAL PENNA                          ", "Penna",
                                                                                                                ifelse(CRONICAS$Hospital == "HOSPITAL MUÃ‘IZ                          ", "Muñiz",
                                                                                                                       ifelse(CRONICAS$Hospital == "HOSPITAL FERNANDEZ                      ", "Fernandez",
                                                                                                                              ifelse(CRONICAS$Hospital == "HOSPITAL VELEZ SARSFIELD                ", "Velez",
                                                                                                                                     ifelse(CRONICAS$Hospital == "HOSPITAL ROCCA                          ", "Rocca",
                                                                                                                                            ifelse(CRONICAS$Hospital == "INSTITUTO DE REHABILITAC. PSICOFISICA   ", "I.R.E.P.",
                                                                                                                                                   ifelse(CRONICAS$Hospital == "HOSPITAL DRA. CECILIA GRIERSON          ", "Grierson",
                                                                                                                                                          ifelse(CRONICAS$Hospital == "HOSPITAL DE QUEMADOS                    ", "Quemados",
                                                                                                                                                                 ifelse(CRONICAS$Hospital == "HOSPITAL MARIA FERRER                   ", "Ferrer",
                                                                                                                                                                        ifelse(CRONICAS$Hospital == "HOSPITAL GUTIERREZ                      ", "Gutierrez",
                                                                                                                                                                               ifelse(CRONICAS$Hospital == "HOSPITAL LAGLEYZE                       ", "Lagleyze",
                                                                                                                                                                                      ifelse(CRONICAS$Hospital == "HOSPITAL SANTA LUCIA                    ", "Santa Lucia",
                                                                                                                                                                                             ifelse(CRONICAS$Hospital == "HOSPITAL SARDA                          ", "Sarda", CRONICAS$Hospital)))))))))))))))))))))))))





wb <- createWorkbook()
addWorksheet(wb, "Internaciones PAMI Nominal", gridLines = TRUE)
addWorksheet(wb, "Internaciones PAMI Cronicas", gridLines = TRUE)
writeData(wb, "Internaciones PAMI Nominal", INTERNACIONES)
writeData(wb, "Internaciones PAMI Cronicas", CRONICAS)
saveWorkbook(wb, "Internaciones.xlsx", overwrite = T)
