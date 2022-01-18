
workdirectory_one <- "C:/Users/iachenbach/Desktop/Facoep - Scripts/DBA/Reportes BI/2021/Facturación/"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version 3"

source("C:/Users/iachenbach/Desktop/Facoep - Scripts/DBA/Reportes BI/2021/Facturación/Script_Facturacion_Funciones.R")

archivo_parametros <- GetArchivoParametros(path_one = WorkdirectoryOne,
                                           path_two = WorkdirectoryTwo,
                                           file = "parametros_servidor.xlsx")


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


query <- "SELECT comprobanteccosto,
                      CAST(os.clienteid AS TEXT) || ' - ' || CAST(os.clientenombre AS TEXT) as OS,
                      c.tipocomprobantecodigo,
                      c.comprobanteprefijo,
                      c.comprobantecodigo,
                      c.comprobantefechaemision,
                      c.comprobantetotalimporte,
                      c.comprobantedetalle,
                      os.obsocialescodigo



  FROM comprobantes c
   LEFT JOIN clientes os ON os.clienteid = c.comprobanteentidadcodigo
                                  
  WHERE c.comprobantetipoentidad = 2 and "



Bruto <- dbGetQuery(con,query) 

