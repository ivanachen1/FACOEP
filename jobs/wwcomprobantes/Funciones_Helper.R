library(data.table)
library(tidyverse)
library(stringr)
library(openxlsx)
library(scales)
library(formattable)
library(stringr)
library(plyr)
library(zoo)
library(lubridate)
library("RPostgreSQL")
library(BBmisc)
library(glue)
library(readxl)
#library(reader)
library(stringr)

GetQuery <- function(){
  
  query <- paste("SELECT",
  "c.comprobanteentidadcodigo as id_entidad,",
  "c.comprobantefechaemision as fecha_emision,",
  "c.comprobantefechavencimiento as fecha_vencimiento,",
  "hist.fecha_tramite as fecha_entrega,",
  "c.comprobantecae as nro_cae,",
  "c.comprobantefechavencimientocae as vencimiento_cae,",
  "provincia.pronom as provincia,",
  "afip.actafipdescripcion as actividad_afip,",
  "tipoiva.tivades as condicion_iva,",
  "c.tipocomprobantecodigo as tipo,",
  "c.comprobanteprefijo as prefijo,",
  "c.comprobantecodigo as numero,",
  "c.comprobantetotalimporte as importe_total,",
  "c.comprobantedetalle as detalle,",
  "c.comprobanteperiodo as periodo,",
  "CASE",
  "WHEN c.comprobantetipoentidad = 2 Then 'Cliente'",
  "WHEN c.comprobantetipoentidad = 1 Then 'Proveedor'",
  "WHEN c.comprobantetipoentidad = 0 Then 'Ninguno' END AS entidad,",
  "TRIM(cc.ccostoabreviatura) as centro_costo,",
  "TRIM(sc.sccostodescripcion) as subcentro_costo,",
  "tl.tpoliqdescripcion as tipo_liquidacion,",
  "c.comprobanteorigen as id_origen,",
  "c.comprobanteasientocodigo as asiento,",
  "c.comprobanteproformanumero as numero_proforma,",
  "c.comprobantesaldo as saldo,",
  "c.comprobanteretencionib as retencion_ingresos_brutos,",
  "c.comprobantepercepcioningbrutos as importe_percepcion_ingresos_brutos,",
  "c.comprobantepercepcioniva as importe_percepcion_iva,",
  "c.comprobantepercepcionganancias as importe_percepcion_ganancias,",
  "c.comprobanteivasobretasa as importe_sobretasa_iva,",
  "c.comprobantenetoexento as importe_exento,",
  "c.comprobantemandatario as comprobante_mandatario,",
  "intimacion.fecha_tramite as fecha_intimacion,",
  "mandatario.fecha_tramite as fecha_procuracion,",
  "c.comprobanteimpreso as fue_impreso,",
  "c.comprobantecovid as es_covid,",
  "c.comprobanteintimacion as es_intimacion,",
  "c.comprobanteimportadoasi as comprobante_importado_de_asi,",
  "c.comprobanteasi as comprobante_asi,",
  "c.comprobantedigital as digital,",
  "COALESCE(c.comprobanterefacturacion,'false') as es_refacturacion,",
  "c.comprobanteesprestacion as es_prestacion,",
  "c.comprobanteconvenio as comprobante_convenio,",
  "CASE WHEN comprobantedetalle LIKE '%ANULADO%' THEN 'SI' ELSE 'NO' END AS es_anulado,",
  "c.comprobanteapertura as id_apertura",
  
  "FROM comprobantes c",
  
  "LEFT JOIN centrocostos as cc", 
  "ON c.comprobanteccosto = cc.ccostocodigo",
  
  "LEFT JOIN subcentrocostos sc",
  "ON", 
  "c.comprobanteccosto = sc.ccostocodigo AND",
  "c.comprobantesccosto  = sc.sccostocodigo AND",
  "c.empcod = sc.empcod",
  
  "LEFT JOIN provincia ON",
  "provincia.proid = c.comprobanteprovinciacodigo",
  
  "LEFT JOIN actividadafip as afip",
  "ON afip.actafipcodigo = c.comprobanteactafipcodigo",
  
  "LEFT JOIN tipoiva ON",
  "c.comprobantetipoivacodigo = tivaid",
  
  "LEFT JOIN tipoliquidacion as tl",
  "ON", 
  "c.comprobantetipoliq = tl.tpoliqcodigo AND",
  "c.comprobanteccosto = tl.ccostocodigo AND",
  "c.comprobantesccosto = tl.sccostocodigo",
  
  "LEFT JOIN (SELECT comprobantetipoentidad,",
  "                  comprobanteentidadcodigo,",
  "                  tipocomprobantecodigo,",
  "                  comprobanteprefijo,",
  "                  comprobantecodigo,",
  "           MAX(comprobantehisfechatramite) as fecha_tramite",
  "                  FROM comprobanteshistorial",
  "           WHERE comprobantehisestado IN (4,13)",
  "           GROUP BY 1,2,3,4,5) as hist",
  
  " ON c.comprobantetipoentidad      = hist.comprobantetipoentidad   AND",
  "    c.comprobanteentidadcodigo    = hist.comprobanteentidadcodigo AND",
  "    c.tipocomprobantecodigo       = hist.tipocomprobantecodigo    AND",
  "    c.comprobanteprefijo          = hist.comprobanteprefijo       AND",
  "    c.comprobantecodigo           = hist.comprobantecodigo",
  
  "LEFT JOIN (SELECT comprobantetipoentidad,",
  "                  comprobanteentidadcodigo,",
  "                  tipocomprobantecodigo,",
  "                  comprobanteprefijo,",
  "                  comprobantecodigo,",
  "           MAX(comprobantehisfechatramite) as fecha_tramite",
  "                  FROM comprobanteshistorial",
  "           WHERE comprobantehisestado = 19",
  "           GROUP BY 1,2,3,4,5) as mandatario",
  
  " ON c.comprobantetipoentidad      = mandatario.comprobantetipoentidad   AND",
  "    c.comprobanteentidadcodigo    = mandatario.comprobanteentidadcodigo AND",
  "    c.tipocomprobantecodigo       = mandatario.tipocomprobantecodigo    AND",
  "    c.comprobanteprefijo          = mandatario.comprobanteprefijo       AND",
  "    c.comprobantecodigo           = mandatario.comprobantecodigo",
  
  "LEFT JOIN (SELECT comprobantetipoentidad,",
  "                  comprobanteentidadcodigo,",
  "                  tipocomprobantecodigo,",
  "                  comprobanteprefijo,",
  "                  comprobantecodigo,",
  "           MAX(comprobantehisfechatramite) as fecha_tramite",
  "                  FROM comprobanteshistorial",
  "           WHERE comprobantehisestado = 10",
  "           GROUP BY 1,2,3,4,5) as intimacion",
  
  " ON c.comprobantetipoentidad      = intimacion.comprobantetipoentidad   AND",
  "    c.comprobanteentidadcodigo    = intimacion.comprobanteentidadcodigo AND",
  "    c.tipocomprobantecodigo       = intimacion.tipocomprobantecodigo    AND",
  "    c.comprobanteprefijo          = intimacion.comprobanteprefijo       AND",
  "    c.comprobantecodigo           = intimacion.comprobantecodigo",
  
  
  "WHERE c.comprobanteentidadcodigo <> -1",
  "ORDER BY c.comprobantefechaemision DESC",sep = " ")
  
  return (query)
}

QuitFields <- function(data){
  data$id_origen <- NULL
  data$Descripcion <- NULL
  data$prefijo <- NULL
  data$numero <- NULL
  data$nombre <- NULL
  return(data)

}

CreateComprobante <- function(data){
  data$tipo <- str_trim(data$tipo)
  
  data$comprobante <- paste(data$tipo,data$prefijo,data$numero,sep = "-")
  
  return(data)
  
}

CreateEntidadTable <- function(drv,con){
  
query_clientes <- paste("SELECT",
                        "clienteid as id,",
                        "clientenombre as nombre,",
                        "'Cliente' as tipo",
                        "FROM clientes",sep = " ")

query_proveedores <- paste("SELECT",
                        "pprid as id,",
                        "pprnombre as nombre,",
                        "'Proveedor' as tipo",
                        "FROM proveedorprestador",sep = " ")

clientes <- dbGetQuery(conn = con,query_clientes)

proveedores <- dbGetQuery(conn = con,query_proveedores)

tabla_entidad <- rbind(clientes,proveedores)

tabla_entidad$nombre <- str_trim(tabla_entidad$nombre)

return(tabla_entidad)
}

ChangeBoolValues <- function(data){
  
  data$comprobante_mandatario <- ifelse(data$comprobante_mandatario == FALSE,
                                        'NO','SI')
  
  data$fue_impreso <- ifelse(data$fue_impreso == FALSE,
                             'NO','SI')
  
  data$es_covid <- ifelse(data$es_covid == FALSE,
                          'NO','SI')
  
  data$es_intimacion <- ifelse(data$es_intimacion == FALSE,
                          'NO','SI')
  
  data$comprobante_importado_de_asi <- ifelse(data$comprobante_importado_de_asi == FALSE,
                               'NO','SI')
  
  data$comprobante_asi <- ifelse(data$comprobante_asi == FALSE,
                                              'NO','SI')
  
  data$digital <- ifelse(data$digital == FALSE,
                                 'NO','SI')
  
  data$es_refacturacion <- ifelse(data$es_refacturacion == FALSE,
                         'NO','SI')
  
  data$es_prestacion <- ifelse(data$es_prestacion  == FALSE,
                                  'NO','SI')
  
  data$comprobante_convenio <- ifelse(data$comprobante_convenio  == FALSE,
                               'NO','SI')
  
  
  return(data)
}

ReplaceIncorrectValue <- function(data){
  data["vencimiento_cae"][data["vencimiento_cae"] == '0001-01-01'] <- NA
  data["fecha_vencimiento"][data["fecha_vencimiento"] == '0001-01-01'] <- NA
  
  return(data)
  
}

GetApertura <- function(df,tabla_apertura){
  
  df$id_apertura[is.na(df$id_apertura)] <- 4
  
  df <- left_join(df,tabla_apertura,by = 'id_apertura')
  
  return(df)
}

GetHistoricDeleteQuery <- function(date){
  query <- glue("DELETE FROM wwcomprobantes_historial WHERE fecha_imagen = '{date}'")
  
  print(query)
  
  return(query)
}

CreateFechaVencimiento <- function(data,dateParameter){
  
  data$fecha_vencimiento <- NULL
  

  data$fecha_vencimiento <- fifelse(data$tipo %in% c('NDB','NDA','NDECA','NDAASI','NDBASI') & data$origen == 'Intimacion',
                                    as.Date(data$fecha_emision),
                                    fifelse(is.na(data$fecha_entrega),
                                            as.Date('1999-01-01'),
                                            fifelse(data$fecha_emision < dateParameter,
                                                    data$fecha_entrega + 60,
                                                    data$fecha_entrega + 90)))
  return(data)
  
}

CreateMandatarioField <- function(data){
  
  data$comprobante_mandatario <- ifelse(is.na(data$fecha_procuracion),
                                        data$comprobante_mandatario,
                                        "PROCURACION")
  
  data$fecha_procuracion <- NULL
  
  return (data)
  
}

CreateFechaEntrega <- function(data){
  data$fecha_entrega <- fifelse(data$tipo %in% c('NDB','NDA','NDECA','NDAASI','NDBASI') & data$origen == 'Intimacion',
                               as.Date(data$fecha_emision),
                               as.Date(data$fecha_entrega))
  
  data$fecha_intimacion <- NULL
  
  return (data)
  
}

queryDetectarTurismo <- function(pprid){
  
  query <- glue(paste( "SELECT DISTINCT",
                  "TRIM(tipocomprobantecodigo) as tipo,",
                  "comprobanteprefijo as prefijo,",
                  "comprobantecodigo as numero",
  
                  "FROM comprobantecrg", 
                  "WHERE comprobantepprid IN ({pprid}) AND comprobantetipoentidad = 2",sep = " "))
  
  

}

esTurismo <- function(data,con){
  
  query_turismo <- queryDetectarTurismo(pprid = 3140) 
    
  
  turismo  <- dbGetQuery(conn = con,query_turismo)
  
  turismo <- CreateComprobante(turismo)
  
  turismo$numero <- NULL
  turismo$prefijo <- NULL
  turismo$tipo  <- NULL
  
  turismo$es_turismo <- "SI"
  
  data <- left_join(data,turismo,by = c('comprobante'))
  
  data$es_turismo <- ifelse(is.na(data$es_turismo),"NO",data$es_turismo)
  
  return (data)

}

esDetectar <- function(data,con){
  
  query_detectar <- glue(paste( "SELECT DISTINCT",
                       "TRIM(tipocomprobantecodigo) as tipo,",
                       "comprobanteprefijo as prefijo,",
                       "comprobantecodigo as numero",
                       
                       "FROM comprobantecrg", 
                       "WHERE comprobantepprid IN (3173,3186) AND comprobantetipoentidad = 2",sep = " "))
  
  
  detectar  <- dbGetQuery(conn = con,query_detectar)
  
  detectar <- CreateComprobante(detectar)
  
  detectar$numero <- NULL
  detectar$prefijo <- NULL
  detectar$tipo  <- NULL
  
  detectar$es_detectar <- "SI"
  
  data <- left_join(data,detectar,by = c('comprobante'))
  
  data$es_detectar <- ifelse(is.na(data$es_detectar),"NO",data$es_detectar)
  
  return (data)
  
}

InsertRecordsPostgres <- function(credenciales,table_name,df,overwrite,append){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = credenciales[2],
                   host = credenciales[1],
                   port = 5432,
                   user = credenciales[3],
                   password = credenciales[4])
  
  dbWriteTable(conn = con,
               name= table_name,
               value = df,
               overwrite = overwrite,
               append = append,
               row.names= FALSE)
  
  lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
  
}

DeletePostgresRows <- function(credenciales,table_name,query){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = credenciales[2],
                   host = credenciales[1],
                   port = 5432,
                   user = credenciales[3],
                   password = credenciales[4])
  
  dbExecute(con, query)
  
  lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
}

GetOrigenTable <- function(){
  
  query <- "SELECT sigla,name FROM origenes"
  
  drv <- dbDriver("PostgreSQL")
  
  pw <- "serveradmin"
  con <- dbConnect(drv, 
                   dbname = "SIF",
                   host = "10.22.1.44",
                   port = 5432,
                   user = "postgres",
                   password = "serveradmin")
  
  data  <- dbGetQuery(conn = con,query)
  
  dbDisconnect(conn = con)
  
  return(data)
  
  dbDisconnect(conn = con)
}
