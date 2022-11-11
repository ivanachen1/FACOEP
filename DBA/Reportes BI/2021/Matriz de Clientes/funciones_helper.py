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