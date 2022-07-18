#workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturaci?n"
workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version4"

#workdirectory_three <- "C:/Users/iachenbach/Desktop/repositorio sigehos"
workdirectory_three <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version 3/repositorio SIGHEOS"

workdirectory_four <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version 3/Repositorio SIGEHOS CRG Export"

workdirectory_five <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Informe_Sigehos_CRG"

Archivo <-"Script_Facturacion_Funciones.R"

source(paste(workdirectory,Archivo,sep = "/"))


archivo_parametros <- GetArchivoParametros(path_one = workdirectory,
                                           path_two = workdirectory,
                                           file = "parametros_servidor.xlsx")


pw <- GetParameter(x = archivo_parametros,
                   parameter = "password")

drv <- dbDriver("PostgreSQL")

user <- GetParameter(x = archivo_parametros,
                     parameter = "user")

host <- GetParameter(x = archivo_parametros,
                     parameter = "host")

database <- GetParameter(x = archivo_parametros,
                         parameter = "database")

con <- dbConnect(drv, dbname = database,
                 host = host,
                 port = 5432,
                 user = user,
                 password = pw)


postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")

estados  <- GetFile("crg_estados.xlsx",
                          path_one = workdirectory,
                          path_two = workdirectory)

efectores  <- GetFile("EfectoresObjetivosNew.xlsx",
                    path_one = workdirectory,
                    path_two = workdirectory)


Sigehos <- ReadSigehosDataNew(workdirectory = workdirectory_four,
                              StartRow = 8)

Sigehos <- unique(Sigehos)

Sigehos$VerificadorImporte <- grepl(",",Sigehos$Importe.Total)

Sigehos$Importe_Total_1 <- ifelse(Sigehos$VerificadorImporte == TRUE,
                                     Sigehos$Importe.Total,-1)

Sigehos$Importe_Total_2 <- ifelse(Sigehos$VerificadorImporte == FALSE,
                                     Sigehos$Importe.Total,-1)

Sigehos <- unique(Sigehos)

Sigehos <- filter(Sigehos,!(is.na(Numero)))

Sigehos$Verificador <-grepl("/",Sigehos$Fecha)

Sigehos$Fecha1 <- ifelse(Sigehos$Verificador == FALSE,
                            Sigehos$Fecha2 <- as.numeric(Sigehos$Fecha),
                            Sigehos$Fecha)

if("Fecha2" %in% colnames(Sigehos)){
  Sigehos$Fecha2 <- as.Date(Sigehos$Fecha2,origin = "1899-12-30")
} else {
  Sigehos$Fecha2 <- -1
}

#SigehosControl <- SigehosFileControl(Sigehos,efectores,FileName = "Control-Sigehos1.xlsx")

Sigehos <- left_join(Sigehos,efectores,by = c("Efector" = "EfectorSigehos"))


Sigehos$IdSIF <- paste(Sigehos$ID,Sigehos$Numero,sep = "-")


SIF <- dbGetQuery(con, "SELECT pprid, crgnum, crgfchemision,crgestado
                        FROM crg")

SIF <- left_join(SIF,estados)

SIF$ID <- paste(SIF$pprid,SIF$crgnum,sep = "-")

SIF$crgestado <- NULL

Sigehos <- left_join(Sigehos,SIF,by = c("IdSIF" = "ID"))

Sigehos$estado1 <- ifelse(is.na(Sigehos$estado),"NO INGRESADO",Sigehos$estado)

Financiador <- GetFile("tipo_financiador.xlsx",
                       path_one = workdirectory_five,
                       path_two = workdirectory_five)

Sigehos <- left_join(Sigehos,Financiador,by = c('Financiador' = 'Financiador'))

Sigehos <- select(Sigehos,
                  "Efector" = EfectorObjetivos,
                  "Fecha" = Fecha,
                  "Fecha1" = Fecha1,
                  "Fecha2" = Fecha2,
                  "Numero" = Numero,
                  "Tipo De Anexo" = Tipo.Anexo,
                  "Estado Sigehos" = Estado,
                  "Estado SIF" = estado1,
                  "Financiador" = Financiador,
                  "Importe Total" = Importe.Total,
                  "Importe_Total_1" = Importe_Total_1,
                  "Importe_Total_2" = Importe_Total_2,
                  "Tipo Cobertura" = Tipo.Cobertura,
                  "Fecha Emision CRG" = crgfchemision,
                  "VerificadorImporte" = VerificadorImporte,
                  "VerificadorFecha" = Verificador)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

remove(efectores,estados,Financiador,SIF,drv,con,archivo_parametros)
