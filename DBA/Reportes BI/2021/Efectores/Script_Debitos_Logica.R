workdirectory <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/detalle debitos"
#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/detalle debitos"
Archivo <-"Script_debitos_Funciones.R"
#source("C:/Users/iachenbach/Desktop/Facoep - Scripts/DBA/Reportes BI/2021/Facturación/Script_Facturacion_Funciones.R")


source(paste(workdirectory,Archivo,sep = "/"))



archivo_parametros <- GetArchivoParametros(path_one = workdirectory,
                                           path_two = workdirectory,
                                           file = "parametros_servidor.xlsx")


pw <- GetParameter(x = archivo_parametros,
                   parameter = "password")

drv <- dbDriver("PostgreSQL")

user <- GetParameter(x = archivo_parametros,parameter = "user")

host <- GetParameter(x = archivo_parametros,parameter = "host")

database <- GetParameter(x = archivo_parametros,parameter = "database")

con <- dbConnect(drv, dbname = database, 
                 host = host,
                 port = 5432,
                 user = user,
                 password = pw)


SelectQuery <- paste("SELECT",
                     "comprobantefechaemision,",
                     "CONCAT(nota.tipocomprobantecodigo,'-',nota.comprobanteprefijo,'-',nota.comprobantecodigo) AS notadb,",
                     "CONCAT(nota.comprobanteentidadcodigo,'-',os.obsocialessigla) AS OOSS,",
                     "hosp.pprnombre as Efector,",
                     "crgs.comprobantecrgnro as CRG,",
                     "cg.crgauditoriamedicausuario as auditor,",
                     "mot.motivodebitodescripcion as TipoDebito,",
                     "cat.motivodebitocategorianombre as Categoria,",
                     "dets.comprobantecrgdetmotivodescrip as Observaciones,",
                     "dets.ComprobanteCRGDetImporteDebita as Rechazado,",
                     "dets.ComprobanteCRGDetImporteAcredi as Aceptado,",
                     "dets.comprobantecrgdetpractica as codigo,",
                     "auditoria.tipocomprobantecodigo AS EnAuditoria",
                     "FROM COMPROBANTES nota",
                     "LEFT JOIN COMPROBANTECRG crgs ON crgs.empcod = nota.empcod AND", 
                     "crgs.sucursalcodigo = nota.sucursalcodigo AND",
                     "crgs.comprobantetipoentidad = nota.comprobantetipoentidad AND",
                     "crgs.comprobanteentidadcodigo = nota.comprobanteentidadcodigo AND",
                     "crgs.tipocomprobantecodigo = nota.tipocomprobantecodigo AND",
                     "crgs.comprobanteprefijo = nota.comprobanteprefijo AND",
                     "crgs.comprobantecodigo = nota.comprobantecodigo",
                     "LEFT JOIN COMPROBANTECRGDET dets ON dets.empcod = crgs.empcod AND",
                     "dets.sucursalcodigo = crgs.sucursalcodigo AND",
                     "dets.comprobantetipoentidad = crgs.comprobantetipoentidad AND",
                     "dets.comprobanteentidadcodigo = crgs.comprobanteentidadcodigo AND",
                     "dets.tipocomprobantecodigo = crgs.tipocomprobantecodigo AND",
                     "dets.comprobanteprefijo = crgs.comprobanteprefijo AND",
                     "dets.comprobantecodigo = crgs.comprobantecodigo AND",
                     "dets.comprobantepprid = crgs.comprobantepprid AND",
                     "dets.comprobantecrgnro = crgs.comprobantecrgnro",
                     "LEFT JOIN proveedorprestador hosp ON hosp.pprid = dets.comprobantepprid",
                     "LEFT JOIN motivodebito mot ON mot.motivodebitoid = dets.comprobantecrgdetmotivodebcred",
                     "LEFT JOIN motivodebitocategoria cat ON cat.motivodebitoid = dets.comprobantecrgdetmotivodebcred AND cat.motivodebitocategoriaid = dets.comprobantecrgdetmotdebcredcat",
                     "LEFT JOIN obrassociales os ON os.obsocialesclienteid = nota.comprobanteentidadcodigo",
                     "LEFT JOIN crg cg ON dets.comprobantepprid = cg.pprid AND dets.comprobantecrgnro = cg.crgnum",
                     "LEFT JOIN auditoriascompartidascomproban auditoria ON",
                     "nota.tipocomprobantecodigo = auditoria.tipocomprobantecodigo AND",
                     "nota.comprobanteprefijo = auditoria.comprobanteprefijo AND",
                     "nota.comprobantecodigo = auditoria.comprobantecodigo",
                     "WHERE nota.tipocomprobantecodigo IN ('NOTADB')")


MotivosDebitos <- dbGetQuery(con,SelectQuery)

MotivosDebitos$EsAuditoriaCompartida <- ifelse(is.na(MotivosDebitos$enauditoria),
                                               "NO","SI")

FacturasQuery <- paste("SELECT",
                     "CONCAT(nota.tipocomprobantecodigo,'-',nota.comprobanteprefijo,'-',nota.comprobantecodigo) AS notadb,",
                     "CONCAT(asociados.comprobanteasoctipo,'-',asociados.comprobanteasocprefijo,'-',asociados.comprobanteasoccodigo) AS factura,",
                     "c.comprobantedetalle as detallefactura",
                     "FROM COMPROBANTES nota",
                     "LEFT JOIN comprobantesasociados as asociados",
                     "ON nota.tipocomprobantecodigo = asociados.tipocomprobantecodigo AND",
                     "nota.comprobanteprefijo = asociados.comprobanteprefijo AND",
                     "nota.comprobantecodigo = asociados.comprobantecodigo ",
                     "LEFT JOIN comprobantes c",
                     "ON asociados.comprobanteasoctipo = c.tipocomprobantecodigo AND",
                     "asociados.comprobanteasocprefijo = c.comprobanteprefijo AND",
                     "asociados.comprobantecodigo = c.comprobantecodigo",
                     "WHERE nota.tipocomprobantecodigo IN ('NOTADB')",
                     "AND asociados.comprobanteasoctipo IN ('FACA2','FACB2','FAECA','FAECB')")

Facturas <- dbGetQuery(con,FacturasQuery)
Facturas$detallefactura <- ifelse(is.na(Facturas$detallefactura),"SIN DETALLE",Facturas$detallefactura)

Facturas$esRefactura <- str_detect(Facturas$detallefactura, "REFACTURA")

MotivosDebitos <- left_join(MotivosDebitos,Facturas, by = c('notadb' = 'notadb'))

MotivosDebitos <- select(MotivosDebitos,
                         "Fecha Emision Comprobante"= comprobantefechaemision,
                         "NOTADB" = notadb,
                         "OOSS" = ooss,
                         "Efector" = efector,
                         "NroCRG" = crg,
                         "Auditor" = auditor,
                         "Tipo Debito"= tipodebito,
                         "Categoria"= categoria,
                         "Observaciones" = observaciones,
                         "Rechazado" = rechazado,
                         "Aceptado" = aceptado,
                         "Prestacion" = codigo,
                         "AuditoriaCompartida" = EsAuditoriaCompartida,
                         "EsRefactura" = esRefactura)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

