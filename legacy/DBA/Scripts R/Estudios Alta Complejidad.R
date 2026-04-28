library(openxlsx)
Resultados <- "~/Excel"

#Conexion

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname="facoep",host="192.9.201.15",port="5432",user="postgres",password="facoep2017")

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
                      CASE WHEN a.autorizacionmodo=1 THEN 'RED FACOEP' ELSE '' END
                      ||
                      CASE WHEN a.autorizacionmodo=2 THEN 'OTRA UGP' ELSE '' END AS Modo,
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
                      WHERE A.AUTORIZACIONFECHA >= '2018-02-01' AND A.AUTORIZACIONFECHA <= '2018-02-28'
                      Order by a.autorizacionfecha
                      ")
tabla <-  as.data.table(tabla)
tabla$codpractica1 <- as.numeric(tabla$codpractica)
tabla <-  tabla[codpractica1 %in% c(342001:342151 #1) RESONANCIA NUCLEAR MAGNETICA: 342001 al 342151 inclusive
                                    , 170161:170168, 177161, 177163, 177165, 177168, 180301 # 2) ECOCARDIOGRAMAS
                                    , 341001:341423, 260260, 300208:300209, 340205, 340206) #3) TOMOGRAFIAS
                ] # Filtro prácticas
# tabla <-  tabla[codpractica %in% c("341201         ", "341202         ")] # Filtro DMO
wb <- createWorkbook("aut")
addWorksheet(wb, "Prácticas", gridLines = F)
writeData(wb, "Prácticas", tabla, colNames = T, startRow = 2)
#  addStyle(wb, "Prácticas", style = s.totales, rows = 2, cols = c(1:dim(tabla)[2]), stack = T) # Estilo del título.
# Graba:
setwd(Resultados)
saveWorkbook(wb, "FACOEP Rs Autorizaciones.xlsx", overwrite = T)
openXL("FACOEP Rs Autorizaciones.xlsx") # Abrel el .xls   

