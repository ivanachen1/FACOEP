#source("C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturacion por Prestaciones/FuncionesHelper.R")

source("E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Automatizado/FuncionesHelper.R")

#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Automatizado/data/excels" 
workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturacion por Prestaciones"

drv <- dbDriver("PostgreSQL")

#pw <- {"odoo"}
#con <- dbConnect(drv, dbname = "facoep",
#                 host = "localhost", port = 5432, 
#                 user = "odoo",password = pw)

pw <- {"serveradmin"}
con <- dbConnect(drv, dbname = "Facoep",
                 host = "10.22.0.142", port = 5432, 
                 user = "postgres", password = pw)

Efectores <- dbGetQuery(conn = con,"SELECT DISTINCT pprnombre as efectores FROM proveedorprestador")

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

Years <-GetFile("years.xlsx",path_one = workdirectory,path_two = workdirectory)


