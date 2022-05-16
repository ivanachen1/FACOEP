workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturación"
#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version 3"


#WorkDirectoryComprobantesDesestimar <- "E:/Estadisticas"
WorkDirectoryComprobantesDesestimar<- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturación"

workdirectory_three <- "C:/Users/iachenbach/Desktop/repositorio sigehos"

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

efectores  <- GetFile("EfectoresObjetivos.xlsx",
                    path_one = workdirectory,
                    path_two = workdirectory)


Sigehos <- ReadSigehosData(workdirectory = workdirectory_three,
                           sheet = "Base")

Sigehos <- unique(Sigehos)

Sigehos$Anio <- year(Sigehos$Fecha)

Sigehos <- left_join(Sigehos,efectores,by = c("Efector" = "EfectorSigehos"))


Sigehos$IdSIF <- paste(Sigehos$ID,Sigehos$Numero,sep = "-")

Sigehos$EfectorObjetivos <- NULL
Sigehos$sif <- NULL


SIF <- dbGetQuery(con, "SELECT pprid, crgnum, crgfchemision,crgestado
                        FROM crg")

SIF <- left_join(SIF,estados)

SIF$ID <- paste(SIF$pprid,SIF$crgnum,sep = "-")

SIF$crgestado <- NULL

Sigehos <- left_join(Sigehos,SIF,by = c("IdSIF" = "ID"))

data <- data.frame("Efector" = unique(Sigehos$Efector))

write.csv(data,file = "EfectoresCorregir.csv")                     
                  
