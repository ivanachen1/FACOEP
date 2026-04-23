#workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Cobranza por Prestaciones"
workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranza por Prestaciones"

Archivo <-"Funciones_Helper.R"

source(paste(workdirectory,Archivo,sep = "/"))

archivo_parametros <- GetArchivoParametros(path_one = workdirectory,
                                           path_two = workdirectory,
                                           file = "parametros_servidor.xlsx")

database <- GetParameter(x = archivo_parametros,"database")
pw <- GetParameter(x = archivo_parametros,"password")
host <- GetParameter(x = archivo_parametros,"host")
user <- GetParameter(x = archivo_parametros,"user")

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = database,
                 host = host, port = 5432, 
                 user = user, password = pw)

query <- glue(paste("SELECT",
              "pprnombre as Efector,",
              "CONCAT(os.clienteid,'-',os.clientenombre) as OS,",
              "CONCAT(c.tipocomprobantecodigo,'-',c.comprobanteprefijo,'-',c.comprobantecodigo) as recibo,",
              "c.comprobantefechaemision as emision,",
              "cc.comprobantecrgnro as comprobantecrgnrocrg,",
              "cd.comprobantecrgnro as comprobantecrgdetnrocrg,",
              "comprobantecrgdetpractica as Prestacion,",
              "comprobantecrgdetimportefactur as ImportePrestacion,",
              "c.comprobanteccosto as CentroCosto,",
              "c.comprobanteorigen as origen",
              
              
              "FROM comprobantes c",
              
              "LEFT JOIN", 
              "(SELECT tipocomprobantecodigo,",
                      "comprobanteprefijo,",
                      "comprobantecodigo,",
                      "comprobantepprid,",
                      "comprobantecrgnro",
               "FROM comprobantecrg) as cc",
               
               "ON c.tipocomprobantecodigo = cc.tipocomprobantecodigo AND",
               "c.comprobanteprefijo = cc.comprobanteprefijo AND",
               "c.comprobantecodigo = cc.comprobantecodigo",
              
              "LEFT JOIN comprobantecrgdet cd", 
              
              "ON cd.tipocomprobantecodigo = cc.tipocomprobantecodigo AND",
              "cd.comprobanteprefijo = cc.comprobanteprefijo AND",
              "cd.comprobantecodigo = cc.comprobantecodigo AND",
              "cd.comprobantecrgnro = cc.comprobantecrgnro AND",
              "cd.comprobantepprid = cc.comprobantepprid",
              
              
              "LEFT JOIN", 
              "clientes os ON os.clienteid = c.comprobanteentidadcodigo",
              
              "LEFT JOIN", 
              "proveedorprestador pp ON pp.pprid = cc.comprobantepprid",
              
              "WHERE c.tipocomprobantecodigo IN ('RECX2') AND",
              "c.comprobantefechaemision > '2017-01-01' AND",
              "c.comprobanteentidadcodigo <> -1"))


data <- dbGetQuery(con,query)

data <- cleanData(data)


RecibosConSinApertura <- unique(select(data,"Recibo" = recibo,
                                             "TipoApertura" = TipoApertura,
                                             "EmsionRecibo" = emision,
                                             "ObraSocial" = os,
                                             "Origen" = origen))

data <- dataTransform(data)

RecibosConSinApertura$ObraSocial <- ifelse(is.na(RecibosConSinApertura$ObraSocial),
                                           "Sin Asignar",
                                           RecibosConSinApertura$ObraSocial)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
     
