workdirectory_one <- "C:/Users/User/Desktop/FACOEP/DBA/Reportes BI/2021/Efectores"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranzas/Versión 7"

source("C:/Users/User/Desktop/FACOEP/DBA/Reportes BI/2021/Efectores/Script_Efectores_Funciones.r")



archivo_parametros <- GetArchivoParametros(path_one = workdirectory_one, 
                                           path_two = workdirectory_two, 
                                           file = "parametros_servidor.xlsx")

pw <- GetPassword()

user <- GetUser()

host <- GetHost() 

drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv, dbname = "facoep",
                 host = host, port = 5432, 
                 user = user, password = pw)

postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")

tabla_parametros_comprobantes <- GetFile("tabla_parametros_comprobantes.xlsx",
                                         path_one = workdirectory_one,
                                         path_two = workdirectory_two)


tabla_parametros_comprobantes <- TransformFile(tabla_parametros_comprobantes,FilterOne = "factura")

FacturasQuery <- TransformFile(tabla_parametros_comprobantes,FilterOne = "factura")

FacturasQuery <- GetListaINSQL(FacturasQuery,print = FALSE)

Base <- glue("SELECT
c.comprobanteccosto as CentroCosto,
  pprnombre,
  CAST(os.clienteid AS TEXT) || ' - ' || CAST(os.clientenombre AS TEXT) as OS,
  c.tipocomprobantecodigo,
  c.comprobanteprefijo,
  c.comprobantecodigo,
  c.comprobantefechaemision,
  comprobantecrgnro,
  comprobantecrgimportetotaldeta
  
  FROM comprobantes c
  LEFT JOIN comprobantecrg crg ON crg.comprobanteprefijo = c.comprobanteprefijo and
                                  crg.empcod = c.empcod and
                                  crg.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                  crg.sucursalcodigo = c.sucursalcodigo and
                                  crg.comprobantetipoentidad = c.comprobantetipoentidad and
                                  crg.comprobantecodigo = c.comprobantecodigo and
                                  crg.comprobanteentidadcodigo = c.comprobanteentidadcodigo
  
  LEFT JOIN clientes os ON os.clienteid = c.comprobanteentidadcodigo
  LEFT JOIN proveedorprestador pp ON pp.pprid = comprobantepprid
 
  WHERE c.tipocomprobantecodigo IN ({FacturasQuery})")

Base <- dbGetQuery(conn = con,Base)

Base <- CleanTablaComprobantes(tabla_comprobantes = Base)

Base <- unique(Base)

Base <- select(Base, 
               "Efector" = pprnombre, 
               "OS" = os, 
               "TipoFac" = tipocomprobantecodigo, 
               "Fact" = NroComprobante, 
               "Emision" = comprobantefechaemision, 
               "Importe" = comprobantecrgimportetotaldeta,
               "IDCentroCosto" = centrocosto)

Base <- aggregate(.~Efector+OS+TipoFac+Fact+Emision+IDCentroCosto, Base, sum)


# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})


QueryCentroCosto <- "SELECT ccostocodigo,ccostodescripcion FROM centrocostos"

CentroCostos <- dbGetQuery(conn = con,QueryCentroCosto)
