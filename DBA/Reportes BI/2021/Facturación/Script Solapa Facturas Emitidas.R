workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturación"


Archivo <-"Script_Facturacion_Funciones.R"

source(paste(workdirectory,Archivo,sep = "/"))



archivo_parametros <- GetArchivoParametros(path_one = workdirectory,
                                           path_two = workdirectory,
                                           file = "parametros_servidor.xlsx")

tipo_comprobantes <- GetFile("tipo_comprobante.xlsx",
                             path_one = workdirectory,
                             path_two = workdirectory)


tipo_comprobantes$Comprobante <- tipo_comprobantes$Tipo.Comprobante


comprobantes_query <- GetListaINSQL(tipo_comprobantes)

CentrosCostos  <- GetFile("centro_costo_comprobantes.xlsx",
                                              path_one = workdirectory,
                                              path_two = workdirectory)

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


comprobantes <- glue(paste( "SELECT comprobanteccosto,",
                            "CONCAT(os.clienteid,'-',os.clientenombre) as OS,",
                            "c.tipocomprobantecodigo,",
                            "c.comprobanteprefijo,",
                            "c.comprobantecodigo,",
                            "c.comprobantefechaemision,",
                            "c.comprobantetotalimporte,",
                            "CASE WHEN c.comprobantedetalle LIKE '%ANULADO%' THEN 'SI' ELSE 'NO' END AS Anulado,", 
                            "os.clienteid",

                            "FROM comprobantes c",
                            "LEFT JOIN clientes os ON os.clienteid = c.comprobanteentidadcodigo",
                                  
                            "WHERE c.comprobantetipoentidad = 2 AND",
                            "c.tipocomprobantecodigo IN ({comprobantes_query}) AND",
                            "c.comprobantefechaemision > '01-01-2017'"))


comprobantes <- dbGetQuery(con,comprobantes) 

comprobantes <- CleanTablaComprobantes(comprobantes)

comprobantes <- left_join(comprobantes,CentrosCostos,by = c("comprobanteccosto" = "id.centro.costo"))

comprobantes$comprobanteccosto <- NULL

tipo_comprobantes <- data.frame("TipoComprobante" = tipo_comprobantes$Tipo.Comprobante,"Multiplicador"=tipo_comprobantes$Multiplicador)

comprobantes <- left_join(comprobantes,tipo_comprobantes,by = c("tipocomprobantecodigo" = "TipoComprobante"))

comprobantes$comprobantetotalimporte <- comprobantes$comprobantetotalimporte * comprobantes$Multiplicador

comprobantes$Multiplicador <- NULL

comprobantes$NombreMes <- months(as.Date(comprobantes$comprobantefechaemision))

comprobantes$Mes <- month(as.Date(comprobantes$comprobantefechaemision))

comprobantes$Anio <- year(as.Date(comprobantes$comprobantefechaemision))

comprobantes$dia <- day(as.Date(comprobantes$comprobantefechaemision))

comprobantes <- select(comprobantes,
                       "Financiador" = os,
                       "tipocomprobantecodigo" = tipocomprobantecodigo,
                       "Fecha Emision" = comprobantefechaemision,
                       "Centro de Costos" = Nombre,
                       "Anio" = Anio,
                       "importe"= comprobantetotalimporte,
                       "Anulado" = anulado,
                       "Mes" = Mes,
                       "Dia" = dia,
                       "Nombre del Mes" = NombreMes,
                       "NroComprobante" = NroComprobante)


lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
