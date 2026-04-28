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
meses <- c("01 - Enero","02 - Febrero","03 - Marzo",
           "04 - Abril","05 - Mayo","06 - Junio",
           "07 - Julio","08 - Agosto","09 - Septiembre",
           "10 - Octubre","11 - Noviembre","12 - Diciembre")
############################################################################################################

Consulta <- dbGetQuery(con, "SELECT
i.informehospnro as nro,
informehospingresofechahora as FechaIngreso,
informehospegresofechahora as FechaEgreso,
pprnombre as hospital,
afinumdoc as Documento,
afiapenom,
af.afinumbeneficio,
CASE WHEN informehospprestmodo = 1 THEN 'Capitada' ELSE '' END
||
CASE WHEN informehospprestmodo = 2 THEN 'Prestacion' ELSE '' END 
||
CASE WHEN informehospprestmodo = 3 THEN 'En Transito' ELSE '' END as Modo,
CASE WHEN informehospprogramada IS NULL THEN 'No Programada' ELSE 'Programada' END AS programa,
diagdescripcion as Diagnostico,
informehospunidadid, informehospunidadinternacion, informehospegresomotivo, InformeHospBajaFecha,informehospniveliii, afifecnacimiento

FROM informehosp i 
LEFT JOIN informehospunidad iu ON iu.informehospnro = i.informehospnro
LEFT JOIN proveedorprestador pp ON pp.pprid = i.informehospefectorid
LEFT JOIN diagnosticos d ON d.diagcodigo = i.informehospdiagprincipalid
LEFT JOIN afiliado af on af.afinumbeneficio = i.afinumbeneficio and 
							     af.afinumbenid = i.afinumbenid
							
WHERE i.afitpamiprofe = 1 and InformeHospBajaFecha IS NULL and
                       informehospingresofechahora BETWEEN '2019-01-01' and '2021-12-31' and informehospprogramada IS NULL and
                       i.informehospefectorid in (5,13,6,2678,17,4,19,12,21,9,11,10,23,2,26,14,7,8,3,24,20,15,16,22,702,25,425,424,1644,938, 704, 1855, 1466, 697)")

Consulta$modo <- ifelse(Consulta$modo == "Capitada", "Capita", "ExtraCapita")

Consulta$diagnostico <- ifelse(Consulta$diagnostico %like% "CORONAV", "CoVid 19", "Otros")

Consulta <- Consulta[order(Consulta$nro, -Consulta$informehospunidadid),]
Consulta <- Consulta[!duplicated(Consulta$nro),]

Consulta$Sala <- ifelse(Consulta$informehospunidadinternacion == 1 , "UTI", 
                        ifelse(Consulta$informehospunidadinternacion == 2 , "UTI",
                               ifelse(Consulta$informehospunidadinternacion == 3 , "UCO",
                                      ifelse(Consulta$informehospunidadinternacion == 4 , "NEO",
                                             ifelse(Consulta$informehospunidadinternacion == 5 , "PISO",
                                                    ifelse(Consulta$informehospunidadinternacion == 6 , "GUARDIA", ""))))))
Consulta$Dias <- ifelse(is.na(Consulta$fechaegreso),difftime(Sys.Date(),Consulta$fechaingreso, units = "days"), Consulta$fechaegreso)
Consulta$Dias <- as.numeric(round(Consulta$Dias, digits = 0))

InternacionesHoy <- select(filter(Consulta, is.na(Consulta$fechaegreso)), "InformeNro" = nro,
                                     "Ingreso" = fechaingreso,
                                     "Egreso" = fechaegreso,
                                     "Efector" = hospital,
                                     "Sala" = Sala,
                                     "Afiliado" = afiapenom,
                                     "Documento" = documento,
                                     "Beneficio" = afinumbeneficio,
                                     "Capita" = modo,
                                     "Programada" = programa,
                                     "Diagnostico" = diagnostico,
                                     "Estadia" = Dias
                                    ) 

InternacionesHoy <- InternacionesHoy[order(InternacionesHoy[,'Afiliado'],InternacionesHoy[,'Estadia']),]
InternacionesHoy <- InternacionesHoy[!duplicated(InternacionesHoy$Afiliado),]


#write.csv(InternacionesHoy, "Hoy.csv")






Historico <- select(Consulta, "InformeNro" = nro,
                           "Ingreso" = fechaingreso,
                           "Egreso" = fechaegreso,
                           "Efector" = hospital,
                           "Sala" = Sala,
                           "Afiliado" = afiapenom,
                           "Documento" = documento,
                           "Beneficio" = afinumbeneficio,
                           "Capita" = modo,
                           "Programada" = programa,
                           "Diagnostico" = diagnostico,
                           "Estadia" = Dias
)


Historico$year <- year(Historico$Ingreso)
Historico$mes <- month(Historico$Ingreso)
Historico$count <- 1

data <- select(Historico, 
               year, mes, Capita, count)

data <- aggregate(.~year+mes+Capita,data,sum)

data20 <- select(filter(data, year == '2020'), mes, Capita, "Total" = count)
data20$mes <- meses[data20$mes] 
data20 <- spread(data20, mes, Total)

data21 <- select(filter(data, year == '2021'), mes, Capita, "Total" = count)
data21$mes <- meses[data21$mes] 
data21 <- spread(data21, mes, Total)

uti19 <- filter(Consulta, Sala == "UTI")
uco19 <- filter(Consulta, Sala == "UCO")

data19ut <- rbind(uti19, uco19)

data19ut$year <- year(data19ut$fechaingreso)

data19ut$mes <- month(data19ut$fechaingreso)
data19ut$count <- 1

data19ut <- select(filter(data19ut, year == '2019'), mes, modo, "Total" = count)
data19ut$mes <- meses[data19ut$mes] 
data19ut <- aggregate(.~mes+modo, data19ut, sum)
data19ut <- spread(data19ut, mes, Total)

data19 <- select(filter(data, year == '2019'), mes, Capita, "Total" = count)
data19$mes <- meses[data19$mes] 
data19 <- spread(data19, mes, Total)

#write.csv(data20, "2020.csv")
#write.csv(data21, "2021.csv")
write.csv(data19ut, "2019.csv")



Historico <- Historico[order(Historico[,'Afiliado'],Historico[,'Estadia']),]
Historico <- Historico[!duplicated(Historico$Afiliado),]


Historico$Egreso <- fifelse(is.na(Historico$Egreso), Sys.time(), Historico$Egreso)

dates = seq(min(Historico$Ingreso), max(Historico$Egreso), by = "day")


HistoricoCapitaCovid <- filter(Historico, Historico$Capita == "Capita")
HistoricoCapitaCovid <- filter(HistoricoCapitaCovid, HistoricoCapitaCovid$Diagnostico == "CoVid 19")     
                    
HistCapCovUTI <- filter(HistoricoCapitaCovid, HistoricoCapitaCovid$Sala == "UTI")                    
HistCapCovUTI <- data.frame(Fecha = dates,
                    Cantidad = sapply(dates, function(x) sum(x <= HistCapCovUTI$Egreso & x >= HistCapCovUTI$Ingreso)))
HistCapCovUTI$Capita <- "Capita"
HistCapCovUTI$Diagnostico <- "CoVid 19"
HistCapCovUTI$Sala <- "UTI"

HistCapCovUCO <- filter(HistoricoCapitaCovid, HistoricoCapitaCovid$Sala == "UCO")                    
HistCapCovUCO <- data.frame(Fecha = dates,
                            Cantidad = sapply(dates, function(x) sum(x <= HistCapCovUCO$Egreso & x >= HistCapCovUCO$Ingreso)))
HistCapCovUCO$Capita <- "Capita"
HistCapCovUCO$Diagnostico <- "CoVid 19"
HistCapCovUCO$Sala <- "UCO"
                    
HistCapCovNEO <- filter(HistoricoCapitaCovid, HistoricoCapitaCovid$Sala == "NEO")                    
HistCapCovNEO <- data.frame(Fecha = dates,
                            Cantidad = sapply(dates, function(x) sum(x <= HistCapCovNEO$Egreso & x >= HistCapCovNEO$Ingreso)))
HistCapCovNEO$Capita <- "Capita"
HistCapCovNEO$Diagnostico <- "CoVid 19"
HistCapCovNEO$Sala <- "NEO"                    
                    
HistCapCovPISO <- filter(HistoricoCapitaCovid, HistoricoCapitaCovid$Sala == "PISO")                    
HistCapCovPISO <- data.frame(Fecha = dates,
                            Cantidad = sapply(dates, function(x) sum(x <= HistCapCovPISO$Egreso & x >= HistCapCovPISO$Ingreso)))
HistCapCovPISO$Capita <- "Capita"
HistCapCovPISO$Diagnostico <- "CoVid 19"
HistCapCovPISO$Sala <- "PISO"                     
                    
HistCapCovGUARDIA <- filter(HistoricoCapitaCovid, HistoricoCapitaCovid$Sala == "GUARDIA")                    
HistCapCovGUARDIA <- data.frame(Fecha = dates,
                            Cantidad = sapply(dates, function(x) sum(x <= HistCapCovGUARDIA$Egreso & x >= HistCapCovGUARDIA$Ingreso)))
HistCapCovGUARDIA$Capita <- "Capita"
HistCapCovGUARDIA$Diagnostico <- "CoVid 19"
HistCapCovGUARDIA$Sala <- "GUARDIA"  

HistoricoCapitaCovid <- rbind(HistCapCovUTI, HistCapCovUCO, HistCapCovGUARDIA, HistCapCovNEO, HistCapCovPISO)
HistoricoCapitaCovid <- aggregate(.~Fecha+Capita+Diagnostico+Sala, HistoricoCapitaCovid, sum)
HistoricoCapitaCovid <- filter(HistoricoCapitaCovid, HistoricoCapitaCovid$Cantidad != 0)
HistoricoCapitaCovid <- filter(HistoricoCapitaCovid, HistoricoCapitaCovid$Fecha > '2021-01-01')                   


HistoricoCapitaOtros <- filter(Historico, Historico$Capita == "Capita")
HistoricoCapitaOtros <- filter(HistoricoCapitaOtros, HistoricoCapitaOtros$Diagnostico == "Otros")     

HistCapOtrUTI <- filter(HistoricoCapitaOtros, HistoricoCapitaOtros$Sala == "UTI")                    
HistCapOtrUTI <- data.frame(Fecha = dates,
                            Cantidad = sapply(dates, function(x) sum(x <= HistCapOtrUTI$Egreso & x >= HistCapOtrUTI$Ingreso)))
HistCapOtrUTI$Capita <- "Capita"
HistCapOtrUTI$Diagnostico <- "Otros"
HistCapOtrUTI$Sala <- "UTI"

HistCapOtrUCO <- filter(HistoricoCapitaOtros, HistoricoCapitaOtros$Sala == "UCO")                    
HistCapOtrUCO <- data.frame(Fecha = dates,
                            Cantidad = sapply(dates, function(x) sum(x <= HistCapOtrUCO$Egreso & x >= HistCapOtrUCO$Ingreso)))
HistCapOtrUCO$Capita <- "Capita"
HistCapOtrUCO$Diagnostico <- "Otros"
HistCapOtrUCO$Sala <- "UCO"

HistCapOtrNEO <- filter(HistoricoCapitaOtros, HistoricoCapitaOtros$Sala == "NEO")                    
HistCapOtrNEO <- data.frame(Fecha = dates,
                            Cantidad = sapply(dates, function(x) sum(x <= HistCapOtrNEO$Egreso & x >= HistCapOtrNEO$Ingreso)))
HistCapOtrNEO$Capita <- "Capita"
HistCapOtrNEO$Diagnostico <- "Otros"
HistCapOtrNEO$Sala <- "NEO"                    

HistCapOtrPISO <- filter(HistoricoCapitaOtros, HistoricoCapitaOtros$Sala == "PISO")                    
HistCapOtrPISO <- data.frame(Fecha = dates,
                             Cantidad = sapply(dates, function(x) sum(x <= HistCapOtrPISO$Egreso & x >= HistCapOtrPISO$Ingreso)))
HistCapOtrPISO$Capita <- "Capita"
HistCapOtrPISO$Diagnostico <- "Otros"
HistCapOtrPISO$Sala <- "PISO"                     

HistCapOtrGUARDIA <- filter(HistoricoCapitaOtros, HistoricoCapitaOtros$Sala == "GUARDIA")                    
HistCapOtrGUARDIA <- data.frame(Fecha = dates,
                                Cantidad = sapply(dates, function(x) sum(x <= HistCapOtrGUARDIA$Egreso & x >= HistCapOtrGUARDIA$Ingreso)))
HistCapOtrGUARDIA$Capita <- "Capita"
HistCapOtrGUARDIA$Diagnostico <- "Otros"
HistCapOtrGUARDIA$Sala <- "GUARDIA"  

HistoricoCapitaOtros <- rbind(HistCapOtrUTI, HistCapOtrUCO, HistCapOtrGUARDIA, HistCapOtrNEO, HistCapOtrPISO)
HistoricoCapitaOtros <- aggregate(.~Fecha+Capita+Diagnostico+Sala, HistoricoCapitaOtros, sum)
HistoricoCapitaOtros <- filter(HistoricoCapitaOtros, HistoricoCapitaOtros$Cantidad != 0)
HistoricoCapitaOtros <- filter(HistoricoCapitaOtros, HistoricoCapitaOtros$Fecha > '2021-01-01')          



HistoricoExtraCovid <- filter(Historico, Historico$Capita == "ExtraCapita")
HistoricoExtraCovid <- filter(HistoricoExtraCovid, HistoricoExtraCovid$Diagnostico == "CoVid 19")     

HistExtCovUTI <- filter(HistoricoExtraCovid, HistoricoExtraCovid$Sala == "UTI")                    
HistExtCovUTI <- data.frame(Fecha = dates,
                            Cantidad = sapply(dates, function(x) sum(x <= HistExtCovUTI$Egreso & x >= HistExtCovUTI$Ingreso)))
HistExtCovUTI$Capita <- "ExtraCapita"
HistExtCovUTI$Diagnostico <- "CoVid 19"
HistExtCovUTI$Sala <- "UTI"

HistExtCovUCO <- filter(HistoricoExtraCovid, HistoricoExtraCovid$Sala == "UCO")                    
HistExtCovUCO <- data.frame(Fecha = dates,
                            Cantidad = sapply(dates, function(x) sum(x <= HistExtCovUCO$Egreso & x >= HistExtCovUCO$Ingreso)))
HistExtCovUCO$Capita <- "ExtraCapita"
HistExtCovUCO$Diagnostico <- "CoVid 19"
HistExtCovUCO$Sala <- "UCO"

HistExtCovNEO <- filter(HistoricoExtraCovid, HistoricoExtraCovid$Sala == "NEO")                    
HistExtCovNEO <- data.frame(Fecha = dates,
                            Cantidad = sapply(dates, function(x) sum(x <= HistExtCovNEO$Egreso & x >= HistExtCovNEO$Ingreso)))
HistExtCovNEO$Capita <- "ExtraCapita"
HistExtCovNEO$Diagnostico <- "CoVid 19"
HistExtCovNEO$Sala <- "NEO"                    

HistExtCovPISO <- filter(HistoricoExtraCovid, HistoricoExtraCovid$Sala == "PISO")                    
HistExtCovPISO <- data.frame(Fecha = dates,
                             Cantidad = sapply(dates, function(x) sum(x <= HistExtCovPISO$Egreso & x >= HistExtCovPISO$Ingreso)))
HistExtCovPISO$Capita <- "ExtraCapita"
HistExtCovPISO$Diagnostico <- "CoVid 19"
HistExtCovPISO$Sala <- "PISO"                     

HistExtCovGUARDIA <- filter(HistoricoExtraCovid, HistoricoExtraCovid$Sala == "GUARDIA")                    
HistExtCovGUARDIA <- data.frame(Fecha = dates,
                                Cantidad = sapply(dates, function(x) sum(x <= HistExtCovGUARDIA$Egreso & x >= HistExtCovGUARDIA$Ingreso)))
HistExtCovGUARDIA$Capita <- "ExtraCapita"
HistExtCovGUARDIA$Diagnostico <- "CoVid 19"
HistExtCovGUARDIA$Sala <- "GUARDIA"  

HistoricoExtraCovid <- rbind(HistExtCovUTI, HistExtCovUCO, HistExtCovGUARDIA, HistExtCovNEO, HistExtCovPISO)
HistoricoExtraCovid <- aggregate(.~Fecha+Capita+Diagnostico+Sala, HistoricoExtraCovid, sum)
HistoricoExtraCovid <- filter(HistoricoExtraCovid, HistoricoExtraCovid$Cantidad != 0)
HistoricoExtraCovid <- filter(HistoricoExtraCovid, HistoricoExtraCovid$Fecha > '2021-01-01')                   


HistoricoExtraOtros <- filter(Historico, Historico$Capita == "ExtraCapita")
HistoricoExtraOtros <- filter(HistoricoExtraOtros, HistoricoExtraOtros$Diagnostico == "Otros")     

HistExtOtrUTI <- filter(HistoricoExtraOtros, HistoricoExtraOtros$Sala == "UTI")                    
HistExtOtrUTI <- data.frame(Fecha = dates,
                            Cantidad = sapply(dates, function(x) sum(x <= HistExtOtrUTI$Egreso & x >= HistExtOtrUTI$Ingreso)))
HistExtOtrUTI$Capita <- "ExtraCapita"
HistExtOtrUTI$Diagnostico <- "Otros"
HistExtOtrUTI$Sala <- "UTI"

HistExtOtrUCO <- filter(HistoricoExtraOtros, HistoricoExtraOtros$Sala == "UCO")                    
HistExtOtrUCO <- data.frame(Fecha = dates,
                            Cantidad = sapply(dates, function(x) sum(x <= HistExtOtrUCO$Egreso & x >= HistExtOtrUCO$Ingreso)))
HistExtOtrUCO$Capita <- "ExtraCapita"
HistExtOtrUCO$Diagnostico <- "Otros"
HistExtOtrUCO$Sala <- "UCO"

HistExtOtrNEO <- filter(HistoricoExtraOtros, HistoricoExtraOtros$Sala == "NEO")                    
HistExtOtrNEO <- data.frame(Fecha = dates,
                            Cantidad = sapply(dates, function(x) sum(x <= HistExtOtrNEO$Egreso & x >= HistExtOtrNEO$Ingreso)))
HistExtOtrNEO$Capita <- "ExtraCapita"
HistExtOtrNEO$Diagnostico <- "Otros"
HistExtOtrNEO$Sala <- "NEO"                    

HistExtOtrPISO <- filter(HistoricoExtraOtros, HistoricoExtraOtros$Sala == "PISO")                    
HistExtOtrPISO <- data.frame(Fecha = dates,
                             Cantidad = sapply(dates, function(x) sum(x <= HistExtOtrPISO$Egreso & x >= HistExtOtrPISO$Ingreso)))
HistExtOtrPISO$Capita <- "ExtraCapita"
HistExtOtrPISO$Diagnostico <- "Otros"
HistExtOtrPISO$Sala <- "PISO"                     

HistExtOtrGUARDIA <- filter(HistoricoExtraOtros, HistoricoExtraOtros$Sala == "GUARDIA")                    
HistExtOtrGUARDIA <- data.frame(Fecha = dates,
                                Cantidad = sapply(dates, function(x) sum(x <= HistExtOtrGUARDIA$Egreso & x >= HistExtOtrGUARDIA$Ingreso)))
HistExtOtrGUARDIA$Capita <- "ExtraCapita"
HistExtOtrGUARDIA$Diagnostico <- "Otros"
HistExtOtrGUARDIA$Sala <- "GUARDIA"  

HistoricoExtraOtros <- rbind(HistExtOtrUTI, HistExtOtrUCO, HistExtOtrGUARDIA, HistExtOtrNEO, HistExtOtrPISO)
HistoricoExtraOtros <- aggregate(.~Fecha+Capita+Diagnostico+Sala, HistoricoExtraOtros, sum)
HistoricoExtraOtros <- filter(HistoricoExtraOtros, HistoricoExtraOtros$Cantidad != 0)
HistoricoExtraOtros <- filter(HistoricoExtraOtros, HistoricoExtraOtros$Fecha > '2021-01-01')          




HistoricoFiNAL <- rbind(HistoricoCapitaCovid, HistoricoCapitaOtros, HistoricoExtraCovid, HistoricoExtraOtros)


write.csv(HistoricoFiNAL, "Historia2021.csv")
