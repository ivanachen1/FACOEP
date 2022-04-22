workdirectory_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Efectores"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranzas/Versión 7"

source("C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Efectores/Script_Efectores_Funciones.r")



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


tabla_parametros_comprobantes <- GetFile("tabla_parametros_comprobantes.xlsx",
                                         path_one = workdirectory_one,
                                         path_two = workdirectory_two)



NotasCredito <- TransformFile(tabla_parametros_comprobantes,FilterOne = "notacredito")

NotasCredito <- GetListaINSQL(NotasCredito,print = FALSE)

FacturasQuery <- TransformFile(tabla_parametros_comprobantes,FilterOne = "factura")

FacturasQuery <- GetListaINSQL(FacturasQuery,print = FALSE)

QueryNc <- glue(paste("SELECT",
                   "c.comprobanteccosto as CentroCosto,",
                   "CASE WHEN c.comprobantedetalle LIKE '%ANULADO%' THEN 'SI' ELSE 'NO' END AS NcAnulada,",
                   "pprnombre,",
                   "CONCAT(os.clienteid,'-',os.clientenombre) as OS,",
                   "CONCAT(asoc.tipocomprobantecodigo,'-',asoc.comprobanteprefijo,'-',asoc.comprobantecodigo) as Factura,",
                   "c.comprobantefechaemision as FechaNotacredito,",
                   "CONCAT(asoc.comprobanteasoctipo,'-',asoc.comprobanteasocprefijo,'-',asoc.comprobanteasoccodigo) as notacredito,",
                   "crg.comprobantecrgnro as nrocrgnotacredito,",
                   "crg.comprobantepprid as ppridnotacredito,",
                   "cg.crgfchemision,",
                   "crg.comprobantecrgimportetotaldeta as importecrgnc",
                   
                   "FROM comprobantes c",
                   
                   "LEFT JOIN comprobantesasociados asoc ON",
                   "c.sucursalcodigo = asoc.sucursalcodigo and",
                   "c.comprobantetipoentidad = asoc.comprobantetipoentidad and",
                   "c.comprobanteentidadcodigo = asoc.comprobanteentidadcodigo and",
                   "c.tipocomprobantecodigo = asoc.tipocomprobantecodigo and",
                   "c.comprobanteprefijo = asoc.comprobanteprefijo and",
                   "c.comprobantecodigo = asoc.comprobantecodigo",
                   
                   "LEFT JOIN comprobantecrg crg ON",
                   "crg.empcod = asoc.empcod and",
                   "crg.tipocomprobantecodigo = asoc.comprobanteasoctipo and",
                   "crg.comprobanteprefijo = asoc.comprobanteasocprefijo and",
                   "crg.comprobantecodigo = asoc.comprobanteasoccodigo and",
                   "crg.sucursalcodigo = asoc.sucursalcodigo and",
                   "crg.comprobantetipoentidad = asoc.comprobantetipoentidad and",
                   "crg.comprobanteentidadcodigo = asoc.comprobanteentidadcodigo",

                   
                   "LEFT JOIN crg cg",
                   "ON crg.comprobantecrgnro = cg.crgnum AND",
                   "crg.comprobantepprid = cg.pprid",
                   
                   "LEFT JOIN clientes os ON os.clienteid = c.comprobanteentidadcodigo",
                   "LEFT JOIN proveedorprestador pp ON pp.pprid = crg.comprobantepprid",
                   
                   "WHERE c.tipocomprobantecodigo IN ({FacturasQuery}) AND",
                   "c.comprobantefechaemision > '2017-12-31' AND",
      					   "asoc.comprobanteasoctipo IN ({NotasCredito})"),sep = "\n")

cat(QueryNc)

Nc <- dbGetQuery(conn = con,QueryNc)

QueryFc <- glue(paste("SELECT",
                      "c.comprobanteccosto as CentroCosto,",
                      "CASE WHEN c.comprobantedetalle LIKE '%ANULADO%' THEN 'SI' ELSE 'NO' END AS FcAnulada,",
                      "pprnombre,",
                      "CONCAT(os.clienteid,'-',os.clientenombre) as OS,",
                      "CONCAT(c.tipocomprobantecodigo,'-',c.comprobanteprefijo,'-',c.comprobantecodigo) as Factura,",
                      "c.comprobantetotalimporte as ValorFactura,",
                      "crg.comprobantecrgnro as nrocrgfactura,",
                      "crg.comprobantepprid as ppridfactura,",
                      "c.comprobantefechaemision as EmisionFactura,",
                      "cg.crgfchemision,",
                      "crg.comprobantecrgimportetotaldeta as importecrg",
                      
                      "FROM comprobantes c",
                      
                      "LEFT JOIN comprobantecrg crg ON",
                      "crg.empcod = c.empcod and",
                      "crg.tipocomprobantecodigo = c.tipocomprobantecodigo and",
                      "crg.comprobanteprefijo = c.comprobanteprefijo and",
                      "crg.comprobantecodigo = c.comprobantecodigo and",
                      "crg.sucursalcodigo = c.sucursalcodigo and",
                      "crg.comprobantetipoentidad = c.comprobantetipoentidad and",
                      "crg.comprobanteentidadcodigo = c.comprobanteentidadcodigo",
                      
                      
                      "LEFT JOIN crg cg",
                      "ON crg.comprobantecrgnro = cg.crgnum AND",
                      "crg.comprobantepprid = cg.pprid",
                      
                      "LEFT JOIN clientes os ON os.clienteid = c.comprobanteentidadcodigo",
                      "LEFT JOIN proveedorprestador pp ON pp.pprid = crg.comprobantepprid",
                      
                      "WHERE c.tipocomprobantecodigo IN ({FacturasQuery}) AND",
                      "c.comprobantefechaemision > '2017-12-31' AND",
                      "c.comprobantetipoentidad = 2"),sep = "\n")

cat(QueryFc)

Fc <- dbGetQuery(conn = con,QueryFc)


ComprobantesAux <- dbGetQuery(conn = con,
                              glue(paste("SELECT CONCAT(tipocomprobantecodigo,'-',comprobanteprefijo,'-',comprobantecodigo) as notacredito,",
                              "comprobantetotalimporte as ImporteNc",
                              "FROM comprobantes WHERE tipocomprobantecodigo IN ({NotasCredito})")))


Nc <- left_join(Nc,ComprobantesAux,by = ("notacredito" = "notacredito"))




TablaFinal <- left_join(Fc,Nc,by = c('factura'='factura',
                                    'os'='os',
                                    'nrocrgfactura'='nrocrgnotacredito',
                                    'ppridfactura'='ppridnotacredito'),keep = TRUE)


TablaFinal <- select(TablaFinal,
                     "CentroCosto" = centrocosto.x,
                     "Efector" = pprnombre.x,
                     "ObraSocial" = os.x,
                     "Factura" = factura.x,
                     "TotalFactura" = valorfactura,
                     "EmisionFactura" = emisionfactura,
                     "CrgFactura"= nrocrgfactura,
                     "PpridFactura"= ppridfactura,
                     "EmisionFactura"= emisionfactura,
                     "EmisionCrg"= crgfchemision.x,
                     "ValorCrgFactura" = importecrg,
                     "NotaCredito" = notacredito,
                     "TotalNotaCredito" = importenc,
                     "EmisionNotaCredito" = fechanotacredito,
                     "CrgNotacredito" = nrocrgnotacredito,
                     "PpridNotaCredito" = ppridnotacredito,
                     "ValorCrgNotacredito" = importecrgnc)

TablaFinal$Igualdad <- ifelse(is.na(TablaFinal$NotaCredito),"SinNc",
                              ifelse(TablaFinal$TotalFactura == TablaFinal$TotalNotaCredito,
                                     "Iguales",
                                     "Diferentes"))


lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})


# tomar las notas de debito
# Mirar los crgs en cero

