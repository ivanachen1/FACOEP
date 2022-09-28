# -*- coding: utf-8 -*-
"""
Created on Tue Sep 20 19:42:34 2022

@author: Usuario
"""

import time
inicio = time.time()
import pandas as pd
from datetime import datetime
from datetime import timedelta
import sys

#sys.path.append('E:/Personales/Sistemas/Agustin/Reportes BI/2021/Matriz de Clientes')
sys.path.append('C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Matriz de Clientes')
import HelperFunctions as aux


conn = aux.My_Postgres_CreateConnection(text_database = "Facoep",
                                         text_host = "localhost",
                                         text_user = "postgres",
                                         text_password = "Galopante01",
                                         text_port = 5432)

#calendar = pd.read_csv('E:/Personales/Sistemas/Agustin/Reportes BI/2021/Matriz de Clientes/Calendar.csv')
calendar = pd.read_csv('C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Matriz de Clientes/Calendar.csv')
calendar['Date'] = pd.to_datetime(calendar['Date']).dt.date
calendar['Date'] = calendar['Date'].astype(str)

facturasQuery = str("SELECT "+ 
                    "client.clienteid as cliente_id, "+
                    "client.clientenombre as cliente, "+
                    "(SELECT MIN(comprobantefechaemision) FROM comprobantes WHERE comprobantefechaemision BETWEEN '2021-08-01' AND '2022-07-31') as fecha_minima, "+
                    "(SELECT MAX(comprobantefechaemision) FROM comprobantes WHERE comprobantefechaemision BETWEEN '2021-08-01' AND '2022-07-31') as fecha_maxima, "+
                    "comprobantes.importe_cliente as importe_cliente, "+
                    "(SELECT sum(comprobantetotalimporte) FROM comprobantes WHERE comprobantefechaemision BETWEEN '2021-08-01' AND '2022-07-31' AND "+
                    "tipocomprobantecodigo IN ('FACA2','FACB2','FAECA','FAECB') AND comprobantetipoentidad = 2) as importe_total, "+

                    "ROUND(comprobantes.importe_cliente  / (SELECT sum(comprobantetotalimporte) FROM comprobantes WHERE comprobantefechaemision BETWEEN '2021-08-01' AND '2022-07-31' AND "+
                    "tipocomprobantecodigo IN ('FACA2','FACB2','FAECA','FAECB') AND comprobantetipoentidad = 2),6) * 100 as porcentaje_cliente "+

                    "FROM clientes as client "+
                    "LEFT JOIN "+
                    
                    "(SELECT "+
                    "os.clienteid ,"+
                    "CONCAT(os.clienteid,'-',os.clientenombre) as cliente ,"+
                    "c.comprobantetipoentidad, "+
                    "c.comprobanteentidadcodigo, "+
                    "SUM(c.comprobantetotalimporte) as importe_cliente "+ 
                      
                    "FROM comprobantes c "+ 
                     
                    "LEFT JOIN clientes os "+ 
                    "ON os.clienteid = c.comprobanteentidadcodigo  "+
                    	
                    "WHERE c.comprobantetipoentidad = 2 AND "+
                    "c.tipocomprobantecodigo IN ('FACA2','FACB2','FAECA','FAECB') AND "+
                    "c.comprobantefechaemision BETWEEN '2021-08-01' AND '2022-07-31' "+ 
                    
                    "GROUP BY os.clienteid, os.clientenombre,c.comprobantetipoentidad,c.comprobanteentidadcodigo "+
                    
                    "ORDER BY importe_cliente DESC) as comprobantes "+ 
                    
                    "ON client.clienteid = comprobantes.comprobanteentidadcodigo") 

df = pd.read_sql_query(facturasQuery,con=conn)

df['importe_total'] = df['importe_total'].apply(lambda x: '%.9f' % x)

df['importe_cliente'] = df['importe_cliente'].fillna(0)
df['porcentaje_cliente'] = df['porcentaje_cliente'].fillna(0)

df['porcentaje_acumulado'] = df['porcentaje_cliente'].cumsum()

def categorizador(df):
    if df['importe_cliente'] == 0:
        return 0
    elif (df['porcentaje_acumulado'] < 80) & (df['importe_cliente'] > 0):
        return 1
    elif (df['porcentaje_acumulado'] >= 80) & (df['importe_cliente'] > 0):
        return 2


df['Categoria'] = df.apply(categorizador,axis = 1)

df['importe_cliente'] = df['importe_cliente'].apply(lambda x: '%.9f' % x)

conn.close()

df.to_csv('C:/Users/Usuario/Desktop/otros/FACOEP/DBA/Reportes BI/2021/Matriz de Clientes/Matriz Facturacion.csv')
                 