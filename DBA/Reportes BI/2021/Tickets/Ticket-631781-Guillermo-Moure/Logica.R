#workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturaci?n"
workdirectory <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Tickets/Ticket-631781-Guillermo-Moure"

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


comprobantes <- paste("SELECT",
                      "CONCAT(nota.tipocomprobantecodigo,'-',nota.comprobanteprefijo,'-',nota.comprobantecodigo) as impugnacion,",
                       "nota.comprobantefechaemision as fecha_impugnacion,",
                       "nota.comprobantetotalimporte as importe_impugnacion,",
                            "CONCAT(asoc.comprobanteasoctipo,'-',asoc.comprobanteasocprefijo,'-',asoc.comprobanteasoccodigo) as factura,",
                            "asoc.comprobanteasoctipo as tipofactura,",
                            
                            "inicial.comprobantehisfechatramite as enviado,",
                            "ultimo.comprobantehisfechatramite as finalizado,",
                            "ultimo.comprobantehisfechatramite - inicial.comprobantehisfechatramite as diferencia",
                            
                            
                            
                            "FROM",
                            
                            "comprobantes as nota",
                            
                            "LEFT JOIN comprobantesasociados as asoc",
                            "ON", 
                            "nota.tipocomprobantecodigo = asoc.tipocomprobantecodigo AND",
                            "nota.comprobanteprefijo = asoc.comprobanteprefijo AND",
                            "nota.comprobantecodigo = asoc.comprobantecodigo",
                            
                            "LEFT JOIN (",
                            " SELECT", 
                            " tipocomprobantecodigo,",
                            " comprobanteprefijo,",
                            " comprobantecodigo,",
                            " MIN(comprobantehisfechatramite) as comprobantehisfechatramite,",
                            " comprobantehisestado",
                              
                            " FROM comprobanteshistorial",
                              
                             "WHERE tipocomprobantecodigo IN ('NOTADB') AND comprobantehisestado = 34",
                             "GROUP BY tipocomprobantecodigo,comprobanteprefijo,",
                             "comprobantecodigo,comprobantehisestado) as inicial",
                            
                            "ON",
                            "nota.tipocomprobantecodigo = inicial.tipocomprobantecodigo AND",
                            "nota.comprobanteprefijo = inicial.comprobanteprefijo AND",
                            "nota.comprobantecodigo = inicial.comprobantecodigo",
                            
                            "LEFT JOIN (",
                            "  SELECT",
                            "  tipocomprobantecodigo,",
                            "  comprobanteprefijo,",
                            "  comprobantecodigo,",
                            "  MAX(comprobantehisfechatramite) as comprobantehisfechatramite,",
                            "  comprobantehisestado",
                              
                            "  FROM comprobanteshistorial",
                              
                            "WHERE tipocomprobantecodigo IN ('NOTADB')",
                            "AND comprobantehisestado = 6",
                            "GROUP BY tipocomprobantecodigo,comprobanteprefijo,",
                            "comprobantecodigo,comprobantehisestado) as ultimo",
                            
                            "ON",
                            "nota.tipocomprobantecodigo = ultimo.tipocomprobantecodigo AND",
                            "nota.comprobanteprefijo = ultimo.comprobanteprefijo AND",
                            "nota.comprobantecodigo = ultimo.comprobantecodigo",
                            
                            
                            "WHERE nota.tipocomprobantecodigo IN ('NOTADB') AND",
                            "asoc.comprobanteasoctipo IN ('FACA2','FACB2','FAECA','FAECB') AND",
                            "inicial.comprobantehisfechatramite IS NOT NULL AND",
                            "ultimo.comprobantehisfechatramite - inicial.comprobantehisfechatramite < 4")


cat(comprobantes)

comprobantes <- dbGetQuery(con,comprobantes)

comprobantes$factura <- str_trim(comprobantes$factura,"both")
comprobantes$impugnacion <- str_trim(comprobantes$impugnacion,"both")
comprobantes$tipofactura <- str_trim(comprobantes$tipofactura,"both")

comprobantes$FAECA <- ifelse(comprobantes$tipofactura == 'FAECA','SI','NO')

comprobantes <- select(comprobantes,
                       "Impugnacion" = impugnacion,
                       "Fecha de la Impugnacion" = fecha_impugnacion,
                       "Importe Total Impugnacion" = importe_impugnacion,
                       "Factura" = factura,
                       "Tipo de Factura" = tipofactura,
                       "Fecha de Envio Auditoria Médica" = enviado,
                       "Fecha de Finalizacion Auditoria Médica" = finalizado,
                       "duracion en dias" = diferencia,
                       "FAECA",FAECA)

write.xlsx(comprobantes,"Impugnaciones.xlsx")

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
