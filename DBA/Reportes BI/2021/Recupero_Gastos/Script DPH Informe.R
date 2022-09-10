#workdirectory <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Facturación/Nuevo Informe CRG"
workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Recupero_Gastos"

Archivo <-"Script_Facturacion_Funciones.R"

source(paste(workdirectory,Archivo,sep = "/"))


archivo_parametros <- GetArchivoParametros(path_one = workdirectory,
                                           path_two = workdirectory,
                                           file = "parametros_servidor.xlsx")

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


postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")


Query <- "SELECT * FROM dph_recupero"

DPH <- dbGetQuery(con,Query)

efectores <- GetFile("databases.xlsx",workdirectory,workdirectory)
efectores$database <- gsub(" ","",efectores$database)

DPH <- left_join(DPH,efectores,by = c("origin" = "database"))

Financiadores <- GetFile("Financiadores.xlsx",workdirectory,workdirectory)

Financiadores$verificador <- str_detect(Financiadores$Financiador,"OBRA SOCIAL")

Financiadores$Tipo.Cobertura <- ifelse(Financiadores$verificador == TRUE,
                                       "OOSS y Prepagas",
                                       Financiadores$Tipo.Cobertura)
Financiadores$verificador <- NULL

DPH <- left_join(DPH,Financiadores,by = c("financiador_nombre" = "Financiador"))

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})


#lista_financiadores <- select(DPH,
#                              "Financiador" = financiador_nombre,
#                              "Tipo Cobertura" = Tipo.Cobertura)

#lista_financiadores <- unique(lista_financiadores)

#write.xlsx(lista_financiadores,"FinanciadoresDPH.xlsx",overwrite = TRUE)


