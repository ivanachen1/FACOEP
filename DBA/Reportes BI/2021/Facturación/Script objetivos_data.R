workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturación"
#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version 3"
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
                                 path_one = workdirectory,
                                 path_two = workdirectory)

ComprobantesDesestimar$comprobante <-paste(ComprobantesDesestimar$tipo,
                               ComprobantesDesestimar$prefijo,
                               ComprobantesDesestimar$codigo,sep = "-")

ComprobantesDesestimar <- as.vector(ComprobantesDesestimar$comprobante)


ObjetivosData <- GetFile(file_name = "Objetivos.xlsx",
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


postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")


SIF2Query <- glue(paste("SELECT pprnombre,",
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

cat(SIF2Query)


SIF2 <- dbGetQuery(con,SIF2Query)

Cesacs <- dbGetQuery(con,paste("SELECT pprid,pprnombre,",
                               "CASE WHEN (pprnombre LIKE'%CES%') THEN TRUE WHEN (pprnombre LIKE'%CEM%') THEN TRUE ELSE FALSE END AS Cesac",
                               "FROM proveedorprestador"))

Cesacs <- filter(Cesacs,cesac == TRUE)
Cesacs$cesac <- NULL
Cesacs$EfectorObjetivos <- "Cesacs"
colnames(Cesacs) <- c("ID","sif","EfectorObjetivos")

Efectores <- rbind(Efectores,Cesacs)

SIF2 <- CleanTablaComprobantes(SIF2)
############ Crear una funcion que me borre facturas Marcadas en un excel######################

SIF2 <- SIF2 %>% filter(!NroComprobante %in% c(ComprobantesDesestimar))

SIF2$comprobantefechaemision <- as.Date(SIF2$comprobantefechaemision)
SIF2$emisioncrg <- as.Date(SIF2$emisioncrg)

SIF2 <- unique(SIF2)

SIF2$AnioEmision <- year(SIF2$comprobantefechaemision)

SIF2 <- left_join(SIF2,Efectores, by = c("pprid" = "ID"))

SIF2 <- aggregate(SIF2$comprobantecrgimportetotaldeta
                  ,by = list(SIF2$EfectorObjetivos,SIF2$Anio),
                  FUN = sum)

colnames(SIF2) <- c("Efector","Anio","Total.Facturado")

SIF2$Fk <- paste(SIF2$Anio,SIF2$Efector,sep = "-")

ObjetivosData$fk <- paste(ObjetivosData$Año,ObjetivosData$Efector,sep = "-")

ObjetivosData <- left_join(ObjetivosData,SIF2,by = c("fk"="Fk"))

ObjetivosData <- select(ObjetivosData,
                        "EfectorSIF" = Efector.x,
                        "EfectorObjetivos" = Efector.y,
                        "Objetivo.Anual.Total" = Objetivo.Anual.Total,
                        "Objetivo.Mensual.OOSS" = Objetivo.Mensual.OOSS,
                        "Objetivo.Anual.PAMI"= Objetivo.Anual.PAMI,
                        "Año" = Año,
                        "SIF.Total.Facturado" = Total.Facturado,
                        "fk" = fk)

rm(CentrosCostos,Efectores,SIF2,tipo_comprobantes,Cesacs,archivo_parametros,con,drv)
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

