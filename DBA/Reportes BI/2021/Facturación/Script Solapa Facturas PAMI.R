workdirectory_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturación"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version 3"
workdirectory_three <- "E:/Personales/Sistemas/Estadisticas"
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

tipo_comprobantes <- select(tipo_comprobantes,Comprobante,Multiplicador,TipoPami)

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

############################################## CONSULTAS ######################################################

nuevo_pami <- glue("SELECT comprobantefechaemision as emision,
                                         tipocomprobantecodigo,
                                         comprobanteprefijo,
                                         comprobantecodigo,
                                         ccostodescripcion, 
                                         sccostodescripcion,
                                         tpoliqdescripcion,
                                         comprobantetotalimporte,
                                         comprobantedetalle

                         FROM comprobantes c
                         LEFT JOIN centrocostos cc ON c.comprobanteccosto = cc.ccostocodigo
                         LEFT JOIN subcentrocostos sc ON c.comprobanteccosto = sc.ccostocodigo and c.comprobantesccosto = sc.sccostocodigo
                         LEFT JOIN tipoliquidacion tp ON tp.tpoliqcodigo = c.comprobantetipoliq and tp.ccostocodigo = c.comprobanteccosto and tp.sccostocodigo = c.comprobantesccosto
                         WHERE comprobanteccosto = 1 and comprobantefechaemision >= '2021-01-01' and tipocomprobantecodigo IN ({comprobantes_query})
                                and comprobantedetalle not like '%ANULA%'")


nuevo_pami <- dbGetQuery(con,nuevo_pami)

nuevo_pami <- CleanTablaComprobantes(nuevo_pami)

nuevo_pami <- left_join(nuevo_pami,tipo_comprobantes,by = c("tipocomprobantecodigo" = "Comprobante"))


nuevo_pami$comprobantetotalimporte <- nuevo_pami$comprobantetotalimporte * nuevo_pami$Multiplicador
  
nuevo_pami$tipo <- nuevo_pami$TipoPami

nuevo_pami$TipoPami <- NULL

nuevo_pami$Multiplicador <- NULL

nuevo_pami$comprobantetotalimporte <- ifelse(nuevo_pami$sccostodescripcion == "CAPITA CLIENTE", 0,
                                       nuevo_pami$comprobantetotalimporte)

DetallesPAMICapita <- GetFile("Detalles PAMI Cápita.xlsx",
                              path_one = workdirectory_one,
                              path_two = workdirectory_two)


DetallesPAMICapita$Emision <- as.Date(DetallesPAMICapita$Emision,origin = "1899-12-30")

rm(CentrosCostos,con,drv,tipo_comprobantes,archivo_parametros)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
