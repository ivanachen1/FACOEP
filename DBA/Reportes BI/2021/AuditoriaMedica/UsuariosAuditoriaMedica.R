workdirectory_one <- "C:/Users/iachenbach/Desktop/FACOEP/DBA/Reportes BI/2021/AuditoriaMedica/V2"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Cobranzas/Versi?n 7"

source("C:/Users/iachenbach/Desktop/FACOEP/DBA/Reportes BI/2021/AuditoriaMedica/V2/Script_AuditoriaMedica_Funciones.r")

archivo_parametros <- GetArchivoParametros(path_one = workdirectory_one, 
                                           path_two = workdirectory_two, 
                                           file = "parametros_servidor.xlsx")
pw <- GetPassword()

user <- GetUser()

host <- GetHost() 

drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv, dbname = "facoep",
                 host = host, port = 5432, 
                 user = user, password = pw)

postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")

medicos <- GetFile("medicos.xlsx",
                   path_one = workdirectory_one,
                   path_two = workdirectory_two)

medicos <- medicos$Medico
medicos <- unique(medicos)
medicos <- as.vector(medicos)
medicos <- toString(sprintf("'%s'", medicos))


CONSULTA <- glue("SELECT crgfchemision,crgauditoriamedicafecha,crgdetfechaalta,
                                    crgauditoriamedicausuario, crgdetnumerocph,
                                    c.crgnum, crgdetmotivodebcred, 
                            crgdetmotivodescripcion, crgimpbrutooriginal, crgimpbruto, crgdetimportefacturar,
                            (SELECT MAX(crghistorialfecha) FROM crghistorial WHERE crghistorial.crgnum = c.crgnum AND crghistorial.pprid = c.pprid AND crghistorialestado = 3 AND crghistorialcod >= 2 AND crghistorialfecha > '2017-01-01') AS auditoria
                            FROM crg c
                            LEFT JOIN crgdet cd ON c.crgnum = cd.crgnum and c.pprid = cd.pprid WHERE crgauditoriamedicausuario IN ({medicos})")


CONSULTA <- dbGetQuery(con, CONSULTA)


CONSULTA <- filter(CONSULTA, !is.na(auditoria))

CONSULTA$crgauditoriamedicausuario<- gsub(" ","",CONSULTA$crgauditoriamedicausuario)
  

CONSULTA$crgdetfechaalta <- as.Date(CONSULTA$crgdetfechaalta)

CONSULTA$auditoria <- as.Date(CONSULTA$auditoria)

CONSULTA$crgauditoriamedicafecha <- fifelse(CONSULTA$crgauditoriamedicafecha == "0001-01-01", CONSULTA$auditoria, CONSULTA$crgauditoriamedicafecha)

CONSULTA$crgauditoriamedicafecha <- fifelse(is.na(CONSULTA$crgauditoriamedicafecha), CONSULTA$auditoria, CONSULTA$crgauditoriamedicafecha)


AuditoriaMedica <- select(CONSULTA, "FechaAuditoriaMedica" = crgauditoriamedicafecha,
                          "Auditor" = crgauditoriamedicausuario,
                          "CRG" = crgnum,
                          "DPH" = crgdetnumerocph,
                          "Agrega" = crgdetmotivodebcred,
                          "AgregadoImporte" = crgdetimportefacturar,
                          "ImporteFinal" = crgimpbruto)

AuditoriaMedica <- aggregate(.~FechaAuditoriaMedica+Auditor+CRG+DPH+Agrega+ImporteFinal, AuditoriaMedica, sum)


AuditoriaMedica$CantidadDPH <- 1
AuditoriaMedica$DPH <- NULL


AuditoriaMedica$ImporteOriginal <- AuditoriaMedica$ImporteFinal - AuditoriaMedica$AgregadoImporte





