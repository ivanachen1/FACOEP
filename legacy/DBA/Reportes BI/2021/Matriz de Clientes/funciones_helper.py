# -*- coding: utf-8 -*-
"""
Created on Wed Nov  9 20:20:10 2022

@author: Usuario
"""

import psycopg2
import pandas as pd

class Tools():
    
    def get_query(array_credentials,query_text):
        try:
            connection = psycopg2.connect(user= array_credentials[0],
                                          password = array_credentials[1],
                                          host = array_credentials[2],
                                          port= array_credentials[3],
                                          database = array_credentials[4])
            
            cursor = connection.cursor()
            
            postgreSQL_select_Query = query_text
        
            cursor.execute(postgreSQL_select_Query)
            res = cursor.fetchall()
            
            cols = []
            for x in cursor.description:
                cols.append(x[0])
            
            df = pd.DataFrame(data = res,columns = cols)
        
        except (Exception, psycopg2.Error) as error:
            print("Error while fetching data from PostgreSQL", error)
        
        finally:
            # closing database connection.
            if connection:
                cursor.close()
                connection.close()
                print("PostgreSQL connection is closed")
        
        return(df)
    
    def get_text_query_comprobantes(tipoentidad,codCliente,sucursal,fecha,tiposcomprobantes,empcod):
        
        # Me falta encontrar el campo 
        query_comprobantes =  ("SELECT "+ 
                               "empcod,sucursalcodigo,comprobantetipoentidad,"+
                               "comprobanteentidadcodigo, "+
                               "tipocomprobantecodigo,comprobanteprefijo,comprobantecodigo,"+
                               "comprobantefechaemision,comprobantetotalimporte FROM comprobantes "+
                               "WHERE comprobantetipoentidad = {} AND "+
                               "comprobanteentidadcodigo IN ({}) AND " +
                               "sucursalcodigo = {} AND " +
                               "comprobantefechaemision <= '{}' AND " +
                               "tipocomprobantecodigo IN ({}) AND " +
                               "empcod = '{}' AND " +
                               "comprobanteasi IS NOT true AND " +
                               "comprobanteasicuenta IS NULL").format(tipoentidad,codCliente,sucursal,
                                                                      fecha,tiposcomprobantes,empcod)
        
        return(query_comprobantes)
    
    def get_tipo_comprobante_signo():
        query = ("SELECT tipocomprobantecodigo,"+
                "tipocomprobantesigno,tipocomprobantetipoasi "+
                "FROM tipocomprobante WHERE sucursalcodigo = 2")
                
        return(query)
    
    def get_query_imputaciones(sucursalcodigo,sucursalcodigo2,tipoentidad,empcod,fechaemision,tipocomprobante):
        
        query = ("SELECT "+ 
                 "imp.empcod, "+
                 "imp.sucursalcodigo, "+
                 "imp.comprobantetipoentidad, "+
                 "imp.comprobanteentidadcodigo, "+
                 "imp.tipocomprobantecodigo, "+
                 "imp.comprobanteprefijo, "+
                 "imp.comprobantecodigo, "+
                 "imp.comprobanteimputaciontipo, "+
                 "imp.comprobanteimputacionprefijo, "+
                 "imp.comprobanteimputacioncodigo, "+
                 "imp.comprobanteimputacionfecha, "+
                 "imp.comprobanteimputacionimporte, "+
                 "aux.comprobantefechaemision, "+
                 "aux.comprobantetotalimporte, "+
                 "tipo.tipocomprobantesigno, "+
                 "tipo.tipocomprobantetipoasi "+

                 "FROM comprobantesimputaciones as imp "+

                 "LEFT JOIN comprobantes as aux "+
                 "ON "+
                 "imp.comprobanteimputacioncodigo = aux.comprobantecodigo AND "+
                 "imp.comprobanteimputaciontipo = aux.tipocomprobantecodigo AND "+
                 "imp.comprobanteimputacionprefijo = aux.comprobanteprefijo "+
                
                 "LEFT JOIN (SELECT tipocomprobantecodigo, "+
                		   "tipocomprobantesigno, "+
                		   "tipocomprobantetipoasi FROM tipocomprobante "+ 
                		   "WHERE sucursalcodigo = {}) as tipo "+
                 "ON aux.tipocomprobantecodigo = tipo.tipocomprobantecodigo "+
                
                 "WHERE imp.sucursalcodigo = {} AND imp.comprobantetipoentidad = {} AND "+
                 "imp.empcod = '{}' AND aux.comprobantefechaemision <= '{}' AND "+
                 "imp.tipocomprobantecodigo IN ({})").format(sucursalcodigo,
                                                             sucursalcodigo2,
                                                             tipoentidad,
                                                             empcod,
                                                             fechaemision,
                                                             tipocomprobante)
        return(query)                                                       
    def verificar_fecha(tabla_comprobantes,tabla_imputaciones):
        
        total = []
        for row in tabla_comprobantes.itertuples():
            empcod = row.empcod
            sucursalcodigo = row.sucursalcodigo
            tipoentidad = row.comprobantetipoentidad
            entidadcodigo = row.comprobanteentidadcodigo
            tipocomprobante = row.tipocomprobantecodigo
            comprobanteprefijo = row.comprobanteprefijo
            comprobantecodigo = row.comprobantecodigo
            valor = Tools.filter_imputaciones(tabla_imputaciones = tabla_imputaciones,
                                              empcod = empcod,
                                              sucursalcodigo = sucursalcodigo,
                                              tipoentidad = tipoentidad,
                                              entidadcodigo = entidadcodigo,
                                              tipocomprobante = tipocomprobante,
                                              comprobanteprefijo = comprobanteprefijo,
                                              comprobantecodigo = comprobantecodigo)
            total.append(valor)
        
        tabla_comprobantes['total_imputaciones'] = valor
        
        return(tabla_comprobantes)
    
    
    
    
    
    def filter_imputaciones(tabla_imputaciones,empcod,sucursalcodigo,
                            tipoentidad,entidadcodigo,tipocomprobante,
                            comprobanteprefijo,comprobantecodigo):
        
        
        df = tabla_imputaciones.query("comprobanteentidadcodigo == @entidadcodigo and tipocomprobantecodigo.str.contains(@tipocomprobante) and comprobanteprefijo == @comprobanteprefijo and comprobantecodigo == @comprobantecodigo",engine = 'python')
        
        if len(df) == 0:
            df['importe'] = 0
        else:
            df['comprobantetotalimporte'] = df['comprobantetotalimporte'].astype(float) 
            df['importe'] = df['comprobantetotalimporte'] * df['tipocomprobantesigno']
        
        return(df)
        
        
        
        
        
        
        