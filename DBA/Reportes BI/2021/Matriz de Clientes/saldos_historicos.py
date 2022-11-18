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

clientes_list = clientes['clienteid'].values.tolist()

lista_clientes = []
for client in clientes_list:
    var = "'"+str(client)+"'"
    lista_clientes.append(var)
    

lista_clientes = ','.join(lista_clientes)

query_tipo_comprobantes_validos = 'SELECT * FROM tipocomprobantelistados WHERE sucursalcodigo = 2 and tipocomprobantelistado = 3' 

tipos_validos = Tools.get_query(array_credentials = array_credentials,
                           query_text = query_tipo_comprobantes_validos)

tipos_validos = tipos_validos['tipocomprobantecodigo'].unique()

lista_tipos_validos = []
for tipo in tipos_validos:
    var = "'"+tipo+"'"
    lista_tipos_validos.append(var)
    

lista_tipos_validos = ','.join(lista_tipos_validos)
#lista = '('+lista+')'


text_comprobantes = Tools.get_text_query_comprobantes(tipoentidad = 2,
                                                     codCliente = lista_clientes, 
                                                     sucursal = 2, 
                                                     fecha = '2022-07-31',
                                                     tiposcomprobantes = lista_tipos_validos,
                                                     empcod = 'ASI')

comprobantes = Tools.get_query(array_credentials = array_credentials,
                           query_text = text_comprobantes)



text_imputaciones = Tools.get_query_imputaciones(sucursalcodigo = 2,
                                                 sucursalcodigo2 =2,
                                                 tipoentidad = 2,
                                                 empcod = 'ASI',
                                                 fechaemision = '2022-07-31',
                                                 tipocomprobante = lista_tipos_validos)

imputaciones = Tools.get_query(array_credentials = array_credentials,
                               query_text = text_imputaciones)

comprobantes['tipocomprobantecodigo'] = comprobantes['tipocomprobantecodigo'].str.strip()
comprobantes['empcod'] = comprobantes['empcod'].str.strip()
imputaciones['tipocomprobantecodigo'] = imputaciones['tipocomprobantecodigo'].str.strip()
imputaciones['empcod'] = imputaciones['empcod'].str.strip() 


#test = Tools.verificar_fecha(tabla_comprobantes = comprobantes,
#                             tabla_imputaciones = imputaciones)

testtt = Tools.filter_imputaciones(tabla_imputaciones = imputaciones,
                                   empcod = 'ASI',
                                   sucursalcodigo = 2,
                                   tipoentidad = 2,
                                   entidadcodigo = 461,
                                   tipocomprobante = 'RECX2',
                                   comprobanteprefijo = 1,
                                   comprobantecodigo = 156) 

imputaciones.dtypes    

#imputaciones.to_csv('imputaciones.csv')   
   
    
