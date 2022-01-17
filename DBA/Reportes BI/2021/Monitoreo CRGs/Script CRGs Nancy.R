
source("C:/Users/User/Desktop/FACOEP/DBA/Reportes BI/2021/Monitoreo CRGs/Script Nancy Logica.R")

path_one <- "C:/Users/User/Desktop/FACOEP/DBA/Reportes BI/2021/Monitoreo CRGs/"

path_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranzas/Versión 7"

archivo_parametros <- GetArchivoParametros(path_one = path_one,path_two = path_two)


pw <- GetPassword(x = archivo_parametros)

drv <- dbDriver("PostgreSQL")

host <-GetHost(x = archivo_parametros)

user <- GetUser(x = archivo_parametros)

con <- dbConnect(drv, dbname = "facoep",
                 host = host, port = 5432, 
                 user = user,password = pw)


workdirectory <- GetWorkDirectory(x = archivo_parametros)
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


#SOLAPA 1 DEL REPORTE


QueryCrgsFacturados <- glue("SELECT
              pprnombre as Efector,
              CAST(cd.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(cd.comprobanteprefijo AS TEXT) || ' - ' ||CAST(cd.comprobantecodigo AS TEXT) as factura,
              cd.comprobantecrgdetpractica as Prestacion,
              cd.comprobantecrgnro
              
              
              FROM comprobantecrgdet cd
              
              
              LEFT JOIN 
              proveedorprestador pp ON pp.pprid = cd.comprobantepprid
              
              WHERE cd.tipocomprobantecodigo IN ({comprobantes}) and cd.comprobantecrgdetpractica IN ({prestaciones})")


CRGsFacturados <- dbGetQuery(con,QueryCrgsFacturados)

CRGsFacturados$factura <- gsub(" ","",CRGsFacturados$factura)

CRGsFacturados$prestacion <- gsub(" ","",CRGsFacturados$prestacion)

CRGsFacturados$cantidad <- 1


CRGsFacturados <- aggregate(CRGsFacturados$cantidad,
                  by = list(CRGsFacturados$efector,CRGsFacturados$factura,CRGsFacturados$prestacion,CRGsFacturados$comprobantecrgnro),
                  FUN = sum)

colnames(CRGsFacturados) <- c("Efector","Factura","Prestacion","NroCRG","Cantidad")


#SOLAPA 2 DEL REPORTE


QueryCrgs <- glue("SELECT det.crgnum as NroCrg,
                  crgestado as CrgIdEstado,
                  det.crgdetpractica as Practica,
                  pp.pprid,
                  pprnombre as Efector 
             
                  FROM crg cd
             
                  LEFT JOIN proveedorprestador pp ON pp.pprid = cd.pprid
             
                  LEFT JOIN crgdet det ON cd.crgnum = det.crgnum 
                                       and cd.pprid = det.pprid
             
                  WHERE det.crgdetpractica IN ({prestaciones})")


print(QueryCrgs)

CRGPorEstados <- dbGetQuery(con,QueryCrgs)


CRGPorEstados$cantidad <- 1



CRGPorEstados <- aggregate(CRGPorEstados$cantidad,
                  by = list(CRGPorEstados$efector,CRGPorEstados$crgidestado,CRGPorEstados$nrocrg,CRGPorEstados$practica),
                  FUN = sum)

colnames(CRGPorEstados) <- c("Efector","EstadoCrg","NroCRG","Prestacion","Cantidad")

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

rm(archivo_parametros,con,drv)

EstadosCrgs <- read.xlsx(paste(workdirectory,"Estados CRGs.xlsx",sep = separador))

print(prestaciones)
#El campo Cantidad hace referencia a la cantidad de prestaciones o practicas del 
#mismo tipo dentro del CRG para la misma factura