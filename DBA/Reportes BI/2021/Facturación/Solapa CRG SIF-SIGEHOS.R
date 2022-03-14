workdirectory_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturación/"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version 3"




Archivo <-"Script_Facturacion_Funciones.R"
#source("C:/Users/iachenbach/Desktop/Facoep - Scripts/DBA/Reportes BI/2021/Facturación/Script_Facturacion_Funciones.R")


GetFileAux <- function(workdirectory_one,workdirectory_two,Archivo){
  intento <- try(source(paste(workdirectory_one,Archivo,sep = "/")),silent = TRUE)
  if (class(intento) == "try-error"){
    return(source(paste(workdirectory_two,Archivo,sep = "/")))} else {return(source(paste(workdirectory_one,Archivo,sep = "/")))}
}



GetFileAux(workdirectory_one = workdirectory_one,
           workdirectory_two = workdirectory_two,
           Archivo = "Script_Facturacion_Funciones.R")

archivo_parametros <- GetArchivoParametros(path_one = workdirectory_one,
                                           path_two = workdirectory_two,
                                           file = "parametros_servidor.xlsx")


pw <- GetPassword()

drv <- dbDriver("PostgreSQL")

user <- GetUser()

host <- GetHost()

con <- dbConnect(drv, dbname = "facoep", 
                 host = host,
                 port = 5432,
                 user = user,
                 password = pw)

postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")

estados  <- GetFile("crg_estados.xlsx",
                          path_one = workdirectory_one,
                          path_two = workdirectory_two)

efectores  <- GetFile("Efectores.xlsx",
                    path_one = workdirectory_one,
                    path_two = workdirectory_two)

SIF <- dbGetQuery(con, "SELECT pprnombre as SIF, crgnum, crgfchemision,crgestado
                        FROM crg c LEFT JOIN proveedorprestador p ON p.pprid = c.pprid")

SIF <- left_join(SIF,estados)

SIF$crgestado <- NULL

# Reemplazo los valores nulos por Ingresado por definicion de negocio

SIF$estado[is.na(SIF$estado)] <- "INGRESADO"

SIF <- left_join(SIF,efectores,by = c("sif" = "sif"))

# Reemplazo los NA por CESAC por definicion de Negocio

SIF$Efector[is.na(SIF$Efector)] <- "CESAC"

SIF$Id <- paste(SIF$Efector,SIF$crgnum,sep = "-")
SIF$Id2 <- paste(SIF$Efector,SIF$crgnum,sep = "-")

#SIF 1 esta terminado

workdirectory_three <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturación/repositorio SIGHEOS"

Sigehos <- ReadSigehosData(workdirectory = workdirectory_three,
                           sheet = "Base")

Sigehos <- unique(Sigehos)

Sigehos$Anio <- year(Sigehos$Fecha)

Sigehos$Id <- paste(Sigehos$Efector,Sigehos$Numero,sep = "-")

Sigehos <- left_join(Sigehos,SIF,by = c("Id" = "Id"))

Sigehos$EstadoSIF <- ifelse(Sigehos$Id == Sigehos$Id2,Sigehos$estado,
                           ifelse(Sigehos$Id != Sigehos$Id2,Sigehos$estado,"INGRESADO",
                                  "INGRESADO"))



                     
                  
