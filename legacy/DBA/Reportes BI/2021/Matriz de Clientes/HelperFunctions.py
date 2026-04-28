# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
import mysql.connector
from mysql.connector import Error
from sqlalchemy import create_engine
import pandas as pd
import glob
from datetime import datetime, timedelta
from datetime import date
import sqlalchemy
import re
import psycopg2
today = date.today()
mesActual = today.month
import psycopg2.extras as extras

HOST = "asi-prod-bbdd-slave.gcba.gob.ar"
USER = 'iachenbach'
PASSWORD = 'UVnhlmg8J62zSUUKQgYNbtVhpxaiFL'
PORT = 3306

record = ""
record2 = ""

def get_MySql_DataFrame(text_query,list_columns,connection,cursor,cursor2,text_database):
    """
    

    Parameters
    ----------
    text_query : Query to execute in format text
        DESCRIPTION.
    list_columns : Array of columns
        Columns use to build dataframe.
    connection : connection object
        is the MySql connection object.
    cursor : cursor
        Is the Query cursor object.
    cursor2 : Cursor
        is the second cursor. Is use to create the query. The first one
        is use to set database
    text_database : Text
        is the database name to execute the query.

    Returns
    -------
    Dataframe Object or print.

    """
    global record
    if connection.is_connected():
        cursor.execute('USE {};'.format(text_database))
        print('USE {};'.format(text_database))
        cursor2.execute(text_query)
        record = cursor2.fetchall()
        print("Query Ejecutada a DB",text_database)
            
        dataframe = pd.DataFrame(list(record),columns= list_columns)
        return(dataframe)
    else:
        print("La conexion no está realizada,por favor revisela")

def MySql_Get_connection(text_host,text_database,text_user,text_password,port):
    try:
        connection = mysql.connector.connect(host= text_host,
                                             database= text_database,
                                             user= text_user,
                                             password= text_password,
                                             port = port)
        db_Info = connection.get_server_info()
        print("Connected to MySQL Server version ", db_Info)
        cursor = connection.cursor(buffered= True)
        cursor2 = connection.cursor(buffered= True)
    
    except Error as e:
        print("Error while connecting to MySQL", e)
        connection.close()
        print("MySQL connection is closed by error",e)
    
    return(connection,cursor,cursor2)
    
def MySql_close_connection(connection,cursor,cursor2):
    cursor.close()
    cursor2.close()
    connection.close()
    print("La conexion fue cerrada exitosamente")
    
def My_Postgres_CreateConnection(text_database,text_host,text_user,text_password,text_port):
    global record2
    try:
    
        conn = psycopg2.connect(
            database = text_database,
            user = text_user,
            password = text_password,
            host = text_host,
            port= text_port)
        
        print("La conexion fue establecida")
        
    except:
        print("No se pudo establecer la conexion")
    
    return(conn)
            
def Postgres_Insert_values(conn, df, table):
  
    tuples = [tuple(x) for x in df.to_numpy()]
  
    cols = ','.join(list(df.columns))
  
    # SQL query to execute
    query = "INSERT INTO %s(%s) VALUES %%s" % (table, cols)
    cursor = conn.cursor()
    try:
        extras.execute_values(cursor, query, tuples)
        conn.commit()
    except (Exception, psycopg2.DatabaseError) as error:
        print("Error: %s" % error)
        conn.rollback()
        cursor.close()
        return 1
    print("funcion ejecutada correctamente")
    cursor.close()

def delete_part(conn,table,date1,date2):
    """ delete part by part id """
    rows_deleted = 0
    try:

        # create a new cursor
        cur = conn.cursor()
        # execute the UPDATE  statement
        cur.execute("DELETE FROM {} WHERE fecha BETWEEN '{}' AND '{}'".format(table,date1,date2))
        # get the number of updated rows
        rows_deleted = cur.rowcount
        # Commit the changes to the database
        conn.commit()
        # Close communication with the PostgreSQL database
        cur.close()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()

    return "filas borradas = " + str(rows_deleted)

def get_crg_query(text_query,fecha_inicio,fecha_fin):
    dataQuery = str(text_query).format(fecha_inicio,fecha_fin)
    
    return(dataQuery)
    
def create_pandas_dataframe(list_databases,define_batch,longitud_dataframe,fecha_inicio,fecha_fin,list_columns,mantein_columns,text_query):
    list_dataframes = []
    contador_batch = 0
    contador_vueltas = 0
    for db in list_databases:
        print("Vuelta",contador_vueltas)
        print("Batch",contador_batch)
        if contador_batch == 0 and contador_vueltas < longitud_dataframe:
            print("Primer IF")
            connection,cursor,cursor2 = MySql_Get_connection(text_host = HOST,
                                                         text_database = 'sigehoslgc_salvear',
                                                         text_user = USER,
                                                         text_password = PASSWORD,
                                                         port = PORT)
            
            dataQuery = get_crg_query(text_query,
                                      fecha_inicio = fecha_inicio,
                                      fecha_fin = fecha_fin)
            
            dataframe = get_MySql_DataFrame(text_query = dataQuery,
                                          connection = connection,
                                          cursor = cursor,
                                          cursor2 = cursor2,
                                          text_database = db,
                                          list_columns = list_columns)
                
            dataframe["origin"] = db
            list_dataframes.append(dataframe)
            contador_batch += 1
            
        elif contador_batch > 0 and contador_batch < define_batch and contador_vueltas < longitud_dataframe:
            print("Segundo IF")
            
            dataQuery = get_crg_query(text_query,
                                      fecha_inicio = fecha_inicio,
                                      fecha_fin = fecha_fin)
            
            dataframe = get_MySql_DataFrame(text_query = dataQuery,
                                          connection = connection,
                                          cursor = cursor,
                                          cursor2 = cursor2,
                                          text_database = db,
                                          list_columns = list_columns)
            
            dataframe["origin"] = db
            list_dataframes.append(dataframe)   
            contador_batch += 1
            
        elif contador_batch == define_batch and contador_vueltas < longitud_dataframe:
            print("Tercer IF")
            dataQuery = get_crg_query(text_query,
                                      fecha_inicio = fecha_inicio,
                                      fecha_fin = fecha_fin)
                
            dataframe = get_MySql_DataFrame(dataQuery,
                                          connection = connection,
                                          cursor = cursor,
                                          cursor2 = cursor2,
                                          text_database = db,
                                          list_columns = list_columns)
             
            dataframe["origin"] = db
        
            list_dataframes.append(dataframe)
            MySql_close_connection(connection = connection, cursor = cursor, cursor2 = cursor2)    
            contador_batch = 0
        
        elif contador_vueltas == longitud_dataframe:
            print("Cuarto IF")
            
            dataQuery = get_crg_query(text_query,
                                      fecha_inicio = fecha_inicio,
                                      fecha_fin = fecha_fin)
                
            dataframe = get_MySql_DataFrame(dataQuery,
                                          connection = connection,
                                          cursor = cursor,
                                          cursor2 = cursor2,
                                          text_database = db,
                                          list_columns = list_columns)
            
            dataframe["origin"] = db
            list_dataframes.append(dataframe)
            MySql_close_connection(connection = connection, cursor = cursor, cursor2 = cursor2)
               
        contador_vueltas += 1        
                
    dataframe = pd.concat(list_dataframes,axis = 0,ignore_index= True)

    dataframe = dataframe[mantein_columns]
    
    return dataframe
    
    
    
