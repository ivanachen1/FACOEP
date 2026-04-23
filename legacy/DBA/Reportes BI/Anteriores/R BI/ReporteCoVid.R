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
meses <- c("01 - Enero","02 - Febrero","03 - Marzo",
           "04 - Abril","05 - Mayo","06 - Junio",
           "07 - Julio","08 - Agosto","09 - Septiembre",
           "10 - Octubre","11 - Noviembre","12 - Diciembre")
alafecha <- as.integer(format(as.Date(Sys.Date()), "%m"))

realizacion <- Sys.time()

pw <- {"facoep2017"} 
drv <- dbDriver("PostgreSQL")

facoep <- dbConnect(drv, dbname = "facoep",
                    host = "172.31.24.12", port = 5432, 
                    user = "postgres", password = pw)

############################################################################################################

ConsultaSolicitudes <- dbGetQuery(facoep,"SELECT derivaalfechahora as fecha, 
                                  s.pprnombre as entrada,
                                  CASE WHEN derivatipocama = 1 THEN 'UTIM' ELSE '' END
                                  ||
                                  CASE WHEN derivatipocama = 2 THEN 'UCO' ELSE '' END
                                  ||
                                  CASE WHEN derivatipocama = 3 THEN 'PISO' ELSE '' END as unidadentrada,
                                  CASE WHEN derivacobertura = 1 THEN 'PAMI' ELSE '' END 
                                  ||
                                  CASE WHEN derivacobertura = 2 THEN 'OOSS' ELSE '' END 
                                  ||
                                  CASE WHEN derivacobertura = 3 THEN 'Sin Cobertura' ELSE '' END AS cobertura,
                                  CASE WHEN derivacapitafacoep = TRUE THEN 'Capita' ELSE 'ExtraCapita' END AS capita,
                                  r.pprnombre as egreso,
                                  derivaefectorreceunidad as unidadegreso,
                                  derivaestado as estado,
                                  derivatipocierre as estadocierre,
                                  diagdescripcion as Diagnostico
                                  
                                  FROM derivaciones d
                                  LEFT JOIN proveedorprestador s on s.pprid = d.derivaefectorsolichospcod
                                  LEFT JOIN proveedorprestador r on r.pprid = d.derivaefectorrecehospcod
                                  LEFT JOIN diagnosticos dg ON dg.diagcodigo = d.diagcodigo
                                  ")

ConsultaSolicitudes$entrada <- ifelse(ConsultaSolicitudes$entrada %like% "HOSPITAL ", "Hospital", 
                                      ifelse(ConsultaSolicitudes$entrada %like% "PAMI", "PAMI",
                                             ifelse(ConsultaSolicitudes$entrada %like% "DETECTAR", "Detectar", 
                                                    ifelse(ConsultaSolicitudes$entrada %like% "RESIDENCIA", "Geriatrico", 
                                                           ifelse(ConsultaSolicitudes$entrada %like% "U.F.U.", "UFU",
                                                                  ifelse(ConsultaSolicitudes$entrada %like% "HOTELES", "Hoteles", "Otros"))))))

ConsultaSolicitudes$capita2 <- fifelse(ConsultaSolicitudes$cobertura == "OOSS", "OOSS", fifelse(ConsultaSolicitudes$cobertura == "Sin Cobertura", "Sin Cobertura", ConsultaSolicitudes$capita)) 


ConsultaSolicitudes$egreso <- ifelse(is.na(ConsultaSolicitudes$egreso), "Sin Receptor", ConsultaSolicitudes$egreso)

ConsultaSolicitudes$unidadegreso <- ifelse(is.na(ConsultaSolicitudes$unidadegreso), 0, ConsultaSolicitudes$unidadegreso)
ConsultaSolicitudes$unidadegreso <- ifelse(ConsultaSolicitudes$unidadegreso == 1, "UTIM", 
                                           ifelse(ConsultaSolicitudes$unidadegreso == 2, "UCO", 
                                                  ifelse(ConsultaSolicitudes$unidadegreso == 3, "PISO", 
                                                         ifelse(ConsultaSolicitudes$unidadegreso == 0, "Sin Receptor",
                                                                ifelse(is.na(ConsultaSolicitudes$unidadegreso), "Sin Receptor", "REVISAR R" )))))

ConsultaSolicitudes$estado <- ifelse(!is.na(ConsultaSolicitudes$estadocierre), 6, ConsultaSolicitudes$estado)

ConsultaSolicitudes$estadocierre <- ifelse(is.na(ConsultaSolicitudes$estadocierre),0,ConsultaSolicitudes$estadocierre)
ConsultaSolicitudes$estadocierre <- ifelse(ConsultaSolicitudes$estadocierre == 1, "Alta", 
                                           ifelse(ConsultaSolicitudes$estadocierre == 2, "Retiro Voluntario",
                                            ifelse(ConsultaSolicitudes$estadocierre == 3, "Obito", 
                                                   ifelse(ConsultaSolicitudes$estadocierre == 0,"Sin Cierre",
                                                          ifelse(ConsultaSolicitudes$estadocierre == 4,"Aislamiento Domiciliario",ifelse(is.na(ConsultaSolicitudes$estadocierre), "Sin Estado", "REVISAR R" ))))))

ConsultaSolicitudes$estado <- ifelse(ConsultaSolicitudes$estado == 1, "Pendiente", 
                                     ifelse(ConsultaSolicitudes$estado == 2, "Traslado a RED", 
                                            ifelse(ConsultaSolicitudes$estado == 3, "Rechazo Conformado", 
                                                   ifelse(ConsultaSolicitudes$estado == 4, "Traslado PAMI", 
                                                          ifelse(ConsultaSolicitudes$estado == 5, "Traslado OS", 
                                                                 ifelse(ConsultaSolicitudes$estado == 6, "Cerrado", 
                                                                        ifelse(ConsultaSolicitudes$estado == 7, "Rechazo No Conformado",
                                                                               ifelse(ConsultaSolicitudes$estado == 8, "Traslado SAME",
                                                                                      ifelse(ConsultaSolicitudes$estado == 9, "Traslado en Taxi","")))))))))



ConsultaSolicitudes$diagnostico <- ifelse(ConsultaSolicitudes$diagnostico %like% "CORONAV", "CoVid 19", "Otros")


ConsultaSolicitudes$fecha <- as.Date(ConsultaSolicitudes$fecha)

Efectores <- data.frame(egreso = c("EFECTORES EXTRAHOSPITALARIOS            ", 
                                      "HOSPITAL LAGLEYZE                       ",
                                      "HOSPITAL DRA. CECILIA GRIERSON          ",
                                      "HOSPITAL SANTOJANNI                     ",
                                      "HOSPITAL PIROVANO                       ",
                                      "HOSPITAL MUÃ‘IZ                          ",
                                      "HOSPITAL DURAND                         ",
                                      "S.A.M.E.                                ",
                                      "HOSPITAL SANTA LUCIA                    ",
                                      "HOSPITAL ZUBIZARRETA                    ",
                                      "HOSPITAL ARGERICH                       ",
                                      "HOSPITAL RIVADAVIA                      ",
                                      "HOSPITAL TORNU                          ", 
                                      "HOSPITAL PENNA                          ", 
                                      "HOSPITAL GUTIERREZ                      ",
                                      "HOSPITAL RAMOS MEJIA                    ", 
                                      "HOSPITAL ALVAREZ                        ", 
                                      "HOSPITAL FERNANDEZ                      ",
                                      "HOSPITAL ELIZALDE                       ", 
                                      "HOSPITAL PINERO                         ", 
                                      "HOSPITAL VELEZ SARSFIELD                ",
                                      "HOSPITAL UDAONDO                        ", 
                                      "HOSPITAL MARIA FERRER                   ", 
                                      "HOSPITAL ODONTO INFAN QUINQUELA MARTIN  ",
                                      "HOSPITAL DE ODONTOLOGIA-DR. J. DUENAS   ", 
                                      "HOSPITAL ROCCA                          ", 
                                      "HOSPITAL MOYANO                         ",
                                      "HOSPITAL PSIQUIATRICAS T . DE ALVEAR    ", 
                                      "HOSPITAL SARDA                          ", 
                                      "HOSPITAL MARIA CURIE                    ",
                                      "HOSPITAL DE QUEMADOS                    ", 
                                      "HOSPITAL DE ODONT. RAMON CARRILLO       ", 
                                      "INSTITUTO DE REHABILITAC. PSICOFISICA   ",
                                      "HOSPITAL TOBAR GARCIA                   ",
                                      "TALLERES PROTEGIDOS DE REHABILITACION PS",
                                      "HOSPITAL BORDA                          ",
                                      "DISPOSITIVO TURISTAS                    ",
                                      "Cesacs",
                                      "Sin Receptor",
                                   "HOTELES                                 ",
                                   "GUARDIA PAMI (DAMNPYP)                  ",
                        "SOC. ESPAÃ‘OLA DE BENEF. HTAL. ESPAÃ‘OL   ",
                        "U.F.U. - OPERATIVO DETECTAR             ",
                        "HOSPITAL DE AUTOGESTION DR. L. GUEMES   ",
                        "HOSPITAL FRANCES                        ",
                        "CENTRO JUVENIL ESPERANZA                ",
                        "HOSPITAL DE CLINICAS                    ",
                        "UNIDADES FEBRILES DE URGENCIA (U.F.U.)  ",
                        "DERIVADOS OS                            ",
                        "ENERI DR. PEDRO LYLYK Y ASOCIADOS S.A.  "),
                        Receptor = c("Barrio 31",
                                    "Lagleyze",
                                    "Grierson",
                                    "Santojanni",
                                    "Pirovano",
                                    "Muñiz",
                                    "Durand",
                                    "SAME",
                                    "Santa Lucía",
                                    "Zubizarreta",
                                    "Argerich",
                                    "Rivadavia",
                                    "Tornú",
                                    "Penna",
                                    "Gutierrez",
                                    "Ramos Mejía",
                                    "Alvarez",
                                    "Fernandez",
                                    "Elizalde",
                                    "Piñero",
                                    "Velez Sarsfield",
                                    "Udaondo",
                                    "María Ferrer",
                                    "Quinquela Martín",
                                    "Dueñas",
                                    "Rocca",
                                    "Moyano",
                                    "Alvear",
                                    "Sardá",
                                    "Marie Curie",
                                    "Quemados",
                                    "Carrillo",
                                    "IREP",
                                    "Tobar García",
                                    "Talleres Protegidos",
                                    "Borda",
                                    "Turismo",
                                    "Cesacs",
                                    "Sin Receptor",
                                    "Hoteles",
                                    "Guardia PAMI (DAMNPYP)",
                                    "Hospital Español",
                                    "U.F.U. - Op. DETECTAR",
                                    "Hospital Güemes",
                                    "Hospital Frances",
                                    "Centro Juvenil Esperanza",
                                    "Hospital de Clínicas",
                                    "U.F.U.",
                                    "Derivados OS",
                                    "Dr. Eneri y Asoc. S.A."
                                    ))
ConsultaSolicitudes <- left_join(ConsultaSolicitudes, Efectores)


MesaOperativa <- select(ConsultaSolicitudes, "Fecha" = fecha,
                                            "Estado" = estado,
                                            "Tipo Cierre" = estadocierre,
                                           "Puerta de Entrada" = entrada,
                                           "Unidad de Entrada" = unidadentrada,
                                           "Cobertura" = cobertura,
                                           "Capita" = capita2,
                                           "Diagnostico" = diagnostico,
                                           "Receptor" = Receptor,
                                           "Unidad Receptora" = unidadegreso
                                           )


