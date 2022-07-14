workdirectory <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Facturación"
#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/FacturaciÃ³n/Informe_Sigehos_CRG"

workdirectory_three <- "C:/Users/Usuario/Desktop/otros/EXPORT DPH ENERO A DICIEMBRE 2021"
#workdirectory_three <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/FacturaciÃ³n/Version 3/Repositorio SIGEHOS DPH Export"
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


SigehosDPH <- ReadSigehosData(workdirectory = workdirectory_three,
                              StartRow = 8)



SigehosDPH$Financiador <- gsub('AsociaciÃ³n','Asociación',SigehosDPH$Financiador)
SigehosDPH$Financiador <- gsub('MÃ©dica','Médica',SigehosDPH$Financiador)
SigehosDPH$Financiador <- gsub('COMPAÃ‘IA','COMPAÑIA',SigehosDPH$Financiador)
SigehosDPH$Financiador <- gsub('ORGANIZACIÃ“N','ORGANIZACIÓN',SigehosDPH$Financiador)
SigehosDPH$Financiador <- gsub('DESEMPEÃ‘O','DESEMPEÑO',SigehosDPH$Financiador)
SigehosDPH$Financiador <- gsub('PEQUEÃ‘A','PEQUEÑA',SigehosDPH$Financiador)
SigehosDPH$Financiador <- gsub('PorteÃ±a','Porteña',SigehosDPH$Financiador)
SigehosDPH$Financiador <- gsub('COMPAÃ‘ÃA','COMPAÑIA',SigehosDPH$Financiador)

SigehosDPH$VerificadorImporte <- grepl(",",SigehosDPH$Importe.Total) 

SigehosDPH$Importe_Total_1 <- ifelse(SigehosDPH$VerificadorImporte == TRUE,
                                     SigehosDPH$Importe.Total,-1)

SigehosDPH$Importe_Total_2 <- ifelse(SigehosDPH$VerificadorImporte == FALSE,
                                     SigehosDPH$Importe.Total,-1)

SigehosDPH <- unique(SigehosDPH)

SigehosDPH <- filter(SigehosDPH,!(is.na(Numero)))

SigehosDPH <- left_join(SigehosDPH,TipoFinanciador,by = c('Financiador' = 'Financiador'),keep = TRUE)

SigehosDPH$Verificador <-grepl("/",SigehosDPH$Fecha)

SigehosDPH$Fecha1 <- ifelse(SigehosDPH$Verificador == FALSE,
                            SigehosDPH$Fecha2 <- as.numeric(SigehosDPH$Fecha),
                            SigehosDPH$Fecha)

SigehosDPH$Fecha2 <- ifelse(SigehosDPH$Verificador == TRUE,
                            SigehosDPH$Fecha1,
                            as.Date(SigehosDPH$Fecha2,origin = "1899-12-30"))


SigehosDPHControl <- SigehosFileControl(SigehosDPH,efectores,FileName = "Control-Sigehos.xlsx")

#SigehosDPH$Fecha <- as.numeric(SigehosDPH$Fecha)

#SigehosDPH$Fecha <- as.Date(SigehosDPH$Fecha)
#SigehosDPH$Anio <- year(SigehosDPH$Fecha)

SigehosDPH <- left_join(SigehosDPH,efectores,by = c("Efector" = "EfectorSigehos"),
                        keep = FALSE)



SigehosDPH <- select(SigehosDPH,
                     "Efector" = EfectorObjetivos,
                     "Fecha" = Fecha,
                     "VerificadorFecha" = Verificador,
                     "Fecha1" = Fecha1,
                     "Fecha2" = Fecha2,
                     "NumeroDPH" = Numero,
                     "CRG" = Num..CRG,
                     "Tipo Anexo" = Tipo.Anexo,
                     "EstadoDPH" = Estado,
                     "Financiador" = Financiador.x,
                     "FinanciadorJoin"= Financiador.y,
                     "FinanciadorBienNombrado" = FinanciadorBienNombrado,
                     "Paciente" = Paciente,
                     "HistClinica" = Hist..Clin.,
                     "Fecha Egreso" = Fecha.egreso,
                     "Documento" = Documento,
                     "Tipo Cobertura" = Tipo.Cobertura,
                     "VerificadorImporte" = VerificadorImporte,
                     "ImporteTotal" = Importe.Total,
                     "Importe_Total_1" = Importe_Total_1,
                     "Importe_Total_2" = Importe_Total_2)

SigehosDPH <- unique(SigehosDPH)

FinanciadoresNoDefinidos <- filter(SigehosDPH,is.na(FinanciadorJoin))

FinanciadoresNoDefinidos <- unique(select(FinanciadoresNoDefinidos,
                                          "Financiador" = FinanciadorJoin))

#write.xlsx(FinanciadoresNoDefinidos,"Financiadores Sin Definir.xlsx")

remove(efectores,estados,FinanciadoresNoDefinidos,TipoFinanciador)

#mirar <- filter(SigehosDPH,Numero == 8250)
#mirar$ImporteTotal<- as.numeric(mirar$ImporteTotal)
