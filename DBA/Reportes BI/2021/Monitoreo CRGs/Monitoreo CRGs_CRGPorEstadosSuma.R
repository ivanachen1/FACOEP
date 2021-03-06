
source("E:/Personales/Sistemas/Agustin/Reportes BI/2021/MonitoreoCRGs/Script Nancy Logica.R")

path_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Monitoreo CRGs/"

path_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/MonitoreoCRGs"

archivo_parametros <- GetArchivoParametros(path_one = path_one,path_two = path_two)


pw <- GetPassword(x = archivo_parametros)

drv <- dbDriver("PostgreSQL")

host <-GetHost(x = archivo_parametros)

database <- GetDatabase(x = archivo_parametros)

user <- GetUser(x = archivo_parametros)

con <- dbConnect(drv, dbname = database,
                 host = host, port = 5432, 
                 user = user,password = pw)

print(con)

workdirectory <- GetWorkDirectory(x = archivo_parametros)
print(paste(workdirectory,"Prestaciones Nancy.xlsx"))
separador <- ("/")



prestaciones <- read.xlsx(paste(workdirectory,"Prestaciones Nancy.xlsx",sep = separador))
GrupoPrestaciones <- prestaciones
prestaciones <- prestaciones$Prestacion
prestaciones <- unique(prestaciones)
prestaciones <- as.vector(prestaciones)
prestaciones <- unique(prestaciones)
prestaciones <- toString(sprintf("'%s'", prestaciones))

PrestacionesNosumar <- GetFile("PrestacionesNoSumar.xlsx",
                               path_one = path_one,
                               path_two = path_two)

QueryCrgsSuma <- glue("SELECT det.pprid,
                          pp.pprnombre as efector,
                          det.crgnum as Nrocrg,
                          det.crgdetnumerocph,
                          os.obsocialesdescripcion,
                          det.crgdetpractica as practica,
                          det.crgdetid as idpractica,
                          det.crgdetimportecrg as importecrg,
                          det.crgdetfechaprestacion as fechaprestacion,
                          det.crgdetnumerocph as numerodph,
                          crg.crgfchemision as emisioncrg,
                          crg.crgestado as crgidestado,
					                aux2.id_test,
					                aux2.id_detalle
					  
                          FROM crgdet det
                          
                          LEFT JOIN crg
                          ON det.crgnum = crg.crgnum and crg.pprid = det.pprid
                          
                          LEFT JOIN
                          obrassociales os ON crg.obsocialescodigo = os.obsocialescodigo
                          
                          LEFT JOIN 
                          proveedorprestador pp ON pp.pprid = det.pprid
                      
                          LEFT JOIN(SELECT DISTINCT 
                                      pprid,
                                      crgnum,
                                      crgdetnumerocph,
                                      CONCAT(pprid ,'-', crgnum,'-',crgdetnumerocph) as id_test,
                                      CONCAT(pprid ,'-', crgnum) as id_detalle
                                      
                                      FROM crgdet det WHERE crgdetpractica IN ({prestaciones})) as aux2
                      
                         ON CONCAT(det.pprid ,'-', det.crgnum,'-',det.crgdetnumerocph) = aux2.id_test
					  
					               WHERE aux2.id_test IS NOT NULL")


CRGPorEstadosSuma <- dbGetQuery(con,QueryCrgsSuma)


CRGPorEstadosSuma$practica <- gsub(" ","",CRGPorEstadosSuma$practica)

CRGPorEstadosSuma <- unique(CRGPorEstadosSuma)

CRGPorEstadosSuma <- select(CRGPorEstadosSuma,
                            "Efector" = efector,
                            "Prestacion" = practica,
                            "NroCrg" = nrocrg,
                            "ObraSocial" = obsocialesdescripcion,
                            "IDPractica" = idpractica,
                            "Fecha de Prestacion" = fechaprestacion,
                            "numero de dph" = numerodph,
                            "Fecha Emision CRG" = emisioncrg,
                            "EstadoCrg" = crgidestado,
                            "Importe" = importecrg,
                            "Id_Test" = id_test,
                            "Id_Detalle" = id_detalle)



CRGPorEstadosSuma <- left_join(CRGPorEstadosSuma,PrestacionesNosumar,by = c("Prestacion" = "Prestacion"))

CRGPorEstadosSuma$Sumar[is.na(CRGPorEstadosSuma$Sumar)] <- TRUE

#Cierra todo

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
rm(archivo_parametros,con,drv,PrestacionesNosumar,GrupoPrestaciones)
