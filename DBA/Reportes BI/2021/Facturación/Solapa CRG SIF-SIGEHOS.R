# Cambie EfectoresObjetivosNew,Databases

workdirectory <-"C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Facturación"
#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version4"



workdirectory_Financiadores <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Facturación/Nuevo Informe CRG"
#workdirectory_Financiadores <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Informe_Sigehos_CRG"

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

conSigehosData <- dbConnect(drv, dbname = 'sigehos_recupero',
                            host = '172.31.24.12',
                            port = 5432,
                            user = 'postgres',
                            password = 'facoep2017') 


postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")

estados  <- GetFile("crg_estados.xlsx",
                          path_one = workdirectory,
                          path_two = workdirectory)

efectores  <- GetFile("EfectoresObjetivosNew.xlsx",
                    path_one = workdirectory,
                    path_two = workdirectory)


Sigehos <- dbGetQuery(conSigehosData,'SELECT * FROM crg_recupero')

SigehosDatabases <- GetFile("databases.xlsx",
                            path_one = workdirectory,
                            path_two = workdirectory)

Sigehos <- left_join(Sigehos,SigehosDatabases,by = c("origin" = "database"))

Sigehos <- left_join(Sigehos,efectores,by = c("Efector.Facoep" = "EfectorObjetivos"))

Sigehos$IdSIF <- paste(Sigehos$ID,Sigehos$numero,sep = "-")


SIF <- dbGetQuery(con, "SELECT pprid, crgnum, crgfchemision,crgestado
                        FROM crg")

SIF <- left_join(SIF,estados)

SIF$ID <- paste(SIF$pprid,SIF$crgnum,sep = "-")

SIF$crgestado <- NULL

Sigehos <- left_join(Sigehos,SIF,by = c("IdSIF" = "ID"))


Sigehos$estado1 <- ifelse(is.na(Sigehos$estado.y),"NO INGRESADO",Sigehos$estado.x)

# Seguir Aca

Financiador <- GetFile("Financiadores.xlsx",
                       path_one = workdirectory_Financiadores,
                       path_two = workdirectory_Financiadores)

Sigehos <- left_join(Sigehos,Financiador,by = c('financiador_nombre' = 'Financiador'))

Sigehos <- select(Sigehos,
                  "Efector" = Efector.Facoep,
                  "Fecha" = fecha,
                  "Numero" = numero,
                  "Tipo De Anexo" = tipo_anexo,
                  "Estado Sigehos" = estado.x,
                  "Estado SIF" = estado1,
                  "Financiador" = financiador_nombre,
                  "Financiador Sigla" = financiador_sigla,
                  "Importe Total" = importe_total,
                  "Tipo Cobertura" = Tipo.Cobertura,
                  "Fecha Emision CRG" = crgfchemision)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

remove(efectores,estados,Financiador,SIF,drv,con,archivo_parametros,
       SigehosDatabases,conSigehosData)
