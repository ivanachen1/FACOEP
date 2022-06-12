workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Cobranza por Prestaciones"
#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranza por Prestaciones"

Archivo <-"Funciones_Helper.R"

source(paste(workdirectory,Archivo,sep = "/"))

archivo_parametros <- GetArchivoParametros(path_one = workdirectory,
                                           path_two = workdirectory,
                                           file = "parametros_servidor.xlsx")

database <- GetParameter(x = archivo_parametros,"database")
pw <- GetParameter(x = archivo_parametros,"password")
host <- GetParameter(x = archivo_parametros,"host")
user <- GetParameter(x = archivo_parametros,"user")

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = database,
                 host = host, port = 5432, 
                 user = user, password = pw)

CentroCostos <- dbGetQuery(conn = con,"SELECT * FROM centrocostos")

GrupoPrestaciones <- GetFile("Grupo Prestaciones.xlsx",workdirectory,workdirectory)

GrupoPrestaciones$Prestacion <- toupper(GrupoPrestaciones$Prestacion)

Origenes <- GetFile("Origen.xlsx",workdirectory,workdirectory)

QueryPrestacionesUnicas <- paste("SELECT DISTINCT comprobantecrgdetpractica as Prestacion",
                                 "FROM comprobantecrgdet",
                                 "WHERE tipocomprobantecodigo IN ('RECX2')") 

PrestacionesUnicas <- dbGetQuery(conn = con,QueryPrestacionesUnicas) 
  
PrestacionesUnicas$prestacion <- toupper(PrestacionesUnicas$prestacion)

PrestacionesUnicas <- unique(PrestacionesUnicas)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
