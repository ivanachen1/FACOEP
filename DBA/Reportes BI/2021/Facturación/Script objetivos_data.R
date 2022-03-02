workdirectory_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturación"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version 3"
Archivo <-"Script_Facturacion_Funciones.R"
library(reader)
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


CentrosCostos  <- GetFile("centro_costo_comprobantes.xlsx",
                          path_one = workdirectory_one,
                          path_two = workdirectory_two)

CodigosOOSSDesestimar <- GetFile(file_name = "Codigos Obra Social a Desestimar.xlsx",
                                 path_one = workdirectory_one,
                                 path_two = workdirectory_two)

CodigosOOSSDesestimar$Comprobante <- CodigosOOSSDesestimar$Codigos.Obra.Social.a.Desestimar

CodigosOOSSDesestimar<- GetListaINSQL(CodigosOOSSDesestimar)

ComprobantesDesestimar <- GetFile(file_name = "comprobantes a desestimar.xlsx",
                                 path_one = workdirectory_one,
                                 path_two = workdirectory_two)


ComprobantesDesestimar$Comprobante <- ComprobantesDesestimar$Listado.Comprobantes.a.desestimar

ComprobantesDesestimar<- GetListaINSQL(ComprobantesDesestimar)

ObjetivosData <- GetFile(file_name = "Objetivos.xlsx",
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


SIF2Query <- glue("SELECT pprnombre,
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
                                  
                      WHERE c.comprobantetipoentidad = 2 and comprobantepprid > 0 and c.tipocomprobantecodigo IN({comprobantes_query}) AND c.comprobantecodigo NOT IN ({ComprobantesDesestimar}) AND os.obsocialescodigo NOT IN ({CodigosOOSSDesestimar}) ")


SIF2 <- dbGetQuery(con,SIF2Query)

SIF2 <- CleanTablaComprobantes(SIF2)

SIF2$comprobantefechaemision <- as.Date(SIF2$comprobantefechaemision)

SIF2 <- unique(SIF2)

SIF2$AnioEmision <- year(SIF2$comprobantefechaemision)

SIF2 <- left_join(SIF2,Efectores, by = c("pprnombre" = "sif"))

SIF2 <- aggregate(SIF2$comprobantecrgimporteneto,by = list(SIF2$Efector,SIF2$Anio),FUN = sum)

colnames(SIF2) <- c("Efector","Anio","Total.Facturado")

SIF2$Fk <- paste(SIF2$Anio,SIF2$Efector,sep = "-")


workdirectory_three <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturación/repositorio SIGHEOS"


Sigehos <- ReadSigehosData(workdirectory = workdirectory_three,
                        sheet = "Base")

Sigehos <- unique(Sigehos)

Sigehos$Anio <- year(Sigehos$Fecha)

Sigehos <- aggregate(Sigehos$Importe.Total,by = list(Sigehos$Anio,Sigehos$Efector),FUN = sum)
  

colnames(Sigehos) <- c("Año","Efector","emitidoSIGEHOS")

Sigehos$fk <- paste(Sigehos$Año,Sigehos$Efector,sep = "-")

ObjetivosData$fk <- paste(ObjetivosData$Año,ObjetivosData$Efector,sep = "-")

ObjetivosData <- left_join(ObjetivosData,SIF2,by = c("fk"="Fk"))

ObjetivosData <- select(ObjetivosData,
                        "Efector" = Efector.x,
                        "Objetivo.Anual.Total" = Objetivo.Anual.Total,
                        "Objetivo.Mensual.OOSS" = Objetivo.Mensual.OOSS,
                        "Objetivo.Anual.PAMI"= Objetivo.Anual.PAMI,
                        "Año" = Año,
                        "SIF.Total.Facturado" = Total.Facturado,
                        "fk" = fk)

ObjetivosData <- left_join(ObjetivosData,Sigehos,by = c("fk" = "fk"))

colnames(ObjetivosData)

ObjetivosData <- select(ObjetivosData,
                        "Efector" = Efector.x,
                        "Objetivo.Anual.Total" = Objetivo.Anual.Total,
                        "Objetivo.Mensual.OOSS" = Objetivo.Mensual.OOSS,
                        "Objetivo.Anual.PAMI"= Objetivo.Anual.PAMI,
                        "Año" = Año.x,
                        "SIF.Total.Facturado" = SIF.Total.Facturado,
                        "Total.Facturado.SIGEHOS" = emitidoSIGEHOS)

ObjetivosData$SIF.Total.Facturado <- replace()
