workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Cobranza por Prestaciones/Cobranza por Cabeceras"
#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranzas/Versión 7"

source(paste(workdirectory,"FuncionesHelper.r",sep = "/"))

archivo_parametros <- GetFile(path_one = workdirectory, 
                              path_two = workdirectory, 
                              file = "parametros_servidor.xlsx")

pw <- GetParameter(x = archivo_parametros,parameter = "password")

user <- GetParameter(x = archivo_parametros,parameter = "user")

host <- GetParameter(x = archivo_parametros,parameter = "host")

database <-GetParameter(x = archivo_parametros,parameter = "database")

drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv, dbname = database,
                 host = host, port = 5432, 
                 user = user, password = pw)


tabla_parametros_comprobantes <- GetFile("tabla_parametros_comprobantes.xlsx",
                                         path_one = workdirectory,
                                         path_two = workdirectory)



NotasDebito <- TransformFile(tabla_parametros_comprobantes,FilterOne = "test")

NotasDebito <- GetListaINSQL(NotasDebito,print = FALSE)

FacturasQuery <- TransformFile(tabla_parametros_comprobantes,FilterOne = "factura")

FacturasQuery <- GetListaINSQL(FacturasQuery,print = FALSE)

FacturasNotasDebito <- dbGetQuery(conn = con,
                                  glue(paste("SELECT CONCAT(tipocomprobantecodigo,'-',comprobanteprefijo,'-',comprobantecodigo) as comprobante,",
                                             "tipocomprobantecodigo,",
                                             "comprobanteprefijo,",
                                             "comprobantecodigo,",
                                             "comprobantefechaemision as emision,",
                                             "comprobantetotalimporte as importe",
                                             "FROM comprobantes",
                                             "WHERE tipocomprobantecodigo IN ({FacturasQuery})")))

FacturasNotasDebito$comprobante <- gsub(" ","",FacturasNotasDebito$comprobante)
FacturasNotasDebito$tipocomprobantecodigo <- gsub(" ","",FacturasNotasDebito$tipocomprobantecodigo)


FacturasNotasDebito <- left_join(FacturasNotasDebito,tabla_parametros_comprobantes,by = c('tipocomprobantecodigo' = 'Comprobante'))

NotasCreditoRecibos <- dbGetQuery(conn = con,
                                  glue(paste("SELECT CONCAT(tipocomprobantecodigo,'-',comprobanteprefijo,'-',comprobantecodigo) as comprobante,",
                                             "tipocomprobantecodigo,",
                                             "comprobanteprefijo,",
                                             "comprobantecodigo,",
                                             "comprobantefechaemision as emision,",
                                             "comprobantetotalimporte as importe",
                                             "FROM comprobantes", 
                                             "WHERE tipocomprobantecodigo IN ({NotasDebito})")))


NotasCreditoRecibos$comprobante <- gsub(" ","",NotasCreditoRecibos$comprobante)
NotasCreditoRecibos$tipocomprobantecodigo <- gsub(" ","",NotasCreditoRecibos$tipocomprobantecodigo)


NotasCreditoRecibos <- left_join(NotasCreditoRecibos,tabla_parametros_comprobantes,by = c('tipocomprobantecodigo' = 'Comprobante'))

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
