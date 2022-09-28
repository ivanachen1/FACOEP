#workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturaci?n"
workdirectory <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Matriz de Clientes"


Archivo <-"Script_Facturacion_Funciones.R"

source(paste(workdirectory,Archivo,sep = "/"))



archivo_parametros <- GetArchivoParametros(path_one = workdirectory,
                                           path_two = workdirectory,
                                           file = "parametros_servidor.xlsx")

tipo_comprobantes <- GetFile("tipo_comprobante.xlsx",
                             path_one = workdirectory,
                             path_two = workdirectory)


tipo_comprobantes$Comprobante <- tipo_comprobantes$Tipo.Comprobante


comprobantes_facturas <- GetListaINSQL(tipo_comprobantes,
                                       Filter = "factura")
comprobantes_nc <- GetListaINSQL(tipo_comprobantes,
                                       Filter = "nota_credito")
comprobantes_notadb <- GetListaINSQL(tipo_comprobantes,
                                 Filter = "notadb")

comprobantes_recibos <- GetListaINSQL(tipo_comprobantes,
                                      Filter = "recibo")

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

Clientes <- dbGetQuery(con,"SELECT clienteid,clientenombre FROM clientes") 

options(scipen=999)
# Caso del Analisis
QueryFacturas <- dfQueryFacturas(tipo_facturas = comprobantes_facturas,
                         fecha_minima = as.Date('2021-06-01'),
                         fecha_maxima = as.Date('2022-05-31'))

cat(QueryFacturas)

facturacion <- dbGetQuery(con,QueryFacturas)

QueryNc <- QueryImputaciones(tipo_facturas = comprobantes_facturas,
                             tipo_imputaciones = comprobantes_nc,
                             fecha_minima_factura = as.Date('2021-06-01'),
                             fecha_maxima_factura = as.Date('2022-05-31'),
                             fecha_minima_imputacion = as.Date('2021-06-01'),
                             fecha_maxima_imputacion = as.Date('2022-07-31'),
                             nombre_imputacion = 'notacredito')

Nc <- dbGetQuery(con,QueryNc)


queryCobranzas <- QueryImputaciones(tipo_facturas = comprobantes_facturas,
                             tipo_imputaciones = comprobantes_recibos,
                             fecha_minima_factura = as.Date('2021-06-01'),
                             fecha_maxima_factura = as.Date('2022-05-31'),
                             fecha_minima_imputacion = as.Date('2021-06-01'),
                             fecha_maxima_imputacion = as.Date('2022-07-31'),
                             nombre_imputacion = 'recibos')

cobranza <- dbGetQuery(con,queryCobranzas)

queryImpugnaciones <- queryNotaDB(tipo_facturas = comprobantes_facturas,
                                    tipo_notadb = comprobantes_notadb,
                                    fecha_minima_factura = as.Date('2021-06-01'),
                                    fecha_maxima_factura = as.Date('2022-05-31'),
                                    fecha_minima_notadb = as.Date('2021-06-01'),
                                    fecha_maxima_notadb = as.Date('2022-07-31'),
                                    nombre_notadb = 'notadb')

NotaDB <- dbGetQuery(con,queryImpugnaciones)

Matriz <- left_join(Clientes,facturacion,by = c('clienteid' = 'clienteid'))
Matriz <- left_join(Matriz,Nc,by = c('clienteid' = 'clienteid'))
Matriz <- left_join(Matriz,cobranza,by = c('clienteid' = 'clienteid'))
Matriz <- left_join(Matriz,NotaDB,by = c('clienteid' = 'clienteid'))

Matriz [is.na(Matriz)] = 0

Matriz$Facturacion_Neta_Cliente <- Matriz$importe_facturado - Matriz$importe_notacredito

Matriz$Facturacion_Neta_Total <- sum(Matriz$importe_facturado) - sum(Matriz$importe_notacredito)

Matriz <- Matriz[order(Matriz$Facturacion_Neta_Cliente,decreasing = TRUE),]

Matriz$porcentaje_cliente <- Matriz$Facturacion_Neta_Cliente / Matriz$Facturacion_Neta_Total 

Matriz$porcentaje_facturado_acumulado <- cumsum(Matriz$porcentaje_cliente)

Matriz$porcentaje_cobrado_cliente <- Matriz$importe_recibos / Matriz$Facturacion_Neta_Cliente 

Matriz$Categoria_facturacion <- ifelse(Matriz$Facturacion_Neta_Cliente == 0,0,
                                ifelse((Matriz$porcentaje_acumulado < 0.8) & (Matriz$Facturacion_Neta_Cliente > 0),
                                       1,
                                       ifelse((Matriz$porcentaje_acumulado >= 0.8) & (Matriz$Facturacion_Neta_Cliente > 0),
                                              2,"definir")))

Matriz$Categoria_impugnaciones <- ifelse(Matriz$importe_impugnado == 0,0,
                                         ifelse(Matriz$importe_impugnado == Matriz$importe_facturado,
                                                2,1)) 


Matriz$Categoria_Cobranzas <- ifelse(Matriz$Facturacion_Neta_Cliente == 0,0,
                                     ifelse((Matriz$Facturacion_Neta_Cliente > 0) & (Matriz$importe_recibos == 0),1,
                                            ifelse((Matriz$Facturacion_Neta_Cliente > 0) & (Matriz$porcentaje_cobrado_cliente < 0.4),2,
                                                   ifelse((Matriz$porcentaje_cobrado_cliente >= 0.40) & (Matriz$porcentaje_cobrado_cliente < 0.80),3,4))))



Matriz$Tipo_Cliente <- ifelse(Matriz$Categoria_facturacion == 0,4,
                              ifelse((Matriz$Categoria_Cobranzas == 1) & (Matriz$Categoria_facturacion == 1),1,
                                     ifelse((Matriz$Categoria_Cobranzas == 1) & (Matriz$Categoria_facturacion == 2),1,
                                            ifelse(((Matriz$Categoria_Cobranzas == 2) | (Matriz$Categoria_Cobranzas == 3)) & ((Matriz$Categoria_facturacion == 1) | (Matriz$Categoria_facturacion == 2)),2,3))))  

write.csv(Matriz,"Matriz de Clientes.csv")

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
