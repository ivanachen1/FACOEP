workdirectory_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturación"
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

tipo_comprobantes <- select(tipo_comprobantes,
                            "TipoComprobante" = Tipo.Comprobante,
                            "SIF2" = Alimenta.a.SIF2)

Efectores <- GetFile("Efectores.xlsx",
                             path_one = workdirectory_one,
                             path_two = workdirectory_two)


tipo_comprobantes$Comprobante <- tipo_comprobantes$TipoComprobante

tipo_comprobantes <- filter(tipo_comprobantes,SIF2 == TRUE)

comprobantes_query <- GetListaINSQL(tipo_comprobantes)

print(comprobantes_query)

CentrosCostos  <- GetFile("centro_costo_comprobantes.xlsx",
                          path_one = workdirectory_one,
                          path_two = workdirectory_two)

CodigosOOSSDesestimar <- GetFile(file_name = "Codigos Obra Social a Desestimar.xlsx",
                                 path_one = workdirectory_one,
                                 path_two = workdirectory_two)

ComprobantesDesestimar <- GetFile(file_name = "comprobantes a desestimar.xlsx",
                                 path_one = workdirectory_one,
                                 path_two = workdirectory_two)


ComprobantesDesestimar$Comprobante <- ComprobantesDesestimar$Listado.Comprobantes.a.desestimar

ComprobantesDesestimar<- GetListaINSQL(ComprobantesDesestimar)


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


BrutoQuery <- glue("SELECT pprnombre,
                      CASE WHEN (pprnombre LIKE'%CES%') THEN 'CESAC' WHEN (pprnombre LIKE'%CEM%') THEN 'CESAC' ELSE pprnombre END AS pprnombre2,
                      obsocialessigla as os,
                      c.tipocomprobantecodigo,
                      c.comprobanteprefijo,
                      c.comprobantecodigo,
                      c.comprobantefechaemision,
                      comprobantecrgnro,
                      comprobantecrgimporteneto,
                      os.obsocialescodigo 

                      FROM comprobantes c
                      LEFT JOIN comprobantecrg crg ON crg.comprobanteprefijo = c.comprobanteprefijo and
                      crg.empcod = c.empcod and
                      crg.tipocomprobantecodigo = c.tipocomprobantecodigo and
                      crg.sucursalcodigo = c.sucursalcodigo and
                      crg.comprobantetipoentidad = c.comprobantetipoentidad and
                      crg.comprobantecodigo = c.comprobantecodigo and
                      crg.comprobanteentidadcodigo = c.comprobanteentidadcodigo
  
                      LEFT JOIN obrassociales os ON os.obsocialescodigo = crg.comprobantecrgos
                      LEFT JOIN proveedorprestador pp on pp.pprid = crg.comprobantepprid
                                  
                      WHERE c.comprobantetipoentidad = 2 and comprobantepprid > 0 and c.tipocomprobantecodigo IN({comprobantes_query}) AND c.comprobantecodigo NOT IN ({ComprobantesDesestimar})")


Bruto <- dbGetQuery(con,BrutoQuery)

Bruto <- CleanTablaComprobantes(Bruto)

Bruto$comprobantefechaemision <- as.Date(Bruto$comprobantefechaemision)

Bruto <- unique(Bruto)

Bruto$AnioEmision <- year(Bruto$comprobantefechaemision)

Bruto <- left_join(Bruto,Efectores, by = c("pprnombre" = "sif"))

Bruto <- aggregate(Bruto$comprobantecrgimporteneto,by = list(Bruto$Efector,Bruto$Anio),FUN = sum)

colnames(Bruto) <- c("Efector","Anio","Total Facturado")

Bruto$Fk <- paste(Bruto$Anio,Bruto$Efector,sep = "-")


