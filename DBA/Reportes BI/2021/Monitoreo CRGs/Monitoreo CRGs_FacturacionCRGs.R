source("C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Monitoreo CRGs/Script Nancy Logica.R")
#source("E:/Personales/Sistemas/Agustin/Reportes BI/2021/MonitoreoCRGs/Script Nancy Logica.R")

path_one <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Monitoreo CRGs"
#path_one <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/MonitoreoCRGs"

archivo_parametros <- GetArchivoParametros(path_one = path_one,
                                           path_two = path_one)


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
print(prestaciones)

PrestacionesNosumar <- GetFile("PrestacionesNoSumar.xlsx",
                               path_one = path_one,
                               path_two = path_two)

TipoFacturas <- GetFile("tabla_parametros_comprobantes.xlsx",
                        path_one = path_one,
                        path_two = path_two)

TipoFacturas <- TipoFacturas$Comprobante
TipoFacturas <- unique(TipoFacturas)
TipoFacturas <- as.vector(TipoFacturas)
TipoFacturas <- unique(TipoFacturas)
TipoFacturas <- toString(sprintf("'%s'", TipoFacturas))
print(TipoFacturas)

QueryCrgsFacturados <- glue("SELECT 
                          det.pprid,
                          pp.pprnombre as efector,
						              CONCAT(comp.tipocomprobantecodigo,'-',comp.comprobanteprefijo,'-',comp.comprobantecodigo) as factura,
						              facturas.comprobantefechaemision as EmisionFactura,
                          det.crgnum as Nrocrg,
                          crg.crgfchemision as emisioncrg,
                          det.crgdetnumerocph,
                          os.obsocialesdescripcion,
                          det.crgdetpractica as practica,
                          det.crgdetid as idcrgdet,
                          det.crgdetimportecrg as importecrg,
                          det.crgdetfechaprestacion as fechaprestacion,
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
						 
						             LEFT JOIN comprobantecrgdet comp
						             ON det.pprid = comp.comprobantepprid AND det.crgnum = comp.comprobantecrgnro AND det.crgdetid = comp.comprobantecrgdetid
						 
						             LEFT JOIN(SELECT CONCAT(tipocomprobantecodigo,'-',comprobanteprefijo,'-',comprobantecodigo) as factura,
												 comprobantefechaemision
								  			 FROM comprobantes
								  			 WHERE tipocomprobantecodigo IN({TipoFacturas})) as facturas
						             ON CONCAT(comp.tipocomprobantecodigo,'-',comp.comprobanteprefijo,'-',comp.comprobantecodigo) = facturas.factura
					  
					               WHERE aux2.id_test IS NOT NULL AND crg.crgestado = 4 AND comp.tipocomprobantecodigo IN({TipoFacturas})")


CRGsFacturados <- dbGetQuery(con,QueryCrgsFacturados)


CRGsFacturados$practica <- gsub(" ","",CRGsFacturados$practica)
CRGsFacturados$factura <- gsub(" ","",CRGsFacturados$factura)

CRGsFacturados$crgdetnumerocph <- as.character(CRGsFacturados$crgdetnumerocph)
CRGsFacturados$nrocrg <- as.character(CRGsFacturados$nrocrg)
CRGsFacturados$idcrgdet<- as.character(CRGsFacturados$idcrgdet)

CRGsFacturados <- left_join(CRGsFacturados,
                            PrestacionesNosumar,
                            by = c('practica' = 'Prestacion'))
CRGsFacturados$Sumar <- ifelse(is.na(CRGsFacturados$Sumar),
                               TRUE,
                               FALSE)

CRGsFacturados <- select(CRGsFacturados,
                            "Efector" = efector,
                            "Factura" = factura,
                            "EmisionFactura" = emisionfactura,
                            "Prestacion" = practica,
                            "NroCrg" = nrocrg,
                            "ObraSocial" = obsocialesdescripcion,
                            "IDCRGdet" = idcrgdet,
                            "Fecha de Prestacion" = fechaprestacion,
                            "numero de dph" = crgdetnumerocph,
                            "Fecha Emision CRG" = emisioncrg,
                            "ImporteCRG" = importecrg,
                            "Id_Test" = id_test,
                            "Id_Detalle" = id_detalle,
                            "Sumar" = Sumar)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
rm(archivo_parametros,con,drv,PrestacionesNosumar,GrupoPrestaciones)
