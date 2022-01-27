workdirectory_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturación/"
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

estados  <- GetFile("crg_estados.xlsx",
                          path_one = workdirectory_one,
                          path_two = workdirectory_two)

efectores  <- GetFile("Efectores.xlsx",
                    path_one = workdirectory_one,
                    path_two = workdirectory_two)

SIF <- dbGetQuery(con, "SELECT pprnombre as SIF, crgnum, crgfchemision,crgestado
                        FROM crg c LEFT JOIN proveedorprestador p ON p.pprid = c.pprid")

SIF <- left_join(SIF,estados)

SIF$crgestado <- NULL

unique()

# Reemplazo los valores nulos por Ingresado por definicion de negocio

SIF$estado[is.na(SIF$estado)] <- "INGRESADO"

SIF <- left_join(SIF,efectores,by = c("sif" = "sif"))

# Reemplazo los NA por CESAC por definicion de Negocio

SIF$Efector[is.na(SIF$Efector)] <- "CESAC"

SIF$id <- paste(SIF$Efector,SIF$crgnum,sep = " ")

SIF2 <- dbGetQuery(con, "SELECT pprnombre,
  obsocialessigla as os,
  c.tipocomprobantecodigo,
  c.comprobanteprefijo,
  c.comprobantecodigo,
  c.comprobantefechaemision,
  comprobantecrgnro, comprobantecrgimporteneto,os.obsocialescodigo 

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
                                  
  WHERE c.comprobantetipoentidad = 2 and comprobantepprid > 0")

SIF2 <- CleanTablaComprobantes(SIF2)

# Lo que queda hacer de SIF2 es migrar las transformaciones de Power BI a R.#SIF 1 esta terminado
