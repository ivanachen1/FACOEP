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
pw <- {"facoep2017"} 
drv <- dbDriver("PostgreSQL")
#junio <- dbConnect(drv, dbname = "facoep30062022", host = "172.31.24.12", port = 5432, user = "postgres", password = pw)
#mayo <- dbConnect(drv, dbname = "facoep31052022", host = "172.31.24.12", port = 5432, user = "postgres", password = pw)
junio <- dbConnect(drv, dbname = "facoep30062022", host = "172.31.24.12", port = 5432, user = "postgres", password = pw)
mayo <- dbConnect(drv, dbname = "facoep31052022", host = "172.31.24.12", port = 5432, user = "postgres", password = pw)



############################################################################################################

Deuda <- dbGetQuery(mayo,"SELECT id, tipo, periodo, sum(vencido) as monto

FROM (SELECT 
c.comprobanteentidadcodigo as id,
CASE WHEN comprobantepprid = 3140 THEN 'Turismo'
     WHEN comprobantepprid = 3173 THEN 'Detectar' ELSE 'Reg-Cov' END AS Tipo,
     entrega, vencimiento,
 CASE WHEN vencimiento < '31-05-2022' THEN EXTRACT(YEAR FROM vencimiento)::varchar
      WHEN EXTRACT(MONTH FROM vencimiento) = 6 THEN 'Actual'
      WHEN vencimiento >= '01-07-2022' THEN 'A Vencer' ELSE '' END AS Periodo,
     c.tipocomprobantecodigo, c.comprobantecodigo,
comprobantesaldo as vencido
                          
FROM comprobantes c
LEFT JOIN comprobantecrg crg ON   crg.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                  crg.comprobantetipoentidad = c.comprobantetipoentidad and
                                  crg.comprobantecodigo = c.comprobantecodigo and
                                  crg.comprobanteentidadcodigo = c.comprobanteentidadcodigo
LEFT JOIN (SELECT
            comprobanteentidadcodigo,
            tipocomprobantecodigo,
            comprobantecodigo,
            MAX(comprobantehisfechatramite) as entrega,
            (MAX(comprobantehisfechatramite) + INTERVAL '60 day') as vencimiento
            FROM comprobanteshistorial 
            WHERE comprobantehisestado IN (4,13)
            GROUP BY 1,2,3) as h ON h.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
                                   h.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                   h.comprobantecodigo = c.comprobantecodigo

                          
WHERE c.tipocomprobantecodigo in ('FACA2','FACB2','FAECA','FAECB','NDA', 'NDB', 'NDECA') and
        vencimiento < '31-07-2022' and
        c.comprobantesaldo > 0 and 
        c.comprobantemandatario = 'FALSE' 
        --and c.comprobanteentidadcodigo = 270
                                
GROUP BY 1,2,3,4,5,6,7,8) as x group by 1,2,3")

## ¿ComprobanteTipo entidad 2 no va?

## Ver esto de mandatarios con el paso de los años
Mandatarios06 <-  dbGetQuery(junio, "SELECT
                          cg.id as id,
                          cg.tipo as tipo,
                          periodo::varchar,
                          sum(c.enviocomprobanteimporte) as mandatarios06
                          
                          
                          FROM enviocompdet c
                          LEFT JOIN (SELECT 
                                      cd.comprobanteentidadcodigo as id,
                                      cd.tipocomprobantecodigo,
                                      cd.comprobantecodigo,
                                     COALESCE(EXTRACT(YEAR FROM vencimiento),'2021') as periodo,
                                      CASE WHEN comprobantepprid = 3140 THEN 'Turismo'
                                       WHEN comprobantepprid = 3173 THEN 'Detectar' ELSE 'Reg-Cov' END AS Tipo
                          
                                      from comprobantecrg cd
                                      LEFT JOIN comprobantes cc ON cc.tipocomprobantecodigo = cd.tipocomprobantecodigo and 
                                                                							cc.comprobantecodigo = cd.comprobantecodigo and
                                                                							cc.comprobanteentidadcodigo = cd.comprobanteentidadcodigo
                                     LEFT JOIN (SELECT
                                                comprobanteentidadcodigo,
                                                tipocomprobantecodigo,
                                                comprobantecodigo,
                                                MAX(comprobantehisfechatramite) as entrega,
                                                (MAX(comprobantehisfechatramite) + INTERVAL '60 day') as vencimiento
                                                FROM comprobanteshistorial 
                                                WHERE comprobantehisestado IN (4,13)
                                                GROUP BY 1,2,3) as h ON h.comprobanteentidadcodigo = cc.comprobanteentidadcodigo and
                                                                       h.tipocomprobantecodigo = cc.tipocomprobantecodigo and
                                                                       h.comprobantecodigo = cc.comprobantecodigo
                                      where cd.tipocomprobantecodigo in ('FACA2','FACB2','FAECA','FAECB','NDA', 'NDB', 'NDECA') and cc.comprobantemandatario = 'TRUE'
                                      group by 1,2,3,4,5) as cg ON  cg.id = c.enviocomprobanteentidadcodigo and 
                                                                  cg.tipocomprobantecodigo = c.enviotipocomprobantecodigo and
                                                                  cg.comprobantecodigo = c.enviocomprobantecodigo
                          LEFT JOIN enviocomprobantes ec ON ec.enviocomptipo = c.enviocomptipo and ec.enviocompnro = c.enviocompnro
                          
                          WHERE cg.tipocomprobantecodigo in ('FACA2','FACB2','FAECA','FAECB','NDA', 'NDB', 'NDECA') and
                                EXTRACT(YEAR FROM ec.enviocompfecha) = 2022 and EXTRACT(MONTH FROM ec.enviocompfecha) = 6
                                -- and c.enviocomprobanteentidadcodigo = 270
                                
                          GROUP BY 1,2,3")

Reporte <- left_join(Deuda, Mandatarios06)

Recibos <- dbGetQuery(junio, "SELECT
                          c.comprobanteentidadcodigo as id,
                          CASE WHEN cg.tipo IS NULL THEN 'Reg-Cov'
                               WHEN cg.tipo = 'Reg-Cov' THEN 'Reg-Cov'
                               WHEN cg.tipo = 'Turismo' THEN 'Turismo' 
                               WHEN cg.tipo = 'Detectar' THEN 'Detectar' ELSE '' END as tipo,
                          CASE WHEN vencimiento < '31-05-2022' THEN EXTRACT(YEAR FROM vencimiento)::varchar
      WHEN EXTRACT(MONTH FROM vencimiento) = 6 THEN 'Actual'
      WHEN vencimiento >= '01-07-2022' THEN 'A Vencer' ELSE '' END AS Periodo,
                          sum(ci.comprobanteimputacionimporte) as Recibos
                          
                          
                          FROM comprobantes c
                          LEFT JOIN (SELECT 
                                      comprobanteentidadcodigo as id,
                                      tipocomprobantecodigo,
                                      comprobantecodigo,
                                      CASE WHEN comprobantepprid = 3140 THEN 'Turismo'
                                           WHEN comprobantepprid = 3173 THEN 'Detectar' ELSE 'Reg-Cov' END AS Tipo
                          
                                      from comprobantecrg
                                      where tipocomprobantecodigo in ('RECX2') --and comprobanteentidadcodigo = 270
                                      group by 1,2,3,4) as cg ON  cg.id = c.comprobanteentidadcodigo and 
                                                                  cg.tipocomprobantecodigo = c.tipocomprobantecodigo and
                                                                  cg.comprobantecodigo = c.comprobantecodigo
                                             
                          
                          LEFT JOIN comprobantesimputaciones ci ON ci.empcod = c.empcod and
  											ci.sucursalcodigo = c.sucursalcodigo and
											ci.comprobantetipoentidad = c.comprobantetipoentidad and
											ci.comprobanteentidadcodigo = c.comprobanteentidadcodigo and
											ci.tipocomprobantecodigo = c.tipocomprobantecodigo and
											ci.comprobanteprefijo = c.comprobanteprefijo and
											ci.comprobantecodigo = c.comprobantecodigo
                                            
                           LEFT JOIN (SELECT
                                    comprobanteentidadcodigo,
                                    tipocomprobantecodigo,
                                    comprobantecodigo,
                                    MAX(comprobantehisfechatramite) as entrega,
                                    (MAX(comprobantehisfechatramite) + INTERVAL '60 day') as vencimiento
                                    FROM comprobanteshistorial 
                                    WHERE comprobantehisestado IN (4,13)
                                    GROUP BY 1,2,3) as h ON h.comprobanteentidadcodigo = ci.comprobanteentidadcodigo and
                                                           h.tipocomprobantecodigo = ci.comprobanteimputaciontipo and
                                                           h.comprobantecodigo = ci.comprobanteimputacioncodigo
                                                    
                          WHERE c.tipocomprobantecodigo in ('RECX2') and ci.comprobanteimputaciontipo in ('FACA2','FACB2','FAECA','FAECB','NDA', 'NDB', 'NDECA') and
                                EXTRACT(YEAR FROM c.comprobantefechaemision) = 2022 and EXTRACT(MONTH FROM c.comprobantefechaemision) = 06 
                                --and c.comprobanteentidadcodigo = 270
                                
                          GROUP BY 1,2,3")

Reporte <- left_join(Reporte, Recibos)

lapply(dbListConnections(drv = dbDriver("PostgreSQL")),
       function(x) {dbDisconnect(conn = x)})
