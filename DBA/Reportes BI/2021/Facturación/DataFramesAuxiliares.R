workdirectory_one <- "C:/Users/iachenbach/Gobierno de la Ciudad de Buenos Aires/Pablo Alfredo Gadea - Tablero Facoep P BI/FACOEP/DBA/Reportes BI/2021/Facturación"
workdirectory_two <- "E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Version 3"
Archivo <-"Script_Facturacion_Funciones.R"
#source("C:/Users/iachenbach/Desktop/Facoep - Scripts/DBA/Reportes BI/2021/Facturación/Script_Facturacion_Funciones.R")


GetFileAux <- function(workdirectory_one,workdirectory_two,Archivo){
  intento <- try(source(paste(workdirectory_one,Archivo,sep = "/")),silent = TRUE)
  if (class(intento) == "try-error"){
    return(source(paste(workdirectory_two,Archivo,sep = "/")))} else {return(source(paste(workdirectory_one,Archivo,sep = "/")))}
}



GetFileAux(workdirectory_one = workdirectory_one,
           workdirectory_two = workdirectory_two,
           Archivo = "Script_Facturacion_Funciones.R")


tipo_financiador <- GetFile(file_name = "tipo_financiador.xlsx",
                            path_one = workdirectory_one,
                            path_two = workdirectory_two)

Efectores <- GetFile(file_name = "Efectores.xlsx",
                     path_one = workdirectory_one,
                     path_two = workdirectory_two)

Objetivos <- GetFile(file_name = "Objetivos.xlsx",
                     path_one = workdirectory_one,
                     path_two = workdirectory_two)          

centro_costos_nombres <- GetFile(file_name = "centro_costo_comprobantes.xlsx",
                                 path_one = workdirectory_one,
                                 path_two = workdirectory_two) 

tipo_comprobante <- GetFile(file_name = "tipo_comprobante.xlsx",
                            path_one = workdirectory_one,
                            path_two = workdirectory_two)

comprobantes_a_desestimar <- GetFile(file_name = "comprobantes a desestimar.xlsx",
                                     path_one = workdirectory_one,
                                     path_two = workdirectory_two)

CodigosOOSSDesestimar <- GetFile(file_name = "Codigos Obra Social a Desestimar.xlsx",
                                 path_one = workdirectory_one,
                                 path_two = workdirectory_two)



