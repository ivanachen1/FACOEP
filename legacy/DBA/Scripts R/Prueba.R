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
library(qdap)
library("RPostgreSQL")
pw <- {"odoo"} 
drv <- dbDriver("PostgreSQL")
#con <- dbConnect(drv, dbname = "facoep",
#                 host = "localhost", port = 5432, 
#                 user = "postgres", password = pw)

con <- dbConnect(drv, dbname = "facoep",
                 host = "localhost", port = 5432, 
                user = "odoo",password = pw)

prestacion <- read.csv(file = "C:/Users/iachenbach/Documents/prestaciones.csv",header = FALSE,stringsAsFactors =  FALSE)

prestacion <- strip(prestacion,char.keep = "")


data <- dbGetQuery(con, "SELECT
      pprnombre as Efector,
      CAST(c.comprobanteentidadcodigo AS TEXT) || ' - ' || CAST(obsocialessigla AS TEXT) as OS,
      CAST(c.tipocomprobantecodigo AS TEXT) || ' - ' || CAST(c.comprobantecodigo AS TEXT) as factura,
      c.comprobantefechaemision as emision,
      comprobantecrgdetpractica as Prestacion,
      comprobantecrgdetimportefactur as ImportePrestacion


      FROM 
      	comprobantes c
                                          
      LEFT JOIN 
      	comprobantecrgdet cd ON cd.comprobantetipoentidad = c.comprobantetipoentidad and
      			      cd.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
      			      cd.tipocomprobantecodigo = c.tipocomprobantecodigo and
      			      cd.comprobanteprefijo = c.comprobanteprefijo and
      			      cd.comprobantecodigo = c.comprobantecodigo
                                                                    
      LEFT JOIN 
      	obrassociales os ON os.obsocialesclienteid = c.comprobanteentidadcodigo
                                            
      LEFT JOIN 
      	proveedorprestador pp ON pp.pprid = cd.comprobantepprid
      
      WHERE c.tipocomprobantecodigo IN ('FACA2','FACB2', 'FAECA', 'FAECB') and c.comprobantefechaemision BETWEEN '2020-03-01' and '2021-10-11' 
                   and comprobantecrgdetpractica IN ('COV.06','COV.12','COV.13','60.06','60.08.05','60.08.06')")


data <- filter(data, data$os != "1 - I.N.S.S.J. y P.")
data <- filter(data, data$os != "1003 - OSPAÃ'A")

data$cantidad <- 1

view(data)


write.csv(data, "data-testeoscovid.csv")






