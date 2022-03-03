workdirectory_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/detalle debitos"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version 3"
Archivo <-"Script_debitos_Funciones.R"
#source("C:/Users/iachenbach/Desktop/Facoep - Scripts/DBA/Reportes BI/2021/Facturación/Script_Facturacion_Funciones.R")


GetFileAux <- function(workdirectory_one,workdirectory_two,Archivo){
  intento <- try(source(paste(workdirectory_one,Archivo,sep = "/")),silent = TRUE)
  if (class(intento) == "try-error"){
    return(source(paste(workdirectory_two,Archivo,sep = "/")))} else {return(source(paste(workdirectory_one,Archivo,sep = "/")))}
}



GetFileAux(workdirectory_one = workdirectory_one,
           workdirectory_two = workdirectory_two,
           Archivo = Archivo)



archivo_parametros <- GetArchivoParametros(path_one = workdirectory_one,
                                           path_two = workdirectory_two,
                                           file = "parametros_servidor.xlsx")


pw <- GetPassword()

drv <- dbDriver("PostgreSQL")

user <- GetUser()

host <- GetHost()
conn <- dbConnect(drv, dbname = "facoep", 
                 host = host,
                 port = 5432,
                 user = user,
                 password = pw)


postgresqlpqExec(conn, "SET client_encoding = 'windows-1252'")

SelectQuery <- paste("SELECT",
                 "comprobantefechaemision,",
                 "CAST(nota.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(nota.comprobantecodigo AS TEXT) as nota,",
                 "CAST(nota.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(os.obsocialessigla AS TEXT) as OS,",
                 "hosp.pprnombre as Efector,",
                 "crgs.comprobantecrgnro as CRG,",
                 "mot.motivodebitodescripcion as TipoDebito,",
                 "cat.motivodebitocategorianombre as Categoria,",
                 "dets.comprobantecrgdetmotivodescrip as Observaciones,",
                 "ComprobanteCRGDetImporteDebita as Rechazado,",
                 "ComprobanteCRGDetImporteAcredi as Aceptado,",
                 "dets.comprobantecrgdetpractica as codigo",
                 "FROM COMPROBANTES nota",
                 "LEFT JOIN COMPROBANTECRG crgs ON crgs.empcod = nota.empcod AND", 
                 "crgs.sucursalcodigo = nota.sucursalcodigo AND",
                 "crgs.comprobantetipoentidad = nota.comprobantetipoentidad AND",
                 "crgs.comprobanteentidadcodigo = nota.comprobanteentidadcodigo AND",
                 "crgs.tipocomprobantecodigo = nota.tipocomprobantecodigo AND",
                 "crgs.comprobanteprefijo = nota.comprobanteprefijo AND",
                 "crgs.comprobantecodigo = nota.comprobantecodigo",
                 "LEFT JOIN COMPROBANTECRGDET dets ON dets.empcod = crgs.empcod AND",
                 "dets.sucursalcodigo = crgs.sucursalcodigo AND",
                 "dets.comprobantetipoentidad = crgs.comprobantetipoentidad AND",
                 "dets.comprobanteentidadcodigo = crgs.comprobanteentidadcodigo AND",
                 "dets.tipocomprobantecodigo = crgs.tipocomprobantecodigo AND",
                 "dets.comprobanteprefijo = crgs.comprobanteprefijo AND",
                 "dets.comprobantecodigo = crgs.comprobantecodigo AND",
                 "dets.comprobantepprid = crgs.comprobantepprid AND",
                 "dets.comprobantecrgnro = crgs.comprobantecrgnro",
                 "LEFT JOIN proveedorprestador hosp ON hosp.pprid = dets.comprobantepprid",
                 "LEFT JOIN motivodebito mot ON mot.motivodebitoid = dets.comprobantecrgdetmotivodebcred",
                 "LEFT JOIN motivodebitocategoria cat ON cat.motivodebitoid = dets.comprobantecrgdetmotivodebcred AND",
                 "cat.motivodebitocategoriaid = dets.comprobantecrgdetmotdebcredcat",
                 "LEFT JOIN obrassociales os ON os.obsocialesclienteid = nota.comprobanteentidadcodigo",
                 "WHERE nota.comprobantefechaemision BETWEEN '2021-12-01' AND '2021-12-31' AND nota.tipocomprobantecodigo IN ('NOTADB')")

print(SelectQuery)


dbGetQuery(conn,SelectQuery)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

