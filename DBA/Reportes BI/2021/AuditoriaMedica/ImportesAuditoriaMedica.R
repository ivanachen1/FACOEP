########################################### LIBRERIAS ########################################################
workdirectory_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/AuditoriaMedica"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/AuditoriaMedica/V2"

source("C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/AuditoriaMedica/Script_AuditoriaMedica_Funciones.r")

setwd("C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/AuditoriaMedica")


library(stringi)
library(stringr)

archivo_parametros <- GetArchivoParametros(path_one = workdirectory_one, 
                                           path_two = workdirectory_two, 
                                           file = "parametros_servidor.xlsx")
#today <- "2021-01-01"
today <- today()

year <- year(today)


database <- GetDatabase()
  
pw <- GetPassword()

user <- GetUser()

host <- GetHost() 

drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv, 
                 dbname = database,
                 host = host, 
                 port = 5432, 
                 user = user, 
                 password = pw)

postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")

medicos <- GetFile("medicos.xlsx",
                   path_one = workdirectory_one,
                   path_two = workdirectory_two)

medicos <- medicos$Medico
medicos <- unique(medicos)
medicos <- as.vector(medicos)
medicos <- toString(sprintf("'%s'", medicos))

######################################### QUERY ###################################################################

CONSULTA <- glue("SELECT crgfchemision,
                         crgauditoriamedicafecha,
                         crgdetfechaalta,
                         crgauditoriamedicausuario as Auditado,
                         crgdetnumerocph,
                         c.crgnum,
                         crgdetmotivodebcred,
                         crgdetmotivodescripcion,
                         crgimpbrutooriginal,
                         crgimpbruto,
                         crgdetimportefacturar,
                         CASE WHEN crgauditoriamedicausuario IN ({medicos}) THEN 'Verdadero' ELSE 'Falso' END AS verificador,
                        (SELECT MAX(crghistorialfecha) FROM crghistorial WHERE crghistorial.crgnum = c.crgnum AND crghistorial.pprid = c.pprid AND crghistorialestado = 3 AND crghistorialcod >= 2) AS auditoria
                        
                        FROM crg c
                        LEFT JOIN crgdet cd ON c.crgnum = cd.crgnum and c.pprid = cd.pprid
                        WHERE crgestado > 1 AND crgfchemision BETWEEN '{year}-01-01' AND '{year}-12-31' ")


CONSULTA <- dbGetQuery(con,CONSULTA)


CONSULTA <- filter(CONSULTA, !is.na(auditoria))

CONSULTA$auditado <- str_replace_all(CONSULTA$auditado, fixed(" "), "")


CONSULTA$TipoAuditoria <- ifelse(CONSULTA$verificador == "Verdadero",
                            "Auditado Medico", 
                            "Auditado")

base <- select(CONSULTA, "Fecha" = auditoria, 
               "TipoAuditoria" = TipoAuditoria, 
               "CRG" = crgnum, 
               "DPH" = crgdetnumerocph, 
               "Agrega" = crgdetmotivodebcred, 
               "ImporteFinal" = crgimpbruto, 
               "AgregadoImporte" = crgdetimportefacturar)

base <- aggregate(.~Fecha+TipoAuditoria+CRG+DPH+Agrega+ImporteFinal, base, sum)
base$AgregadoImporte <- ifelse(base$Agrega == 42, base$AgregadoImporte, 0)

base$Agrega <- NULL
base <- aggregate(.~Fecha+TipoAuditoria+CRG+DPH+ImporteFinal, base, sum)
base$CantidadDPH <- 1

base$DPH <- NULL
base <- aggregate(.~Fecha+TipoAuditoria+CRG+ImporteFinal, base, sum)
base$ImporteOriginal <- base$ImporteFinal - base$AgregadoImporte

base$Clasifica <- ifelse(base$ImporteOriginal > 200000, ">$200k",
                         ifelse(base$ImporteOriginal > 100000, ">$100k",
                                ifelse(base$ImporteOriginal > 50000, ">$50k", "<$50k")))

original <- select(base, Fecha, TipoAuditoria, CRG, CantidadDPH, Clasifica, "Importe" = ImporteOriginal)
original$TipoImporte <- "Original"

agregado <- select(base, Fecha, TipoAuditoria, CRG, CantidadDPH, Clasifica, "Importe" = AgregadoImporte)
agregado <- filter(agregado, Importe != 0)
agregado$CantidadDPH <- 0
agregado$TipoImporte <- "Agregado"

final <- rbind(original, agregado)
final$id <- paste(final$Fecha,final$TipoAuditoria,final$CRG)

nombre_archivo <- glue("AuditoriaImportes_{year}.csv")

write.csv(final,nombre_archivo)
