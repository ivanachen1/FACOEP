workdirectory_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Efectores"

workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranzas/Versión 7"

source("C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Efectores/Script_Efectores_Funciones.r")


archivo_parametros <- GetArchivoParametros(path_one = workdirectory_one, 
                                           path_two = workdirectory_two, 
                                           file = "parametros_servidor.xlsx")

pw <- GetPassword()

user <- GetUser()

host <- GetHost() 

drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv, dbname = "facoep",
                 host = host, port = 5432, 
                 user = user, password = pw)

postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")

tabla_parametros_comprobantes <- GetFile("tabla_parametros_comprobantes.xlsx",
                                         path_one = workdirectory_one,
                                         path_two = workdirectory_two)




FacturasQuery <- TransformFile(tabla_parametros_comprobantes,FilterOne = "factura")

FacturasQuery <- GetListaINSQL(FacturasQuery,print = FALSE)


NotaDB <- TransformFile(tabla_parametros_comprobantes,FilterOne = "notadb")

NotaDB <- GetListaINSQL(NotaDB,print = FALSE)

tabla_apertura <- GetFile("tabla_aperturas.xlsx",
                          path_one = workdirectory_one,
                          path_two = workdirectory_two)



tabla_apertura <- TransFormTablaApertura(archivo  = tabla_apertura,print = TRUE)

query <- glue("SELECT

hosp.pprnombre as Efector,
CAST(ooss.clienteid AS TEXT) || ' - ' || CAST(ooss.clientenombre AS TEXT) as OOSS,
CAST(fact.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(fact.comprobanteprefijo AS TEXT) || ' - ' || CAST(fact.comprobantecodigo AS TEXT) as Factura,
fact.comprobanteccosto as CentroCosto,
CAST(asoc.comprobanteasoctipo AS TEXT) || ' - ' || CAST(asoc.comprobanteasocprefijo AS TEXT) || ' - ' || CAST(asoc.comprobanteasoccodigo AS TEXT) as impugnacion,
dets.comprobantecrgdetpractica as prestacion,
nota.comprobantefechaemision as Fecha,
dets.comprobantecrgdetmotivodebcred,
ComprobanteCRGDetImporteDebita as Rechazado,
ComprobanteCRGDetImporteAcredi as Aceptado

FROM COMPROBANTES fact

LEFT JOIN COMPROBANTESASOCIADOS asoc ON fact.empcod = asoc.empcod and 
					fact.sucursalcodigo = asoc.sucursalcodigo and
					fact.comprobantetipoentidad = asoc.comprobantetipoentidad and
					fact.comprobanteentidadcodigo = asoc.comprobanteentidadcodigo and
					fact.tipocomprobantecodigo = asoc.tipocomprobantecodigo and
					fact.comprobanteprefijo = asoc.comprobanteprefijo and
					fact.comprobantecodigo = asoc.comprobantecodigo
					
LEFT JOIN COMPROBANTES nota 	ON 	asoc.comprobanteasoctipo = nota.tipocomprobantecodigo and
					asoc.comprobanteasocprefijo = nota.comprobanteprefijo and
					asoc.comprobanteasoccodigo = nota.comprobantecodigo

LEFT JOIN COMPROBANTECRG crgs ON	crgs.empcod = nota.empcod and 
					crgs.sucursalcodigo = nota.sucursalcodigo and
					crgs.comprobantetipoentidad = nota.comprobantetipoentidad and
					crgs.comprobanteentidadcodigo = nota.comprobanteentidadcodigo and
					crgs.tipocomprobantecodigo = nota.tipocomprobantecodigo and
					crgs.comprobanteprefijo = nota.comprobanteprefijo and
					crgs.comprobantecodigo = nota.comprobantecodigo

LEFT JOIN COMPROBANTECRGDET dets ON 	dets.empcod = crgs.empcod and 
					dets.sucursalcodigo = crgs.sucursalcodigo and
					dets.comprobantetipoentidad = crgs.comprobantetipoentidad and
					dets.comprobanteentidadcodigo = crgs.comprobanteentidadcodigo and
					dets.tipocomprobantecodigo = crgs.tipocomprobantecodigo and
					dets.comprobanteprefijo = crgs.comprobanteprefijo and
					dets.comprobantecodigo = crgs.comprobantecodigo and
					dets.comprobantepprid = crgs.comprobantepprid and
					dets.comprobantecrgnro = crgs.comprobantecrgnro
					
LEFT JOIN proveedorprestador hosp ON 	hosp.pprid = dets.comprobantepprid

LEFT JOIN clientes ooss ON 	ooss.clienteid = nota.comprobanteentidadcodigo

WHERE   fact.tipocomprobantecodigo IN ({FacturasQuery}) and
	asoc.comprobanteasoctipo = {NotaDB} and
	nota.comprobanteapertura IN ({tabla_apertura}) and
	nota.comprobanteentidadcodigo NOT IN (1,201,208,209,210,272,532,621,649,650,651,652,657,1069)")

print(query)


Base <- dbGetQuery(conn = con,query)

Base$factura <- gsub(" ","",Base$factura)
Base$impugnacion <- gsub(" ","",Base$impugnacion)


Base <- select(Base, "Efector" = efector, 
               "Obra social" = ooss,
               "Factura" = factura,
               "CentroCosto" = centrocosto,
               "Impugnacion" = impugnacion,
               "Prestacion" = prestacion,
               "FechaNotaDB" = fecha,
               "MotivoDebitoCredito" = comprobantecrgdetmotivodebcred,
               "Rechazado" = rechazado,
               "Aceptado" = aceptado)

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

rm(archivo_parametros,tabla_parametros_comprobantes,con,drv)
