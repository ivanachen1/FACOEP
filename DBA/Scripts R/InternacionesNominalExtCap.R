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
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname="facoep",host="172.31.24.12",port="5432",user="postgres",password="facoep2017")

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
							
WHERE af.afitpamiprofe = 1 and informehospingresofechahora BETWEEN '2020-10-01' and '2021-05-31' and InformeHospBajaFecha IS NULL")

Consulta$modo <- ifelse(Consulta$modo == "Capitada", "Capita", "ExtraCapita")

Consulta$informehospprogramada <- ifelse(Consulta$informehospprogramada == 'TRUE', "Programada", "No Programada")

#Consulta$diagnostico <- ifelse(Consulta$diagnostico %like% "CORONAV", "CoVid 19", "Otros")

Consulta <- Consulta[order(Consulta$nro, -Consulta$informehospunidadid),]
Consulta <- Consulta[!duplicated(Consulta$nro),]

Consulta$Sala <- ifelse(Consulta$informehospunidadinternacion == 1 , "UTI", 
                        ifelse(Consulta$informehospunidadinternacion == 2 , "UTI",
                               ifelse(Consulta$informehospunidadinternacion == 3 , "UCO",
                                      ifelse(Consulta$informehospunidadinternacion == 4 , "NEO",
                                             ifelse(Consulta$informehospunidadinternacion == 5 , "PISO",
                                                    ifelse(Consulta$informehospunidadinternacion == 6 , "GUARDIA", ""))))))
Consulta$Dias <- ifelse(is.na(Consulta$fechaegreso), difftime(Sys.Date(),Consulta$fechaingreso, units = "days"), difftime(Consulta$fechaegreso,Consulta$fechaingreso, units = "days"))
Consulta$Dias <- as.numeric(round(Consulta$Dias, digits = 2))
Consulta$Estado <- ifelse(!is.na(Consulta$fechaegreso), "Cerrada", "Activa" )

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
INTERNACIONES <- select(Consulta, 
                        "Informe Nro" = nro,
                        "Hospital" = hospital,
                        "Fecha de Ingreso" = fechaingreso,
                        "Fecha de Egreso" = fechaegreso,
                        "Estado" = Estado,
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


write.csv(INTERNACIONESEXTCAP, "Internaciones.csv")


INTERNACIONESEXTCAP <- filter(INTERNACIONES, INTERNACIONES$Cobertura == "ExtraCapita")


wb <- createWorkbook()
addWorksheet(wb, "Internaciones PAMI Nominal", gridLines = TRUE)
writeData(wb, "Internaciones PAMI Nominal", INTERNACIONESEXTCAP)
saveWorkbook(wb, "Internaciones PAMI ExtraCapita Desde 15.03.2020.xlsx", overwrite = T)
