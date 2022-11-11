#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Matriz_de_clientes/scripts"
workdirectory <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Matriz de Clientes"
#workdirectory_archivos <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Matriz_de_clientes/archivos"
workdirectory_archivos <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Matriz de Clientes"
# Tengo que ver por que carajo me tira error, deberia probar las funciones por afuera

wd <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Matriz de Clientes/exportables"
Archivo <-"FuncionesHelper.R"

source(paste(workdirectory,Archivo,sep = "/"))


Saldos <- GetFile("SaldosCuentasCorriente_Julio.xlsx",
                  path_one = wd,
                  path_two = wd)

Saldos$Fecha <- as.Date(paste(Saldos$anio,Saldos$mes,Saldos$dia,sep = "-"))

Saldos <- select(Saldos,
                 "clienteid" = Código,
                 "saldo" = Saldo,
                 "fecha" = Fecha)

drv <- dbDriver("PostgreSQL")

con_insercion <- dbConnect(drv, dbname = "DBA",
                           host = "172.31.24.12", port = 5432,
                           user = "postgres", password = "facoep2017")


dbWriteTable(conn= con_insercion, name='saldos_clientes', value = Saldos,
             overwrite=FALSE, append=TRUE, row.names= FALSE)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
