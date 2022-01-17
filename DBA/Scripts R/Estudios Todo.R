    library(openxlsx)
    library(RPostgreSQL)
    library(data.table)
    Resultados <- "~/Excel"
    
    #Conexion
    
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname="facoep",host="172.31.24.12",port="5432",user="postgres",password="facoep2017")
    
    #/ Autoprizaciones abiertas por práctica:
    tabla <-   dbGetQuery(con, "SELECT
                          A.AUTORIZACIONFECHA AS FECHAEMISION,
                          A.AUTORIZACIONNROORDEN AS NROAUTORIZACION,
                          CASE WHEN A.AUTORIZACIONEMISOR IS NULL THEN 'FACOEP' ELSE B.PPRNOMBRE END AS EMISOR,
                          CASE WHEN A.AUTORIZACIONSOLICITANTE IS NULL THEN 'SIN SOLICITANTE' ELSE C.PPRNOMBRE END AS SOLICITANTE,
                          CASE WHEN a.afitpamiprofe=1 THEN 'PAMI' ELSE '' END
                          ||
                          CASE WHEN a.afitpamiprofe=2 THEN 'INCLUIR' ELSE '' END
                          ||
                          CASE WHEN a.afitpamiprofe=4 THEN 'INCLUIR PROV' ELSE '' END as TipoAfi,
                          A.AFINUMBENEFICIO AS AFILIADO,
                          A.AFINUMBENID AS ID, F.AFIAPENOM
                          AS AFILIADONOMBRE,
                          P.PPRNOMBRE AS PRESTADOR,
                          CASE WHEN a.autorizacionmodo=1 THEN 'Capita' ELSE '' END
                          ||
                          CASE WHEN a.autorizacionmodo=2 THEN 'ExtraCapita' ELSE '' END AS Modo,
                          A.AUTORIZACIONPRESTORDEN AS NUMOPCABECERA,
                          A.AUTORIZACIONPRESTORDENACTIVACI AS ACTIVACIONCABECERA,
                          L.AUTORIZACIONLINEAOP AS NUMOPPRACTICA,
                          L.AUTORIZACIONLINEAOPACTIVACION AS ACTIVACIONPRACTICA,
                          CASE WHEN l.autorizacionlineaorigen=1 THEN 'SOLICITADA' ELSE '' END
                          ||
                          CASE WHEN l.autorizacionlineaorigen=2 THEN 'FACTURADA' ELSE '' END
                          ||
                          CASE WHEN l.autorizacionlineaorigen=3 THEN 'SOLICITADA FACTURADA' ELSE '' END AS Origen,
                          L.AUTORIZACIONLINEANOMENCLADOR AS CODPRACTICA,
                          N.NOMENCLADORNOMBRE AS PRACTICA
                          FROM AUTORIZACION A
                          LEFT JOIN PROVEEDORPRESTADOR AS B ON A.AUTORIZACIONEMISOR = B.PPRID
                          LEFT JOIN PROVEEDORPRESTADOR AS C ON A.AUTORIZACIONSOLICITANTE = C.PPRID
                          INNER JOIN AFILIADO F ON F.AFITPAMIPROFE = A.AFITPAMIPROFE AND F.AFINUMBENEFICIO = A.AFINUMBENEFICIO AND F.AFINUMBENID = A.AFINUMBENID
                          INNER JOIN PROVEEDORPRESTADOR P ON P.PPRID = A.AUTORIZACIONPRESTADOR
                          INNER JOIN AUTORIZACIONLINEA L ON L.AUTORIZACIONNROORDEN = A.AUTORIZACIONNROORDEN
                          INNER JOIN NOMENCLADOR  N ON N.NOMENCLADORCODIGO = L.AUTORIZACIONLINEANOMENCLADOR AND N.NOMENCLADORTIPO = L.AUTORIZACIONLINEANOMENCLADORTI
                          
                          WHERE A.AUTORIZACIONFECHA BETWEEN '2021-01-01' and '2021-12-31'
                          
                          Order by a.autorizacionfecha
                          ")
    tabla <-  as.data.table(tabla)
    
    write.csv(tabla, "datos.csv")
    
    tabla <- select(tabla, "Emision" = fechaemision,
                           "Nro Autorizacion" = nroautorizacion,
                           "Emisor" = emisor,
                           "Solicitante" = solicitante,
                           "TipoAfiliado" = tipoafi,
                           "NroBeneficio" = afiliado,
                           "ID" = id,
                           "Nombre" = afiliadonombre,
                           "Prestador" = prestador,
                           "Modo" = modo,
                           "OPCabecera" = numopcabecera,
                           "ActivacionCabecera" = activacioncabecera,
                           "OPPractica" = numoppractica,
                           "ActivacionPractica" = activacionpractica,
                           "Origen" = origen)
    tabla <- unique(tabla)
    

    
    wb <- createWorkbook()
    addWorksheet(wb, "Ambulatorio", gridLines = F)
    writeData(wb, "Ambulatorio", tabla, colNames = T, startRow = 2)
    setwd(Resultados)
    saveWorkbook(wb, "Ambulatorio2021.xlsx", overwrite = T)
    
