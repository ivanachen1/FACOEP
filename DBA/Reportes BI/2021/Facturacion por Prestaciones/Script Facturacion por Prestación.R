source("C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturacion por Prestaciones/FuncionesHelper.R")

 

drv <- dbDriver("PostgreSQL")

#pw <- {"odoo"}
#con <- dbConnect(drv, dbname = "facoep",
#                 host = "localhost", port = 5432, 
#                 user = "odoo",password = pw)

pw <- {"serveradmin"}
con <- dbConnect(drv, dbname = "Facoep",
                 host = "10.22.0.142", port = 5432, 
                 user = "postgres", password = pw)

workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Automatizado/data" 
#workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturacion por Prestaciones"

#fecha_actual <- as.Date("2022-02-01")
fecha_actual <- Sys.Date()

start_date <- floor_date(fecha_actual, 'month')
end_date <- ceiling_date(fecha_actual, 'month') - 1


if(fecha_actual == start_date){
  print("entro a la condicion 1")
  fecha_fin <- fecha_actual - 1
  fecha_inicio <- floor_date(fecha_fin, 'month')}
if(fecha_actual == end_date){
  print("entro a la condicion 2")
  fecha_fin <- fecha_actual
  fecha_inicio <- floor_date(fecha_fin %m-% days(1), 'month')}
if(fecha_actual != start_date & fecha_actual != end_date){
    print("entro a la condicion 3")
  fecha_inicio <- start_date
  fecha_fin <- fecha_actual}


query <- GetQuery(fecha_actual = fecha_fin,
                  fecha_anterior = fecha_inicio)[[1]]

nombre_archivo <- GetQuery(fecha_actual = fecha_fin,
                           fecha_anterior = fecha_inicio)[[2]]


setwd(workdirectory)
data <- dbGetQuery(con,query)
if(nrow(data) == 0){
  write.csv(data,nombre_archivo)}
if(nrow(data)>0){
  data$cantidad <- 1
  data$emision <- as.Date(data$emision)
  write.csv(data,nombre_archivo)}

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})


