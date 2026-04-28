#workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturaci?n"
workdirectory <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/distribucion_PAMI"
workdirectory_sigehos <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Conexion CRGs"

Archivo <-"FuncionesHelper.R"

# Filtrar en la Data los anexos que necesito segun Estado

source(paste(workdirectory,Archivo,sep = "/"))

pw <- {"facoep2017"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "sigehos_recupero",
                 host = "172.31.24.12", port = 5432, 
                 user = "postgres", password = pw)

meses <- c("01 - Enero","02 - Febrero","03 - Marzo",
           "04 - Abril","05 - Mayo","06 - Junio",
           "07 - Julio","08 - Agosto","09 - Septiembre",
           "10 - Octubre","11 - Noviembre","12 - Diciembre")


alafecha <- as.Date(Sys.Date())
realizacion <- Sys.time()
postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")

EfectoresConvenio <- GetFile("Efectores.xlsx",
                     path_one = workdirectory,
                     path_two = workdirectory)

#alafecha <- as.Date(Sys.Date())
alafecha <- as.Date('2022-09-15')

Desde <- getDateRange(alafecha)[[1]]
Hasta <- getDateRange(alafecha)[[2]]

query <- getQueryAnexos(FechaDesde = Desde,
                        FechaHasta = Hasta,
                        FinanciadorNombre = 'FACOEP PAMI')

data <- dbGetQuery(conn = con,query)
data <- filter(data, (estado == 'Arancelado') | (estado == 'Facturado'))

databases <- GetFile("databases.xlsx",
                     path_one = workdirectory_sigehos,
                     path_two = workdirectory_sigehos)


EfectoresConvenio <- left_join(EfectoresConvenio,
                               databases,by = c('pprid' = 'id'))

data$Fecha <- as.Date(data$fecha)
data$Mes <- month(data$fecha)
data$Mes <- meses[ data$Mes  ]


Afiliados <- select(data, origin, Mes, documento)
Afiliados$Cantidad <- 1
Afiliados <- unique(Afiliados)
Afiliados <- select(Afiliados, origin, Mes, Cantidad)
Afiliados <- aggregate(.~origin+Mes, Afiliados, sum)
Afiliados$Total <- "Total"
Afiliados$Mes <- NULL
Afiliados <- spread(Afiliados, Total, Cantidad)
Afiliados$Percentage <- Afiliados$Total/sum(Afiliados$Total)

Afiliados <- left_join(Afiliados,EfectoresConvenio, 
                       by = c('origin' = 'database'))

Apertura <- filter(Afiliados, Convenio == TRUE)

Apertura <- select(Apertura, pprnombre, pprid, Percentage)

wb <- createWorkbook()
addWorksheet(wb, paste("Apertura", " ", month(first(data$fecha)), "-", year(first(data$fecha)), sep = ""), gridLines = TRUE)
writeData(wb, paste("Apertura", " ", month(first(data$fecha)), "-", year(first(data$fecha)), sep = ""), Apertura, colNames = FALSE)
saveWorkbook(wb, paste("Apertura", " ", month(first(data$fecha)), "-", year(first(data$fecha)),".xlsx", sep = ""), overwrite = TRUE)

# Cierra todo
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})

