############################################ LIBRERIAS ########################################################
library(data.table)
library(tidyverse)
library(stringr)
library(openxlsx)
library(scales)
library(formattable)
library(stringr)
library(plyr)
library(zoo)
library("RPostgreSQL")
library(lubridate)
library(glue)
library(BBmisc)
library(tidyr)
library(dplyr)

listaDB <- read.xlsx("E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Informe_Sigehos_CRG/Conexion con DB/databases.xlsx")

nrow(listaDB)
#install.packages('RMySQL')
require(RMySQL) #if already installed


dataframes = data.frame()

for(i in 1:nrow(listaDB)){

  db = listaDB[[1,1]]

  dbname = paste("sigehoslgc_",db,sep = "")
  con <- dbConnect(RMySQL::MySQL(),
                   host = "asi-prod-bbdd-slave.gcba.gob.ar",
                   dbname=dbname,
                   user = "iachenbach",
                   password = "UVnhlmg8J62zSUUKQgYNbtVhpxaiFL",
                   port = 3306)

  dataQuery <- paste("SELECT CRG.fechaEmision as FECHA,",
                     "CRG.numeroCRG as NUMERO,",
                     "tipo_anexo.descripcion as TIPO_ANEXO,",
                     "DiccEstado.Descripcion as ESTADO,",
                     "(Select count(FKCRG) from CPH where FKCRG = IDCRG group by FKCRG) as CANT_DPHs,",
                     "obrasocial.os_sigla as FINANCIADOR_SIGLA,",
                     "obrasocial.os_nombre as FINANCIADOR_NOMBRE,",
                     "CRG.importeTotalCRG as IMPORTE_TOTAL",
                     "FROM CRG,tipo_anexo,DiccEstado,obrasocial",
                     "WHERE CRG.id_tipo_anexo = tipo_anexo.id_tipo_anexo",
                     "and CRG.estado = DiccEstado.IDDiccEstado",
                     "and CRG.FKFinanciador = obrasocial.os_obrasocial_id",
                     "and CRG.fechaEmision BETWEEN '2020-01-01' and '2022-08-20'")

  #databaseses <- "SHOW databases"

  res <- dbGetQuery(conn = con,dataQuery)

  #write.csv(res,"Bases de datos Sigehos.csv")
  res$DB <- db
  dataframes <- rbind(dataframes, res)

  lapply(dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)

}

unique(dataf<-rames$DB)

test <- function(db){
  db = listaDB[[1]]

  dbname = paste("sigehoslgc_",db,sep = "")
  con <- dbConnect(RMySQL::MySQL(),
                   host = "asi-prod-bbdd-slave.gcba.gob.ar",
                   dbname=dbname,
                   user = "iachenbach",
                   password = "UVnhlmg8J62zSUUKQgYNbtVhpxaiFL",
                   port = 3306)

  dataQuery <- paste("SELECT CRG.fechaEmision as FECHA,",
                     "CRG.numeroCRG as NUMERO,",
                     "tipo_anexo.descripcion as TIPO_ANEXO,",
                     "DiccEstado.Descripcion as ESTADO,",
                     "(Select count(FKCRG) from CPH where FKCRG = IDCRG group by FKCRG) as CANT_DPHs,",
                     "obrasocial.os_sigla as FINANCIADOR_SIGLA,",
                     "obrasocial.os_nombre as FINANCIADOR_NOMBRE,",
                     "CRG.importeTotalCRG as IMPORTE_TOTAL",
                     "FROM CRG,tipo_anexo,DiccEstado,obrasocial",
                     "WHERE CRG.id_tipo_anexo = tipo_anexo.id_tipo_anexo",
                     "and CRG.estado = DiccEstado.IDDiccEstado",
                     "and CRG.FKFinanciador = obrasocial.os_obrasocial_id",
                     "and CRG.fechaEmision BETWEEN '2020-01-01' and '2022-08-20'")

  #databaseses <- "SHOW databases"

  res <- dbGetQuery(conn = con,dataQuery)

  #write.csv(res,"Bases de datos Sigehos.csv")
  res$DB <- db
  dataframes <- rbind(dataframes, res)

  lapply(dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)
}

dataframes <- lapply(listaDB$database,test)[[15]]

mirar <- dataframes[15][[1]]
