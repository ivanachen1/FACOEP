library(RPostgreSQL)
library(data.table)
library(tidyverse)
library(stringr)
library(openxlsx)
library(scales)
library(formattable)
library(dplyr)
library(plyr)
library(zoo)
library(lubridate)
pw <- {"facoep2017"} 
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "facoep2020", host = "172.31.24.12", port = 5432, user = "postgres", password = pw)
############################################################################################################
age_years <- function(earlier, later)
{
  lt <- data.frame(earlier, later)
  age <- as.numeric(format(lt[,2],format="%Y")) - as.numeric(format(lt[,1],format="%Y"))
  
  dayOnLaterYear <- ifelse(format(lt[,1],format="%m-%d")!="02-29",
                           as.Date(paste(format(lt[,2],format="%Y"),"-",format(lt[,1],format="%m-%d"),sep="")),
                           ifelse(as.numeric(format(later,format="%Y")) %% 400 == 0 | as.numeric(format(later,format="%Y")) %% 100 != 0 & as.numeric(format(later,format="%Y")) %% 4 == 0,
                                  as.Date(paste(format(lt[,2],format="%Y"),"-",format(lt[,1],format="%m-%d"),sep="")),
                                  as.Date(paste(format(lt[,2],format="%Y"),"-","02-28",sep=""))))
  
  age[which(dayOnLaterYear > lt$later)] <- age[which(dayOnLaterYear > lt$later)] - 1
  
  age
}

# Ambulatorio

tabla <-   dbGetQuery(con, "SELECT
                          A.AUTORIZACIONFECHA AS FECHAEMISION,
                          A.AUTORIZACIONNROORDEN AS NROAUTORIZACION,
                          CASE WHEN a.afitpamiprofe=1 THEN 'PAMI' ELSE '' END
                          ||
                          CASE WHEN a.afitpamiprofe=2 THEN 'INCLUIR' ELSE '' END
                          ||
                          CASE WHEN a.afitpamiprofe=4 THEN 'INCLUIR PROV' ELSE '' END as TipoAfi,
                          CASE WHEN a.autorizacionmodo=1 THEN 'Capita' ELSE '' END
                          ||
                          CASE WHEN a.autorizacionmodo=2 THEN 'ExtraCapita' ELSE '' END AS Modo,
                          afinumdoc as documento,
                          A.AFINUMBENEFICIO AS beneficio,
                          A.AFINUMBENID AS beneficioid, 
                          F.AFIAPENOM AS nombre,
                          afifecnacimiento as nacimiento,
                          afitelefono as telefono,
                          afitelefonoalternativo telefono2,
                          afiemail
                          
                          FROM AUTORIZACION A
                          LEFT JOIN AFILIADO F ON F.AFITPAMIPROFE = A.AFITPAMIPROFE AND F.AFINUMBENEFICIO = A.AFINUMBENEFICIO AND F.AFINUMBENID = A.AFINUMBENID
                          
                          
                          WHERE A.AUTORIZACIONFECHA > '2020-01-01' and a.afitpamiprofe = 1 and a.autorizacionmodo = 1 and f.afifecbaja IS NULL
                          
                          Order by a.autorizacionfecha")
                          

tabla$edad <- age_years(tabla$nacimiento, Sys.Date()) 

AfiliadosAmbulatorio <- select(unique(tabla),
                                      "Afiliado" = nombre,
                                      "Documento" = documento,
                                      "Beneficio" = beneficio,
                                      "BeneficioID" = beneficioid,
                                      "Nacimiento" = nacimiento,
                                      "Edad" = edad,
                                      "Teléfono" = telefono,
                                      "TelefonoAlternativo" = telefono2,
                                      "CorreoElectronico" = afiemail
                                      )
AfiliadosAmbulatorio <- unique(AfiliadosAmbulatorio)

AfiliadosAmbulatorio$asd <- duplicated(AfiliadosAmbulatorio$Afiliado)


internaciones <-   dbGetQuery(con, "SELECT
                          i.informehospingresofechahora AS FECHAEMISION,
                          i.informehospnro AS NROAUTORIZACION,
                          CASE WHEN i.afitpamiprofe=1 THEN 'PAMI' ELSE '' END
                          ||
                          CASE WHEN i.afitpamiprofe=2 THEN 'INCLUIR' ELSE '' END
                          ||
                          CASE WHEN i.afitpamiprofe=4 THEN 'INCLUIR PROV' ELSE '' END as TipoAfi,
                          CASE WHEN informehospprestmodo = 1 THEN 'Capitada' ELSE '' END
||
CASE WHEN informehospprestmodo = 2 THEN 'Prestacion' ELSE '' END 
||
CASE WHEN informehospprestmodo = 3 THEN 'En Transito' ELSE '' END as Modo,
                          afinumdoc as documento,
                          i.AFINUMBENEFICIO AS beneficio,
                          i.AFINUMBENID AS beneficioid, 
                          F.AFIAPENOM AS nombre,
                          afifecnacimiento as nacimiento,
                          afitelefono as telefono,
                          afitelefonoalternativo telefono2,
                          afiemail
                          
                          FROM informehosp i
                          LEFT JOIN AFILIADO F ON F.AFITPAMIPROFE = i.AFITPAMIPROFE AND F.AFINUMBENEFICIO = i.AFINUMBENEFICIO AND F.AFINUMBENID = i.AFINUMBENID
                          
                          
                          WHERE i.informehospingresofechahora > '2020-01-01' and i.afitpamiprofe = 1 and informehospprestmodo = 1 and f.afifecbaja IS NULL")
                          

internaciones$edad <- age_years(internaciones$nacimiento, Sys.Date()) 

AfiliadosInternaciones <- select(unique(internaciones),
                               "Afiliado" = nombre,
                               "Documento" = documento,
                               "Beneficio" = beneficio,
                               "BeneficioID" = beneficioid,
                               "Nacimiento" = nacimiento,
                               "Edad" = edad,
                               "Teléfono" = telefono,
                               "TelefonoAlternativo" = telefono2,
                               "CorreoElectronico" = afiemail
)
AfiliadosInternaciones <- unique(AfiliadosInternaciones)

AfiliadosInternaciones$asd <- duplicated(AfiliadosInternaciones$Afiliado)


write.csv(AfiliadosAmbulatorio, "amb.csv")
write.csv(AfiliadosInternaciones,"int.csv")
