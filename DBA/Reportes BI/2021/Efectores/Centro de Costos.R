workdirectory_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Efectores"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranzas/Versión 7"

source("C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Efectores/Script_Efectores_Funciones.r")



archivo_parametros <- GetArchivoParametros(path_one = workdirectory_one, 
                                           path_two = workdirectory_two, 
                                           file = "parametros_servidor.xlsx")

pw <- GetPassword()

user <- GetUser()

host <- GetHost()

database <-GetDatabase()

drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv, dbname = database,
                 host = host, port = 5432, 
                 user = user, password = pw)

QueryCentroCosto <- "SELECT ccostocodigo,ccostodescripcion FROM centrocostos"

CentroCostos <- dbGetQuery(conn = con,QueryCentroCosto)

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
