workdirectory_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/AuditoriaMedica"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/AuditoriaMedica/V2"

source("C:/Users/iachenbach/Desktop/FACOEP/DBA/Reportes BI/2021/AuditoriaMedica/V2/Script_AuditoriaMedica_Funciones.r")


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


CentroCostos <-("SELECT cc.ccostocodigo as IdCentroCosto,
                        cc.ccostoabreviatura as NombreCentroCosto,
                        sc.sccostocodigo as IDSubCentroCosto,
                        sc.sccostodescripcion as NombreSubCentroCosto
                        FROM centrocostos cc
                        LEFT JOIN subcentrocostos sc
                        ON cc.ccostocodigo = sc.ccostocodigo")


CentroCostos <- dbGetQuery(con, CentroCostos)

CentroCostos$ID <- paste(CentroCostos$idcentrocosto,CentroCostos$idsubcentrocosto,sep = "-")

