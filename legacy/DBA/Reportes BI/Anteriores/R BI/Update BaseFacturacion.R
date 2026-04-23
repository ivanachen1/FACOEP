    ########################################### LIBRERIAS ########################################################
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
    pw <- {"facoep2017"} 
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = "facoep",
                     host = "172.31.24.12", port = 5432, 
                     user = "postgres", password = pw)
    rm(pw)
    meses <- c("01 - Enero","02 - Febrero","03 - Marzo",
               "04 - Abril","05 - Mayo","06 - Junio",
               "07 - Julio","08 - Agosto","09 - Septiembre",
               "10 - Octubre","11 - Noviembre","12 - Diciembre")
    alafecha <- as.integer(format(as.Date(Sys.Date()), "%m"))
    ############################################################################################################
    
      CRG2019 <- dbGetQuery(con, "SELECT 
                                        crgfchemision as fechaemision,
                                        c.crgnum,
                                        CASE WHEN c.pprid IN (2940,3000,3001,2987,3004,2994,3003,2984,2986,2991,2988,3002,2989,3031,3085,3081,3084,3086,3082) THEN 'PRIMER NIVEL' ELSE '' END 
                                        ||
                                        CASE WHEN c.pprid IN (5,13,17,4,10,23,2,26,14,3,20,16,22) THEN 'AGUDOS' ELSE '' END
                                        ||
                                        CASE WHEN c.pprid IN (424,9,425,1644,938,1607,3075,3074) THEN 'SALUD MENTAL' ELSE '' END
                                        ||
                                        CASE WHEN c.pprid IN (6,21,11,7,15,702) THEN 'MONOVALENTE' ELSE '' END
                                        ||
                                        CASE WHEN c.pprid IN (1466,704,1855) THEN 'ODONTOLOGICO' ELSE '' END
                                        ||
                                        CASE WHEN c.pprid IN (2678,2334,41) THEN 'OTROS' ELSE '' END
                                        ||
                                        CASE WHEN c.pprid IN (25,19) THEN 'PEDIATRICO' ELSE '' END
                                        ||
                                        CASE WHEN c.pprid IN (12,8) THEN 'OFTALMOLOGICO' ELSE '' END
                                        ||
                                        CASE WHEN c.pprid IN (24) THEN 'MATERNIDAD' ELSE '' END 
                                        ||
                                        CASE WHEN c.pprid IN (3118) THEN 'EXTRAHOSPITALARIO' ELSE '' END AS TipoEfector,
                                        pprnombre as Efector,
                                        CASE WHEN obsocialestipo = 0 THEN 'NINGUNO' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 1 THEN 'OS NACIONAL' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 2 THEN 'OS PROVINCIAL' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 3 THEN 'ART/SEGURO' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 4 THEN 'MUTUAL' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 5 THEN 'FINANCIADORES' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 6 THEN 'MEDICINA PREPAGA' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 7 THEN 'OTROS/RESIDUAL' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 8 THEN 'COMPANIA DE SEGUROS' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 9 THEN 'CONSULADO' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 10 THEN 'PROGRAMA NACIONAL (CUS)' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 11 THEN 'PROGRAMA PROVINCIAL' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 12 THEN 'PRESTADORES PRIVADOS' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 13 THEN 'PROVINCIA' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 14 THEN 'MUNICIPIO' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 15 THEN 'PRESTADORES PUBLICOS' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 16 THEN 'PAMI' ELSE '' END 
                                        ||
                                        CASE WHEN obsocialestipo = 99 THEN 'NO DEFINIDA' ELSE '' END
                                        ||
                                        CASE WHEN obsocialestipo IS NULL THEN 'NO DEFINIDA' ELSE '' END AS financiadortipo,
                                        obsocialesdescripcion as financiador,
                                        (SELECT crghistorialfecha FROM crghistorial WHERE crghistorial.crgnum = c.crgnum AND crghistorial.pprid = c.pprid AND crghistorialcod = 1) AS carga,
                                        CASE WHEN c.crgestado=1 THEN 'INGRESADO' ELSE '' END
                                        ||
                                        CASE WHEN c.crgestado=3 THEN 'PROFORMA' ELSE '' END
                                        ||
                                        CASE WHEN c.crgestado=4 THEN 'FACTURADO' ELSE '' END
                                        ||
                                        CASE WHEN c.crgestado=9 THEN 'AUDITADO' ELSE '' END
                                        ||
                                        CASE WHEN c.crgestado=10 THEN 'PENDIENTE' ELSE '' END
                                        ||
                                        CASE WHEN c.crgestado IS NULL THEN 'INGRESADO' ELSE '' END AS Estado,
                                        (SELECT MAX(crghistorialfecha) FROM crghistorial WHERE crghistorial.crgnum = c.crgnum AND crghistorial.pprid = c.pprid AND crghistorialestado = 3 AND crghistorialcod >= 2) AS auditoria,
                                        (SELECT MAX(crghistorialusuario) FROM crghistorial WHERE crghistorial.crgnum = c.crgnum AND crghistorial.pprid = c.pprid AND crghistorialestado = 3 AND crghistorialcod >= 2) AS usuario,
                                        crgimpbruto as ImporteBruto,
                                        (SELECT SUM(CRGDETIMPORTEDEBITADO) + crgimpdescuento FROM CRGDET WHERE CRGNUM = C.CRGNUM AND PPRID = C.PPRID) AS DEBITOS
                                        
                                        FROM
                                        crg c
                                        
                                        LEFT JOIN proveedorprestador p ON p.pprid = c.pprid
                                        LEFT JOIN obrassociales o ON o.obsocialescodigo = c.obsocialescodigo
    
                                        
                                        WHERE
                                        crgfchemision > '2020-01-01'")
    
    CRG2019$debitos[is.na(CRG2019$debitos)] <- 0
    CRG2019$facturado <- CRG2019$importebruto - CRG2019$debitos
    CRG2019$Auditado <- ifelse(CRG2019$estado == "AUDITADO", "Si",
                             ifelse(CRG2019$estado == "FACTURADO", "Si",
                                    ifelse(CRG2019$estado == "PROFORMA", "Si", "No")))
    CRG2019$fechaemision <- format(CRG2019$fechaemision, "%Y-%m-%d")
    CRG2019$carga <- format(CRG2019$carga, "%Y-%m-%d")
    CRG2019$auditoria <-ifelse(CRG2019$Auditado == "No", NA, format(CRG2019$auditoria,"%Y-%m-%d"))
    CRG2019$setardoencargar <- as.numeric(difftime(CRG2019$carga ,CRG2019$fechaemision , units = c("days")))
    CRG2019$setardoenauditar <- as.numeric(difftime(CRG2019$auditoria ,CRG2019$carga , units = c("days")))
    CRG2019$setardoenauditar <- ifelse(is.na(CRG2019$setardoenauditar), 0, as.numeric(CRG2019$setardoenauditar))
    CRG2019$setardoenauditar <-ifelse(CRG2019$Auditado == "No", NA, CRG2019$setardoenauditar)
    
    
    
    FACTURAS <- dbGetQuery(con, "SELECT CASE WHEN comprobanteccosto = 1 THEN  'PAMI' ELSE '' END
                      ||
                      CASE WHEN comprobanteccosto = 2 THEN 'INCLUIR' ELSE '' END
                      ||
                      CASE WHEN comprobanteccosto = 5 THEN 'Seguridad Social y Privados' ELSE '' END as CentroCosto, c.comprobantefechaemision as fechaemision,
                      CASE WHEN obsocialestipo = 0 THEN 'NINGUNO' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 1 THEN 'OS NACIONAL' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 2 THEN 'OS PROVINCIAL' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 3 THEN 'ART/SEGURO' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 4 THEN 'MUTUAL' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 5 THEN 'FINANCIADORES' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 6 THEN 'MEDICINA PREPAGA' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 7 THEN 'OTROS/RESIDUAL' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 8 THEN 'COMPANIA DE SEGUROS' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 9 THEN 'CONSULADO' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 10 THEN 'PROGRAMA NACIONAL (CUS)' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 11 THEN 'PROGRAMA PROVINCIAL' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 12 THEN 'PRESTADORES PRIVADOS' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 13 THEN 'PROVINCIA' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 14 THEN 'MUNICIPIO' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 15 THEN 'PRESTADORES PUBLICOS' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 16 THEN 'PAMI' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 99 THEN 'NO DEFINIDA' ELSE '' END
                      ||
                      CASE WHEN obsocialestipo IS NULL THEN 'NO DEFINIDA' ELSE '' END AS financiadortipo,
                           clientenombre as financiador,
                           c.tipocomprobantecodigo as tipofactura, 
                           c.comprobantecodigo as factura, 
                           c.comprobanteentidadcodigo,
                           comprobantetotalimporte,
                           comprobanteimputaciontipo,
                           comprobanteimputacioncodigo,
                           comprobanteimputacionimporte
                           
                           
                           
                           FROM comprobantes c
                           left join comprobantesimputaciones as i on i.comprobantecodigo = c.comprobantecodigo and i.tipocomprobantecodigo = c.tipocomprobantecodigo
                            left join obrassociales os on os.obsocialesclienteid = c.comprobanteentidadcodigo
                           LEFT JOIN clientes on clienteid = c.comprobanteentidadcodigo
                           WHERE comprobantefechaemision > '2020-01-01' AND c.tipocomprobantecodigo IN ('FACB2', 'FACA2', 'FAECA', 'FAECB') --and comprobantehisestado = 4
                           ")
    FACTURAS <- unique(FACTURAS)
    FACTURAS$debitos <- ifelse(FACTURAS$comprobanteimputaciontipo %like% 'NC', FACTURAS$comprobanteimputacionimporte, 0)
    FACTURAS$facturado <- FACTURAS$comprobantetotalimporte - FACTURAS$debitos
    FACTURAS <- select(FACTURAS, centrocosto, financiador, fechaemision, financiadortipo, tipofactura, factura, comprobantetotalimporte,debitos, facturado)
    FACTURAS <- FACTURAS[!duplicated(FACTURAS[ , c("centrocosto","financiador", "fechaemision", "tipofactura", "factura", "comprobantetotalimporte")]),]

    FACTURAS <- select(FACTURAS, centrocosto, fechaemision, financiadortipo, financiador, tipofactura, factura, "importeneto" = comprobantetotalimporte, debitos, importefactura = facturado)
    
RECIBOS <- dbGetQuery(con, "SELECT
CASE WHEN c.comprobanteccosto = 1 THEN  'PAMI' ELSE '' END
||
CASE WHEN c.comprobanteccosto = 2 THEN 'INCLUIR' ELSE '' END
||
CASE WHEN c.comprobanteccosto = 5 THEN 'Seguridad Social y Privados' ELSE '' END as CentroCosto,
CASE WHEN obsocialestipo = 0 THEN 'NINGUNO' ELSE '' END
||
CASE WHEN obsocialestipo = 1 THEN 'OS NACIONAL' ELSE '' END
||
CASE WHEN obsocialestipo = 2 THEN 'OS PROVINCIAL' ELSE '' END
||
CASE WHEN obsocialestipo = 3 THEN 'ART/SEGURO' ELSE '' END
||
CASE WHEN obsocialestipo = 4 THEN 'MUTUAL' ELSE '' END
||
CASE WHEN obsocialestipo = 5 THEN 'FINANCIADORES' ELSE '' END
||
CASE WHEN obsocialestipo = 6 THEN 'MEDICINA PREPAGA' ELSE '' END
||
CASE WHEN obsocialestipo = 7 THEN 'OTROS/RESIDUAL' ELSE '' END
||
CASE WHEN obsocialestipo = 8 THEN 'COMPANIA DE SEGUROS' ELSE '' END
||
CASE WHEN obsocialestipo = 9 THEN 'CONSULADO' ELSE '' END
||
CASE WHEN obsocialestipo = 10 THEN 'PROGRAMA NACIONAL (CUS)' ELSE '' END
||
CASE WHEN obsocialestipo = 11 THEN 'PROGRAMA PROVINCIAL' ELSE '' END
||
CASE WHEN obsocialestipo = 12 THEN 'PRESTADORES PRIVADOS' ELSE '' END
||
CASE WHEN obsocialestipo = 13 THEN 'PROVINCIA' ELSE '' END
||
CASE WHEN obsocialestipo = 14 THEN 'MUNICIPIO' ELSE '' END
||
CASE WHEN obsocialestipo = 15 THEN 'PRESTADORES PUBLICOS' ELSE '' END
||
CASE WHEN obsocialestipo = 16 THEN 'PAMI' ELSE '' END
||
CASE WHEN obsocialestipo = 99 THEN 'NO DEFINIDA' ELSE '' END
||
CASE WHEN obsocialestipo IS NULL THEN 'NO DEFINIDA' ELSE '' END AS financiadortipo,
clientenombre as financiador,
c.tipocomprobantecodigo as tipoimputacion,
c.comprobantecodigo as imputacion,
c.comprobantetotalimporte as importeimp,
c.comprobantefechaemision as fechacobro,
comprobanteasoctipo as tipofactura,
comprobanteasoccodigo as factura,
fact.comprobantefechaemision as fechaemision,
fact.comprobantetotalimporte as importe,
comprobantehisfechatramite as fechaentrega
FROM comprobantes c
LEFT JOIN comprobantesasociados as asoc ON c.empcod = asoc.empcod and
c.sucursalcodigo = asoc.sucursalcodigo and
c.comprobantetipoentidad = asoc.comprobantetipoentidad and
c.comprobanteentidadcodigo = asoc.comprobanteentidadcodigo and
c.tipocomprobantecodigo = asoc.tipocomprobantecodigo and
c.comprobanteprefijo = asoc.comprobanteprefijo and
c.comprobantecodigo = asoc.comprobantecodigo
LEFT JOIN comprobantes as fact ON asoc.comprobanteasoctipo = fact.tipocomprobantecodigo and
asoc.comprobanteasoccodigo = fact.comprobantecodigo
LEFT JOIN comprobanteshistorial as h ON h.comprobanteentidadcodigo = fact.comprobanteentidadcodigo and
h.comprobantetipoentidad = fact.comprobantetipoentidad and
h.comprobanteprefijo = fact.comprobanteprefijo and
h.comprobantecodigo  = fact.comprobantecodigo and
h.tipocomprobantecodigo = fact.tipocomprobantecodigo
and comprobantehisestado = 4
left join clientes on clienteid = c.comprobanteentidadcodigo
left join obrassociales os on os.obsocialesclienteid = c.comprobanteentidadcodigo
WHERE c.tipocomprobantecodigo IN ('RECX2') and fact.tipocomprobantecodigo IN ('FACA2', 'FACB2', 'FAECA', 'FAECB') and
c.comprobantefechaemision > '01-01-2020' and c.comprobantefechaemision < '31-12-2020'
order by c.comprobantefechaemision
")


    RECIBOS <- RECIBOS[!duplicated(RECIBOS$imputacion, fromFirst = TRUE), ]
    
    
    COBRANZAS <- dbGetQuery(con, "SELECT
                      CASE WHEN comprobanteccosto = 1 THEN  'PAMI' ELSE '' END
                      ||
                      CASE WHEN comprobanteccosto = 2 THEN 'INCLUIR' ELSE '' END
                      ||
                      CASE WHEN comprobanteccosto = 5 THEN 'FACOEP' ELSE '' END as CentroCosto,
                      comprobantefechaemision as fechaemision,
                      CASE WHEN obsocialestipo = 0 THEN 'NINGUNO' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 1 THEN 'OS NACIONAL' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 2 THEN 'OS PROVINCIAL' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 3 THEN 'ART/SEGURO' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 4 THEN 'MUTUAL' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 5 THEN 'FINANCIADORES' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 6 THEN 'MEDICINA PREPAGA' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 7 THEN 'OTROS/RESIDUAL' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 8 THEN 'COMPANIA DE SEGUROS' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 9 THEN 'CONSULADO' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 10 THEN 'PROGRAMA NACIONAL (CUS)' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 11 THEN 'PROGRAMA PROVINCIAL' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 12 THEN 'PRESTADORES PRIVADOS' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 13 THEN 'PROVINCIA' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 14 THEN 'MUNICIPIO' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 15 THEN 'PRESTADORES PUBLICOS' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 16 THEN 'PAMI' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 99 THEN 'NO DEFINIDA' ELSE '' END
                      ||
                      CASE WHEN obsocialestipo IS NULL THEN 'NO DEFINIDA' ELSE '' END AS financiadortipo,
                      clientenombre as financiador,
                      c.tipocomprobantecodigo as tipofactura, 
                      c.comprobantecodigo as factura, 
                      comprobantetotalimporte as importe,
                      h.comprobantehisfechahora as fechaentrega,
                      comprobanteimputaciontipo as tipoimputacion,
                      comprobanteimputacioncodigo as imputacion,
                      comprobanteimputacionimporte as importeimp,
                      comprobanteimputacionfecha as fechacobro
                      
                     FROM comprobantes c
                       

                       LEFT JOIN comprobanteshistorial as h ON h.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                              h.comprobantetipoentidad = c.comprobantetipoentidad and
                                                              h.comprobanteprefijo = c.comprobanteprefijo and
                                                              h.comprobantecodigo  = c.comprobantecodigo and 
                                                              h.tipocomprobantecodigo = c.tipocomprobantecodigo 
                                                              and comprobantehisestado = 4
                                                               
                       LEFT JOIN comprobantesimputaciones i  ON i.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                              i.comprobantetipoentidad = c.comprobantetipoentidad and
                                                              i.comprobanteprefijo = c.comprobanteprefijo and
                                                              i.comprobantecodigo  = c.comprobantecodigo and 
                                                              i.tipocomprobantecodigo = c.tipocomprobantecodigo
                       left join clientes on clienteid = c.comprobanteentidadcodigo 
                       left join obrassociales os on os.obsocialesclienteid = c.comprobanteentidadcodigo
                                                              
                      
                       
                       
                       WHERE c.tipocomprobantecodigo IN ('FACB2', 'FACA2', 'FAECA', 'FAECB') and 
                       comprobanteimputaciontipo = 'RECX2' and
                       comprobanteimputacionfecha > '01-01-2020'
                       
                       order by c.comprobantefechaemision")
    COBRANZAS$tardoenpagar <- as.numeric(difftime(COBRANZAS$fechacobro, COBRANZAS$fechaentrega, units = c("days")))
    COBRANZAS$tipodeuda <- ifelse(COBRANZAS$tardoenpagar < 60, "Deuda Corriente", "Deuda Vencida")
    COBRANZAS$tardoenpagar <- format(COBRANZAS$tardoenpagar, digits = 2)
    
    
    TABLEROCOBRANZA <-
      dbGetQuery(con, "SELECT
                      CASE WHEN comprobanteccosto = 1 THEN  'PAMI' ELSE '' END
                      ||
                      CASE WHEN comprobanteccosto = 2 THEN 'INCLUIR' ELSE '' END
                      ||
                      CASE WHEN comprobanteccosto = 5 THEN 'FACOEP' ELSE '' END as CentroCosto,
                      comprobantefechaemision as fechaemision,
                      CASE WHEN obsocialestipo = 0 THEN 'NINGUNO' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 1 THEN 'OS NACIONAL' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 2 THEN 'OS PROVINCIAL' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 3 THEN 'ART/SEGURO' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 4 THEN 'MUTUAL' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 5 THEN 'FINANCIADORES' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 6 THEN 'MEDICINA PREPAGA' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 7 THEN 'OTROS/RESIDUAL' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 8 THEN 'COMPANIA DE SEGUROS' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 9 THEN 'CONSULADO' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 10 THEN 'PROGRAMA NACIONAL (CUS)' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 11 THEN 'PROGRAMA PROVINCIAL' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 12 THEN 'PRESTADORES PRIVADOS' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 13 THEN 'PROVINCIA' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 14 THEN 'MUNICIPIO' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 15 THEN 'PRESTADORES PUBLICOS' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 16 THEN 'PAMI' ELSE '' END 
                      ||
                      CASE WHEN obsocialestipo = 99 THEN 'NO DEFINIDA' ELSE '' END
                      ||
                      CASE WHEN obsocialestipo IS NULL THEN 'NO DEFINIDA' ELSE '' END AS financiadortipo,
                      clientenombre as financiador,
                      c.tipocomprobantecodigo as tipofactura, 
                      c.comprobantecodigo as factura, 
                      comprobantetotalimporte as importe,
                      h.comprobantehisfechahora as fechaentrega,
                      comprobanteimputaciontipo as tipoimputacion,
                      comprobanteimputacioncodigo as imputacion,
                      comprobanteimputacionimporte as importeimp,
                      comprobanteimputacionfecha as fechacobro
                      
                      FROM comprobantes c
                       

                       LEFT JOIN comprobanteshistorial as h ON h.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                              h.comprobantetipoentidad = c.comprobantetipoentidad and
                                                              h.comprobanteprefijo = c.comprobanteprefijo and
                                                              h.comprobantecodigo  = c.comprobantecodigo and 
                                                              h.tipocomprobantecodigo = c.tipocomprobantecodigo 
                                                              and comprobantehisestado = 4
                                                               
                       LEFT JOIN comprobantesimputaciones i  ON i.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                                              i.comprobantetipoentidad = c.comprobantetipoentidad and
                                                              i.comprobanteprefijo = c.comprobanteprefijo and
                                                              i.comprobantecodigo  = c.comprobantecodigo and 
                                                              i.tipocomprobantecodigo = c.tipocomprobantecodigo
                       left join clientes on clienteid = c.comprobanteentidadcodigo 
                       left join obrassociales os on os.obsocialesclienteid = c.comprobanteentidadcodigo
                                                              
                      
                       
                       
                       WHERE c.tipocomprobantecodigo IN ('FACB2', 'FACA2', 'FAECA', 'FAECB') and 
                       comprobanteimputaciontipo = 'RECX2' and
                       comprobantefechaemision > '01-01-2020'
                       
                       order by c.comprobantefechaemision")
    
    TABLEROCOBRANZA$tardoenpagar <- as.numeric(difftime(TABLEROCOBRANZA$fechacobro, TABLEROCOBRANZA$fechaentrega, units = c("days")))
    TABLEROCOBRANZA$tipodeuda <- ifelse(TABLEROCOBRANZA$tardoenpagar < 60, "Deuda Corriente", "Deuda Vencida")
    TABLEROCOBRANZA$tardoenpagar <- format(TABLEROCOBRANZA$tardoenpagar, digits = 2)
    
    FACTURACOBRA <- anti_join(FACTURAS, TABLEROCOBRANZA)
    FACTURACOBRA$fechaentrega <- NA
    FACTURACOBRA$tipoimputacion <- NA
    FACTURACOBRA$imputacion <- NA
    FACTURACOBRA$importeimp <- NA
    FACTURACOBRA$fechacobro <- NA
    FACTURACOBRA$tardoenpagar <- NA
    FACTURACOBRA$tipodeuda <- NA
    FACTURACOBRA$tardoenpagar <- NA
    FACTURACOBRA$debitos <- NULL
    FACTURACOBRA$importeneto <- NULL
    FACTURACOBRA$importe <- FACTURACOBRA$importefactura
    FACTURACOBRA$importefactura <- NULL
    FACTURACOBRA <- setcolorder(FACTURACOBRA, names(TABLEROCOBRANZA))
    TABLEROCOBRANZA <- rbind(TABLEROCOBRANZA, FACTURACOBRA, COBRANZAS)
    
    TABLEROCRG <- select(CRG2019,
                         "Tipo de Efector" = tipoefector,
                         "Efector" = efector, 
                         "Tipo de Financiador" = financiadortipo,
                         "Financiador" = financiador,
                         "CRG" = crgnum,
                         "Fecha de Emision" = fechaemision,
                         "Importe Bruto" = importebruto,
                         "Débitos" = debitos, 
                         "Facturado" = facturado,
                         "Fecha de Carga" = carga,
                         "Estado" = estado,
                         "Auditado" = Auditado,
                         "Fecha de Auditoria" = auditoria,
                         "Usuario Auditoria" = usuario,
                         "Se Tardo en Cargar (dias)" = setardoencargar,
                         "Se Tardo en Auditar (dias)" = setardoenauditar)
    
    
    TABLEROCOBRANZA <- select(TABLEROCOBRANZA,
                              "Centro de Costo" = centrocosto,
                              "Tipo de Financiador" = financiadortipo,
                              "Financiador" = financiador,
                              "Tipo de Factura" = tipofactura,
                              "Factura" = factura,
                              "Fecha de Emision" = fechaemision,
                              "Importe Factura" = importe,
                              "Fecha de Entrega" = fechaentrega,
                              "Tipo de Imputacion" = tipoimputacion,
                              "Imputacion" = imputacion,
                              "Importe Imputacion" = importeimp,
                              "Fecha de Cobro" = fechacobro,
                              "Se Tardo en Cobrar (dias)" = tardoenpagar,
                              "Tipo de Deuda" = tipodeuda)
    wb <-createWorkbook()
    addWorksheet(wb, "CRG SIF")
    writeData(wb,"CRG SIF", TABLEROCRG, startRow = 1)
    addWorksheet(wb, "FACTURAS EMITIDAS EN 2020")
    writeData(wb, "FACTURAS EMITIDAS EN 2020", FACTURAS, startCol = 1, startRow = 1)
    addWorksheet(wb, "RECIBOS COBRADOS EN 2020")
    writeData(wb, "RECIBOS COBRADOS EN 2020", RECIBOS, startCol = 1, startRow = 1)
    
    saveWorkbook(wb, "Update BaseFacturacion.xlsx", overwrite = TRUE)
    
          
      # Cierra todo
      lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
