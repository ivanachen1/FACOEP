#credenciales_produccion <- c('10.22.1.44','facoep_01dic2025','postgres','serveradmin')
credenciales_produccion <- c("10.22.1.61","facoep","postgres","r00tFacoDB2023*")

path <- "E:/DataWarehouse/wwcomprobantes"

print(path)

file <- "Funciones_Helper.R"

source(paste(path,file,sep = "/"))
source("E:/DataWarehouse/credenciales/validaciones/validaciones.R")

drv <- dbDriver("PostgreSQL")

pw <- credenciales_produccion[4]
con <- dbConnect(drv, dbname = credenciales_produccion[2],
                 host = credenciales_produccion[1],
                 port = 5432,
                 user = credenciales_produccion[3],
                 password = pw)

path_control <- paste(path,"control.csv",sep = "/")

df_control <- read.csv(path_control)

origen <- GetOrigenTable()

query <- GetQuery() 

data  <- dbGetQuery(conn = con,query)

df_control <- df_control$longitud


data <- left_join(data,origen,by = c('id_origen' = 'sigla'))

data <- CreateComprobante(data)

entidad <- CreateEntidadTable(drv,con)

data <- left_join(data,
                  entidad,
                  by = c('id_entidad' = 'id', 'entidad' = 'tipo'))

data$razon_social <- paste(data$id_entidad," - ",data$nombre)

data <- QuitFields(data)

names(data)[names(data) == 'name'] <- "origen"

data <- ChangeBoolValues(data)

data <- ReplaceIncorrectValue(data)

tabla_apertura <- read.xlsx("E:/DataWarehouse/tablas_lookup/files/tabla_apertura.xlsx")

data <- CreateFechaEntrega(data = data)

data <- GetApertura(df = data,
                    tabla_apertura = tabla_apertura)

data <- CreateFechaVencimiento(data = data,dateParameter = as.Date('2022-11-01'))

data <- CreateMandatarioField(data = data)

data <- esTurismo(data = data, con = con) 

data <- esDetectar(data = data, con = con)

data <- data[!duplicated(data), ]

credenciales_SIF <-  c('10.22.1.44','SIF','postgres','serveradmin')

setwd(path)

InsertRecordsPostgres(credenciales = credenciales_SIF,
                      table_name = 'wwcomprobantes',
                      df = data,
                      overwrite = TRUE,
                      append = FALSE)

## Borro como seguridad la imagen historica de ese dia

#dia_anterior <- '2025-11-30'

dia_anterior <- Sys.Date() -1

data$fecha_imagen <- dia_anterior

query_delete <- GetHistoricDeleteQuery(dia_anterior)

credenciales_historical <-  c('10.22.1.44','SIF_HISTORICAL','postgres','serveradmin')

DeletePostgresRows(credenciales_historical,
                   table_name = 'wwcomprobantes_historial',
                   query = query_delete)

InsertRecordsPostgres(credenciales = credenciales_historical,
                      table_name = 'wwcomprobantes_historial',
                      df = data,
                      overwrite = FALSE,
                      append = TRUE)

# Delete Historic data > 90 days

query_purge <- "DELETE FROM wwcomprobantes_historial WHERE fecha_imagen < current_date - 360"

DeletePostgresRows(credenciales_historical,
                   table_name = 'wwcomprobantes_historial',
                   query = query_purge)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")),
       function(x) {dbDisconnect(conn = x)})

conteo <- nrow(data)


write.csv(data.frame(longitud = conteo), path_control, row.names = FALSE)

print("Script Finalizado exitosamente")


