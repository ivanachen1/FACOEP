workdirectory <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Facturación"
#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturaci?n/Version4"

workdirectory_three <- "C:/Users/Usuario/Desktop/otros/Test DPH"
#workdirectory_three <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturaci?n/Version 3/repositorio SIGHEOS"

Archivo <-"Script_Facturacion_Funciones.R"

source(paste(workdirectory,Archivo,sep = "/"))


archivo_parametros <- GetArchivoParametros(path_one = workdirectory,
                                           path_two = workdirectory,
                                           file = "parametros_servidor.xlsx")


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

SigehosDPH <- filter(SigehosDPH,!(is.na(Numero)))
SigehosDPH$Fecha <- as.numeric(SigehosDPH$Fecha)
SigehosDPH$Fecha <- as.Date(SigehosDPH$Fecha,origin = "1899-12-30")
SigehosDPH$Anio <- year(SigehosDPH$Fecha)

SigehosDPH <- left_join(SigehosDPH,efectores,by = c("Efector" = "EfectorSigehos"),
                        keep = FALSE)

SigehosDPH <- left_join(SigehosDPH,TipoFinanciador,by = c('Financiador' = 'Financiador'),
                     keep = FALSE)

SigehosDPH <- select(SigehosDPH,
                     "Fecha" = Fecha,
                     "NumDPH"= Numero,
                     "TipoAnexo" = Tipo.Anexo,
                     "Estado" = Estado,
                     "CRG" = Num..CRG,
                     "Financiador" = Financiador,
                     "Paciente" = Paciente,
                     "Documento" = Documento,
                     "HistClinica" = Hist..Clin.,
                     "FechaEgreso" = Fecha.egreso,
                     "Importe Total" = Importe.Total,
                     "Efector" = EfectorObjetivos,
                     "Año" = Anio,
                     "Tipo Cobertura" = Tipo.Cobertura)



#Matchear con Tipo de cobertura y con los Efectores para que quede bien

remove(archivo_parametros,efectores,estados,TipoFinanciador)
