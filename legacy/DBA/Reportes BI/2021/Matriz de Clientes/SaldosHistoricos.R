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

tipo_comprobantes <- GetFile("tipo_comprobante_saldos.xlsx",
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

fechaHasta <- (fechas_corte$Fecha_fin_otros[1])
fechaHasta <- as.Date(fechaHasta)

FacturasHistoricas <- dfQueryFacturas(tipo_facturas = comprobantes_facturas,
                                      fecha_minima = as.Date('1998-01-01'),
                                      fecha_maxima = fechaHasta)

FacturasHistoricas <- dbGetQuery(con,FacturasHistoricas)

NcHistoricas <- GetHistoricQuery(fechaDesde = as.Date('1998-01-01'),
                                 fechaHasta = fechaHasta,
                                 tipoFacturas = comprobantes_facturas,
                                 tipoImputaciones = comprobantes_nc,
                                 nombre_imputacion = "notacredito")

NcHistoricas <- dbGetQuery(con,NcHistoricas)

RecibosHistoricos <- GetHistoricQuery(fechaDesde = as.Date('1998-01-01'),
                                      fechaHasta = fechaHasta,
                                      tipoFacturas = comprobantes_facturas,
                                      tipoImputaciones = comprobantes_recibos,
                                      nombre_imputacion = "recibos")

RecibosHistoricos <- dbGetQuery(con,RecibosHistoricos)

SaldoHistorico <- GetSaldosDeuda(dataframeClientes = Clientes,
                                 dataframeFacturado = FacturasHistoricas,
                                 dataframeNc = NcHistoricas,
                                 dataframeRecibos = RecibosHistoricos)

write.csv(SaldoHistorico,"historico_Saldos2.csv",row.names = FALSE)
