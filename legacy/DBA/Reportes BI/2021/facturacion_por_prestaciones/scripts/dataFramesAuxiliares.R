
#source("C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Facturacion por Prestaciones/FuncionesHelper.R")
source("E:/Personales/Sistemas/Agustin/Reportes BI/2021/facturacion_por_prestaciones/scripts/FuncionesHelper.R")

#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturaci?n/Automatizado/data/excels"
workdirectory <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Facturacion por Prestaciones/"

drv <- dbDriver("PostgreSQL")

#pw <- {"odoo"}
#con <- dbConnect(drv, dbname = "facoep",
#                 host = "localhost", port = 5432,
#                 user = "odoo",password = pw)

pw <- {"serveradmin"}
con <- dbConnect(drv, dbname = "Facoep",
                 host = "10.22.0.142", port = 5432,
                 user = "postgres", password = pw)

con_DBA <- dbConnect(drv, dbname = "DBA",
                     host = "172.31.24.12", port = 5432,
                     user = "postgres", password = "facoep2017")

Efectores <- dbGetQuery(conn = con,"SELECT pprid as id_efector,pprnombre as efectores FROM proveedorprestador")

Financiadores <- dbGetQuery(conn = con,"SELECT clienteid as id_cliente,clientenombre as Financiador_Nombre  FROM clientes")


Actualizacion <- dbGetQuery(conn = con_DBA,"SELECT MAX(fecha_fin) as actualizado FROM prestaciones_facturadas")


lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})


