workdirectory_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/detalle debitos"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Efectores/version2"
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

con <- dbConnect(drv, dbname = "facoep", 
                 host = host,
                 port = 5432,
                 user = user,
                 password = pw)


SelectQuery <- paste("SELECT",
                 "comprobantefechaemision,",
                 "CONCAT(nota.tipocomprobantecodigo,'-',nota.comprobanteprefijo,'-',nota.comprobantecodigo) AS notadb,",
                 "CONCAT(nota.comprobanteentidadcodigo,'-',os.obsocialessigla) AS OOSS,",
                 "hosp.pprnombre as Efector,",
                 "crgs.comprobantecrgnro as CRG,",
                 "mot.motivodebitodescripcion as TipoDebito,",
                 "cat.motivodebitocategorianombre as Categoria,",
                 "dets.comprobantecrgdetmotivodescrip as Observaciones,",
                 "dets.ComprobanteCRGDetImporteDebita as Rechazado,",
                 "dets.ComprobanteCRGDetImporteAcredi as Aceptado,",
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
                 "LEFT JOIN motivodebitocategoria cat ON cat.motivodebitoid = dets.comprobantecrgdetmotivodebcred AND cat.motivodebitocategoriaid = dets.comprobantecrgdetmotdebcredcat",
                 "LEFT JOIN obrassociales os ON os.obsocialesclienteid = nota.comprobanteentidadcodigo",
                 "WHERE nota.tipocomprobantecodigo IN ('NOTADB')")


MotivosDebitos <- dbGetQuery(con,SelectQuery)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

MotivosDebitos <- select(MotivosDebitos,
                         "Fecha Emision Comprobante"= comprobantefechaemision,
                         "NOTADB" = notadb,
                         "OOSS" = ooss,
                         "Efector" = efector,
                         "NroCRG" = crg,
                         "Tipo Debito"= tipodebito,
                         "Categoria"= categoria,
                         "Observaciones" = observaciones,
                         "Rechazado" = rechazado,
                         "Aceptado" = aceptado,
                         "Prestacion" = codigo)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

