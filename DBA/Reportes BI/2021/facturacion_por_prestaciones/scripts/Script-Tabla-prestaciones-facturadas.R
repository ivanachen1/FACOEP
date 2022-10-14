#source("C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Facturacion por Prestaciones/FuncionesHelper.R")
source("E:/Personales/Sistemas/Agustin/Reportes BI/2021/facturacion_por_prestaciones/scripts/FuncionesHelper.R")


drv <- dbDriver("PostgreSQL")


pw <- {"serveradmin"}
con_prod <- dbConnect(drv, dbname = "Facoep",
                 host = "10.22.0.142", port = 5432,
                 user = "postgres", password = pw)

#workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturacion por Prestaciones"

fecha_fin <- Sys.Date()


#fecha_inicio <- as.Date('2022-01-01')
#fecha_fin <- as.Date('2022-12-31')

fecha_inicio <- ceiling_date(fecha_fin, 'month') - 1
fecha_inicio <- floor_date(fecha_inicio,unit = 'month') - 1
fecha_inicio <- floor_date(fecha_inicio,unit = 'month')

hoy <- Sys.Date()
mes_hoy <- month(hoy)
anio_hoy <- year(hoy)


query <- GetQuery(fecha_actual = fecha_fin,
                  fecha_anterior = fecha_inicio)


facturacion <- dbGetQuery(conn = con_prod,query)

#lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

facturacion$year <- year(facturacion$emision)
facturacion$month <- month(facturacion$emision)
facturacion$emision <- as.Date(facturacion$emision)

fecha_final_df <- max(facturacion$emision)
facturacion$fecha_inicio <- floor_date(facturacion$emision,'month')


facturacion$fecha_fin <- fifelse(mes_hoy == facturacion$month & anio_hoy == facturacion$year,
                                 fecha_final_df,ceiling_date(facturacion$emision,unit = 'month')-1)



fecha_final_df

facturacion$cantidad <- 1

facturacion <- select(facturacion,
                      "efectorcodigo" = efectorcodigo,
                      "codigoooss" = codigoooss,
                      "prestacion" = prestacion,
                      "importeprestacion" = importeprestacion,
                      "centrocosto" = centrocosto,
                      "fecha_inicio" = fecha_inicio,
                      "fecha_fin" = fecha_fin,
                      "year" = year,
                      "month" = month,
                      "cantidad" = cantidad)

facturacion <- aggregate(.~efectorcodigo+codigoooss+prestacion+centrocosto+year+month+fecha_inicio+fecha_fin,
                         facturacion, sum)

facturacion <- select(facturacion,
                      "id_efector" = efectorcodigo,
                      "id_cliente" = codigoooss,
                      "prestacion" = prestacion,
                      "id_centro_costo" = centrocosto,
                      "anio" = year,
                      "mes" = month,
                      "importe_prestacion" = importeprestacion,
                      "cantidad" = cantidad,
                      "fecha_inicio" = fecha_inicio,
                      "fecha_fin" = fecha_fin)

drv1 <- dbDriver("PostgreSQL")
con_insercion <- dbConnect(drv1, dbname = "DBA",
                      host = "172.31.24.12", port = 5432,
                      user = "postgres", password = "facoep2017")

fechas_borrado <- unique(facturacion$fecha_inicio)

for(fecha in fechas_borrado){
  fecha <- as.Date(fecha)
  anio_borrado <- year(fecha)
  mes_borrado <- month(fecha)
  dia_borrado <- 1
  query <- glue(paste("DELETE FROM prestaciones_facturadas",
                      "WHERE fecha_inicio = '{anio_borrado}-{mes_borrado}-{dia_borrado}'"))

  dbExecute(con_insercion, query)
}


dbWriteTable(conn = con_insercion,
             value = facturacion, name = "prestaciones_facturadas",
             row.names = FALSE,append = TRUE)


lapply(dbListConnections(drv = dbDriver("PostgreSQL")),
       function(x) {dbDisconnect(conn = x)})

