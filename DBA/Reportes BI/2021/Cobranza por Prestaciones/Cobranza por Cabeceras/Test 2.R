workdirectory_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Cobranza por Prestaciones/Cobranza por Cabeceras/"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranzas/Versión 7"

source("C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Cobranza por Prestaciones/Cobranza por Cabeceras/Script_Efectores_Funciones.r")



archivo_parametros <- GetArchivoParametros(path_one = workdirectory_one, 
                                           path_two = workdirectory_two, 
                                           file = "parametros_servidor.xlsx")

pw <- GetPassword()

user <- GetUser()

host <- GetHost()

database <-GetDatabase()

drv <- dbDriver("PostgreSQL")

#con <- dbConnect(drv, dbname = database,
#                 host = host, port = 5432, 
#                 user = user, password = pw)

con <- dbConnect(drv, dbname = "facoep1",
                 host = "localhost", port = 5432, 
                 user = "odoo", password = "odoo")


tabla_parametros_comprobantes <- GetFile("tabla_parametros_comprobantes _test.xlsx",
                                         path_one = workdirectory_one,
                                         path_two = workdirectory_two)



NotasDebito <- TransformFile(tabla_parametros_comprobantes,FilterOne = "test")

NotasDebito <- GetListaINSQL(NotasDebito,print = FALSE)

FacturasQuery <- TransformFile(tabla_parametros_comprobantes,FilterOne = "factura")

FacturasQuery <- GetListaINSQL(FacturasQuery,print = FALSE)

FacturasNotasDebito <- dbGetQuery(conn = con,
                                  glue(paste("SELECT CONCAT(tipocomprobantecodigo,'-',comprobanteprefijo,'-',comprobantecodigo) as comprobante,",
                                             "tipocomprobantecodigo,",
                                             "comprobanteprefijo,",
                                             "comprobantecodigo",
                                             "FROM comprobantes WHERE tipocomprobantecodigo IN ({FacturasQuery})")))

FacturasNotasDebito$comprobante <- gsub(" ","",FacturasNotasDebito$comprobante)
FacturasNotasDebito$tipocomprobantecodigo <- gsub(" ","",FacturasNotasDebito$tipocomprobantecodigo)


FacturasNotasDebito <- left_join(FacturasNotasDebito,tabla_parametros_comprobantes,by = c('tipocomprobantecodigo' = 'Comprobante'))

NotasCreditoRecibos <- dbGetQuery(conn = con,
                                  glue(paste("SELECT CONCAT(tipocomprobantecodigo,'-',comprobanteprefijo,'-',comprobantecodigo) as comprobante,",
                                             "tipocomprobantecodigo,",
                                             "comprobanteprefijo,",
                                             "comprobantecodigo",
                                             "FROM comprobantes WHERE tipocomprobantecodigo IN ({NotasDebito})")))


NotasCreditoRecibos$comprobante <- gsub(" ","",NotasCreditoRecibos$comprobante)
NotasCreditoRecibos$tipocomprobantecodigo <- gsub(" ","",NotasCreditoRecibos$tipocomprobantecodigo)


NotasCreditoRecibos <- left_join(NotasCreditoRecibos,tabla_parametros_comprobantes,by = c('tipocomprobantecodigo' = 'Comprobante'))

