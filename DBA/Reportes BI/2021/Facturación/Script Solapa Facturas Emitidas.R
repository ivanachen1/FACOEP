workdirectory_one <- "C:/Users/iachenbach/Desktop/Facoep - Scripts/DBA/Reportes BI/2021/Facturación"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version 3"
Archivo <-"Script_Facturacion_Funciones.R"
#source("C:/Users/iachenbach/Desktop/Facoep - Scripts/DBA/Reportes BI/2021/Facturación/Script_Facturacion_Funciones.R")


GetFileAux <- function(workdirectory_one,workdirectory_two,Archivo){
  intento <- try(source(paste(workdirectory_one,Archivo,sep = "/")),silent = TRUE)
  if (class(intento) == "try-error"){
    return(source(paste(workdirectory_two,Archivo,sep = "/")))} else {return(source(paste(workdirectory_one,Archivo,sep = "/")))}
}



GetFileAux(workdirectory_one = workdirectory_one,
           workdirectory_two = workdirectory_two,
           Archivo = "Script_Facturacion_Funciones.R")



archivo_parametros <- GetArchivoParametros(path_one = workdirectory_one,
                                           path_two = workdirectory_two,
                                           file = "parametros_servidor.xlsx")

tipo_comprobantes <- GetFile("tipo_comprobante.xlsx",
                             path_one = workdirectory_one,
                             path_two = workdirectory_two)


tipo_comprobantes$Comprobante <- tipo_comprobantes$Tipo.Comprobante


comprobantes_query <- GetListaINSQL(tipo_comprobantes)

CentrosCostos  <- GetFile("centro_costo_comprobantes.xlsx",
                                              path_one = workdirectory_one,
                                              path_two = workdirectory_two)

pw <- GetPassword()

drv <- dbDriver("PostgreSQL")

user <- GetUser()

host <- GetHost()
con <- dbConnect(drv, dbname = "facoep", 
                 host = host,
                 port = 5432,
                 user = user,
                 password = pw)


postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")


comprobantes <- glue("SELECT comprobanteccosto,
                      CAST(os.clienteid AS TEXT) || ' - ' || CAST(os.clientenombre AS TEXT) as OS,
                      c.tipocomprobantecodigo,
                      c.comprobanteprefijo,
                      c.comprobantecodigo,
                      c.comprobantefechaemision,
                      c.comprobantetotalimporte,
                      CASE WHEN c.comprobantedetalle LIKE '%ANULADO%' THEN 'SI' ELSE 'NO' END AS Anulado, 
                      os.clienteid



  FROM comprobantes c
   LEFT JOIN clientes os ON os.clienteid = c.comprobanteentidadcodigo
                                  
  WHERE c.comprobantetipoentidad = 2 and c.tipocomprobantecodigo IN ({comprobantes_query})")


comprobantes <- dbGetQuery(con,comprobantes) 

comprobantes <- CleanTablaComprobantes(comprobantes)

comprobantes <- left_join(comprobantes,CentrosCostos,by = c("comprobanteccosto" = "id.centro.costo"))

comprobantes$comprobanteccosto <- NULL

tipo_comprobantes <- data.frame("TipoComprobante" = tipo_comprobantes$Tipo.Comprobante,"Multiplicador"=tipo_comprobantes$Multiplicador)

comprobantes <- left_join(comprobantes,tipo_comprobantes,by = c("tipocomprobantecodigo" = "TipoComprobante"))

comprobantes$comprobantetotalimporte <- comprobantes$comprobantetotalimporte * comprobantes$Multiplicador

comprobantes$Multiplicador <- NULL

comprobantes$NombreMes <- months(as.Date(comprobantes$comprobantefechaemision))

comprobantes$Mes <- month(as.Date(comprobantes$comprobantefechaemision))

comprobantes$Anio <- year(as.Date(comprobantes$comprobantefechaemision))

comprobantes$dia <- day(as.Date(comprobantes$comprobantefechaemision))

comprobantes <- select(comprobantes,
                       "Financiador" = os,
                       "tipocomprobantecodigo" = tipocomprobantecodigo,
                       "Fecha Emision" = comprobantefechaemision,
                       "Centro de Costos" = Nombre,
                       "Anio" = Anio,
                       "importe"= comprobantetotalimporte,
                       "Anulado" = anulado,
                       "Mes" = Mes,
                       "Dia" = dia,
                       "Nombre del Mes" = NombreMes,
                       "NroComprobante" = NroComprobante)
