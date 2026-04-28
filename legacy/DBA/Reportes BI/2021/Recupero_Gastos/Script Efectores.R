workdirectory <- "C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Recupero_Gastos"
#workdirectory <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Recupero_Gastos"

Archivo <-"Script_Facturacion_Funciones.R"

source(paste(workdirectory,Archivo,sep = "/"))


archivo_parametros <- GetArchivoParametros(path_one = workdirectory,
                                           path_two = workdirectory,
                                           file = "parametros_servidor.xlsx")

Efectores <- GetFile("databases.xlsx",workdirectory,workdirectory)
