GetQueryComprobantes <- function(){
  query = ("SELECT
  pprnombre,
  CAST(c.clienteid AS TEXT) || ' - ' || CAST(clientenombre AS TEXT) as OS,
  os.clientecuit,
  c.tipocomprobantecodigo,
  c.comprobanteprefijo,
  c.comprobantecodigo,
  c.comprobantefechaemision,
  c.comprobanteccosto,
  c.comprobantetotalimporte
  
  FROM comprobantes c

  LEFT JOIN clientes os ON os.clienteid = c.comprobanteentidadcodigo
  LEFT JOIN proveedorprestador pp ON pp.pprid = comprobantepprid")
  return(x)
}

CleanTablaComprobantes <- function(tabla_comprobantes,tabla_parametros_comprobantes){
  tabla_comprobantes$tipocomprobantecodigo <- gsub(" ","",tabla_comprobantes$tipocomprobantecodigo)
  tabla_comprobantes$NroComprobante <- paste(tabla_comprobantes$tipocomprobantecodigo,
                                             tabla_comprobantes$comprobanteprefijo,
                                             tabla_comprobantes$comprobantecodigo,sep = "-")
  
  tabla_comprobantes$comprobanteprefijo <- NULL
  tabla_comprobantes$comprobantecodigo <- NULL
  
  #tabla_comprobantes<- filter(tabla_comprobantes,os != is.na(os))
  tabla_comprobantes<- unique(tabla_comprobantes)
  
  tabla_comprobantes <- left_join(tabla_comprobantes,tabla_parametros_comprobantes,by = c("tipocomprobantecodigo" = "Comprobante"))
  tabla_comprobantes <- filter(tabla_comprobantes,tipo != is.na(tipo))
  return(tabla_comprobantes)
}

#GetQueryComprobantesAsociados <- function(){
  
  #query <- }

CleanComprobantesAsociados <- function(tabla_comprobantes_asociados,tabla_parametros_comprobantes,tabla_comprobantes_importes){
  
  tabla_comprobantes_asociados$tipocomprobantecodigo <- gsub(" ","",tabla_comprobantes_asociados$tipocomprobantecodigo)
  tabla_comprobantes_asociados$NroComprobante <- paste(tabla_comprobantes_asociados$tipocomprobantecodigo,
                                                       tabla_comprobantes_asociados$comprobanteprefijo,
                                                       tabla_comprobantes_asociados$comprobantecodigo,sep = "-")
  
  tabla_comprobantes_asociados$comprobanteprefijo <- NULL
  tabla_comprobantes_asociados$comprobantecodigo <- NULL
  
  tabla_comprobantes_asociados$comprobanteasoctipo <- gsub(" ","",tabla_comprobantes_asociados$comprobanteasoctipo)
  tabla_comprobantes_asociados$NroComprobanteAsociado <- paste(tabla_comprobantes_asociados$comprobanteasoctipo,
                                                               tabla_comprobantes_asociados$comprobanteasocprefijo,
                                                               tabla_comprobantes_asociados$comprobanteasoccodigo,sep = "-")
  
  tabla_comprobantes_asociados$comprobanteasocprefijo <- NULL
  tabla_comprobantes_asociados$comprobanteasoccodigo <- NULL
  tabla_comprobantes_asociados$comprobanteasocobs <- NULL
  #tabla_comprobantes<- filter(tabla_comprobantes,os != is.na(os))
  tabla_comprobantes_asociados<- unique(tabla_comprobantes_asociados)
  
  tabla_comprobantes_asociados <- left_join(tabla_comprobantes_asociados,tabla_parametros_comprobantes,by = c("comprobanteasoctipo" = "Comprobante"))
  tabla_comprobantes_asociados <- filter(tabla_comprobantes_asociados,tipo != is.na(tipo))
  
  tabla_comprobantes_asociados <- left_join(tabla_comprobantes_asociados,tabla_comprobantes_importes,by = c("NroComprobanteAsociado" = "Comprobante"))
  return(tabla_comprobantes_asociados)
}