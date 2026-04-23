source("E:/Personales/Sistemas/Agustin/Reportes BI/2021/facturacion_por_prestaciones/scripts/FuncionesHelper.R")
#source("C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Facturacion por Prestaciones/FuncionesHelper.R")

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "DBA",
                           host = "172.31.24.12", port = 5432,
                           user = "postgres", password = "facoep2017")


df <- dbGetQuery(conn = con,"SELECT * FROM prestaciones_facturadas")

df$id_efector <- as.integer(df$id_efector)
df$id_cliente <- as.integer(df$id_cliente)
df$id_centro_costo <- as.integer(df$id_centro_costo)
df$importe_prestacion <- as.numeric(df$importe_prestacion)
df$cantidad <- as.integer(df$cantidad)

data <- data.frame("Mes" = c(1:12),
                     "Nombre" = c("Enero","Febrero","Marzo","Abril",
                                  "Mayo","Junio","Julio","Agosto",
                                  "Septiembre","Octubre","Noviembre","Diciembre"))

df <- left_join(df,data,by = c("mes" = "Mes"))

df$fecha_inicio <- NULL
df$fecha_delete <- NULL
df$fecha_fin <- NULL
df$mes <- NULL

df1 <- pivot_wider(df,names_from = "Nombre",
                  values_from = c(importe_prestacion,cantidad),
                  values_fill = 0)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")),
       function(x) {dbDisconnect(conn = x)})
