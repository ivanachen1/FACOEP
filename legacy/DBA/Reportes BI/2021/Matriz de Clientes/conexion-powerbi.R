#workdirectory <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturaci?n"
workdirectory <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Matriz de Clientes"
# Tengo que ver por que carajo me tira error, deberia probar las funciones por afuera

Archivo <-"FuncionesHelper.R"

source(paste(workdirectory,Archivo,sep = "/"))

archivo_parametros <- GetArchivoParametros(path_one = workdirectory,
                                           path_two = workdirectory,
                                           file = "parametros_servidor.xlsx")

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "DBA",
                 host = "172.31.24.12", port = 5432,
                 user = "postgres", password = "facoep2017")

bigMatrix <- dbGetQuery(con,"SELECT * FROM matriz_clientes")

bigMatrix <- select(bigMatrix,
                    "id" = cliente_id,
                    "Cliente" = cliente_nombre,
                    "Saldo Historico" = saldo_historico,
                    "Facturacion Bruta" = importe_facturado,
                    "Importe Notas Credito" = importe_notacredito,
                    "Importe Recibos" = importe_recibos,
                    "Importe Impugnado" = importe_impugnado,
                    "Facturacion Neta" = facturacion_neta_cliente,
                    "Facturacion Neta Total Periodo" = facturacion_neta_total,
                    "% Facturado del total" = porcentaje_cliente,
                    "% Acumulado Facturado del total" = porcentaje_facturado_acumulado,
                    "% Cobrado sobre Facturado" = porcentaje_cobrado_cliente,
                    "Categoria Facturacion" = categoria_facturacion,
                    "Categoria Impugnacion" = categoria_impugnaciones,
                    "Categoria Cobranzas" = categoria_cobranzas,
                    "Tipo Cliente" = tipo_cliente,
                    "Fecha Inicio Analisis" = inicio_analisis,
                    "Fecha Fin Analisis" = fin_analisis,
                    "Fecha Inicio Revision" = inicio_revision)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
