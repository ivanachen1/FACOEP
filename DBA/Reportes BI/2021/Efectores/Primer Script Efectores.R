#workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Efectores"
workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranzas/Versión 7"

Archivo <- "Script_Efectores_Funciones.r"

source(paste(workdirectory,Archivo,sep = "/"))
#WorkDirectoryComprobantesDesestimar <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturación"
WorkDirectoryComprobantesDesestimar <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version 3"

archivo_parametros <- GetFile(path_one = workdirectory, 
                              path_two = workdirectory, 
                              file = "parametros_servidor.xlsx")

pw <- GetPassword()

user <- GetUser()

host <- GetHost()

database <-GetDatabase()

drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv, dbname = database,
                 host = host, port = 5432, 
                 user = user, password = pw)


tabla_parametros_comprobantes <- GetFile("tabla_parametros_comprobantes.xlsx",
                                         path_one = workdirectory,
                                         path_two = workdirectory)


tabla_parametros_comprobantes <- TransformFile(tabla_parametros_comprobantes,FilterOne = "factura")

FacturasQuery <- TransformFile(tabla_parametros_comprobantes,FilterOne = "factura")

FacturasQuery <- GetListaINSQL(FacturasQuery,print = FALSE)

ComprobantesDesestimar <- GetFile(file_name = "ComprobantesDesestimar.xlsx",
                                  path_one = WorkDirectoryComprobantesDesestimar,
                                  path_two = WorkDirectoryComprobantesDesestimar)

ComprobantesDesestimar$comprobante <-paste(ComprobantesDesestimar$tipo,
                                           ComprobantesDesestimar$prefijo,
                                           ComprobantesDesestimar$codigo,sep = "-")

ComprobantesDesestimar <- as.vector(ComprobantesDesestimar$comprobante)

Base <- glue(paste("SELECT",
                   "c.comprobanteccosto as CentroCosto,",
                   "CASE WHEN c.comprobantedetalle LIKE '%ANULADO%' THEN 'SI' ELSE 'NO' END AS FactAnulada,",
                   "pprnombre,",
                   "CONCAT(os.clienteid,'-',os.clientenombre) as OS,",
                   "c.tipocomprobantecodigo,",
                   "c.comprobanteprefijo,",
                   "c.comprobantecodigo,",
                   "c.comprobantefechaemision,",
                   "comprobantecrgnro,",
                   "cg.crgfchemision,",
                   "comprobantecrgimportetotaldeta",
  
                   "FROM comprobantes c",
                   "LEFT JOIN comprobantecrg crg ON",
                   "crg.comprobanteprefijo = c.comprobanteprefijo and",
                   "crg.empcod = c.empcod and",
                   "crg.tipocomprobantecodigo = c.tipocomprobantecodigo and",
                   "crg.sucursalcodigo = c.sucursalcodigo and",
                   "crg.comprobantetipoentidad = c.comprobantetipoentidad and",
                   "crg.comprobantecodigo = c.comprobantecodigo and",
                   "crg.comprobanteentidadcodigo = c.comprobanteentidadcodigo",
                   "LEFT JOIN crg cg",
                   "ON crg.comprobantecrgnro = cg.crgnum AND",
                   "crg.comprobantepprid = cg.pprid",
  
                   "LEFT JOIN clientes os ON os.clienteid = c.comprobanteentidadcodigo",
                   "LEFT JOIN proveedorprestador pp ON pp.pprid = comprobantepprid",
                   "WHERE c.tipocomprobantecodigo IN ({FacturasQuery}) AND",
                   "c.comprobantefechaemision > '2017-12-31' "))

Base <- dbGetQuery(conn = con,Base)

Base <- CleanTablaComprobantes(tabla_comprobantes = Base)

Base <- Base %>% filter(!NroComprobante %in% c(ComprobantesDesestimar))

Base <- unique(Base)

Base <- select(Base, 
               "Efector" = pprnombre, 
               "OS" = os, 
               "TipoFac" = tipocomprobantecodigo,
               "FactAnulada" = factanulada,
               "Fact" = NroComprobante, 
               "EmisionFact" = comprobantefechaemision,
               "Crg" = comprobantecrgnro,
               "EmisionCRG" = crgfchemision, 
               "Importe" = comprobantecrgimportetotaldeta,
               "IDCentroCosto" = centrocosto)

Base <- aggregate(.~Efector+OS+TipoFac+Fact+FactAnulada+EmisionFact+Crg+EmisionCRG+IDCentroCosto, Base, sum)


QueryCentroCosto <- "SELECT ccostocodigo,ccostodescripcion FROM centrocostos"

CentroCostos <- dbGetQuery(conn = con,QueryCentroCosto)

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

