source("C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturacion por Prestaciones/FuncionesHelper.R")

#pw <- {"odoo"} 
pw <- {"odoo"}
drv <- dbDriver("PostgreSQL")
#con <- dbConnect(drv, dbname = "facoep",
#                 host = "172.31.24.12", port = 5432, 
#                 user = "postgres", password = pw)

con <- dbConnect(drv, dbname = "facoep",
                 host = "localhost", port = 5432, 
                 user = "odoo",password = pw)


#setwd("E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Automatizado/data")

fecha_actual <- as.Date("2022-01-01")
#fecha_actual <- today("UTC")
fecha_anterior <- fecha_actual - 1
fecha_siguiente <- fecha_actual + 1

#Condicion del mes actual
query <- GetQuery(fecha_actual = fecha_actual,
                  fecha_anterior = fecha_anterior)[[1]]
nombre_archivo <- GetQuery(fecha_actual = fecha_actual,
                           fecha_anterior = fecha_anterior)[[2]]
print(query)

CreateFile(query = query,con = con)

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})



