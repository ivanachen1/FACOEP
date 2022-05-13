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

tipo_comprobantes <- select(tipo_comprobantes,Comprobante,Multiplicador,TipoPami)

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

############################################## CONSULTAS ######################################################

nuevo_pami <- glue(paste("SELECT comprobantefechaemision as emision,",
                         "tipocomprobantecodigo,",
                         "comprobanteprefijo,",
                         "comprobantecodigo,",
                         "ccostodescripcion,", 
                         "sccostodescripcion,",
                         "tpoliqdescripcion,",
                         "comprobantetotalimporte,",
                         "comprobantedetalle",

                         "FROM comprobantes c",
                         "LEFT JOIN centrocostos cc ON c.comprobanteccosto = cc.ccostocodigo",
                         
                         "LEFT JOIN subcentrocostos sc",
                         "ON c.comprobanteccosto = sc.ccostocodigo",
                         "AND c.comprobantesccosto = sc.sccostocodigo",
                         
                         "LEFT JOIN tipoliquidacion tp",
                         "ON tp.tpoliqcodigo = c.comprobantetipoliq",
                         "AND tp.ccostocodigo = c.comprobanteccosto",
                         "AND tp.sccostocodigo = c.comprobantesccosto",
                         
                         "WHERE comprobanteccosto = 1",
                         "AND comprobantefechaemision >= '2021-01-01'",
                         "AND tipocomprobantecodigo IN ({comprobantes_query})",
                         "AND comprobantedetalle not like '%ANULA%'"))

nuevo_pami <- dbGetQuery(con,nuevo_pami)

nuevo_pami <- CleanTablaComprobantes(nuevo_pami)

nuevo_pami <- left_join(nuevo_pami,tipo_comprobantes,by = c("tipocomprobantecodigo" = "Comprobante"))


nuevo_pami$comprobantetotalimporte <- nuevo_pami$comprobantetotalimporte * nuevo_pami$Multiplicador
  
nuevo_pami$tipo <- nuevo_pami$TipoPami

nuevo_pami$TipoPami <- NULL

nuevo_pami$Multiplicador <- NULL

nuevo_pami$comprobantetotalimporte <- ifelse(nuevo_pami$sccostodescripcion == "CAPITA CLIENTE", 0,
                                       nuevo_pami$comprobantetotalimporte)

DetallesPAMICapita <- GetFile("Detalles PAMI Cápita.xlsx",
                              path_one = workdirectory,
                              path_two = workdirectory)


DetallesPAMICapita$Emision <- as.Date(DetallesPAMICapita$Emision,origin = "1899-12-30")

rm(CentrosCostos,con,drv,tipo_comprobantes,archivo_parametros)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
