# -*- coding: utf-8 -*-
"""
Created on Mon Aug 22 23:29:24 2022

@author: Administrador
"""
import time
inicio = time.time()
import pandas as pd
from datetime import datetime
from datetime import timedelta
import sys
sys.path.append('E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Informe_Sigehos_CRG/Conexion con DB')
import HelperFunctions as aux 

fecha_fin = datetime.today().strftime('%Y-%m-%d')

fecha_fin_resta = datetime.today()
fecha_inicio = fecha_fin_resta - timedelta(days = 365)
#fecha_inicio = '2020-01-01'
fecha_inicio = fecha_inicio.strftime('%Y-%m-%d')

databases = pd.read_excel("E:/Personales/Sistemas/Agustin/Reportes BI/2021/Facturación/Informe_Sigehos_CRG/Conexion con DB/databases.xlsx")
list_databases = databases["database"]

dataCrgQuery = str(
             "SELECT CRG.fechaEmision as FECHA,"+
             "CRG.numeroCRG as NUMERO,"+
             "tipo_anexo.descripcion as TIPO_ANEXO,"+
             "DiccEstado.Descripcion as ESTADO,"+
             "(Select count(FKCRG) from CPH where FKCRG = IDCRG group by FKCRG) as CANT_DPHs,"+
             "obrasocial.os_sigla as FINANCIADOR_SIGLA,"+
             "obrasocial.os_nombre as FINANCIADOR_NOMBRE,"+
             "CRG.importeTotalCRG as IMPORTE_TOTAL"+" "+
             "FROM CRG,tipo_anexo,DiccEstado,obrasocial "+
             "WHERE CRG.id_tipo_anexo = tipo_anexo.id_tipo_anexo "+
             "and CRG.estado = DiccEstado.IDDiccEstado "+
             "and CRG.FKFinanciador = obrasocial.os_obrasocial_id "+
             "and CRG.fechaEmision BETWEEN '{}' and '{}'")

dataDphQuery = str("SELECT CPH.fechaCreacion as FECHA, "+
               "CPH.numeroCPH as NUMERO, "+
               "tipo_anexo.descripcion as TIPO_ANEXO, " +
               "DiccEstado.Descripcion as ESTADO, "+
               "obrasocial.os_sigla as FINANCIADOR_SIGLA, "+
               "obrasocial.os_nombre as FINANCIADOR_NOMBRE, "+
               "paciente.pac_apellido as APELLIDOS, "+
               "paciente.pac_nombres as NOMBRES, "+
               "paciente.pac_nro_doc as DOCUMENTO, "+
               "CPH.ImporteTotalCPH as IMPORTE_TOTAL "+ 
               "FROM CPH " +
               "left join paciente on CPH.IDPaciente = paciente.pac_paciente_id "+
               "left join tipo_anexo on CPH.id_tipo_anexo = tipo_anexo.id_tipo_anexo "+
               "left join DiccEstado on CPH.estado = DiccEstado.IDDiccEstado "+
               "left join obrasocial on CPH.FKFinanciador = obrasocial.os_obrasocial_id "+
               "WHERE CPH.fechaCreacion BETWEEN '{}' AND '{}'")


aux.get_crg_query(text_query = dataDphQuery, fecha_inicio = fecha_inicio, fecha_fin = fecha_fin)

define_batch = 10
longitud_dataframe = len(list_databases)

crg_columns = ['fecha','numero','tipo_anexo','estado','cant_dphs',
               'financiador_sigla','financiador_nombre','importe_total']

crg_mantein_postgres_columns = ["fecha","numero","tipo_anexo","estado","cant_dphs",
                   "financiador_sigla","financiador_nombre","importe_total","origin"]

dph_columns = ['fecha','numero','tipo_anexo','estado','financiador_sigla','financiador_nombre',
               'apellidos','nombres','documento','importe_total']

dph_mantein_postgres_columns = ['fecha','numero','tipo_anexo','estado',
                                'financiador_sigla','financiador_nombre',
                                'apellidos','nombres','documento',
                                'importe_total','origin']

crgData = aux.create_pandas_dataframe(list_databases = list_databases,
                                      define_batch = define_batch,
                                      longitud_dataframe = longitud_dataframe,
                                      fecha_inicio = fecha_inicio,
                                      fecha_fin = fecha_fin,
                                      list_columns = crg_columns,
                                      mantein_columns = crg_mantein_postgres_columns,
                                      text_query = dataCrgQuery)

conn = aux.My_Postgres_CreateConnection(text_database= 'sigehos_recupero',
                           text_host = 'localhost',
                           text_user = 'postgres',
                           text_password = 'facoep2017',
                           text_port = 5432)

aux.delete_part(conn = conn,
                table = "crg_recupero",
                date1 = fecha_inicio,
                date2 = fecha_fin)

conn = aux.My_Postgres_CreateConnection(text_database= 'sigehos_recupero',
                           text_host = 'localhost',
                           text_user = 'postgres',
                           text_password = 'facoep2017',
                           text_port = 5432)

aux.Postgres_Insert_values(conn, crgData, 'crg_recupero')

dphData = aux.create_pandas_dataframe(list_databases = list_databases,
                                      define_batch = define_batch,
                                      longitud_dataframe = longitud_dataframe,
                                      fecha_inicio = fecha_inicio,
                                      fecha_fin = fecha_fin,
                                      list_columns = dph_columns,
                                      mantein_columns = dph_mantein_postgres_columns,
                                      text_query = dataDphQuery)

conn = aux.My_Postgres_CreateConnection(text_database= 'sigehos_recupero',
                           text_host = 'localhost',
                           text_user = 'postgres',
                           text_password = 'facoep2017',
                           text_port = 5432)

aux.delete_part(conn = conn,
                table = "dph_recupero",
                date1 = fecha_inicio,
                date2 = fecha_fin)

conn = aux.My_Postgres_CreateConnection(text_database= 'sigehos_recupero',
                           text_host = 'localhost',
                           text_user = 'postgres',
                           text_password = 'facoep2017',
                           text_port = 5432)

aux.Postgres_Insert_values(conn, dphData, 'dph_recupero')

fin = time.time()

distancia = round((fin - inicio) / 3600,2)



