
source("C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/RRHH-Licencias/licencias_logica.R")

path_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/RRHH-Licencias"

path_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranzas/Versión 7"

archivo_parametros <- GetArchivoParametros(path_one = path_one,path_two = path_two)


pw <- GetPassword(x = archivo_parametros)

drv <- dbDriver("PostgreSQL")

host <-GetHost(x = archivo_parametros)

user <- GetUser(x = archivo_parametros)

con <- dbConnect(drv, dbname = "facoep",
                 host = host, port = 5432, 
                 user = user,password = pw)


#SOLAPA 1 DEL REPORTE


QueryLicencias <- "SELECT * FROM licencias"


Licencias <- dbGetQuery(con,QueryLicencias)

EstadosLicencias <- GetFile(file_name = "estados_licencias.xlsx",
                            path_one = path_one,
                            path_two = path_two)



Licencias <- left_join(Licencias,EstadosLicencias,by = c("liceestado" = "Value"))
  
Licencias$liceestado <- NULL

QueryTipoLicencia <- "SELECT tipolicid,tipolicdesc as TipoLicencia FROM tipolicencia" 

TipoLicencia <- dbGetQuery(con,QueryTipoLicencia)

Licencias <- left_join(Licencias,TipoLicencia,by = c("tipolicid" = "tipolicid"))
  

# Creo la Query para crear una tabla intermedia con las tablas tusuario, biousuario y sectores llamada TablaUsuario

QueryTablaUsuario <- "SELECT bs.bionombre as NombrePersona,
                             bs.bioid,
                             bs.usuid as IDUSUARIO,
                             tu.usunom as NombreUsuario,
                             tu.sectorid as IdSector,
                             st.sectornombre,
                             tu.usufechaegreso as egreso
                             
                             FROM biousuario bs
                             
                             LEFT JOIN tusuario tu 
                             ON bs.usuid = tu.usuid
                             
                             LEFT JOIN sectores st
                             ON tu.sectorid = st.sectorid"

TablaUsuario <- dbGetQuery(con,QueryTablaUsuario)

Licencias <- left_join(Licencias,TablaUsuario,by = c("bioid" = "bioid"))

Licencias <- CleanTablaLicencias(Licencias)

Licencias <- ChangeLicenciasFieldsNames(Licencias)


# Cierra todo
rm(archivo_parametros,con,drv,EstadosLicencias,TablaUsuario,TipoLicencia)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})



#El campo Cantidad hace referencia a la cantidad de prestaciones o practicas del 
#mismo tipo dentro del CRG para la misma factura
