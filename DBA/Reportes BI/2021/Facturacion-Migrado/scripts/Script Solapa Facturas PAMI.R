#workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturaci?n"
#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturaci?n/Version4"

workdirectory_funciones <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturacion-Migrado/scripts"
workdirectory_excels <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturacion-Migrado/excels"

#workdirectoryPami <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturaci?n"
workdirectoryPami <- "E:/Estadisticas"

Archivo <-"Script_Facturacion_Funciones.R"

source(paste(workdirectory_funciones,Archivo,sep = "/"))


archivo_parametros <- GetArchivoParametros(path_one = workdirectory_excels,
                                           path_two = workdirectory_excels,
                                           file = "parametros_servidor.xlsx")

tipo_comprobantes <- GetFile("tipo_comprobante.xlsx",
                             path_one = workdirectory_excels,
                             path_two = workdirectory_excels)


tipo_comprobantes$Comprobante <- tipo_comprobantes$Tipo.Comprobante


comprobantes_query <- GetListaINSQL(tipo_comprobantes)

tipo_comprobantes <- select(tipo_comprobantes,Comprobante,Multiplicador,TipoPami)

CentrosCostos  <- GetFile("centro_costo_comprobantes.xlsx",
                          path_one = workdirectory_excels,
                          path_two = workdirectory_excels)

pw <- GetParameter(x = archivo_parametros,parameter = "password")

drv <- dbDriver("PostgreSQL")

user <- GetParameter(x = archivo_parametros,parameter = "user")

host <- GetParameter(x = archivo_parametros,parameter = "host")

database <- GetParameter(x = archivo_parametros,parameter = "database")

con <- dbConnect(drv, dbname = database,
                 host = host,
                 port = 5432,
                 user = user,
                 password = pw)

############################################## CONSULTAS ######################################################

DetallesPAMICapita <- GetFile("Detalles PAMI Cápita.xlsx",
                              path_one = workdirectoryPami,
                              path_two = workdirectoryPami)


DetallesPAMICapita$Emision <- as.Date(DetallesPAMICapita$Emision,origin = "1899-12-30")

rm(CentrosCostos,con,drv,tipo_comprobantes,archivo_parametros)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
