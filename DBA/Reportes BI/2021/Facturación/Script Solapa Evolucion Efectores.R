workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturación"
#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version 3"


#WorkDirectoryComprobantesDesestimar <- "E:/Estadisticas"
WorkDirectoryComprobantesDesestimar<- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturación"

Archivo <-"Script_Facturacion_Funciones.R"

source(paste(workdirectory,Archivo,sep = "/"))


archivo_parametros <- GetArchivoParametros(path_one = workdirectory,
                                           path_two = workdirectory,
                                           file = "parametros_servidor.xlsx")

tipo_comprobantes <- GetFile("tipo_comprobante.xlsx",
                             path_one = workdirectory,
                             path_two = workdirectory)

tipo_comprobantes <- select(tipo_comprobantes,
                            "TipoComprobante" = Tipo.Comprobante,
                            "SIF2" = Alimenta.a.SIF2)

Efectores <- GetFile("EfectoresObjetivos.xlsx",
                     path_one = workdirectory,
                     path_two = workdirectory)

Efectores <- select(Efectores,ID,sif,EfectorObjetivos)

Efectores <- unique(Efectores)


tipo_comprobantes$Comprobante <- tipo_comprobantes$TipoComprobante

tipo_comprobantes <- filter(tipo_comprobantes,SIF2 == TRUE)

comprobantes_query <- GetListaINSQL(tipo_comprobantes)


CentrosCostos  <- GetFile("centro_costo_comprobantes.xlsx",
                          path_one = workdirectory,
                          path_two = workdirectory)

CodigosOOSSDesestimar <- GetFile(file_name = "Codigos Obra Social a Desestimar.xlsx",
                                 path_one = workdirectory,
                                 path_two = workdirectory)

CodigosOOSSDesestimar$Comprobante <- CodigosOOSSDesestimar$Codigos.Obra.Social.a.Desestimar

CodigosOOSSDesestimar<- GetListaINSQL(CodigosOOSSDesestimar)

ComprobantesDesestimar <- GetFile(file_name = "ComprobantesDesestimar.xlsx",
                                  path_one = WorkDirectoryComprobantesDesestimar,
                                  path_two = WorkDirectoryComprobantesDesestimar)

ComprobantesDesestimar$comprobante <-paste(ComprobantesDesestimar$tipo,
                                           ComprobantesDesestimar$prefijo,
                                           ComprobantesDesestimar$codigo,sep = "-")

ComprobantesDesestimar <- as.vector(ComprobantesDesestimar$comprobante)


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


postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")


Query <- glue(paste("SELECT pprnombre,",
                    "crg.comprobantepprid as pprid,",
                    "CONCAT(os.clienteid,'-',os.clientenombre) as OS,",
                    "c.tipocomprobantecodigo,",
                    "c.comprobanteprefijo,",
                    "c.comprobantecodigo,",
                    "c.comprobantefechaemision,",
                    "crg.comprobantecrgnro,",
                    "crg.comprobantecrgfchemision as emisioncrg,",
                    "crg.comprobantecrgimportetotaldeta",
                        
                    "FROM comprobantes c",
                    "LEFT JOIN comprobantecrg crg ON crg.comprobanteprefijo = c.comprobanteprefijo AND",
                    "crg.empcod = c.empcod and",
                    "crg.tipocomprobantecodigo = c.tipocomprobantecodigo AND",
                    "crg.sucursalcodigo = c.sucursalcodigo AND",
                    "crg.comprobantetipoentidad = c.comprobantetipoentidad AND",
                    "crg.comprobantecodigo = c.comprobantecodigo AND",
                    "crg.comprobanteentidadcodigo = c.comprobanteentidadcodigo",
                        
                    "LEFT JOIN clientes os ON os.clienteid = c.comprobanteentidadcodigo",
                    "LEFT JOIN proveedorprestador pp on pp.pprid = crg.comprobantepprid",
                        
                    "WHERE c.comprobantetipoentidad = 2 and comprobantepprid > 0 and",
                    "c.tipocomprobantecodigo IN({comprobantes_query})",
                    "AND c.comprobanteccosto = 5"),sep = "\n")

Bruto <- dbGetQuery(con,Query)

Cesacs <- dbGetQuery(con,paste("SELECT pprid,pprnombre,",
                               "CASE WHEN (pprnombre LIKE'%CES%') THEN TRUE WHEN (pprnombre LIKE'%CEM%') THEN TRUE ELSE FALSE END AS Cesac",
                               "FROM proveedorprestador"))

Cesacs <- filter(Cesacs,cesac == TRUE)
Cesacs$cesac <- NULL
Cesacs$EfectorObjetivos <- "Cesacs"
colnames(Cesacs) <- c("ID","sif","EfectorObjetivos")

Efectores <- rbind(Efectores,Cesacs)

Bruto <- CleanTablaComprobantes(Bruto)

Bruto <- Bruto %>% filter(!NroComprobante %in% c(ComprobantesDesestimar))

Bruto$comprobantefechaemision <- as.Date(Bruto$comprobantefechaemision)
Bruto$emisioncrg <- as.Date(Bruto$emisioncrg)

Bruto <- unique(Bruto)

Bruto$AnioEmision <- year(Bruto$comprobantefechaemision)

Bruto <- left_join(Bruto,Efectores, by = c("pprid" = "ID"))

Bruto <- filter(Bruto,!is.na(sif))

Bruto <- select(Bruto,
                "ooss" = os,
                "Efector" = EfectorObjetivos,
                "Fecha de Emision Comprobante" = comprobantefechaemision,
                "NroCRG" = comprobantecrgnro,
                "Fecha de Emision CRG" = emisioncrg,
                "Total Facturado" = comprobantecrgimportetotaldeta,
                "Comprobante" = NroComprobante)

rm(CentrosCostos,Cesacs,Efectores,tipo_comprobantes,archivo_parametros)
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
