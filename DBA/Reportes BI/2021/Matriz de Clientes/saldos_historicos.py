# -*- coding: utf-8 -*-
"""
Created on Wed Nov  9 20:15:13 2022

@author: Usuario
"""

from funciones_helper import Tools

array_credentials = ['postgres','Galopante01','localhost',
                     5432,'Facoep'] 

query_clientes = 'SELECT clienteid FROM clientes'

clientes = Tools.get_query(array_credentials = array_credentials,
                           query_text = query_clientes)


query_tipo_comprobantes_validos = 'SELECT * FROM tipocomprobantelistados WHERE sucursalcodigo = 2 and tipocomprobantelistado = 3' 

tipos_validos = Tools.get_query(array_credentials = array_credentials,
                           query_text = query_tipo_comprobantes_validos)

tipos_validos = tipos_validos['tipocomprobantecodigo'].unique()

query_comprobantes =  ('SELECT'+ 
                       'empcod,sucursalcodigo,comprobantetipoentidad,'+
                       'tipocomprobantecodigo,comprobanteprefijo,comprobantecodigo'+
                       'comprobantefechaemision,comprobantetotalimporte FROM comprobantes'+
                       'WHERE comprobantetipoentidad = {comprobantetipoentidad} AND' +
                       'sucursalcodigo = {sucursalcodigo} AND' +
                       'comprobantefechaemision <= {comprobantefechaemision} AND' +
                       'tipocomprobantecodigo IN {tipos_validos}' +
                       'ttt')

#for cliente in clientes:
#    comprobantetipoentidad = 2
#    comprobantesaldo = 0
#    sucursalcodigo = 2
    
#    empcod = 'ASI'
    
    
