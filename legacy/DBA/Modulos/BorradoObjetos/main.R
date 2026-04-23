workdirectory <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Modulos/BorradoObjetos"
#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version4"


Archivo <-"Script_Facturacion_Funciones.R"

source(paste(workdirectory,Archivo,sep = "/"))


archivo_parametros <- GetArchivoParametros(path_one = workdirectory,
                                           path_two = workdirectory,
                                           file = "parametros_servidor.xlsx")

dfBorrar <- GetFile("Provincia_art_crg.xlsx",
                    path_one = workdirectory,
                    path_two = workdirectory)

dfBorrar$HOSPITAL <- str_trim(dfBorrar$HOSPITAL,"both")

pw <- GetParameter(x = archivo_parametros,parameter = "password")

drv <- dbDriver("PostgreSQL")

user <- GetParameter(x = archivo_parametros,parameter = "user")

host <- GetParameter(x = archivo_parametros,parameter = "host")

database <- GetParameter(x = archivo_parametros,parameter = "database")

con <- dbConnect(drv, dbname = database,
                 host = host,
                 port = 5432,
                 user = user,
                 password = pw)

ListaCrgs <- dfBorrar$CRG.NRO. 
ListaCrgs <- gsub(" ","",ListaCrgs)

unique(Proveedor$pprnombre)

Proveedor <- dbGetQuery(conn = con,
                        "SELECT pprid, pprnombre FROM proveedorprestador")

Proveedor$pprnombre <- str_trim(Proveedor$pprnombre,"both")

dfBorrar <- left_join(dfBorrar,
                      Proveedor,
                      by = c("HOSPITAL" = "pprnombre"))

ListaCrgs <- dfBorrar$CRG.NRO. 
ListaCrgs <- gsub(" ","",ListaCrgs)
ListaCrgs <- as.vector(ListaCrgs)
ListaCrgs <- toString(sprintf("'%s'", ListaCrgs))

ListaPprid <- dfBorrar$pprid
ListaPprid <- as.vector(ListaPprid)
ListaPprid <- toString(sprintf("'%s'", ListaPprid))

QueryComprobanteCRG <- glue(paste("SELECT * FROM comprobantecrg",
                                  "WHERE comprobantecrgnro IN ({ListaCrgs}) AND",
                                  "comprobantepprid IN ({ListaPprid}) AND",
                                  "comprobantecrgos IN('90004017')",sep = " "))

ComprobanteCRG <- dbGetQuery(conn = con,
                             QueryComprobanteCRG)

ComprobanteCRG <- left_join(ComprobanteCRG,
                            Proveedor,
                            by = c("comprobantepprid" = "pprid"))
ComprobanteCRG$fk <- paste(ComprobanteCRG$comprobantepprid,
                           ComprobanteCRG$comprobantecrgnro,sep = 
                             "-")
dfBorrar$pprid <- gsub(" ","",dfBorrar$pprid)
dfBorrar$CRG.NRO. <- gsub(" ","",dfBorrar$CRG.NRO.)

dfBorrar$fk <- paste(dfBorrar$pprid,
                     dfBorrar$CRG.NRO.,sep = 
                       "-")

dfBorrar <- left_join(dfBorrar,ComprobanteCRG,by = c("fk" = "fk"))

dfNoBorrar <- filter(dfBorrar,!is.na(dfBorrar$tipocomprobantecodigo))

rm(CentrosCostos,Efectores,SIF2,tipo_comprobantes,Cesacs,archivo_parametros,con,drv)
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

