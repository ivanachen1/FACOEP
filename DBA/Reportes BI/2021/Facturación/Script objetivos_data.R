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


BrutoQuery <- "SELECT pprnombre,
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
                                  
                      WHERE c.comprobantetipoentidad = 2 and comprobantepprid > 0"


Bruto <- dbGetQuery(con,BrutoQuery)

Bruto <- CleanTablaComprobantes(Bruto)

Bruto$obsocialescodigo <- as.
