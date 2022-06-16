workdirectory <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Facturación"
#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturaci?n/Version4"

workdirectory_three <- "C:/Users/Usuario/Desktop/otros/Test Sigehos"
#workdirectory_three <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturaci?n/Version 3/repositorio SIGHEOS"

Archivo <-"Script_Facturacion_Funciones.R"

source(paste(workdirectory,Archivo,sep = "/"))

estados  <- GetFile("crg_estados.xlsx",
                    path_one = workdirectory,
                    path_two = workdirectory)

efectores  <- GetFile("EfectoresObjetivos.xlsx",
                      path_one = workdirectory,
                      path_two = workdirectory)

TipoFinanciador <- GetFile("tipo_financiador.xlsx",
                           path_one = workdirectory,
                           path_two = workdirectory)


SigehosCRG <- ReadSigehosData(workdirectory = workdirectory_three,
                           StartRow = 8)

SigehosCRG <- unique(SigehosCRG)

SigehosCRG <- filter(SigehosCRG,!(is.na(Numero)))

SigehosCRG <- left_join(SigehosCRG,TipoFinanciador,by = c('Financiador' = 'Financiador'),keep = TRUE)

SigehosCRG$Verificador <-grepl("/",SigehosCRG$Fecha)

SigehosCRG$Fecha1 <- ifelse(SigehosCRG$Verificador == FALSE,
                            SigehosCRG$Fecha2 <- as.numeric(SigehosCRG$Fecha),
                            SigehosCRG$Fecha)

SigehosCRG$Fecha2 <- as.Date(SigehosCRG$Fecha2,origin = "1899-12-30")


SigehosCRGControl <- SigehosFileControl(SigehosCRG,efectores,FileName = "Control-Sigehos.xlsx")

#SigehosCRG$Fecha <- as.numeric(SigehosCRG$Fecha)

#SigehosCRG$Fecha <- as.Date(SigehosCRG$Fecha)
#SigehosCRG$Anio <- year(SigehosCRG$Fecha)

SigehosCRG <- left_join(SigehosCRG,efectores,by = c("Efector" = "EfectorSigehos"),
                     keep = FALSE)

SigehosCRG <- select(SigehosCRG,
                       "Efector" = EfectorObjetivos,
                       "Fecha" = Fecha,
                       "Verificador" = Verificador,
                       "Fecha1" = Fecha1,
                       "Fecha2" = Fecha2,
                       "Numero" = Numero,
                       "Tipo Anexo" = Tipo.Anexo,
                       "Estado" = Estado,
                       "Cant DPHs" = Cant..DPHs,
                       "Financiador" = Financiador.y,
                       "Tipo Cobertura" = Tipo.Cobertura,
                       "Importe Total" = Importe.Total)

FinanciadoresNoDefinidos <- filter(SigehosCRG,is.na(Financiador))

FinanciadoresNoDefinidos <- unique(select(FinanciadoresNoDefinidos,
                                          "Financiador" = Financiador))

#write.xlsx(FinanciadoresNoDefinidos,"Financiadores Sin Definir.xlsx")

remove(efectores,estados,FinanciadoresNoDefinidos,TipoFinanciador)
