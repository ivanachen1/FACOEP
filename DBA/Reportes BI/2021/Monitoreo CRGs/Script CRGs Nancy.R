
source("C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Monitoreo CRGs/Script Nancy Logica.R")

path_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Monitoreo CRGs/"

path_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranzas/Versión 7"

archivo_parametros <- GetArchivoParametros(path_one = path_one,path_two = path_two)


pw <- GetPassword(x = archivo_parametros)

drv <- dbDriver("PostgreSQL")

host <-GetHost(x = archivo_parametros)

user <- GetUser(x = archivo_parametros)

con <- dbConnect(drv, dbname = "facoep",
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


comprobantes <- read.xlsx(paste(workdirectory,"tabla_parametros_comprobantes.xlsx",sep = separador))
comprobantes <- comprobantes$Comprobante
comprobantes <- as.vector(comprobantes)
comprobantes <- toString(sprintf("'%s'", comprobantes))

print(comprobantes)
print(prestaciones)

PrestacionesNosumar <- GetFile("PrestacionesNoSumar.xlsx",
                               path_one = path_one,
                               path_two = path_two)


#SOLAPA 1 DEL REPORTE


QueryCrgsFacturados <- glue("SELECT
                            det.pprid,
                            det.crgnum as Nrocrg,
                            det.crgdetnumerocph,
                            aux.factura,
                            aux.efector,
                            aux.crgfchemision,
                            aux.importecrg,
                            aux.prestacion
                            
                            FROM crgdet det
                            
                            LEFT JOIN 
                            proveedorprestador pp ON pp.pprid = det.pprid
                            
                            LEFT JOIN(
                              SELECT
                              cd.comprobantepprid,
                              pprnombre as Efector,
                              CAST(cd.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(cd.comprobanteprefijo AS TEXT) || ' - ' ||CAST(cd.comprobantecodigo AS TEXT) as factura,
                              cd.comprobantecrgdetpractica as Prestacion,
                              cd.comprobantecrgnro,
                              crg.crgfchemision,
                              cd.comprobantecrgdetimportecrg as ImporteCRG
                              
                              
                              FROM comprobantecrgdet cd
                              
                              LEFT JOIN 
                              crg ON cd.comprobantecrgnro = crg.crgnum and crg.pprid = cd.comprobantepprid
                              
                              
                              
                              LEFT JOIN 
                              proveedorprestador pp ON pp.pprid = cd.comprobantepprid
                            ) as aux
                            
                            ON det.pprid = aux.comprobantepprid AND det.crgnum = aux.comprobantecrgnro 
                            
                            WHERE det.crgdetpractica IN ({prestaciones}) and aux.factura IS NOT NULL")


CRGsFacturados <- dbGetQuery(con,QueryCrgsFacturados)

CRGsFacturados$factura <- gsub(" ","",CRGsFacturados$factura)

CRGsFacturados$prestacion <- gsub(" ","",CRGsFacturados$prestacion)

CRGsFacturados <- select(CRGsFacturados,
                         "Efector" = efector,
                         "Factura" = factura,
                         "Prestacion" = prestacion,
                         "NroCrg" = nrocrg,
                         "Fecha Emision CRG" = crgfchemision,
                         "Importe del CRG" = importecrg,
                         "Numero DPH" = crgdetnumerocph)

CRGsFacturados <- left_join(CRGsFacturados,PrestacionesNosumar,by = c("Prestacion" = "Prestacion"))

CRGsFacturados$Sumar[is.na(CRGsFacturados$Sumar)] <- TRUE

#SOLAPA 2 DEL REPORTE


QueryCrgs <- glue("SELECT
                      det.pprid,
                      det.crgnum as Nrocrg,
					            aux.emisioncrg,
                      aux.CrgIdEstado,
                      aux.Practica,
                      pp.pprid,
                      aux.idpractica,
                      aux.importecrg,
                      aux.fechaprestacion,
                      aux.numerodph,
                      aux.Efector
              
              
                      FROM crgdet det
              
                      LEFT JOIN 
                      proveedorprestador pp ON pp.pprid = det.pprid
          
                      
                      LEFT JOIN (
                      
                      SELECT dets.crgnum as NroCrg,
                  cd.crgfchemision as emisioncrg,
                  crgestado as CrgIdEstado,
                  dets.crgdetpractica as Practica,
                  pp.pprid,
                  dets.crgdetid as idpractica,
                  dets.crgdetimportecrg as importecrg,
                  dets.crgdetfechaprestacion as fechaprestacion,
                  dets.crgdetnumerocph as numerodph,
                  pprnombre as Efector 
             
                  FROM crg cd
             
                  LEFT JOIN proveedorprestador pp ON pp.pprid = cd.pprid
             
                  LEFT JOIN crgdet dets ON cd.crgnum = dets.crgnum 
                                       and cd.pprid = dets.pprid
                      ) as aux
                      
                  ON det.pprid = aux.pprid AND det.crgnum = aux.nrocrg AND det.crgdetnumerocph = aux.numerodph
				  
				  WHERE det.crgdetpractica IN ({prestaciones})")


CRGPorEstados <- dbGetQuery(con,QueryCrgs)

CRGPorEstados$practica <- gsub(" ","",CRGPorEstados$practica)

CRGPorEstados <- select(CRGPorEstados,
                         "Efector" = efector,
                         "Prestacion" = practica,
                         "NroCrg" = nrocrg,
                         "IDPractica" = idpractica,
                         "Fecha de Prestacion" = fechaprestacion,
                         "numero de dph" = numerodph,
                         "Fecha Emision CRG" = emisioncrg,
                         "EstadoCrg" = crgidestado,
                         "Importe" = importecrg)



CRGPorEstados <- left_join(CRGPorEstados,PrestacionesNosumar,by = c("Prestacion" = "Prestacion"))

CRGPorEstados$Sumar[is.na(CRGPorEstados$Sumar)] <- TRUE

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

rm(archivo_parametros,con,drv)

EstadosCrgs <- read.xlsx(paste(workdirectory,"Estados CRGs.xlsx",sep = separador))

print(prestaciones)
#El campo Cantidad hace referencia a la cantidad de prestaciones o practicas del 
#mismo tipo dentro del CRG para la misma factura
