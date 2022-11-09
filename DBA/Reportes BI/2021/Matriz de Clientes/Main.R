#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Matriz_de_clientes/scripts"
workdirectory <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Matriz de Clientes"
#workdirectory_archivos <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Matriz_de_clientes/archivos"
workdirectory_archivos <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Matriz de Clientes"
# Tengo que ver por que carajo me tira error, deberia probar las funciones por afuera

Archivo <-"FuncionesHelper.R"

source(paste(workdirectory,Archivo,sep = "/"))



archivo_parametros <- GetArchivoParametros(path_one = workdirectory_archivos,
                                           path_two = workdirectory_archivos,
                                           file = "parametros_servidor.xlsx")

tipo_comprobantes <- GetFile("tipo_comprobante.xlsx",
                             path_one = workdirectory_archivos,
                             path_two = workdirectory_archivos)


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

fechas_corte <- GetFile("fechas_corte.xlsx",path_one = workdirectory_archivos,path_two = workdirectory_archivos)

fechas_corte <- GetMasterDate(fechas_corte)

fecha_final <-  floor_date(Sys.Date(), 'month')
fecha_mes_anterior <- floor_date(fecha_final,unit = 'month') - 1
fecha_mes_anterior <- floor_date(fecha_mes_anterior,unit = 'month')

########### Criterio para obtener un mes, hardcodear fecha Revision ##############

mes_actual <- as.Date('2022-08-01')
fechas_corte <- filter(fechas_corte,
                       fecha_revision == mes_actual)

#mes_actual <- Sys.Date()
#mes_actual <- floor_date(mes_actual,'month')

#fechas_corte <- filter(fechas_corte,
#                       fecha_revision == mes_actual)

# Acordarse de volver a Hardocdear fecha minima con '2017-01-01'
datalist = list()
for(i in 1:nrow(fechas_corte)){
  
  fechaHasta <- (fechas_corte$Fecha_fin_otros[i])
  fechaHasta <- as.Date(fechaHasta)
  
  FacturasHistoricas <- dfQueryFacturas(tipo_facturas = comprobantes_facturas,
                                        fecha_minima = as.Date('2017-01-01'),
                                        fecha_maxima = fechaHasta)
  
  FacturasHistoricas <- dbGetQuery(con,FacturasHistoricas)
  
  NcHistoricas <- GetHistoricQuery(fechaDesde = as.Date('2017-01-01'),
                                   fechaHasta = fechaHasta,
                                   tipoFacturas = comprobantes_facturas,
                                   tipoImputaciones = comprobantes_nc,
                                   nombre_imputacion = "notacredito")
  
  NcHistoricas <- dbGetQuery(con,NcHistoricas)
  
  RecibosHistoricos <- GetHistoricQuery(fechaDesde = as.Date('2017-01-01'),
                                        fechaHasta = fechaHasta,
                                        tipoFacturas = comprobantes_facturas,
                                        tipoImputaciones = comprobantes_recibos,
                                        nombre_imputacion = "recibos")
  
  RecibosHistoricos <- dbGetQuery(con,RecibosHistoricos)
  
  SaldoHistorico <- GetSaldosDeuda(dataframeClientes = Clientes,
                                   dataframeFacturado = FacturasHistoricas,
                                   dataframeNc = NcHistoricas,
                                   dataframeRecibos = RecibosHistoricos)
  
  QueryFacturas <- dfQueryFacturas(tipo_facturas = comprobantes_facturas,
                                   fecha_minima = as.Date(fechas_corte$Fecha_inicio_factura[i]),
                                   fecha_maxima = as.Date(fechas_corte$fecha_fin_factura[i]))
  
  facturacion <- dbGetQuery(con,QueryFacturas)
  
  QueryNc <- QueryImputaciones(tipo_facturas = comprobantes_facturas,
                               tipo_imputaciones = comprobantes_nc,
                               fecha_minima_factura = as.Date(fechas_corte$Fecha_inicio_factura[i]),
                               fecha_maxima_factura = as.Date(fechas_corte$fecha_fin_factura[i]),
                               fecha_minima_imputacion = as.Date(fechas_corte$Fecha_inicio_otros[i]),
                               fecha_maxima_imputacion = as.Date(fechas_corte$Fecha_fin_otros[i]),
                               nombre_imputacion = 'notacredito')
  Nc <- dbGetQuery(con,QueryNc)
  
  queryCobranzas <- QueryImputaciones(tipo_facturas = comprobantes_facturas,
                                      tipo_imputaciones = comprobantes_recibos,
                                      fecha_minima_factura = as.Date(fechas_corte$Fecha_inicio_factura[i]),
                                      fecha_maxima_factura = as.Date(fechas_corte$fecha_fin_factura[i]),
                                      fecha_minima_imputacion = as.Date(fechas_corte$Fecha_inicio_otros[i]),
                                      fecha_maxima_imputacion = as.Date(fechas_corte$Fecha_fin_otros[i]),
                                      nombre_imputacion = 'recibos')
  
  cobranza <- dbGetQuery(con,queryCobranzas)
  
  queryImpugnaciones <- queryNotaDB(tipo_facturas = comprobantes_facturas,
                                    tipo_notadb = comprobantes_notadb,
                                    fecha_minima_factura = as.Date(fechas_corte$Fecha_inicio_factura[i]),
                                    fecha_maxima_factura = as.Date(fechas_corte$fecha_fin_factura[i]),
                                    fecha_minima_notadb = as.Date(fechas_corte$Fecha_inicio_otros[i]),
                                    fecha_maxima_notadb = as.Date(fechas_corte$Fecha_fin_otros[i]),
                                    nombre_notadb = 'notadb')
  
  NotaDB <- dbGetQuery(con,queryImpugnaciones)
  
  Matriz <- left_join(Clientes,SaldoHistorico,by = c('clienteid' = 'clienteid'))
  Matriz <- left_join(Matriz,facturacion,by = c('clienteid' = 'clienteid'))
  Matriz <- left_join(Matriz,Nc,by = c('clienteid' = 'clienteid'))
  Matriz <- left_join(Matriz,cobranza,by = c('clienteid' = 'clienteid'))
  Matriz <- left_join(Matriz,NotaDB,by = c('clienteid' = 'clienteid'))
  
  Matriz [is.na(Matriz)] = 0
  
  Matriz$Facturacion_Neta_Cliente <- Matriz$importe_facturado - Matriz$importe_notacredito
  
  Matriz$Facturacion_Neta_Total <- sum(Matriz$importe_facturado) - sum(Matriz$importe_notacredito)
  
  Matriz <- Matriz[order(Matriz$Facturacion_Neta_Cliente,decreasing = TRUE),]
  
  Matriz$porcentaje_cliente <- Matriz$Facturacion_Neta_Cliente / Matriz$Facturacion_Neta_Total
  
  Matriz$porcentaje_facturado_acumulado <- cumsum(Matriz$porcentaje_cliente)
  
  Matriz$porcentaje_cobrado_cliente <- ifelse(Matriz$importe_recibos == 0,0,
                                              Matriz$importe_recibos / Matriz$Facturacion_Neta_Cliente)
  Matriz <- matrixFormat(Matriz)
  
  Matriz$Categoria_facturacion <- ifelse(Matriz$Facturacion_Neta_Cliente == 0,0,
                                         ifelse((Matriz$porcentaje_facturado_acumulado < 0.8) & (Matriz$Facturacion_Neta_Cliente > 0),
                                                1,
                                                ifelse((Matriz$porcentaje_facturado_acumulado >= 0.8) & (Matriz$Facturacion_Neta_Cliente > 0),
                                                       2,-1)))
  
  Matriz$Categoria_impugnaciones <- ifelse(Matriz$importe_impugnado == 0,0,
                                           ifelse(Matriz$importe_impugnado == Matriz$importe_facturado,
                                                  2,1))
  Matriz$Categoria_Cobranzas <- ifelse(Matriz$Facturacion_Neta_Cliente == 0,0,
                                       ifelse((Matriz$Facturacion_Neta_Cliente >= 0) & (Matriz$importe_recibos == 0),1,
                                              ifelse((Matriz$Facturacion_Neta_Cliente > 0) & (Matriz$porcentaje_cobrado_cliente < 0.4),2,
                                                     ifelse((Matriz$porcentaje_cobrado_cliente >= 0.40) & (Matriz$porcentaje_cobrado_cliente < 0.80),3,4))))
  
  
  
  Matriz$Tipo_Cliente <- ifelse((Matriz$Categoria_facturacion == 0) & (Matriz$SaldoHistorico > 0),4,
                                ifelse((Matriz$Categoria_facturacion == 0) & (Matriz$SaldoHistorico == 0),-1,
                                       ifelse((Matriz$Categoria_Cobranzas == 1) & (Matriz$Categoria_facturacion == 1),1,
                                              ifelse((Matriz$Categoria_Cobranzas == 1) & (Matriz$Categoria_facturacion == 2),1,
                                                     ifelse(((Matriz$Categoria_Cobranzas == 2) | (Matriz$Categoria_Cobranzas == 3)) & ((Matriz$Categoria_facturacion == 1) | (Matriz$Categoria_facturacion == 2)),
                                                            2,3)))))
  
  
  
  Matriz$inicio_analisis <- fechas_corte$fecha_inicio[i]
  Matriz$fin_analisis <- fechas_corte$Fecha_fin_otros[i]
  Matriz$inicio_revision <- fechas_corte$fecha_revision[i]
  datalist[[i]] <- Matriz
  
}

bigMatrix <- do.call(rbind, datalist)

# Siempre tengo que dejar el nombre exacto en R con respecto a Postgres, con las minus y todo.
bigMatrix <- select(bigMatrix,
                    "cliente_id" = clienteid,
                    "cliente_nombre" = clientenombre,
                    "saldo_historico" = SaldoHistorico,
                    "importe_facturado" = importe_facturado,
                    "importe_notacredito" = importe_notacredito,
                    "importe_recibos" = importe_recibos,
                    "importe_impugnado" = importe_impugnado,
                    "facturacion_neta_cliente" = Facturacion_Neta_Cliente,
                    "facturacion_neta_total" = Facturacion_Neta_Total,
                    "porcentaje_cliente" = porcentaje_cliente,
                    "porcentaje_facturado_acumulado" = porcentaje_facturado_acumulado,
                    "porcentaje_cobrado_cliente" = porcentaje_cobrado_cliente,
                    "categoria_facturacion" = Categoria_facturacion,
                    "categoria_impugnaciones" = Categoria_impugnaciones,
                    "categoria_cobranzas" = Categoria_Cobranzas,
                    "tipo_cliente" = Tipo_Cliente,
                    "inicio_analisis" = inicio_analisis,
                    "fin_analisis" = fin_analisis,
                    "inicio_revision" = inicio_revision)

#con_insercion <- dbConnect(drv, dbname = "DBA",
#                           host = "172.31.24.12", port = 5432,
#                           user = "postgres", password = "facoep2017")


#dbWriteTable(conn= con_insercion, name='matriz_clientes', value = bigMatrix,
#             overwrite=FALSE, append=TRUE, row.names= FALSE)

write.csv(SaldoHistorico,"historico_Saldos1.csv",row.names = FALSE)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})


#SELECT 
#tipocomprobantecodigo,
#sum(comprobantetotalimporte) 

#FROM comprobantes 
#WHERE comprobanteentidadcodigo = 159 AND
#comprobantefechaemision BETWEEN '1998-01-01' AND '2022-07-31'

#GROUP BY tipocomprobantecodigo
