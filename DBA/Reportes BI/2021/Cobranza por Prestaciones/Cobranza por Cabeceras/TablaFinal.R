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

Nc <- dbGetQuery(conn = con,QueryNc)

Fc <- dbGetQuery(conn = con,QueryFc)


TablaFinal <- left_join(Fc,Nc,by = c('factura'='factura',
                                     'os'='os',
                                     'nrocrgfactura'='nrocrgnotacredito',
                                     'ppridfactura'='ppridnotacredito'),
                        keep = TRUE)


TablaFinal <- select(TablaFinal,
                     "CentroCosto" = centrocosto,
                     "SubcentroCosto" = subcentrocosto,
                     "Efector" = pprnombre,
                     "ObraSocial" = os.x,
                     "Factura" = factura.x,
                     "Saldo" = saldo,
                     "EmisionFactura" = emisionfactura,
                     "CrgFactura"= nrocrgfactura,
                     "PpridFactura"= ppridfactura,
                     "EmisionFactura"= emisionfactura,
                     "EmisionCrg"= crgfchemision,
                     "ValorCrgFactura" = importecrg,
                     "NotaCredito" = notacredito,
                     "CrgNotacredito" = nrocrgnotacredito,
                     "PpridNotaCredito" = ppridnotacredito,
                     "ValorCrgNotacredito" = importecrgnc,
                     "Anulada" = anulada,
                     "Interes" = interes)

TablaFinal$Factura <- gsub(" ","",TablaFinal$Factura)
TablaFinal$NotaCredito <- gsub(" ","",TablaFinal$NotaCredito)
TablaFinal$CrgFactura <- as.character(TablaFinal$CrgFactura)

rm(archivo_parametros,ComprobantesAux,Fc,Nc,tabla_parametros_comprobantes)


lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

