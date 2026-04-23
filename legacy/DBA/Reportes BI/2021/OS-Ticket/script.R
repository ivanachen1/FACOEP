library(data.table)
library(tidyverse)
library(stringr)
library(openxlsx)
library(scales)
library(formattable)
library(stringr)
library(plyr)
library(zoo)
library(lubridate)
library("RPostgreSQL")
library(BBmisc)
library(glue)
library(readxl)
#library(reader)
library(stringr)

drv <- dbDriver("PostgreSQL")

con<- dbConnect(drv, dbname = "DBA",
                     host = "172.31.24.12", port = 5432,
                     user = "postgres", password = "facoep2017")

query <- dbGetQuery(conn = con,"SELECT * FROM os_ticket")

lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
